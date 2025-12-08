# Real-Time Orders Platform

Event-driven microservices for processing orders using Kafka, Couchbase, and AWS.

![Architecture](https://via.placeholder.com/800x400?text=Architecture+Diagram)

## What it does

- Generates random orders via Kafka producer
- Processes events through fraud detection, payment, and analytics services
- Stores real-time analytics in Couchbase
- Displays live dashboard via React frontend

## Tech Stack

| Layer | Technology |
|-------|------------|
| Streaming | Confluent Cloud (Kafka) |
| Database | Couchbase Capella |
| Backend | FastAPI (Python) |
| Frontend | React |
| Infrastructure | Terraform, ECS, EKS |
| CI/CD | GitHub Actions |

## Quick Start

### Local Development

```bash
docker-compose up -d
```

### Production (AWS ECS)

```bash
cd infra/terraform-ecs
terraform init
terraform apply
```

Terraform will prompt for:
- `ghcr_pat` - GitHub token for pulling images
- `confluent_api_key` / `confluent_api_secret` - Kafka credentials
- `couchbase_password` - Database password

## Project Structure

```
├── producer/                 # Order generator
├── consumers/
│   ├── analytics-service/    # Writes to Couchbase
│   ├── fraud-service/        # Fraud detection
│   └── payment-service/      # Payment processing
├── web/
│   ├── backend/              # FastAPI API
│   └── frontend/             # React dashboard
├── infra/
│   ├── terraform-ecs/        # ECS deployment
│   └── terraform-eks/        # EKS deployment
├── k8s/                      # Helm charts
├── connect/                  # Kafka Connect configs
└── docs/                     # Documentation
```

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Secrets Setup](docs/SECRETS-SETUP.md)
- [ECS Deployment](docs/ECS-DEPLOYMENT-FIXES.md)
- [EKS Deployment](docs/EKS-DEPLOYMENT-FIXES.md)

## Services

| Service | Port | Description |
|---------|------|-------------|
| Frontend | 80 | React dashboard |
| Backend | 8000 | FastAPI + Couchbase |
| Producer | - | Kafka order generator |
| Fraud | - | Fraud detection consumer |
| Payment | - | Payment processing consumer |
| Analytics | - | Analytics + Couchbase writer |

## Live Demo

https://orders.jumptotech.net

## Related

- [Project writeup on DEV.to](https://dev.to/jumptotech/project-idea-real-time-orders-platform-305d)
- [Confluent Cloud](https://confluent.cloud)
- [Couchbase Capella](https://cloud.couchbase.com)
