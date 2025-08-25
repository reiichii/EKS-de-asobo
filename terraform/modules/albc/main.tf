################################################################################
# IAM Policy for AWS Load Balancer Controller
################################################################################

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name_prefix = "AWSLoadBalancerControllerIAMPolicy-"
  path        = "/"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = data.aws_iam_policy_document.aws_load_balancer_controller.json

  tags = var.tags
}

################################################################################
# IAM Role for AWS Load Balancer Controller (IRSA)
################################################################################

resource "aws_iam_role" "aws_load_balancer_controller" {
  name_prefix        = "AmazonEKSLoadBalancerControllerRole-"
  assume_role_policy = data.aws_iam_policy_document.aws_load_balancer_controller_assume_role_policy.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
  role       = aws_iam_role.aws_load_balancer_controller.name
}

################################################################################
# Kubernetes Service Account
################################################################################

resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = var.service_account_name
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_load_balancer_controller.arn
    }
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
    }
  }

  depends_on = [aws_iam_role_policy_attachment.aws_load_balancer_controller]
}

################################################################################
# Helm Release for AWS Load Balancer Controller
################################################################################

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.helm_chart_version
  namespace  = var.namespace

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = var.service_account_name
  }

  set {
    name  = "replicaCount"
    value = var.replica_count
  }

  set {
    name  = "region"
    value = data.aws_region.current.name
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "logLevel"
    value = var.log_level
  }

  dynamic "set" {
    for_each = var.enable_shield ? [1] : []
    content {
      name  = "enableShield"
      value = "true"
    }
  }

  dynamic "set" {
    for_each = var.enable_waf ? [1] : []
    content {
      name  = "enableWaf"
      value = "true"
    }
  }

  # Resource limits and requests
  set {
    name  = "resources.limits.cpu"
    value = "200m"
  }

  set {
    name  = "resources.limits.memory"
    value = "500Mi"
  }

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "200Mi"
  }

  # Node selector for Linux nodes
  set {
    name  = "nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }

  # Pod disruption budget
  set {
    name  = "podDisruptionBudget.maxUnavailable"
    value = "1"
  }

  depends_on = [kubernetes_service_account.aws_load_balancer_controller]
}