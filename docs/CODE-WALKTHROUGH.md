# Code Walkthrough

Line-by-line explanation of every folder.

---

## Flow

```
producer/ → Kafka "orders" topic → consumers/ (3 services) → Couchbase → web/backend/ → web/frontend/
```

---

# producer/

Generates fake orders and sends to Kafka.

## producer/requirements.txt

```
kafka-python==2.0.2
faker==30.3.0
```
- `kafka-python` - Kafka client library
- `faker` - generates fake data (customer IDs)

## producer/Dockerfile

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY producer.py .
ENV KAFKA_BOOTSTRAP_SERVERS=kafka:9092
ENV TOPIC_NAME=orders
ENV SLEEP_SECONDS=2
CMD ["python", "producer.py"]
```
- Line 1: Python 3.11 slim image (smaller size)
- Line 2: Set working directory
- Line 3-4: Install dependencies first (Docker layer caching)
- Line 5: Copy code
- Line 6-8: Default env vars (overridden by ECS)
- Line 9: Run the script

## producer/producer.py

```python
import json                      # serialize orders to JSON
import os                        # read environment variables
import random                    # random amounts/countries
import time                      # sleep between orders
from datetime import datetime    # timestamps
from faker import Faker          # fake customer IDs
from kafka import KafkaProducer  # Kafka client
```

```python
BOOTSTRAP_SERVERS = os.environ["KAFKA_BOOTSTRAP_SERVERS"]  # pkc-xxx.confluent.cloud:9092
API_KEY = os.environ["CONFLUENT_API_KEY"]                  # from Secrets Manager
API_SECRET = os.environ["CONFLUENT_API_SECRET"]            # from Secrets Manager
TOPIC_NAME = os.getenv("TOPIC_NAME", "orders")             # default "orders"
SLEEP_SECONDS = float(os.getenv("SLEEP_SECONDS", "2"))     # default 2 seconds
```
- `os.environ[]` - required, crashes if missing
- `os.getenv()` - optional with default

```python
fake = Faker()  # instance for generating fake data
```

```python
def create_producer():
    return KafkaProducer(
        bootstrap_servers=BOOTSTRAP_SERVERS,     # Kafka broker address
        security_protocol="SASL_SSL",            # Confluent requires SSL + auth
        sasl_mechanism="PLAIN",                  # username/password auth
        sasl_plain_username=API_KEY,             # API key as username
        sasl_plain_password=API_SECRET,          # API secret as password
        value_serializer=lambda v: json.dumps(v).encode("utf-8"),  # dict → JSON bytes
        key_serializer=lambda k: str(k).encode("utf-8"),           # int → string bytes
        linger_ms=10,                            # batch messages for 10ms
        retries=5,                               # retry failed sends 5 times
        acks="all",                              # wait for all replicas to confirm
        api_version=(2, 6, 0),                   # skip auto-detection (faster startup)
    )
```

```python
def generate_order(order_id):
    return {
        "order_id": order_id,                                    # 1, 2, 3...
        "customer_id": fake.random_int(min=1000, max=9999),     # random 4-digit
        "amount": round(random.uniform(10, 500), 2),            # $10.00 - $500.00
        "currency": "USD",
        "country": random.choice(["US", "CA", "DE", "IN", "GB", "FR", "CN", "BR"]),
        "status": random.choice(["CREATED", "CONFIRMED", "CANCELLED"]),
        "created_at": datetime.utcnow().isoformat() + "Z",      # 2024-01-15T10:30:00Z
        "source": "order-service",
    }
```

```python
def main():
    print(f"Connecting to {BOOTSTRAP_SERVERS}...")
    producer = create_producer()                                  # connect to Kafka
    print(f"Producer ready. Publishing to '{TOPIC_NAME}'")

    order_id = 1
    while True:                                                   # infinite loop
        order = generate_order(order_id)
        future = producer.send(TOPIC_NAME, key=order["order_id"], value=order)
        # send() is async, returns Future

        try:
            meta = future.get(timeout=20)                         # wait for confirmation
            print(f"order={order_id} topic={meta.topic} partition={meta.partition} offset={meta.offset}")
        except Exception as e:
            print(f"Error: {e}")

        order_id += 1
        time.sleep(SLEEP_SECONDS)                                 # wait 2 seconds

if __name__ == "__main__":
    main()
