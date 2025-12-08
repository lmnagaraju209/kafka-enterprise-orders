import json
import os
import time
from kafka import KafkaConsumer, KafkaProducer

BOOTSTRAP_SERVERS = os.environ["KAFKA_BOOTSTRAP_SERVERS"]
API_KEY = os.environ["CONFLUENT_API_KEY"]
API_SECRET = os.environ["CONFLUENT_API_SECRET"]

ORDERS_TOPIC = "orders"
PAYMENTS_TOPIC = "payments"

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
    group_id="payments-group",
    value_deserializer=lambda m: json.loads(m.decode("utf-8")),
    auto_offset_reset="earliest",
    enable_auto_commit=True,
    api_version=(2, 6, 0),
)

producer = KafkaProducer(
    **KAFKA_CONFIG,
    value_serializer=lambda v: json.dumps(v).encode("utf-8"),
    key_serializer=lambda k: str(k).encode("utf-8"),
    api_version=(2, 6, 0),
)

print("Payment service started...")

for msg in consumer:
    order = msg.value
    print(f"[payment] order_id={order.get('order_id')}")

    time.sleep(0.1)  # simulate processing

    payment = {
        "order_id": order["order_id"],
        "status": "PAID",
        "amount": order["amount"],
        "country": order["country"],
        "timestamp": time.time(),
    }
    producer.send(PAYMENTS_TOPIC, key=payment["order_id"], value=payment)
    print(f"[payment] processed: {payment['order_id']}")
