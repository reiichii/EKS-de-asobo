variable "user" {
  description = "User name from environment variable"
  type        = string
  default     = ""
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-handson"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.33"
}

variable "argocd_repo_url" {
  description = "ArgoCD repository URL"
  type        = string
  default     = "https://github.com/reiichii/EKS-de-asobo"
}

variable "argocd_repo_branch" {
  description = "ArgoCD repository branch"
  type        = string
  default     = "main"
}