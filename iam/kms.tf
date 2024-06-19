resource "aws_kms_key" "eks_secrets_encryption" {
  description             = "KMS key for EKS secrets encryption"
  deletion_window_in_days = 10

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Allow root user to manage key",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow EKS to use the key",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/eks-cluster-role"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
        "kms:CreateGrant"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_kms_key" "eks_ebs_encryption" {
  description             = "KMS key for EBS volume encryption"
  deletion_window_in_days = 10

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Allow root user to manage key",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow EBS CSI Driver to use the key",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ebs-csi-driver-role"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
        "kms:CreateGrant"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

# resource "aws_kms_alias" "eks_secrets_encryption_alias" {
#   name          = "alias/eks-secrets-encryption"
#   target_key_id = aws_kms_key.eks_secrets_encryption.id
# }
#
# resource "aws_kms_alias" "eks_ebs_encryption_alias" {
#   name          = "alias/eks-ebs-encryption"
#   target_key_id = aws_kms_key.eks_ebs_encryption.id
# }

output "eks_secrets_encryption_key_arn" {
  description = "The ARN of the KMS key for EKS secrets encryption"
  value       = aws_kms_key.eks_secrets_encryption.id
}

output "eks_ebs_encryption_key_arn" {
  description = "The ARN of the KMS key for EBS volume encryption"
  value       = aws_kms_key.eks_ebs_encryption.arn
}

data "aws_caller_identity" "current" {}