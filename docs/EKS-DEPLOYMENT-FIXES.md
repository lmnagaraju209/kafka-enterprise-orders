# EKS Fixes

## what broke

1. **images not pulling** - wrong paths + no ghcr secret
2. **404 on ALB** - ingress only had host rule, no default
3. **502 on backend** - service pointed to 80, fastapi runs on 8000
4. **no https** - added ACM cert

## deploy

push to main, pipeline does the rest.

### github secrets needed

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
GHCR_PAT
COUCHBASE_HOST
COUCHBASE_BUCKET
COUCHBASE_USERNAME
COUCHBASE_PASSWORD
```

## manual deploy

```bash
aws eks update-kubeconfig --name keo-eks --region us-east-2

kubectl create secret docker-registry ghcr \
  --docker-server=ghcr.io \
  --docker-username=aisalkyn85 \
  --docker-password=<pat>

helm upgrade --install webapp ./k8s/charts/webapp
```

## check

```bash
kubectl get pods
kubectl get ingress
```

## troubleshooting

- ImagePullBackOff - check ghcr secret: `kubectl get secret ghcr`
- 502 errors - check backend logs: `kubectl logs <pod> -c backend`
- ingress not working - check alb controller: `kubectl get pods -n kube-system | grep load-balancer`

---

## files changed

### new files
| file | lines | what |
|------|-------|------|
| k8s/charts/webapp/templates/_helpers.tpl | 5 | docker config helper |
| k8s/charts/webapp/templates/ghcr-secret.yaml | 9 | ghcr pull secret |
| k8s/cert-manager/cluster-issuer.yaml | 31 | lets encrypt issuers |
| k8s/cert-manager/certificate.yaml | 12 | domain certificate |
| k8s/cert-manager/README.md | 20 | cert-manager setup |
| argocd/cert-manager.yaml | 23 | cert-manager argocd app |
| argocd/cert-manager-config.yaml | 18 | issuers argocd app |
| docs/SSL-HTTPS-SETUP.md | 104 | ssl guide |

### modified files
| file | lines | what |
|------|-------|------|
| k8s/charts/webapp/values.yaml | 16 | images, cert ARN, ports |
| k8s/charts/webapp/Chart.yaml | 6 | cleaned up |
| k8s/charts/webapp/templates/deployment.yaml | 65 | imagePullSecrets, env vars |
| k8s/charts/webapp/templates/service.yaml | 17 | backend port 8000 |
| k8s/charts/webapp/templates/ingress.yaml | 88 | HTTPS annotations, default rule |
| argocd/webapp.yaml | 35 | updated config |
| .github/workflows/eks-webapp-ci-cd.yml | 66 | secrets creation, deploy steps |
