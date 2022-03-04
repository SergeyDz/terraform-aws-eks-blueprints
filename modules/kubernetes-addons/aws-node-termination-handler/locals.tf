locals {
  namespace            = "kube-system"
  name                 = "aws-node-termination-handler"
  service_account_name = "${local.name}-sa"

  default_helm_config = {
    name             = local.name
    chart            = local.name
    repository       = "https://aws.github.io/eks-charts"
    version          = "0.16.0"
    namespace        = local.namespace
    timeout          = "1200"
    create_namespace = false
    description      = "AWS Node Termination Handler Helm Chart"
    values           = local.default_helm_values
  }

  helm_config = merge(
    local.default_helm_config,
    var.helm_config
  )

  default_helm_values = [templatefile("${path.module}/values.yaml", {
    nth-sa-name = local.service_account_name
  })]

  irsa_config = {
    kubernetes_namespace              = local.namespace
    kubernetes_service_account        = local.service_account_name
    create_kubernetes_namespace       = false
    create_kubernetes_service_account = true
    iam_role_path                     = "/"
    tags                              = var.addon_context.tags
    irsa_iam_policies                 = [aws_iam_policy.aws_node_termination_handler_irsa.arn]
  }

  event_rules = [
    {
      name          = "NTHASGTermRule",
      event_pattern = <<EOF
{"source":["aws.autoscaling"],"detail-type":["EC2 Instance-terminate Lifecycle Action"]}
EOF
    },
    {
      name          = "NTHSpotTermRule",
      event_pattern = <<EOF
{"source": ["aws.ec2"],"detail-type": ["EC2 Spot Instance Interruption Warning"]}
EOF
    },
    {
      name          = "NTHRebalanceRule",
      event_pattern = <<EOF
{"source": ["aws.ec2"],"detail-type": ["EC2 Instance Rebalance Recommendation"]}
EOF
    },
    {
      name          = "NTHInstanceStateChangeRule",
      event_pattern = <<EOF
{"source": ["aws.ec2"],"detail-type": ["EC2 Instance State-change Notification"]}
EOF
    },
    {
      name          = "NTHScheduledChangeRule",
      event_pattern = <<EOF
{"source": ["aws.health"],"detail-type": ["AWS Health Event"]}
EOF
    }
  ]
}
