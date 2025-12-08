import json
import os
import random
import time
from datetime import datetime
from faker import Faker
from kafka import KafkaProducer

# === Correct environment variables from ECS ===
BOOTSTRAP_SERVERS = os.environ["KAFKA_BOOTSTRAP_SERVERS"]
API_KEY = os.environ["CONFLUENT_API_KEY"]
API_SECRET = os.environ["CONFLUENT_API_SECRET"]
TOPIC_NAME = os.getenv("TOPIC_NAME", "orders")     # <-- real topic name
SLEEP_SECONDS = float(os.getenv("SLEEP_SECONDS", "2"))

fake = Faker()

def create_producer():
    print("=== Creating Kafka Producer with SASL_SSL ===")
    print(f"BOOTSTRAP_SERVERS = {BOOTSTRAP_SERVERS}")
    print(f"TOPIC = {TOPIC_NAME}")

    return KafkaProducer(
        bootstrap_servers=BOOTSTRAP_SERVERS,
        security_protocol="SASL_SSL",
        sasl_mechanism="PLAIN",
        sasl_plain_username=API_KEY,
        sasl_plain_password=API_SECRET,
        value_serializer=lambda v: json.dumps(v).encode("utf-8"),
        key_serializer=lambda k: str(k).encode("utf-8"),
        linger_ms=10,
        retries=5,
        acks="all",
        request_timeout_ms=30000,
        api_version=(2, 6, 0),  # Skip auto-detection for Confluent Cloud
    )

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
    print(f"=== Connecting to Confluent Cloud Kafka ===")
    print(f"Using broker: {BOOTSTRAP_SERVERS}")

    producer = create_producer()
    print("=== Producer created successfully ===")

    order_id = 1
    while True:
        order = generate_order(order_id)
        key = order["order_id"]

        future = producer.send(TOPIC_NAME, key=key, value=order)

        try:
            metadata = future.get(timeout=20)
            print(
                f"Sent order_id={order_id} → "
                f"topic={metadata.topic}, "
                f"partition={metadata.partition}, "
                f"offset={metadata.offset}"
            )
        except Exception as e:
            print("❌ ERROR SENDING MESSAGE")
            print(f"❌ {e}")

        order_id += 1
        time.sleep(SLEEP_SECONDS)

if __name__ == "__main__":
    main()