```

---

# consumers/fraud-service/

Detects suspicious orders.

## fraud_consumer.py

```python
ORDERS_TOPIC = "orders"        # reads from here
ALERTS_TOPIC = "fraud-alerts"  # writes alerts here
```

```python
KAFKA_CONFIG = {
    "bootstrap_servers": BOOTSTRAP_SERVERS,
    "security_protocol": "SASL_SSL",
    "sasl_mechanism": "PLAIN",
    "sasl_plain_username": API_KEY,
    "sasl_plain_password": API_SECRET,
}
```
Reusable config dict for consumer and producer.

```python
consumer = KafkaConsumer(
    ORDERS_TOPIC,                                              # subscribe to "orders"
    **KAFKA_CONFIG,                                            # spread config dict
    group_id="fraud-group",                                    # consumer group name
    value_deserializer=lambda m: json.loads(m.decode("utf-8")),# JSON bytes → dict
    auto_offset_reset="earliest",                              # start from beginning if new
    enable_auto_commit=True,                                   # auto-save progress
    api_version=(2, 6, 0),
)
```
- `group_id` - Kafka delivers each message to ONE consumer per group
- `auto_offset_reset="earliest"` - read all messages if this is a new group
- `enable_auto_commit=True` - Kafka saves which messages we've read

```python
producer = KafkaProducer(
    **KAFKA_CONFIG,
    value_serializer=lambda v: json.dumps(v).encode("utf-8"),
    api_version=(2, 6, 0),
)
```
For sending fraud alerts.

```python
def is_fraud(order):
    return order.get("amount", 0) > 300 and order.get("country") not in ["US", "CA"]
```
Rule: amount > $300 AND country not US/CA = suspicious.

```python
print("Fraud service started...")

for msg in consumer:                           # blocks waiting for messages
    order = msg.value                          # deserialized dict
    print(f"[fraud] order_id={order.get('order_id')}")

    if is_fraud(order):
        alert = {
            "order_id": order["order_id"],
            "reason": "HIGH_AMOUNT_RISKY_COUNTRY",
            "amount": order["amount"],
            "country": order["country"],
        }
        producer.send(ALERTS_TOPIC, value=alert)
        print(f"[fraud] ALERT: {alert}")
```
- `for msg in consumer` - infinite loop, blocks until message arrives
- Checks fraud rule
- Sends alert to separate topic if triggered

---

# consumers/payment-service/

Simulates payment processing.

## payment_consumer.py

```python
ORDERS_TOPIC = "orders"     # reads from here
PAYMENTS_TOPIC = "payments" # writes here
```

```python
consumer = KafkaConsumer(
    ORDERS_TOPIC,
    **KAFKA_CONFIG,
    group_id="payments-group",   # different group than fraud
    ...
)
```
Different `group_id` so this service also gets ALL orders (not shared with fraud).

```python
for msg in consumer:
    order = msg.value
    print(f"[payment] order_id={order.get('order_id')}")

    time.sleep(0.1)  # simulate 100ms processing time

    payment = {
        "order_id": order["order_id"],
        "status": "PAID",
        "amount": order["amount"],
        "country": order["country"],
        "timestamp": time.time(),         # unix timestamp
    }
    producer.send(PAYMENTS_TOPIC, key=payment["order_id"], value=payment)
    print(f"[payment] processed: {payment['order_id']}")
```
- Reads order
- Waits 100ms (simulates real payment processing)
- Sends "PAID" status to payments topic

---

# consumers/analytics-service/

Stores orders to Couchbase for the dashboard.

## analytics_consumer.py

```python
from couchbase.cluster import Cluster
from couchbase.options import ClusterOptions, ClusterTimeoutOptions
from couchbase.auth import PasswordAuthenticator
```
Couchbase Python SDK.

```python
COUCHBASE_HOST = os.environ.get("COUCHBASE_HOST", "localhost")
COUCHBASE_BUCKET = os.environ.get("COUCHBASE_BUCKET", "order_analytics")
COUCHBASE_USER = os.environ.get("COUCHBASE_USERNAME", "Administrator")
COUCHBASE_PASS = os.environ.get("COUCHBASE_PASSWORD", "password")
```
Defaults for local dev, overridden by ECS secrets in production.

```python
ORDERS_TOPIC = "orders"
ANALYTICS_TOPIC = "order-analytics"
```

```python
consumer = KafkaConsumer(
    ORDERS_TOPIC,
    **KAFKA_CONFIG,
    group_id="analytics-group",  # third group, also gets ALL orders
    ...
)
```

```python
print(f"Connecting to Couchbase at {COUCHBASE_HOST}...")
collection = None
try:
    # couchbases:// for Capella (TLS), couchbase:// for local
    conn_str = f"couchbases://{COUCHBASE_HOST}" if "cloud.couchbase.com" in COUCHBASE_HOST else f"couchbase://{COUCHBASE_HOST}"
    
    cluster = Cluster(
        conn_str,
        ClusterOptions(
            PasswordAuthenticator(COUCHBASE_USER, COUCHBASE_PASS),
            timeout_options=ClusterTimeoutOptions(kv_timeout=timedelta(seconds=10))
        )
    )
    bucket = cluster.bucket(COUCHBASE_BUCKET)      # get bucket
    collection = bucket.default_collection()        # get default collection
    print(f"Connected to Couchbase bucket: {COUCHBASE_BUCKET}")
