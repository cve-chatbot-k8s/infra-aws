# https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
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

  enable_irsa = true

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

  enable_cluster_creator_admin_permissions = true

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

# Reference: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon
# Resource: EBS CSI Driver AddOn EKS Add-Ons (aws_eks_addon)
# resource "aws_eks_addon" "eks_cluster_ebs_csi_addon" {
#   cluster_name             = module.eks.cluster_name
#   addon_name               = "aws-ebs-csi-driver"
#   # addon_version            = "v1.25.0-eksbuild.1"
#   service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
#   depends_on = [
#     module.irsa-ebs-csi
#   ]
#   tags = {
#     tag-key = "ebs-csi-addon"
#   }
# }
############################################################################################################
# EKS Add-On - EBS CSI Driver
############################################################################################################
# output "eks_cluster_ebs_addon_arn" {
#   description = "Amazon Resource Name (ARN) of the EKS add-on"
#   value       = aws_eks_addon.eks_cluster_ebs_csi_addon.arn
# }
# output "eks_cluster_ebs_addon_id" {
#   description = "EKS Cluster name and EKS Addon name"
#   value       = aws_eks_addon.eks_cluster_ebs_csi_addon.id
# }
# output "eks_cluster_ebs_addon_time" {
#   description = "Date and time in RFC3339 format that the EKS add-on was created"
#   value       = aws_eks_addon.eks_cluster_ebs_csi_addon.created_at
# }

############################################################################################################
# EKS Add-On - EBS CSI Driver
############################################################################################################
output "cluster_certificate_authority_data" {
  description = "The base64 encoded certificate data required to communicate with your cluster."
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_endpoint" {
  description = "The endpoint for your Kubernetes API server."
  value       = module.eks.cluster_endpoint
}

# data "aws_eks_cluster" "cluster" {
#   name = module.eks.cluster_name
# }

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  config_path    = "~/.kube/config"
  config_context = "arn:aws:eks:us-east-1:905418442014:cluster/cve-eks-cluster"
}

resource "kubernetes_storage_class" "ebs_csi_encrypted" {
  metadata {
    name = "ebs-csi-encrypted"
  }

  parameters = {
    type        = "gp2"
    encrypted   = "true"
    kmsKeyId    = var.eks_ebs_encryption_key_arn
  }

  reclaim_policy = "Retain"
  volume_binding_mode = "Immediate"
  storage_provisioner = "ebs.csi.aws.com"

  depends_on = [
    # aws_eks_addon.eks_cluster_ebs_csi_addon,
    var.eks_create_storageclass_attachment_arn,
    var.eks_create_storageclass_policy_arn,
    var.eks_cluster_role_arn
  ]
}

variable "eks_cluster_id" {}
variable "eks_cluster_name" {}
variable "region" {}
variable "irsa_role_arn" {}

variable "eks_create_storageclass_attachment_arn" {}
variable "eks_create_storageclass_policy_arn" {}
variable "eks_cluster_role_arn" {}
