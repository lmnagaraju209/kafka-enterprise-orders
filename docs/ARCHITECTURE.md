# Architecture

Event-driven order processing with Kafka and Couchbase.

## How it works

```
┌──────────┐     ┌───────────┐     ┌───────────┐
│ Frontend │────▶│  Backend  │────▶│ Couchbase │
└──────────┘     └───────────┘     └─────▲─────┘
                                         │
┌──────────┐     ┌───────────┐     ┌─────┴─────┐
│ Producer │────▶│   Kafka   │────▶│ Analytics │
└──────────┘     └─────┬─────┘     └───────────┘
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
     ┌────────┐  ┌─────────┐  ┌──────────┐
     │ Fraud  │  │ Payment │  │ Analytics│
     └────────┘  └─────────┘  └──────────┘
```

Producer generates orders → Kafka distributes → Three services process in parallel → Analytics stores to Couchbase → Backend reads → Frontend displays.

## Components

**Producer** - Generates random orders every 2 sec. Sends to "orders" topic.

**Fraud Service** - Reads orders, flags suspicious ones (>$300 from risky countries), sends alerts.

**Payment Service** - Reads orders, simulates processing, marks as PAID.

**Analytics Service** - Reads orders, stores to Couchbase for the dashboard.

**Backend** - FastAPI. Queries Couchbase, returns JSON.

**Frontend** - React dashboard showing orders and stats.

## Kafka Topics

| Topic | Who writes | Who reads |
|-------|-----------|-----------|
| orders | producer | fraud, payment, analytics |
| payments | payment-service | - |
| fraud-alerts | fraud-service | - |
| order-analytics | analytics-service | - |

## Order Schema

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

## Deployment

Six ECS services behind an ALB:
- producer-svc
- fraud-svc
- payment-svc
- analytics-svc
- backend-svc
- frontend-svc

Terraform creates everything. Secrets stored in AWS Secrets Manager, injected at runtime.

## External Services

**Confluent Cloud** - Managed Kafka. SASL/SSL auth.

**Couchbase Capella** - NoSQL for analytics. Free tier works.

## Local Dev

```bash
docker-compose up -d
```

Runs Kafka, Couchbase, Postgres locally. Then run each service manually or via docker-compose.

## Production

```bash
cd infra/terraform-ecs
terraform apply
```

Prompts for secrets, creates everything in AWS.