except Exception as e:
    print(f"Couchbase connection failed: {e}")
```
- Auto-detect cloud vs local based on hostname
- `couchbases://` = TLS (required for Capella)
- 10 second timeout for operations

```python
total_sales = 0.0
order_count = 0
```
Running totals (in memory).

```python
for msg in consumer:
    order = msg.value
    amount = float(order.get("amount", 0))
    total_sales += amount
    order_count += 1

    analytics = {
        "total_sales": round(total_sales, 2),
        "order_count": order_count,
    }

    producer.send(ANALYTICS_TOPIC, value=analytics)  # publish stats to Kafka
```

```python
    if collection:
        try:
            doc_id = str(order.get("order_id", uuid.uuid4()))  # document key
            order_doc = {
                **order,                                        # copy all fields
                "processed_at": str(msg.timestamp) if msg.timestamp else None,
                "kafka_offset": msg.offset,
                "kafka_partition": msg.partition,
            }
            collection.upsert(doc_id, order_doc)               # insert or update
            print(f"[analytics] order {doc_id} saved | {analytics}")
        except Exception as e:
            print(f"[analytics] couchbase error: {e}")
    else:
        print(f"[analytics] {analytics}")
```
- `upsert` = insert if new, update if exists (handles duplicates)
- Uses order_id as document key
- Adds Kafka metadata for debugging

---

# web/backend/

FastAPI serving the dashboard API.

## requirements.txt

```
fastapi
uvicorn
couchbase==4.3.0
psycopg2-binary
```
- `fastapi` - web framework
- `uvicorn` - ASGI server
- `couchbase` - database client
- `psycopg2-binary` - PostgreSQL (unused currently)

## Dockerfile

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
```
- Runs uvicorn on port 8000
- `app:app` = module `app`, variable `app`

## app.py

```python
from fastapi import FastAPI
from datetime import timedelta
import os

from couchbase.cluster import Cluster, ClusterOptions
from couchbase.auth import PasswordAuthenticator
from couchbase.options import ClusterTimeoutOptions

app = FastAPI()
```

```python
COUCHBASE_HOST = os.getenv("COUCHBASE_HOST")
COUCHBASE_BUCKET = os.getenv("COUCHBASE_BUCKET")
COUCHBASE_USER = os.getenv("COUCHBASE_USERNAME")
COUCHBASE_PASS = os.getenv("COUCHBASE_PASSWORD")
```
From ECS secrets.

```python
@app.get("/healthz")
def healthz():
    return {"status": "ok"}
```
Health check endpoint. ALB calls this every 30 seconds.

```python
@app.get("/api/analytics")
def get_analytics():
    try:
        conn_str = f"couchbases://{COUCHBASE_HOST}" if "cloud.couchbase.com" in COUCHBASE_HOST else f"couchbase://{COUCHBASE_HOST}"
        
        cluster = Cluster(
            conn_str,
            ClusterOptions(
                PasswordAuthenticator(COUCHBASE_USER, COUCHBASE_PASS),
                timeout_options=ClusterTimeoutOptions(kv_timeout=timedelta(seconds=5))
            )
        )

        bucket = cluster.bucket(COUCHBASE_BUCKET)
        result = cluster.query(f"SELECT * FROM `{COUCHBASE_BUCKET}` LIMIT 10;")
        # N1QL query - SQL-like syntax for Couchbase

        return {"status": "ok", "orders": [row for row in result]}

    except Exception as e:
        return {"error": str(e)}
