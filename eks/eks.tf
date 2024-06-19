module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  authentication_mode = "API_AND_CONFIG_MAP"
  cluster_name    = "cve-eks-cluster"
  cluster_version = "1.29"

  // default value is false
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access  = true

  // default value is ipv4
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
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
    }
  }

  cluster_encryption_config = {
    provider_key_arn = var.eks_secrets_encryption_key_arn
    resources = ["secrets"]
  }

  vpc_id = var.vpc_id
  // private subnets
  subnet_ids               = var.private_subnets
  // public subnets
  control_plane_subnet_ids = var.public_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["c3.large"]
  }

  eks_managed_node_groups = {
    webapp = {
      ami_type        = "AL2_x86_64"
      capacity_type   = "ON_DEMAND"
      instance_types  = ["c3.large"]
      desired_size    = 2  // Change this later according to requirements
      min_size        = 1
      max_size        = 2

      update_config = {
        max_unavailable = 1
      }

      tags = {
        Name   = "webapp-nodes"
      }
    }
  }

  # Cluster access entry
  # To add the current caller identity as an administrator
#   enable_cluster_creator_admin_permissions = true

#   access_entries = {
#     example = {
#       kubernetes_groups = []
#       principal_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/existing-role"
#
#       policy_associations = {
#         example = {
#           policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
#           access_scope = {
#             namespaces = ["default"]
#             type       = "namespace"
#           }
#         }
#       }
#     }
#   }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

variable "vpc_id" {}
variable "private_subnets" {}
variable "public_subnets" {}
variable "eks_ebs_encryption_key_arn" {}
variable "eks_secrets_encryption_key_arn" {}

# Defined in iam/kms.tf
# data "aws_kms_key" "eks_secrets_encryption" {
#   key_id = "alias/eks-secrets-encryption"
# }
# #
# # // Defined in iam/kms.tf
# data "aws_kms_key" "eks_ebs_encryption" {
#   key_id = "alias/eks-ebs-encryption"
# }

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