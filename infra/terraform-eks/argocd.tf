# ArgoCD Namespace - use data source if exists, create if not
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }

  lifecycle {
    ignore_changes = all
  }

  depends_on = [module.eks]
}

# ArgoCD Installation via Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "5.51.6"

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }

  depends_on = [
    module.eks,
    helm_release.alb_controller
  ]
}

# GHCR Pull Secret for default namespace
resource "kubernetes_secret" "ghcr" {
  metadata {
    name      = "ghcr"
    namespace = "default"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "ghcr.io" = {
          username = var.ghcr_username
          password = var.ghcr_pat
          auth     = base64encode("${var.ghcr_username}:${var.ghcr_pat}")
        }
      }
    })
  }

  lifecycle {
    ignore_changes = all
  }

  depends_on = [module.eks]
}

# ArgoCD Application for webapp
resource "kubectl_manifest" "webapp_application" {
  yaml_body = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: webapp
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: 'https://github.com/Aisalkyn85/kafka-enterprise-orders.git'
        targetRevision: main
        path: k8s/charts/webapp
        helm:
          values: |
            frontendImage: "ghcr.io/aisalkyn85/kafka-enterprise-orders/web-frontend:latest"
            backendImage: "ghcr.io/aisalkyn85/kafka-enterprise-orders/web-backend:latest"
            backendPort: 8000
            replicaCount: 1
            ghcr:
              enabled: false
            ingress:
              host: "${var.app_domain}"
              certificateArn: "${var.certificate_arn}"
              class: "alb"
              annotations:
                alb.ingress.kubernetes.io/scheme: internet-facing
                alb.ingress.kubernetes.io/target-type: ip
            couchbase:
              host: "${var.couchbase_host}"
              bucket: "${var.couchbase_bucket}"
              username: "${var.couchbase_username}"
              password: "${var.couchbase_password}"
      destination:
        server: https://kubernetes.default.svc
        namespace: default
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
  YAML

  depends_on = [
    helm_release.argocd,
    kubernetes_secret.ghcr
  ]
}

