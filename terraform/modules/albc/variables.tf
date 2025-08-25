variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider for the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where the EKS cluster is deployed"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "helm_chart_version" {
  description = "Version of the AWS Load Balancer Controller Helm chart"
  type        = string
  default     = "1.8.0"
}

variable "namespace" {
  description = "Namespace to install the AWS Load Balancer Controller"
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "Name of the service account for AWS Load Balancer Controller"
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "replica_count" {
  description = "Number of replicas for the AWS Load Balancer Controller"
  type        = number
  default     = 2
}

variable "enable_shield" {
  description = "Enable AWS Shield Advanced for ALB"
  type        = bool
  default     = false
}

variable "enable_waf" {
  description = "Enable AWS WAF for ALB"
  type        = bool
  default     = false
}

variable "log_level" {
  description = "Log level for the AWS Load Balancer Controller"
  type        = string
  default     = "info"
  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.log_level)
    error_message = "Log level must be one of: debug, info, warn, error."
  }
}