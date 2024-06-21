variable "worker_iam_role_names" {
  description = "List of IAM role names for the EKS worker nodes"
  type        = list(string)
}
