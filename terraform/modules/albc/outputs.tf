output "iam_role_arn" {
  description = "ARN of the IAM role created for the AWS Load Balancer Controller"
  value       = aws_iam_role.aws_load_balancer_controller.arn
}

output "iam_role_name" {
  description = "Name of the IAM role created for the AWS Load Balancer Controller"
  value       = aws_iam_role.aws_load_balancer_controller.name
}

output "iam_policy_arn" {
  description = "ARN of the IAM policy created for the AWS Load Balancer Controller"
  value       = aws_iam_policy.aws_load_balancer_controller.arn
}

output "service_account_name" {
  description = "Name of the Kubernetes service account"
  value       = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
}

output "service_account_namespace" {
  description = "Namespace of the Kubernetes service account"
  value       = kubernetes_service_account.aws_load_balancer_controller.metadata[0].namespace
}

output "helm_release_name" {
  description = "Name of the Helm release"
  value       = helm_release.aws_load_balancer_controller.name
}

output "helm_release_namespace" {
  description = "Namespace of the Helm release"
  value       = helm_release.aws_load_balancer_controller.namespace
}

output "helm_release_version" {
  description = "Version of the Helm release"
  value       = helm_release.aws_load_balancer_controller.version
}

output "helm_release_status" {
  description = "Status of the Helm release"
  value       = helm_release.aws_load_balancer_controller.status
}