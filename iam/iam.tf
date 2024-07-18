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

# resource "aws_iam_openid_connect_provider" "eks" {
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
#   url             = var.oidc_issuer_url
# }

# data "aws_iam_policy_document" "eks_cluster_autoscaler_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#     effect  = "Allow"
#
#     condition {
#       test     = "StringEquals"
#       variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
#       values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
#     }
#
#     principals {
#       identifiers = [aws_iam_openid_connect_provider.eks.arn]
#       type        = "Federated"
#     }
#   }
# }
#
# resource "aws_iam_role" "eks_cluster_autoscaler" {
#   assume_role_policy = data.aws_iam_policy_document.eks_cluster_autoscaler_assume_role_policy.json
#   name               = "eks-cluster-autoscaler"
# }
#
# resource "aws_iam_policy" "eks_cluster_autoscaler" {
#   name = "eks-cluster-autoscaler"
#
#   policy = jsonencode({
#     Statement = [{
#       Action = [
#         "autoscaling:DescribeAutoScalingGroups",
#         "autoscaling:DescribeAutoScalingInstances",
#         "autoscaling:DescribeLaunchConfigurations",
#         "autoscaling:DescribeTags",
#         "autoscaling:SetDesiredCapacity",
#         "autoscaling:TerminateInstanceInAutoScalingGroup",
#         "ec2:DescribeLaunchTemplateVersions"
#       ]
#       Effect   = "Allow"
#       Resource = "*"
#     }]
#     Version = "2012-10-17"
#   })
# }
#
# resource "aws_iam_role_policy_attachment" "eks_cluster_autoscaler_attach" {
#   role       = aws_iam_role.eks_cluster_autoscaler.name
#   policy_arn = aws_iam_policy.eks_cluster_autoscaler.arn
# }
#
# output "eks_cluster_autoscaler_arn" {
#   value = aws_iam_role.eks_cluster_autoscaler.arn
# }

resource "aws_iam_role" "eks_autoscaler_role" {
  name = "eks-autoscaler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::905418442014:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/1F549F2157D312A4AFA5E0BB8C1F44FC"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "oidc.eks.us-east-1.amazonaws.com/id/1F549F2157D312A4AFA5E0BB8C1F44FC:sub" : "system:serviceaccount:kube-system:cluster-autoscaler"
          }
        }
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

resource "aws_iam_role_policy_attachment" "eks_autoscaler_ec2_policy" {
  role       = aws_iam_role.eks_autoscaler_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "eks_autoscaler_worker_node_policy" {
  role       = aws_iam_role.eks_autoscaler_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

output "eks_autoscaler_role_arn" {
    value = aws_iam_role.eks_autoscaler_role.arn
  }
