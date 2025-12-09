# Real-Time Orders Platform

Event-driven order processing with Kafka, Couchbase, and AWS.

## What it does

Producer generates orders → Kafka distributes → Services process (fraud, payment, analytics) → Couchbase stores → Dashboard displays.

## Stack

- Confluent Cloud (Kafka)
- Couchbase Capella
- FastAPI + React
- AWS ECS + Terraform

## Quick Start

Local:
```bash
docker-compose up -d
```

Production:
```bash
cd infra/terraform-ecs
terraform apply
```

## Structure

```
producer/           # generates orders
consumers/          # fraud, payment, analytics services
web/backend/        # FastAPI API
web/frontend/       # React dashboard
infra/terraform-ecs # AWS infrastructure
k8s/                # Helm charts for EKS
```

## Demo

https://orders.jumptotech.net

## Docs

- [Architecture](docs/ARCHITECTURE.md)
- [Code Walkthrough](docs/CODE-WALKTHROUGH.md)
- [Secrets Setup](docs/SECRETS-SETUP.md)
- [Presentation](docs/PRESENTATION.md)
