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