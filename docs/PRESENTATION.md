# Real-Time Orders Platform
## Event-Driven Microservices with Kafka

---

# Problem Statement

- E-commerce needs real-time order processing
- Multiple systems need order data simultaneously
- Traditional sync calls don't scale
- Need fraud detection, payments, analytics in parallel

---

# Solution: Event-Driven Architecture

```
Producer → Kafka → Consumers → Couchbase → Dashboard
```

- Decouple services via message queue
- Process events in parallel
- Scale independently
- Real-time analytics

---

# Tech Stack

| Component | Technology |
|-----------|------------|
| Streaming | Confluent Cloud (Kafka) |
| Database | Couchbase Capella |
| Backend | FastAPI (Python) |
| Frontend | React |
| Infrastructure | Terraform, AWS ECS |
| CI/CD | GitHub Actions |

---

# Architecture Overview

```
┌────────────┐      ┌─────────────┐      ┌────────────┐
│  Frontend  │ ───▶ │   Backend   │ ───▶ │  Couchbase │
│  (React)   │      │  (FastAPI)  │      │  (NoSQL)   │
└────────────┘      └─────────────┘      └─────▲──────┘
                                               │
┌────────────┐      ┌─────────────┐      ┌─────┴──────┐
│  Producer  │ ───▶ │    Kafka    │ ───▶ │  Analytics │
│  (Orders)  │      │  (Topics)   │      │  Consumer  │
└────────────┘      └──────┬──────┘      └────────────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
         ┌────────┐  ┌─────────┐  ┌──────────┐
         │ Fraud  │  │ Payment │  │ Analytics│
         │Service │  │ Service │  │ Service  │
         └────────┘  └─────────┘  └──────────┘
```

---

# Data Flow

1. **Producer** generates orders (every 2 sec)
2. Orders published to `orders` topic
3. **Three consumers** process in parallel:
   - Fraud → flags suspicious orders
   - Payment → marks as PAID
   - Analytics → stores to Couchbase
4. **Backend API** reads from Couchbase
5. **Frontend** displays live dashboard

---

# Kafka Topics

| Topic | Producer | Consumers |
|-------|----------|-----------|
| orders | order-producer | fraud, payment, analytics |
| payments | payment-service | analytics |
| fraud-alerts | fraud-service | alerting |
| order-analytics | analytics-service | Couchbase sink |

---

# Order Schema

```json
{
  "order_id": 123,
  "customer_id": 5678,
  "amount": 249.99,
  "currency": "USD",
  "country": "US",
  "status": "CREATED",
  "created_at": "2024-01-15T10:30:00Z"
}
```

---

# Fraud Detection Logic

```python
def is_fraud(order):
    # Flag high-value orders from risky countries
    return order["amount"] > 300 and \
           order["country"] not in ["US", "CA"]
```

Simple rule-based detection (can extend to ML)

---

# AWS Deployment

```
┌─────────────────────────────────────────┐
│              AWS ECS Fargate            │
├─────────────────────────────────────────┤
│  ┌──────────┐ ┌──────────┐ ┌──────────┐│
│  │ Producer │ │  Fraud   │ │ Payment  ││
│  └──────────┘ └──────────┘ └──────────┘│
│  ┌──────────┐ ┌──────────┐ ┌──────────┐│
│  │Analytics │ │ Backend  │ │ Frontend ││
│  └──────────┘ └──────────┘ └──────────┘│
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│         Application Load Balancer       │
│         orders.jumptotech.net           │
└─────────────────────────────────────────┘
```

---

# Infrastructure as Code

```
infra/terraform-ecs/
├── ecs.tf       # Services & Tasks
├── alb.tf       # Load Balancer
├── secrets.tf   # AWS Secrets Manager
├── vpc.tf       # Networking
└── variables.tf # Config
```

One command deployment:
```bash
terraform apply
```

---

# Secrets Management

Terraform prompts for sensitive values:
- GitHub PAT (image pulls)
- Confluent API keys (Kafka)
- Couchbase password (database)

Stored in AWS Secrets Manager, injected at runtime.

---

# Project Structure

```
kafka-enterprise-orders/
├── producer/           # Order generator
├── consumers/
│   ├── fraud-service/
│   ├── payment-service/
│   └── analytics-service/
├── web/
│   ├── backend/        # FastAPI
│   └── frontend/       # React
├── infra/terraform-ecs/
└── k8s/charts/         # Helm (EKS)
```

---

# Live Demo

**URL:** https://orders.jumptotech.net

Features:
- Real-time order count
- Total sales tracking
- Live order feed
- System status

---

# Key Benefits

✓ **Scalable** - Each service scales independently

✓ **Resilient** - Kafka handles backpressure

✓ **Real-time** - Sub-second processing

✓ **Observable** - CloudWatch logging

✓ **Reproducible** - Infrastructure as Code

---

# Technologies Learned

- Apache Kafka / Confluent Cloud
- Event-driven microservices
- Couchbase NoSQL
- AWS ECS / EKS
- Terraform
- Docker / Helm
- FastAPI / React

---

# Future Improvements

- [ ] Machine learning fraud detection
- [ ] Kafka Streams for real-time aggregations
- [ ] ksqlDB for stream processing
- [ ] Grafana dashboards
- [ ] Multi-region deployment

---

# Questions?

**GitHub:** github.com/aisalkyn85/kafka-enterprise-orders

**Blog:** dev.to/jumptotech/project-idea-real-time-orders-platform

**Demo:** orders.jumptotech.net

