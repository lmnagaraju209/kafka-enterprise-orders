# Code Walkthrough

How data flows through the system, file by file.

## The Flow

```
Producer → Kafka → Consumers → Couchbase → API → Frontend
```

---

## producer/producer.py

Generates fake orders and sends to Kafka.

```python
BOOTSTRAP_SERVERS = os.environ["KAFKA_BOOTSTRAP_SERVERS"]
API_KEY = os.environ["CONFLUENT_API_KEY"]
API_SECRET = os.environ["CONFLUENT_API_SECRET"]
```
Credentials come from ECS secrets (originally from Terraform).

```python
def create_producer():
    return KafkaProducer(
        bootstrap_servers=BOOTSTRAP_SERVERS,
        security_protocol="SASL_SSL",        # Confluent needs SSL
        sasl_mechanism="PLAIN",
        sasl_plain_username=API_KEY,
        sasl_plain_password=API_SECRET,
        value_serializer=lambda v: json.dumps(v).encode("utf-8"),
        ...
    )
```
Standard Confluent Cloud setup. `value_serializer` converts dict → JSON bytes.

```python
def generate_order(order_id):
    return {
        "order_id": order_id,
        "customer_id": fake.random_int(min=1000, max=9999),
        "amount": round(random.uniform(10, 500), 2),
        "country": random.choice(["US", "CA", "DE", "IN", "GB"]),
        ...
    }
```
Random order between $10-500, random country.

```python
while True:
    order = generate_order(order_id)
    producer.send(TOPIC_NAME, key=order["order_id"], value=order)
    order_id += 1
    time.sleep(2)
```
Infinite loop, one order every 2 seconds.

---

## consumers/fraud-service/fraud_consumer.py

Reads orders, flags suspicious ones.

```python
consumer = KafkaConsumer(
    "orders",
    group_id="fraud-group",
    value_deserializer=lambda m: json.loads(m.decode("utf-8")),
    ...
)
```
`group_id` means multiple fraud instances share the load. `deserializer` converts JSON bytes → dict.

```python
def is_fraud(order):
    return order.get("amount", 0) > 300 and order.get("country") not in ["US", "CA"]
```
Simple rule: >$300 from outside US/CA = suspicious.

```python
for msg in consumer:
    order = msg.value
    if is_fraud(order):
        alert = {"order_id": order["order_id"], "reason": "HIGH_AMOUNT_RISKY_COUNTRY", ...}
        producer.send("fraud-alerts", value=alert)
```
Blocks waiting for messages. Sends alert to separate topic if fraud.

---

## consumers/payment-service/payment_consumer.py

Simulates payment processing.

```python
for msg in consumer:
    order = msg.value
    time.sleep(0.1)  # fake processing delay
    
    payment = {"order_id": order["order_id"], "status": "PAID", ...}
    producer.send("payments", key=payment["order_id"], value=payment)
```
Reads order, waits 100ms, marks as PAID, sends to payments topic.

---

## consumers/analytics-service/analytics_consumer.py

Stores orders to Couchbase for the dashboard.

```python
conn_str = f"couchbases://{COUCHBASE_HOST}" if "cloud.couchbase.com" in COUCHBASE_HOST else f"couchbase://{COUCHBASE_HOST}"
```
`couchbases://` for Capella (TLS), `couchbase://` for local.

```python
cluster = Cluster(
    conn_str,
    ClusterOptions(
        PasswordAuthenticator(COUCHBASE_USER, COUCHBASE_PASS),
        timeout_options=ClusterTimeoutOptions(kv_timeout=timedelta(seconds=10))
    )
)
bucket = cluster.bucket(COUCHBASE_BUCKET)
collection = bucket.default_collection()
```
Connect, get bucket, get collection.

```python
for msg in consumer:
    order = msg.value
    doc_id = str(order.get("order_id"))
    order_doc = {
        **order,
        "kafka_offset": msg.offset,
        "kafka_partition": msg.partition,
    }
    collection.upsert(doc_id, order_doc)
```
Uses order_id as document key. `upsert` = insert or update.

---

## web/backend/app.py

FastAPI serving the dashboard data.

```python
@app.get("/healthz")
def healthz():
    return {"status": "ok"}
```
ALB health check endpoint.

```python
@app.get("/api/analytics")
def get_analytics():
    cluster = Cluster(...)
    bucket = cluster.bucket(COUCHBASE_BUCKET)
    result = cluster.query(f"SELECT * FROM `{COUCHBASE_BUCKET}` LIMIT 10;")
    return {"status": "ok", "orders": [row for row in result]}
```
Connects to Couchbase, runs N1QL query, returns last 10 orders.

---

## infra/terraform-ecs/secrets.tf

Creates AWS Secrets Manager entries.

```hcl
resource "aws_secretsmanager_secret_version" "couchbase" {
  secret_id = aws_secretsmanager_secret.couchbase.id
  secret_string = jsonencode({
    host     = var.couchbase_host
    bucket   = var.couchbase_bucket
    username = var.couchbase_username
    password = var.couchbase_password
  })
}
```
Stores creds as JSON. Values come from `terraform apply` prompts.

---

## infra/terraform-ecs/ecs.tf

Injects secrets into containers.

```hcl
secrets = [
  { name = "COUCHBASE_HOST", valueFrom = "${aws_secretsmanager_secret.couchbase.arn}:host::" },
  { name = "COUCHBASE_PASSWORD", valueFrom = "${aws_secretsmanager_secret.couchbase.arn}:password::" },
  ...
]
```
ECS reads from Secrets Manager at startup, injects as env vars. Format is `{arn}:{json_key}::`.

---

## End-to-End Trace

1. Producer generates `{order_id: 123, amount: 350, country: "DE"}`
2. Sends to Kafka topic "orders", lands on partition 2
3. Fraud service reads it, sees amount > 300 AND country != US/CA
4. Fraud sends alert to "fraud-alerts" topic
5. Payment service reads same order (different consumer group)
6. Payment sends `{status: "PAID"}` to "payments"
7. Analytics service reads order, writes to Couchbase with doc_id "123"
8. User hits dashboard, frontend calls `/api/analytics`
9. Backend queries Couchbase, returns order 123 in the list

---

## Notes

**Consumer groups** - Each service has its own group_id so they all get every message independently.

**Partitioning** - 6 partitions per topic. Same order_id always goes to same partition (ordering guarantee).

**Upsert** - Handles duplicates. If Kafka redelivers, we just overwrite the doc.

**Secret flow** - Terraform creates secrets → ECS reads at startup → containers get env vars → code reads with `os.environ`.
