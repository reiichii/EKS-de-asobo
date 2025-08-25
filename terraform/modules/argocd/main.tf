resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    yamlencode({
      global = {
        nodeSelector = var.node_selector
      }

      controller = {
        nodeSelector = var.node_selector
      }

      server = {
        nodeSelector = var.node_selector
        service = {
          type = "ClusterIP"
        }
        ingress = {
          enabled = true
          annotations = {
            "kubernetes.io/ingress.class"            = "alb"
            "alb.ingress.kubernetes.io/scheme"       = "internet-facing"
            "alb.ingress.kubernetes.io/target-type"  = "ip"
            "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\":80}]"
          }
          paths    = ["/"]
          pathType = "Prefix"
        }
        extraArgs = [
          "--insecure"
        ]
      }

      repoServer = {
        nodeSelector = var.node_selector
      }

      applicationSet = {
        nodeSelector = var.node_selector
      }

      notifications = {
        nodeSelector = var.node_selector
      }

      dex = {
        nodeSelector = var.node_selector
      }

      redis = {
        nodeSelector = var.node_selector
      }
    })
  ]

  depends_on = [kubernetes_namespace.argocd]
}
