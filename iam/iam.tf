data "aws_iam_policy_document" "eks_create_storageclass" {
  statement {
    actions = [
      "eks:CreateStorageClass",
      "kms:CreateGrant",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
      "ec2:DescribeVpcs",
      "eks:DescribeCluster",
      "eks-auth:AssumeRoleForPodIdentity",
      "ec2:CreateVolume",
      "ec2:DeleteVolume",
      "ec2:AttachVolume"
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

data "aws_iam_policy_document" "worker_node_ebs_policy" {
  statement {
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
      "ec2:DescribeVpcs",
      "eks:DescribeCluster",
      "eks-auth:AssumeRoleForPodIdentity",
      "ec2:CreateVolume",
      "ec2:DeleteVolume",
      "ec2:AttachVolume"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "worker_node_ebs_policy" {
  name        = "worker-node-ebs-policy"
  description = "Policy for EKS worker nodes to manage EBS volumes"
  policy      = data.aws_iam_policy_document.worker_node_ebs_policy.json
}

resource "aws_iam_role_policy_attachment" "worker_node_ebs_policy_attachment" {
  for_each = toset(var.worker_iam_role_names)

  role       = each.value
  policy_arn = aws_iam_policy.worker_node_ebs_policy.arn
}

data "aws_iam_policy_document" "ebs_csi_driver_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver_role" {
  name               = "ebs-csi-driver-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume_role_policy.json
}

data "aws_iam_policy_document" "ebs_csi_driver_policy_document" {
  statement {
    actions = [
      "ec2:CreateVolume",
      "ec2:AttachVolume",
      "ec2:DeleteVolume",
      "ec2:DescribeVolumes",
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2:ModifyVolume",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeVolumeAttribute",
      "ec2:DescribeVolumeStatus",
      "ec2:DescribeSnapshots",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "kms:CreateGrant",
      "cloudwatch:PutMetricData",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ebs_csi_driver_policy" {
  name        = "ebsCSIDriverPolicy"
  description = "Policy for EBS CSI Driver"
  policy      = data.aws_iam_policy_document.ebs_csi_driver_policy_document.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy_attachment" {
  role       = aws_iam_role.ebs_csi_driver_role.name
  policy_arn = aws_iam_policy.ebs_csi_driver_policy.arn
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

output "worker_node_ebs_policy_arn" {
  description = "The ARN of the worker node EBS policy"
  value       = aws_iam_policy.worker_node_ebs_policy.arn
}
