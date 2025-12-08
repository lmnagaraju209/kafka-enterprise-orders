import json
import os
import time
from kafka import KafkaConsumer, KafkaProducer

BOOTSTRAP_SERVERS = os.environ["KAFKA_BOOTSTRAP_SERVERS"]
API_KEY = os.environ["CONFLUENT_API_KEY"]
API_SECRET = os.environ["CONFLUENT_API_SECRET"]
ORDERS_TOPIC = "orders"
PAYMENTS_TOPIC = "payments"

# SASL_SSL config for Confluent Cloud
KAFKA_CONFIG = {
    "bootstrap_servers": BOOTSTRAP_SERVERS,
    "security_protocol": "SASL_SSL",
    "sasl_mechanism": "PLAIN",
    "sasl_plain_username": API_KEY,
    "sasl_plain_password": API_SECRET,
}

producer = KafkaProducer(
    **KAFKA_CONFIG,
    value_serializer=lambda v: json.dumps(v).encode("utf-8"),
    key_serializer=lambda k: str(k).encode("utf-8"),
    api_version=(2, 6, 0),  # Skip auto-detection for Confluent Cloud
)

consumer = KafkaConsumer(
    ORDERS_TOPIC,
    **KAFKA_CONFIG,
    group_id="payments-group",
    value_deserializer=lambda m: json.loads(m.decode("utf-8")),
    auto_offset_reset="earliest",
    enable_auto_commit=True,
    api_version=(2, 6, 0),  # Skip auto-detection for Confluent Cloud
)

def process_payment(order):
    time.sleep(0.1)  # simulate processing
    return {
        "order_id": order["order_id"],
        "status": "PAID",
        "amount": order["amount"],
        "country": order["country"],
        "timestamp": time.time(),
    }

print("Payment service started. Listening to 'orders' topic...")

for msg in consumer:
    order = msg.value
    print(f"[payment-service] Received order: {order}")

    payment_event = process_payment(order)

    producer.send(PAYMENTS_TOPIC, key=payment_event["order_id"], value=payment_event)
    print(f"[payment-service] Sent payment: {payment_event}")

