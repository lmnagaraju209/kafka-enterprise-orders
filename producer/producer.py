import json
import os
import random
import time
from datetime import datetime

from faker import Faker
from kafka import KafkaProducer

BOOTSTRAP_SERVERS = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "kafka:9092")
TOPIC_NAME = os.getenv("TOPIC_NAME", "orders")
SLEEP_SECONDS = float(os.getenv("SLEEP_SECONDS", "2"))

fake = Faker()

def create_producer():
    producer = KafkaProducer(
        bootstrap_servers=BOOTSTRAP_SERVERS,
        value_serializer=lambda v: json.dumps(v).encode("utf-8"),
        key_serializer=lambda k: str(k).encode("utf-8"),
        linger_ms=10,
        acks="all",
        retries=3,
    )
    return producer

def generate_order(order_id: int) -> dict:
    amount = round(random.uniform(10, 500), 2)
    country = random.choice(["US", "CA", "DE", "IN", "GB", "FR", "CN", "BR"])
    status = random.choice(["CREATED", "CONFIRMED", "CANCELLED"])

    return {
        "order_id": order_id,
        "customer_id": fake.random_int(min=1000, max=9999),
        "amount": amount,
        "currency": "USD",
        "country": country,
        "status": status,
        "created_at": datetime.utcnow().isoformat() + "Z",
        "source": "order-service",
    }

def main():
    print(f"Connecting to Kafka at {BOOTSTRAP_SERVERS} ...")
    producer = create_producer()
    print(f"Producer created. Sending messages to topic '{TOPIC_NAME}'")

    order_id = 1
    while True:
        order = generate_order(order_id)
        key = order["order_id"]

        future = producer.send(TOPIC_NAME, key=key, value=order)
        try:
            record_metadata = future.get(timeout=10)
            print(
                f"Sent order_id={order_id} to "
                f"topic={record_metadata.topic}, "
                f"partition={record_metadata.partition}, "
                f"offset={record_metadata.offset}"
            )
        except Exception as e:
            print(f"Error sending message: {e}")

        order_id += 1
        time.sleep(SLEEP_SECONDS)

if __name__ == "__main__":
    main()

