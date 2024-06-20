data "aws_iam_policy_document" "eks_create_storageclass" {
  statement {
    actions = [
      "eks:CreateStorageClass"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "eks_create_storageclass" {
  name        = "eksCreateStorageClass"
  description = "Allows creation of storageclasses in EKS"
  policy      = data.aws_iam_policy_document.eks_create_storageclass.json
}

resource "aws_iam_role_policy_attachment" "eks_create_storageclass" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = aws_iam_policy.eks_create_storageclass.arn
}

resource "aws_iam_role" "eks_cluster_role" {
name = "eks-cluster-role"

assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role" "ebs_csi_driver_role" {
name = "ebs-csi-driver-role"

assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
role       = aws_iam_role.ebs_csi_driver_role.name
}

output "eks_cluster_role_arn" {
  value = aws_iam_role.eks_cluster_role.arn
}

output "ebs_csi_driver_role_arn" {
  value = aws_iam_role.ebs_csi_driver_role.arn
}

output "eks_create_storageclass_attachment" {
  description = "The IAM role policy attachment for EKS storage class creation"
  value       = aws_iam_role_policy_attachment.eks_create_storageclass
}

output "eks_create_storageclass_policy" {
  description = "value of the IAM policy document for EKS storage class creation"
  value = aws_iam_policy.eks_create_storageclass.arn
}
