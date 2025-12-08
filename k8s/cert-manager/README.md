# cert-manager setup

Optional - use this if you want Let's Encrypt instead of ACM.

## install

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager
```

## create issuer

```bash
kubectl apply -f cluster-issuer.yaml
```

## request cert

```bash
kubectl apply -f certificate.yaml
kubectl get certificate
```

## notes

- ACM is easier if you're using ALB
- Let's Encrypt certs expire in 90 days (auto-renewed by cert-manager)
- Use staging issuer first to avoid rate limits
