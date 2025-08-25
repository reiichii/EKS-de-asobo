output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_server_service_name" {
  description = "ArgoCD server service name"
  value       = "argocd-server"
}

output "argocd_release_name" {
  description = "ArgoCD Helm release name"
  value       = helm_release.argocd.name
}

output "argocd_chart_version" {
  description = "ArgoCD Helm chart version"
  value       = helm_release.argocd.version
}

output "argocd_ingress_name" {
  description = "ArgoCD ingress name"
  value       = "argocd-server"
}

output "argocd_ingress_class" {
  description = "ArgoCD ingress class"
  value       = "alb"
}