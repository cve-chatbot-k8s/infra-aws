# https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  authentication_mode = "API_AND_CONFIG_MAP"
  cluster_name    = var.eks_cluster_name
  cluster_version = "1.29"

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access  = true

  cluster_ip_family = "ipv4"

  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
      configuration_values = jsonencode({
        "enableNetworkPolicy" = "true"
      })
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
    }
  }

  enable_irsa = true

  cluster_encryption_config = {
    provider_key_arn = var.eks_secrets_encryption_key_arn
    resources = ["secrets"]
  }

  vpc_id = var.vpc_id
  subnet_ids               = var.private_subnets
  control_plane_subnet_ids = var.public_subnets

  eks_managed_node_group_defaults = {
    instance_types = var.instance_types
  }

  eks_managed_node_groups = {
    webapp = {
      ami_type        = var.ami_type
      capacity_type   = var.capacity_type
      instance_types  = var.instance_types
      desired_size    = var.desired_size
      min_size        = var.min_size
      max_size        = var.max_size

      update_config = {
        max_unavailable = var.max_unavailable
      }

      tags = {
        Name   = "webapp-nodes"
      }
    }
  }

  enable_cluster_creator_admin_permissions = true

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

output "irsa_output" {
  value = module.irsa-ebs-csi.iam_role_name
}

output "irsa_role_arn" {
  value = module.irsa-ebs-csi.iam_role_arn
}

output "cluster_certificate_authority_data" {
  description = "The base64 encoded certificate data required to communicate with your cluster."
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_endpoint" {
  description = "The endpoint for your Kubernetes API server."
  value       = module.eks.cluster_endpoint
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

resource "kubernetes_storage_class" "ebs_csi_encrypted" {
  metadata {
    name = "ebs-csi-encrypted"
  }

  parameters = {
    type        = "gp3"
    encrypted   = "true"
    kmsKeyId    = var.eks_ebs_encryption_key_arn
  }

  reclaim_policy = var.reclaim_policy
  volume_binding_mode = var.volume_binding_mode
  storage_provisioner = "ebs.csi.aws.com"

  depends_on = [
    # var.eks_create_storageclass_attachment_arn,
    # var.eks_create_storageclass_policy_arn,
    var.eks_cluster_role_arn
  ]
}

resource "kubernetes_namespace" "kafka" {
  metadata {
    name = "kafka"
  }
}

resource "kubernetes_namespace" "webapp" {
  metadata {
    name = "webapp"
  }
}

resource "kubernetes_namespace" "consumer" {
  metadata {
    name = "consumer"
  }
}

resource "kubernetes_namespace" "operator" {
  metadata {
    name = "operator"
  }
}

# resource "kubernetes_resource_quota" "kafka" {
#   metadata {
#     name      = "kafka"
#     namespace = kubernetes_namespace.kafka.metadata[0].name
#   }
#
#   spec {
#     hard = {
#       "requests.cpu"    = "1.9"
#       "requests.memory" = "3100Mi"
#       "limits.cpu"      = "3.5"
#       "limits.memory"   = "5400Mi"
#     }
#   }
# }

resource "kubernetes_limit_range" "webapp" {
  metadata {
    name      = "webapp"
    namespace = kubernetes_namespace.webapp.metadata[0].name
  }

  spec {
    limit {
      type = "Container"

      default = {
        cpu    = var.webapp_default_limits["cpu"]
        memory = var.webapp_default_limits["memory"]
      }

      default_request = {
        cpu    = var.webapp_default_requests["cpu"]
        memory = var.webapp_default_requests["memory"]
      }

      max = {
        cpu    = var.webapp_max_limits["cpu"]
        memory = var.webapp_max_limits["memory"]
      }

      min = {
        cpu    = var.webapp_min_limits["cpu"]
        memory = var.webapp_min_limits["memory"]
      }
    }
  }
}

resource "kubernetes_limit_range" "consumer" {
  metadata {
    name      = "consumer"
    namespace = kubernetes_namespace.consumer.metadata[0].name
  }

  spec {
    limit {
      type = "Container"

      max = {
        cpu    = var.consumer_max_limits["cpu"]
        memory = var.consumer_max_limits["memory"]
      }

      min = {
        cpu    = var.consumer_min_limits["cpu"]
        memory = var.consumer_min_limits["memory"]
      }

      default = {
        cpu    = var.consumer_default_limits["cpu"]
        memory = var.consumer_default_limits["memory"]
      }

      default_request = {
        cpu    = var.consumer_default_requests["cpu"]
        memory = var.consumer_default_requests["memory"]
      }
    }
  }
}

resource "kubernetes_limit_range" "kafka" {
  metadata {
    name      = "kafka"
    namespace = kubernetes_namespace.kafka.metadata[0].name
  }

  spec {
    limit {
      type = "Container"

      default = {
        cpu    = var.kafka_default_limits["cpu"]
        memory = var.kafka_default_limits["memory"]
      }

      default_request = {
        cpu    = var.kafka_default_requests["cpu"]
        memory = var.kafka_default_requests["memory"]
      }

      max = {
        cpu    = var.kafka_max_limits["cpu"]
        memory = var.kafka_max_limits["memory"]
      }

      min = {
        cpu    = var.kafka_min_limits["cpu"]
        memory = var.kafka_min_limits["memory"]
      }
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
    config_path = "~/.kube/config"
  }
}

# data "helm_repository" "bitnami" {
#   name = "bitnami"
#   url  = "https://charts.bitnami.com/bitnami"
# }

resource "helm_release" "kafka" {
  name       = "kafka"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "kafka"
  version    = "29.3.4"
  namespace  = "kafka"

  values = [
    file("./eks/values.yaml")
  ]

  depends_on = [module.eks]
}

resource "helm_release" "cluster_autoscaler" {
  depends_on = [module.eks, var.eks_autoscaler_role_arn]
  name       = "cluster-autoscaler"
  chart = var.chart_path
  namespace  = "kube-system"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.eks_autoscaler_role_arn
  }

  values     = [file(var.values_file_path), file(var.values_override_file_path)]
}

output "oidc_provider" {
  value = module.eks.oidc_provider
}
