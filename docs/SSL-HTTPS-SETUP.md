# SSL/HTTPS Setup

How to enable HTTPS for the application.

---

## Option 1: AWS Certificate Manager (ECS/ALB)

### Request Certificate

```bash
aws acm request-certificate \
  --domain-name orders.jumptotech.net \
  --validation-method DNS \
  --region us-east-2
```

### Add DNS Validation Record

ACM provides a CNAME record. Add it to your DNS:

```
Name:  _abc123.orders.jumptotech.net
Type:  CNAME
Value: _xyz789.acm-validations.aws.
```

### Attach to ALB

In Terraform (`alb.tf`):

```hcl
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = "arn:aws:acm:us-east-2:xxx:certificate/xxx"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# Redirect HTTP to HTTPS
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
```

---

## Option 2: cert-manager (EKS/Kubernetes)

### Install cert-manager

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

### Create ClusterIssuer

```yaml
# k8s/cert-manager/cluster-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your@email.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
```

```bash
kubectl apply -f k8s/cert-manager/cluster-issuer.yaml
```

### Create Certificate

```yaml
# k8s/cert-manager/certificate.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: webapp-tls
spec:
  secretName: webapp-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - orders.jumptotech.net
```

```bash
kubectl apply -f k8s/cert-manager/certificate.yaml
```

### Update Ingress

```yaml
# k8s/charts/webapp/templates/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - orders.jumptotech.net
      secretName: webapp-tls
  rules:
    - host: orders.jumptotech.net
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: webapp
                port:
                  number: 80
```

---

## Verify HTTPS

```bash
# Check certificate
curl -vI https://orders.jumptotech.net

# Check expiry
echo | openssl s_client -servername orders.jumptotech.net -connect orders.jumptotech.net:443 2>/dev/null | openssl x509 -noout -dates
```

---

## Troubleshooting

### Certificate Not Issuing

```bash
# Check certificate status
kubectl describe certificate webapp-tls

# Check cert-manager logs
kubectl logs -n cert-manager deploy/cert-manager

# Check challenges
kubectl get challenges
kubectl describe challenge <challenge-name>
```

### DNS Not Resolving

```bash
nslookup orders.jumptotech.net
dig orders.jumptotech.net
```

### Mixed Content Errors

Make sure all resources use HTTPS. In React:

```javascript
// Use relative URLs
fetch('/api/analytics')  // Good
fetch('http://...')      // Bad - will fail on HTTPS
```

