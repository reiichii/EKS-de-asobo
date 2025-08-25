variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "7.6.12"
}

variable "node_selector" {
  description = "Node selector for ArgoCD pods"
  type        = map(string)
  default = {
    "workload-type" = "ops"
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "repo_url" {
  description = "ArgoCD applications repository URL"
  type        = string
}

variable "repo_branch" {
  description = "ArgoCD applications repository branch"
  type        = string
  default     = "main"
}