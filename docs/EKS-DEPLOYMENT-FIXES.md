# EKS Deployment Fixes

Issues encountered on Kubernetes and how they were resolved.

---

## 1. Connect to EKS Cluster

```bash
aws eks update-kubeconfig --name keo-eks --region us-east-2
kubectl config current-context
```

---

## 2. Backend Environment Variables Wrong

**Error:** Dashboard showing "Connection Error" even after ECS was fixed.

**Cause:** Domain `orders.jumptotech.net` pointed to EKS, not ECS.

**Fix:**
```bash
# Check current env vars
kubectl get deployment web-backend -o jsonpath='{.spec.template.spec.containers[0].env}'

# Update environment variables
kubectl set env deployment/web-backend \
  COUCHBASE_HOST=cb.xxx.cloud.couchbase.com \
  COUCHBASE_BUCKET=order_analytics \
  COUCHBASE_USERNAME=admin \
  COUCHBASE_PASSWORD=your-password

# Verify rollout
kubectl rollout status deployment/web-backend
```

---

## 3. Pod Not Starting

```bash
# Check pod status
kubectl get pods

# Describe pod for events
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name> -c backend
kubectl logs <pod-name> -c frontend
```

---

## 4. Image Pull Error

**Error:**
```
Failed to pull image: unauthorized
```

**Fix:** Create/update GHCR secret:
```bash
kubectl create secret docker-registry ghcr \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USER \
  --docker-password=ghp_xxxx \
  --docker-email=your@email.com
```

---

## 5. Ingress Not Working

```bash
# Check ingress
kubectl get ingress
kubectl describe ingress webapp-ingress

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

---

## 6. Certificate Issues

```bash
# Check certificate status
kubectl get certificate
kubectl describe certificate webapp-tls

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager
```

---

## 7. Restart Deployment

```bash
kubectl rollout restart deployment/web-backend
kubectl rollout restart deployment/web-frontend
```

---

## 8. Update Helm Values

```bash
cd k8s/charts/webapp

helm upgrade webapp . \
  --set couchbase.host=cb.xxx.cloud.couchbase.com \
  --set couchbase.password=your-password
```

---

## 9. Check All Resources

```bash
kubectl get all
kubectl get secrets
kubectl get configmaps
kubectl get ingress
kubectl get certificate
```

---

## 10. Delete and Reinstall

```bash
helm uninstall webapp
helm install webapp . -f values.yaml --set couchbase.password=xxx
```

