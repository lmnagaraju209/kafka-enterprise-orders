import json
import os
import time
from kafka import KafkaConsumer, KafkaProducer

BOOTSTRAP_SERVERS = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "kafka:9092")
ORDERS_TOPIC = "orders"
PAYMENTS_TOPIC = "payments"

producer = KafkaProducer(
    bootstrap_servers=BOOTSTRAP_SERVERS,
    value_serializer=lambda v: json.dumps(v).encode("utf-8"),
    key_serializer=lambda k: str(k).encode("utf-8"),
)

consumer = KafkaConsumer(
    ORDERS_TOPIC,
    bootstrap_servers=BOOTSTRAP_SERVERS,
    group_id="payments-group",
    value_deserializer=lambda m: json.loads(m.decode("utf-8")),
    auto_offset_reset="earliest",
    enable_auto_commit=True,
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

