# EKS Deployment Guide

Quick guide for deploying the webapp to EKS.

## What we fixed

Had a few issues getting this running on EKS:

1. **Images not pulling** - The image paths were wrong and we didn't have a pull secret for GHCR. Fixed the paths and added secret creation to the pipeline.

2. **404 on the ALB URL** - Ingress was only set up for the custom domain, not for direct ALB access. Added a default rule.

3. **Backend returning 502** - Service was pointing to port 80 but FastAPI runs on 8000. Updated the service.

## Deploying

The pipeline handles everything. Just push to main and it'll:
- Build the images
- Push to GHCR  
- Create the secrets in k8s
- Deploy with helm

### Secrets you need in GitHub

Go to repo Settings > Secrets > Actions and add:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `GHCR_PAT` - your GitHub personal access token
- `COUCHBASE_HOST`
- `COUCHBASE_BUCKET`
- `COUCHBASE_USERNAME`
- `COUCHBASE_PASSWORD`

## Manual deploy (if needed)

```bash
# connect to eks
aws eks update-kubeconfig --name keo-eks --region us-east-2

# create the ghcr secret
kubectl create secret docker-registry ghcr \
  --docker-server=ghcr.io \
  --docker-username=aisalkyn85 \
  --docker-password=<your-pat>

# deploy
helm upgrade --install webapp ./k8s/charts/webapp \
  --set couchbase.host=<host> \
  --set couchbase.password=<pass>
```

## Checking if it worked

```bash
# pods should be 2/2 Running
kubectl get pods

# get the url
kubectl get ingress
```

Then hit the ALB url in your browser.

## If something breaks

**ImagePullBackOff** - check the ghcr secret exists: `kubectl get secret ghcr`

**502 errors** - check backend logs: `kubectl logs <pod> -c backend`

**Ingress not working** - make sure ALB controller is running: `kubectl get pods -n kube-system | grep load-balancer`
