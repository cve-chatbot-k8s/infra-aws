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

resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# #try removing this policy and see if it works
# data "aws_iam_policy_document" "eks_create_storageclass" {
#   statement {
#     actions = [
#       "ec2:CreateVolume",
#       "ec2:DeleteVolume",
#       "ec2:AttachVolume",
#       "ec2:DetachVolume",
#       "ec2:DescribeVolumes",
#       "ec2:DescribeVolumeStatus",
#       "kms:CreateGrant",
#       "kms:ListGrants",
#       "kms:RevokeGrant"
#     ]
#     resources = ["*"]
#   }
# }

# resource "aws_iam_policy" "eks_create_storageclass" {
#   name        = "eksCreateStorageClass"
#   description = "Allows creation of storageclasses in EKS"
#   policy      = data.aws_iam_policy_document.eks_create_storageclass.json
# }

# resource "aws_iam_role_policy_attachment" "eks_create_storageclass" {
#   # role       = aws_iam_role.eks_cluster_role.name
#   role       = aws_iam_role.eks_node_role.name
#   policy_arn = aws_iam_policy.eks_create_storageclass.arn
# }

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
  role       = aws_iam_role.eks_node_role.name
  policy_arn = aws_iam_policy.worker_node_ebs_policy.arn
}

resource "aws_iam_policy" "irsa_ebs_kms_policy" {
  name        = "irsa_ebs_kms_policy"
  description = "Custom policy for IRSA"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant"
      ],
      "Resource": ["arn:aws:kms:us-east-1:905418442014:key/6944060a-2038-4c79-a561-29ddc8965034"],
      "Condition": {
        "Bool": {
          "kms:GrantIsForAWSResource": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": ["arn:aws:kms:us-east-1:905418442014:key/6944060a-2038-4c79-a561-29ddc8965034"]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "irsa_ebs_kms_policy_attachment" {
  role       = var.irsa_output
  policy_arn = aws_iam_policy.irsa_ebs_kms_policy.arn
}

output "eks_cluster_role_arn" {
  value = aws_iam_role.eks_cluster_role.arn
}

# output "eks_create_storageclass_attachment" {
#   description = "The IAM role policy attachment for EKS storage class creation"
#   value       = aws_iam_role_policy_attachment.eks_create_storageclass
# }

# output "eks_create_storageclass_policy" {
#   description = "value of the IAM policy document for EKS storage class creation"
#   value = aws_iam_policy.eks_create_storageclass.arn
# }

output "worker_node_ebs_policy_arn" {
  description = "The ARN of the worker node EBS policy"
  value       = aws_iam_policy.worker_node_ebs_policy.arn
}

data "aws_iam_policy_document" "eks_namespace_management" {
  statement {
    actions = [
      "eks:CreateNamespace",
      "eks:DeleteNamespace",
      "eks:DescribeNamespace",
      "eks:ListNamespaces"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "eks_namespace_management" {
  name        = "eksNamespaceManagement"
  description = "Allows management of EKS namespaces"
  policy      = data.aws_iam_policy_document.eks_namespace_management.json
}

resource "aws_iam_role_policy_attachment" "eks_namespace_management" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = aws_iam_policy.eks_namespace_management.arn
}

resource "aws_iam_role" "eks_autoscaler_role" {
    name = "eks-autoscaler-role"
  
    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = {
            Service = "ec2.amazonaws.com"
          }
          Action = "sts:AssumeRole"
        }
      ]
    })
  }
  
  resource "aws_iam_role_policy_attachment" "eks_autoscaler_policy" {
    role       = aws_iam_role.eks_autoscaler_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  }
  
  resource "aws_iam_role_policy_attachment" "eks_autoscaler_autoscaling_policy" {
    role       = aws_iam_role.eks_autoscaler_role.name
    policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
  }
  
  resource "aws_iam_role_policy_attachment" "eks_autoscaler_cloudwatch_policy" {
    role       = aws_iam_role.eks_autoscaler_role.name
    policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  }
  
  output "eks_autoscaler_role_arn" {
    value = aws_iam_role.eks_autoscaler_role.arn
  }
