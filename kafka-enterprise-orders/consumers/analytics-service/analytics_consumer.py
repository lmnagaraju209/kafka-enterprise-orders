import json
import os
from kafka import KafkaConsumer, KafkaProducer

BOOTSTRAP_SERVERS = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "kafka:9092")

ORDERS_TOPIC = "orders"
ANALYTICS_TOPIC = "order-analytics"

consumer = KafkaConsumer(
    ORDERS_TOPIC,
    bootstrap_servers=BOOTSTRAP_SERVERS,
    group_id="analytics-group",
    value_deserializer=lambda m: json.loads(m.decode("utf-8")),
    auto_offset_reset="earliest",
    enable_auto_commit=True,
)

producer = KafkaProducer(
    bootstrap_servers=BOOTSTRAP_SERVERS,
    value_serializer=lambda v: json.dumps(v).encode("utf-8"),
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

