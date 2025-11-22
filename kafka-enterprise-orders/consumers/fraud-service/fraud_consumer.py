import json
import os
from kafka import KafkaConsumer, KafkaProducer

BOOTSTRAP_SERVERS = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "kafka:9092")

ORDERS_TOPIC = "orders"
PAYMENTS_TOPIC = "payments"
ALERTS_TOPIC = "fraud-alerts"

consumer = KafkaConsumer(
    ORDERS_TOPIC,
    PAYMENTS_TOPIC,
    bootstrap_servers=BOOTSTRAP_SERVERS,
    group_id="fraud-group",
    value_deserializer=lambda m: json.loads(m.decode("utf-8")),
    auto_offset_reset="earliest",
    enable_auto_commit=True,
)

producer = KafkaProducer(
    bootstrap_servers=BOOTSTRAP_SERVERS,
    value_serializer=lambda v: json.dumps(v).encode("utf-8"),
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

