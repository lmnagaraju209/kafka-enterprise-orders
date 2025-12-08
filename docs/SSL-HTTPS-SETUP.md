# SSL/HTTPS Setup

How to enable HTTPS on your EKS app.

## Using AWS ACM (what we did)

ACM certs are free and work great with ALB.

### Get a certificate

```bash
aws acm request-certificate \
  --domain-name orders.jumptotech.net \
  --validation-method DNS \
  --key-algorithm RSA_2048 \
  --region us-east-2
```

This gives you a certificate ARN - save it.

### Validate ownership

AWS needs to verify you own the domain. Run this to get the validation record:

```bash
aws acm describe-certificate --certificate-arn <ARN> --region us-east-2 \
  --query "Certificate.DomainValidationOptions[0].ResourceRecord"
```

Add the CNAME record to your DNS. For Route53:

```bash
aws route53 change-resource-record-sets --hosted-zone-id <ZONE_ID> \
  --change-batch file://validation-record.json
```

Wait a minute, then check status:

```bash
aws acm describe-certificate --certificate-arn <ARN> --region us-east-2 \
  --query "Certificate.Status"
```

Should say `ISSUED`.

### Point domain to ALB

Get your ALB hostname:
```bash
kubectl get ingress
```

Then add an A record alias in Route53 pointing your domain to the ALB.

### Update ingress

Add these annotations to your ingress:

```yaml
annotations:
  alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80},{"HTTPS":443}]'
  alb.ingress.kubernetes.io/ssl-redirect: "443"
  alb.ingress.kubernetes.io/certificate-arn: <your-cert-arn>
```

---

## Using Let's Encrypt (alternative)

If you want auto-renewing certs without ACM.

### Install cert-manager

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
```

### Create issuer

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@domain.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
      - http01:
          ingress:
            class: nginx
```

### Request certificate

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: orders-tls
spec:
  secretName: orders-tls-secret
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - orders.jumptotech.net
```

Check status: `kubectl get certificate`

---

## Why ALB URL shows "Not secure"

The ALB URL (`k8s-xxx.elb.amazonaws.com`) will always show a certificate warning because:
- Your cert is for `orders.jumptotech.net`
- The ALB URL doesn't match
- You can't get a cert for `*.elb.amazonaws.com` (AWS owns it)

Just use your custom domain for production.

---

## Our current setup

- Domain: `orders.jumptotech.net`
- Cert: `arn:aws:acm:us-east-2:343218219153:certificate/00353776-9755-4283-98f8-e05c1e337b28`
- ALB: `k8s-default-webappin-d73ba67759-1374685594.us-east-2.elb.amazonaws.com`
- Route53 zone: `Z0883248KM45SNH4FO6U`

---

## Quick troubleshooting

**Cert stuck on pending?**
Check if DNS validation record propagated: `nslookup _xxx.orders.jumptotech.net 8.8.8.8`

**Ingress not working?**
Check events: `kubectl describe ingress webapp-ingress`

**Browser still shows not secure?**
Clear cache or try incognito. DNS changes take a few minutes.
