import json
import os
from kafka import KafkaConsumer, KafkaProducer

BOOTSTRAP_SERVERS = os.environ["KAFKA_BOOTSTRAP_SERVERS"]
API_KEY = os.environ["CONFLUENT_API_KEY"]
API_SECRET = os.environ["CONFLUENT_API_SECRET"]

ORDERS_TOPIC = "orders"
ALERTS_TOPIC = "fraud-alerts"

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
    group_id="fraud-group",
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

def is_fraud(order):
    # Flag high-value orders from risky countries
    return order.get("amount", 0) > 300 and order.get("country") not in ["US", "CA"]

print("Fraud service started...")

for msg in consumer:
    order = msg.value
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
