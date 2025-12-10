# Kafka Enterprise Orders

Real-time order processing system with Kafka, Couchbase, and AWS.

**Live Demo:** https://orders.jumptotech.net

---

## What This Does

1. **Producer** generates fake orders → sends to Kafka
2. **3 Consumers** process orders in parallel:
   - Fraud detection (flags suspicious orders)
   - Payment processing (simulates payments)
   - Analytics (stores to Couchbase)
3. **Dashboard** shows live order data from Couchbase

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS ECS / EKS                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   ┌──────────┐      ┌─────────────────┐      ┌──────────────────┐   │
│   │ Producer │ ───► │ Confluent Cloud │ ───► │ fraud-service    │   │
│   │          │      │   (Kafka)       │      │ payment-service  │   │
│   └──────────┘      │                 │      │ analytics-service│   │
│                     │   orders topic  │      └────────┬─────────┘   │
│                     └─────────────────┘               │             │
│                                                       ▼             │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │                    Couchbase Capella                          │  │
│   │                    (order_analytics bucket)                   │  │
│   └──────────────────────────────────────────────────────────────┘  │
│                                                       ▲             │
│   ┌──────────────┐      ┌──────────────┐              │             │
│   │   Frontend   │ ───► │   Backend    │ ─────────────┘             │
│   │   (React)    │      │   (FastAPI)  │                            │
│   └──────────────┘      └──────────────┘                            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Folder Structure

```
kafka-enterprise-orders/
├── producer/                    # Generates fake orders → Kafka
│   ├── producer.py
│   ├── requirements.txt
│   └── Dockerfile
│
├── consumers/
│   ├── fraud-service/           # Detects suspicious orders
│   ├── payment-service/         # Simulates payment processing
│   └── analytics-service/       # Saves to Couchbase
│
├── web/
│   ├── frontend/                # React dashboard
│   └── backend/                 # FastAPI → Couchbase queries
│
├── infra/
│   ├── terraform-ecs/           # AWS ECS deployment
│   └── terraform-eks/           # AWS EKS deployment
│
├── k8s/
│   └── charts/webapp/           # Helm chart for Kubernetes
│
└── docs/                        # Documentation
```

---

## Data Flow

### Step 1: Producer

```python
# producer/producer.py
order = {
    "order_id": 1,
    "customer_id": 4582,
    "amount": 249.99,
    "country": "US",
    "status": "CREATED",
    "created_at": "2024-01-15T10:30:00Z"
}
producer.send("orders", value=order)
```

### Step 2: Kafka

Order lands in `orders` topic on Confluent Cloud. Three consumer groups subscribe:
- `fraud-group`
- `payments-group`
- `analytics-group`

Each group gets a copy of every message.

### Step 3: Fraud Service

```python
# consumers/fraud-service/fraud_consumer.py
def is_fraud(order):
    return order["amount"] > 300 and order["country"] not in ["US", "CA"]

for msg in consumer:
    if is_fraud(msg.value):
        producer.send("fraud-alerts", {
            "order_id": order["order_id"],
            "reason": "HIGH_AMOUNT_RISKY_COUNTRY"
        })
```

### Step 4: Payment Service

```python
# consumers/payment-service/payment_consumer.py
for msg in consumer:
    time.sleep(0.1)  # simulate processing
    producer.send("payments", {
        "order_id": order["order_id"],
        "status": "PAID"
    })
```

### Step 5: Analytics Service

```python
# consumers/analytics-service/analytics_consumer.py
for msg in consumer:
    doc_id = str(order["order_id"])
    collection.upsert(doc_id, order)  # save to Couchbase
```

### Step 6: Backend API

```python
# web/backend/app.py
@app.get("/api/analytics")
def get_analytics():
    result = cluster.query("SELECT * FROM order_analytics LIMIT 10")
    return {"orders": [row for row in result]}
```

### Step 7: Frontend

```javascript
// web/frontend/src/App.js
useEffect(() => {
    fetch('/api/analytics')
        .then(res => res.json())
        .then(data => setOrders(data.orders));
}, []);
```

---

## Quick Start (Local)

```bash
# Start everything
docker-compose up -d

# Check logs
docker logs -f order-producer
docker logs -f analytics-service
```

Access:
- Kafdrop (Kafka UI): http://localhost:9000
- Control Center: http://localhost:9021
- Couchbase: http://localhost:8091

---

## Deploy to AWS ECS

### 1. Set variables

```bash
cd infra/terraform-ecs
cp secrets.tfvars.example secrets.tfvars
```

Edit `secrets.tfvars`:
```hcl
ghcr_pat                   = "ghp_xxxx"
confluent_api_key          = "LUTQDYGP3XTVJE5V"
confluent_api_secret       = "cfltQUDfj0BQV..."
couchbase_password         = "your-password"
```

### 2. Deploy

```bash
terraform init
terraform apply -var-file="secrets.tfvars"
```

Terraform creates:
- ECS cluster
- 6 services (producer, 3 consumers, frontend, backend)
- ALB with HTTPS
- Secrets in AWS Secrets Manager

---

## Deploy to AWS EKS

```bash
cd infra/terraform-eks
terraform apply

# Configure kubectl
aws eks update-kubeconfig --name keo-eks --region us-east-2

# Deploy app
cd ../../k8s/charts/webapp
helm install webapp . \
  --set couchbase.password=your-password \
  --set couchbase.host=cb.xxx.cloud.couchbase.com
```

---

## Environment Variables

All services read from AWS Secrets Manager:

| Variable | Source |
|----------|--------|
| `KAFKA_BOOTSTRAP_SERVERS` | `confluent-credentials.bootstrap_servers` |
| `CONFLUENT_API_KEY` | `confluent-credentials.api_key` |
| `CONFLUENT_API_SECRET` | `confluent-credentials.api_secret` |
| `COUCHBASE_HOST` | `couchbase-credentials.host` |
| `COUCHBASE_USERNAME` | `couchbase-credentials.username` |
| `COUCHBASE_PASSWORD` | `couchbase-credentials.password` |

---

## Couchbase Setup

1. Create cluster on [cloud.couchbase.com](https://cloud.couchbase.com)
2. Create bucket: `order_analytics`
3. Create user with read/write access
4. Whitelist AWS NAT Gateway IPs
5. Connection string: `couchbases://cb.xxx.cloud.couchbase.com`

---

## Files Explained

| File | Purpose |
|------|---------|
| `producer/producer.py` | Generates 1 order every 2 seconds |
| `consumers/*/` | Three microservices processing orders |
| `web/backend/app.py` | FastAPI with `/api/analytics` endpoint |
| `web/frontend/src/App.js` | React dashboard with auto-refresh |
| `infra/terraform-ecs/secrets.tf` | Creates AWS Secrets Manager entries |
| `infra/terraform-ecs/ecs.tf` | ECS cluster, services, and task definitions |

---

## Troubleshooting

**Kafka connection timeout:**
```bash
# Check secret values
aws secretsmanager get-secret-value --secret-id kafka-enterprise-orders-confluent-credentials
```

**Couchbase errors:**
```bash
# Check ECS logs
aws logs tail /ecs/kafka-enterprise-orders-analytics --follow
```

**Backend 500 errors:**
```bash
# Check backend logs
kubectl logs -l app=webapp -c backend
```

---

## Docs

- [Architecture](docs/ARCHITECTURE.md)
- [Code Walkthrough](docs/CODE-WALKTHROUGH.md)
- [Secrets Setup](docs/SECRETS-SETUP.md)
- [Presentation](docs/PRESENTATION.md)