```
- Connects to Couchbase
- Runs N1QL query to get last 10 orders
- Returns JSON array

---

# infra/terraform-ecs/

Infrastructure as code.

## variables.tf

```hcl
variable "ghcr_pat" {
  type        = string
  sensitive   = true                    # hidden in logs
  description = "GitHub PAT with read:packages scope"
}
```
No default = Terraform prompts for it.

```hcl
variable "confluent_api_key" {
  type        = string
  sensitive   = true
  description = "Confluent Cloud API key"
}

variable "confluent_api_secret" {
  type        = string
  sensitive   = true
  description = "Confluent Cloud API secret"
}
```

```hcl
variable "couchbase_password" {
  type        = string
  sensitive   = true
  description = "Couchbase database password"
}
```

## secrets.tf

```hcl
resource "aws_secretsmanager_secret" "ghcr" {
  name = "${var.project_name}-ghcr-credentials"
}

resource "aws_secretsmanager_secret_version" "ghcr" {
  secret_id = aws_secretsmanager_secret.ghcr.id
  secret_string = jsonencode({
    username = var.ghcr_username
    password = var.ghcr_pat
  })
}
```
Creates secret, stores as JSON.

```hcl
resource "aws_secretsmanager_secret" "confluent" {
  name = "${var.project_name}-confluent-credentials"
}

resource "aws_secretsmanager_secret_version" "confluent" {
  secret_id = aws_secretsmanager_secret.confluent.id
  secret_string = jsonencode({
    bootstrap_servers = var.confluent_bootstrap_servers
    api_key           = var.confluent_api_key
    api_secret        = var.confluent_api_secret
  })
}
```

```hcl
resource "aws_secretsmanager_secret" "couchbase" {
  name = "${var.project_name}-couchbase-credentials"
}

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

## ecs.tf (key parts)

```hcl
resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"
}
```
Creates ECS cluster.

```hcl
resource "aws_iam_role_policy" "ecs_secrets_policy" {
  policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Action = ["secretsmanager:GetSecretValue"]
      Resource = [
        aws_secretsmanager_secret.ghcr.arn,
        aws_secretsmanager_secret.confluent.arn,
        aws_secretsmanager_secret.couchbase.arn
      ]
    }]
  })
}
```
Allows ECS tasks to read secrets.

```hcl
secrets = [
  { name = "COUCHBASE_HOST", valueFrom = "${aws_secretsmanager_secret.couchbase.arn}:host::" },
  { name = "COUCHBASE_BUCKET", valueFrom = "${aws_secretsmanager_secret.couchbase.arn}:bucket::" },
  { name = "COUCHBASE_USERNAME", valueFrom = "${aws_secretsmanager_secret.couchbase.arn}:username::" },
  { name = "COUCHBASE_PASSWORD", valueFrom = "${aws_secretsmanager_secret.couchbase.arn}:password::" }
]
```
ECS injects these as environment variables. Format: `{arn}:{json_key}::`.

---

# Complete Flow

```
1. terraform apply
   └── Creates secrets in AWS Secrets Manager
   └── Creates ECS cluster, services, ALB

2. ECS starts containers
   └── Pulls images from GHCR (using ghcr secret)
   └── Injects env vars from secrets

3. Producer starts
   └── Reads KAFKA_BOOTSTRAP_SERVERS, CONFLUENT_API_KEY, CONFLUENT_API_SECRET
   └── Connects to Confluent Cloud
   └── Generates order {order_id: 1, amount: 249.99, country: "US"}
   └── Sends to "orders" topic, partition 3, offset 1000

4. Fraud service receives (group: fraud-group)
   └── Checks: amount > 300 AND country not in [US, CA]?
   └── No → skip

5. Payment service receives (group: payments-group)
   └── Waits 100ms
   └── Sends {status: "PAID"} to "payments" topic

6. Analytics service receives (group: analytics-group)
   └── Updates total_sales, order_count
   └── Connects to Couchbase Capella
   └── Upserts document with key "1"

7. User opens https://orders.jumptotech.net
   └── Frontend loads
   └── Calls GET /api/analytics
   └── Backend connects to Couchbase
   └── Runs: SELECT * FROM order_analytics LIMIT 10
   └── Returns JSON array
   └── Frontend renders dashboard
```
