# Real-Time Orders Platform - Architecture

Event-driven microservices platform for processing orders in real-time using Kafka, Couchbase, and AWS.

## System Overview

```
┌──────────────┐     ┌─────────────────────────────────────────────────────────┐
│   Frontend   │────▶│                    Backend API                          │
│   (React)    │     │                    (FastAPI)                            │
└──────────────┘     └────────────────────────┬────────────────────────────────┘
                                              │
                                              ▼
                                    ┌──────────────────┐
                                    │    Couchbase     │
                                    │   (Analytics)    │
                                    └────────▲─────────┘
                                             │
┌──────────────┐                             │
│   Producer   │                    ┌────────┴─────────┐
│  (Orders)    │───────────────────▶│                  │
└──────────────┘                    │  Confluent Kafka │
                                    │                  │
         ┌──────────────────────────┤     Topics:      │
         │                          │  - orders        │
         │    ┌─────────────────────┤  - payments      │
         │    │                     │  - fraud-alerts  │
         │    │    ┌────────────────┤  - order-analytics│
         │    │    │                │                  │
         ▼    ▼    ▼                └──────────────────┘
    ┌────────┬────────┬────────┐
    │ Fraud  │Payment │Analytics│
    │Service │Service │Service  │
    └────────┴────────┴────┬───┘
                           │
                           ▼
                    ┌──────────────┐
                    │  Couchbase   │
                    │   Capella    │
                    └──────────────┘
```

## Data Flow

1. **Producer** generates random orders every 2 seconds
2. Orders published to `orders` topic in Kafka
3. Three consumers process events in parallel:
   - **Fraud Service** - flags suspicious orders (>$300 from risky countries)
   - **Payment Service** - simulates payment processing
   - **Analytics Service** - aggregates stats and stores to Couchbase
4. **Backend API** queries Couchbase for latest analytics
5. **Frontend** displays real-time dashboard

## Components

### Producer (`producer/`)
Generates fake orders with random amounts, countries, and statuses.

```python
# Order schema
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

### Consumers (`consumers/`)

| Service | Input Topic | Output Topic | Action |
|---------|-------------|--------------|--------|
| fraud-service | orders | fraud-alerts | Flags risky transactions |
| payment-service | orders | payments | Marks orders as PAID |
| analytics-service | orders | order-analytics | Stores to Couchbase |

### Web App (`web/`)

- **Frontend**: React dashboard showing orders, total sales, and system status
- **Backend**: FastAPI with `/api/analytics` endpoint querying Couchbase

## Kafka Topics

| Topic | Partitions | Producers | Consumers |
|-------|------------|-----------|-----------|
| orders | 6 | producer | fraud, payment, analytics |
| payments | 6 | payment-service | analytics |
| fraud-alerts | 6 | fraud-service | (alerting) |
| order-analytics | 6 | analytics-service | Couchbase sink |

## Infrastructure

### AWS ECS (Production)

```
infra/terraform-ecs/
├── ecs.tf          # ECS services and task definitions
├── alb.tf          # Application Load Balancer
├── secrets.tf      # AWS Secrets Manager
├── vpc.tf          # Networking
└── variables.tf    # Configuration
```

Services deployed:
- `producer-svc` - Order generator
- `fraud-svc` - Fraud detection
- `payment-svc` - Payment processing
- `analytics-svc` - Analytics + Couchbase writer
- `backend-svc` - API
- `frontend-svc` - React app

### AWS EKS (Alternative)

```
k8s/charts/webapp/
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
└── values.yaml
```

Helm deployment:
```bash
helm upgrade webapp k8s/charts/webapp \
  --set couchbase.password=xxx \
  --set ghcr.password=xxx
```

## External Services

### Confluent Cloud (Kafka)
- Managed Kafka cluster
- SASL/SSL authentication
- Auto-scaling partitions

### Couchbase Capella
- NoSQL document store
- Real-time analytics queries
- Free tier available

## Deployment

### Quick Start (Docker Compose)
```bash
docker-compose up -d
```

### Production (ECS)
```bash
cd infra/terraform-ecs
terraform init
terraform apply
# Terraform prompts for secrets
```

### Production (EKS)
```bash
helm upgrade webapp k8s/charts/webapp -f values-secrets.yaml
```

## Secrets

Required credentials:

| Secret | Source | Used By |
|--------|--------|---------|
| GHCR PAT | github.com/settings/tokens | ECS/EKS image pulls |
| Confluent API Key | confluent.cloud | All Kafka services |
| Couchbase Password | cloud.couchbase.com | Analytics, Backend |

See [SECRETS-SETUP.md](SECRETS-SETUP.md) for configuration.

## Monitoring

- CloudWatch Logs for ECS tasks
- Couchbase Capella metrics dashboard
- Confluent Cloud consumer lag monitoring

## Local Development

```bash
# Start infrastructure
docker-compose up -d kafka postgres couchbase

# Run producer
cd producer && python producer.py

# Run consumer
cd consumers/analytics-service && python analytics_consumer.py

# Run backend
cd web/backend && uvicorn app:app --reload
```

