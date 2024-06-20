terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.54.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 1.11.0"
    }
  }

  required_version = ">= 0.12"
}

module "vpc" {
  source = "./vpc"
}

module "iam" {
  source = "./iam"
}

module "eks" {
  source                                 = "./eks"
  vpc_id                                 = module.vpc.vpc_id
  private_subnets                        = module.vpc.vpc_private_subnets
  public_subnets                         = module.vpc.vpc_public_subnets
  eks_ebs_encryption_key_arn             = module.iam.eks_ebs_encryption_key_arn
  eks_secrets_encryption_key_arn         = module.iam.eks_secrets_encryption_key_arn
  eks_cluster_id                         = ""
  eks_cluster_name                       = ""
  irsa_role_arn                          = ""
  region                                 = ""
  eks_create_storageclass_attachment_arn = module.iam.eks_create_storageclass_attachment
  eks_create_storageclass_policy_arn     = module.iam.eks_create_storageclass_policy
  eks_cluster_role_arn                   = module.iam.eks_cluster_role_arn
}
