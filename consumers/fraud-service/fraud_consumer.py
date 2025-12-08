import json
import os
from kafka import KafkaConsumer, KafkaProducer

BOOTSTRAP_SERVERS = os.environ["KAFKA_BOOTSTRAP_SERVERS"]
API_KEY = os.environ["CONFLUENT_API_KEY"]
API_SECRET = os.environ["CONFLUENT_API_SECRET"]

ORDERS_TOPIC = "orders"
PAYMENTS_TOPIC = "payments"
ALERTS_TOPIC = "fraud-alerts"

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
    group_id="fraud-group",
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

def is_fraud(event):
    # simple rule: high amount AND non-US/CA
    return float(event.get("amount", 0)) > 300 and event.get("country") not in ["US", "CA"]

print("Fraud service started. Listening to 'orders' and 'payments'...")

for msg in consumer:
    event = msg.value
    print(f"[fraud-service] Received event from {msg.topic}: {event}")

    if "amount" in event and "country" in event and "order_id" in event:
        if is_fraud(event):
            alert = {
                "order_id": event["order_id"],
                "reason": "HIGH_AMOUNT_RISKY_COUNTRY",
                "amount": event["amount"],
                "country": event["country"],
                "source_topic": msg.topic,
            }
            producer.send(ALERTS_TOPIC, value=alert)
            print(f"[fraud-service] FRAUD ALERT: {alert}")

