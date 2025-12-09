# Real-Time Orders Platform

---

# Problem

E-commerce needs real-time processing. Multiple systems need the same data. Sync calls don't scale.

---

# Solution

Event-driven architecture with Kafka.

```
Producer → Kafka → Consumers → Database → Dashboard
```

---

# Tech Stack

- Kafka (Confluent Cloud)
- Couchbase Capella
- FastAPI + React
- AWS ECS
- Terraform

---

# Architecture

```
Producer → Kafka "orders" → Fraud Service
                         → Payment Service  
                         → Analytics Service → Couchbase
                                                   ↓
                              Frontend ← Backend ←─┘
```

---

# Data Flow

1. Producer sends order to Kafka
2. Three services read in parallel
3. Analytics writes to Couchbase
4. API reads from Couchbase
5. Dashboard shows results

---

# Order Format

```json
{
  "order_id": 123,
  "amount": 249.99,
  "country": "US",
  "status": "CREATED"
}
```

---

# Fraud Detection

```python
def is_fraud(order):
    return amount > 300 and country not in ["US", "CA"]
```

---

# AWS Setup

ECS Fargate runs 6 services. ALB exposes frontend and backend. Secrets in AWS Secrets Manager.

---

# Deployment

```bash
cd infra/terraform-ecs
terraform apply
# enter secrets when prompted
```

---

# Project Structure

```
producer/           - order generator
consumers/          - fraud, payment, analytics
web/backend/        - FastAPI
web/frontend/       - React
infra/terraform-ecs - infrastructure
```

---

# Demo

https://orders.jumptotech.net

---

# What I Learned

- Kafka consumer groups
- Event-driven design
- Couchbase N1QL
- Terraform + ECS
- Secrets management

---

# Questions?

Code: github.com/aisalkyn85/kafka-enterprise-orders
