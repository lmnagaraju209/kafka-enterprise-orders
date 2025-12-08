import json
import os
from kafka import KafkaConsumer, KafkaProducer

BOOTSTRAP_SERVERS = os.environ["KAFKA_BOOTSTRAP_SERVERS"]
API_KEY = os.environ["CONFLUENT_API_KEY"]
API_SECRET = os.environ["CONFLUENT_API_SECRET"]

ORDERS_TOPIC = "orders"
ANALYTICS_TOPIC = "order-analytics"

# SASL_SSL config for Confluent Cloud
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
    api_version=(2, 6, 0),  # Skip auto-detection for Confluent Cloud
)

producer = KafkaProducer(
    **KAFKA_CONFIG,
    value_serializer=lambda v: json.dumps(v).encode("utf-8"),
    api_version=(2, 6, 0),  # Skip auto-detection for Confluent Cloud
)

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
    print(f"[analytics-service] {analytics}")

