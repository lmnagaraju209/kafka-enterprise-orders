import json
import os
import uuid
from datetime import timedelta
from kafka import KafkaConsumer, KafkaProducer
from couchbase.cluster import Cluster
from couchbase.options import ClusterOptions, ClusterTimeoutOptions
from couchbase.auth import PasswordAuthenticator

BOOTSTRAP_SERVERS = os.environ["KAFKA_BOOTSTRAP_SERVERS"]
API_KEY = os.environ["CONFLUENT_API_KEY"]
API_SECRET = os.environ["CONFLUENT_API_SECRET"]

COUCHBASE_HOST = os.environ.get("COUCHBASE_HOST", "localhost")
COUCHBASE_BUCKET = os.environ.get("COUCHBASE_BUCKET", "order_analytics")
COUCHBASE_USER = os.environ.get("COUCHBASE_USERNAME", "Administrator")
COUCHBASE_PASS = os.environ.get("COUCHBASE_PASSWORD", "password")

ORDERS_TOPIC = "orders"
ANALYTICS_TOPIC = "order-analytics"

KAFKA_CONFIG = {
    "bootstrap_servers": BOOTSTRAP_SERVERS,
    "security_protocol": "SASL_SSL",
    "sasl_mechanism": "PLAIN",
    "sasl_plain_username": API_KEY,
    "sasl_plain_password": API_SECRET,
}

consumer = KafkaConsumer(
    ORDERS_TOPIC,
    **KAFKA_CONFIG,
    group_id="analytics-group",
    value_deserializer=lambda m: json.loads(m.decode("utf-8")),
    auto_offset_reset="earliest",
    enable_auto_commit=True,
    api_version=(2, 6, 0),
)

producer = KafkaProducer(
    **KAFKA_CONFIG,
    value_serializer=lambda v: json.dumps(v).encode("utf-8"),
    api_version=(2, 6, 0),
)

# Connect to Couchbase
print(f"Connecting to Couchbase at {COUCHBASE_HOST}...")
collection = None
try:
    conn_str = f"couchbases://{COUCHBASE_HOST}" if "cloud.couchbase.com" in COUCHBASE_HOST else f"couchbase://{COUCHBASE_HOST}"
    cluster = Cluster(
        conn_str,
        ClusterOptions(
            PasswordAuthenticator(COUCHBASE_USER, COUCHBASE_PASS),
            timeout_options=ClusterTimeoutOptions(kv_timeout=timedelta(seconds=10))
        )
    )
    bucket = cluster.bucket(COUCHBASE_BUCKET)
    collection = bucket.default_collection()
    print(f"Connected to Couchbase bucket: {COUCHBASE_BUCKET}")
except Exception as e:
    print(f"Couchbase connection failed: {e}")

total_sales = 0.0
order_count = 0

print("Analytics service started. Listening to 'orders'...")

for msg in consumer:
    order = msg.value
    amount = float(order.get("amount", 0))
    total_sales += amount
    order_count += 1

    analytics = {
        "total_sales": round(total_sales, 2),
        "order_count": order_count,
    }

    producer.send(ANALYTICS_TOPIC, value=analytics)

    if collection:
        try:
            doc_id = str(order.get("order_id", uuid.uuid4()))
            order_doc = {
                **order,
                "processed_at": str(msg.timestamp) if msg.timestamp else None,
                "kafka_offset": msg.offset,
                "kafka_partition": msg.partition,
            }
            collection.upsert(doc_id, order_doc)
            print(f"[analytics] order {doc_id} saved | {analytics}")
        except Exception as e:
            print(f"[analytics] couchbase error: {e}")
    else:
        print(f"[analytics] {analytics}")
