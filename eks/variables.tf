variable "vpc_id" {
  description = "The ID of the VPC where the EKS cluster will be created"
}

variable "private_subnets" {
  description = "The private subnets for the EKS cluster"
  type        = list(string)
}

variable "public_subnets" {
  description = "The public subnets for the EKS cluster"
  type        = list(string)
}

variable "eks_ebs_encryption_key_arn" {
  description = "The ARN of the EBS encryption key for the EKS cluster"
}

variable "eks_secrets_encryption_key_arn" {
  description = "The ARN of the secrets encryption key for the EKS cluster"
}

variable "eks_cluster_id" {
  default = "905418442014"
  description = "The ID of the EKS cluster"
}

variable "eks_cluster_name" {
  default = "cve-eks-cluster"
  description = "The name of the EKS cluster"
}

variable "region" {
  default = "us-east-1"
  description = "The AWS region where the EKS cluster will be created"
}

# variable "irsa_role_arn" {
#   description = "The ARN of the IAM role for service accounts (IRSA)"
# }

# variable "eks_create_storageclass_attachment_arn" {
#   description = "The ARN of the IAM role policy attachment for EKS storage class creation"
# }

# variable "eks_create_storageclass_policy_arn" {
#   description = "The ARN of the IAM policy for EKS storage class creation"
# }

variable "eks_cluster_role_arn" {
  description = "The ARN of the IAM role for the EKS cluster"
}

variable "ami_type" {
  description = "The type of Amazon Machine Image (AMI) that will be used for the EKS nodes"
  default     = "AL2_x86_64"
}

variable "capacity_type" {
  description = "The capacity type for the EKS nodes"
  default     = "ON_DEMAND"
}

variable "instance_types" {
  description = "The instance types to be used for the EKS nodes"
  type        = list(string)
  default     = ["c3.large"]
}

variable "desired_size" {
  description = "The desired number of worker nodes"
  default     = 3
}

variable "min_size" {
  description = "The minimum number of worker nodes"
  default     = 3
}

variable "max_size" {
  description = "The maximum number of worker nodes"
  default     = 6
}

variable "max_unavailable" {
  description = "The maximum number of worker nodes that can be unavailable during an update"
  default     = 1
}

variable "reclaim_policy" {
  description = "The reclaim policy for the storage class in the EKS cluster"
  default     = "Retain"
}

variable "volume_binding_mode" {
  description = "The volume binding mode for the storage class in the EKS cluster"
  default     = "Immediate"
}


variable "worker_node_ebs_policy_arn" {
  description = "ebs policy arn"
}

variable "eks_autoscaler_role_arn" {
  description = "The ARN of the IAM role for the EKS autoscaler"
}

variable "values_file_path" {
  description = "Path to the values.yaml file"
  type        = string
  default     = "../helm-eks-autoscaler/cluster-autoscaler/values.yaml"
}

variable "chart_path" {
  description = "Path to the Helm chart"
  type        = string
  default     = "../helm-eks-autoscaler/cluster-autoscaler"
}

variable "values_override_file_path" {
  description = "Path to the values.override.yaml file"
  default     = "../helm-eks-autoscaler/cluster-autoscaler/values.override.yaml"
  type        = string
}

variable "webapp_default_limits" {
  description = "Default limits for CPU and memory for webapp"
  type = map(string)
  default = {
    cpu    = "1"
    memory = "2000Mi"
  }
}

variable "webapp_default_requests" {
  description = "Default requests for CPU and memory for webapp"
  type = map(string)
  default = {
    cpu    = "0.5"
    memory = "1Gi"
  }
}

variable "webapp_max_limits" {
  description = "Maximum limits for CPU and memory for webapp"
  type = map(string)
  default = {
    cpu    = "1.5"
    memory = "3600Mi"
  }
}

variable "webapp_min_limits" {
  description = "Minimum limits for CPU and memory for webapp"
  type = map(string)
  default = {
    cpu    = "100m"
    memory = "256Mi"
  }
}

variable "consumer_max_limits" {
  description = "Maximum CPU and memory limits for the consumer namespace"
  type        = map(string)
  default     = {
    cpu    = "4"
    memory = "3700Mi"
  }
}

variable "consumer_min_limits" {
  description = "Minimum CPU and memory limits for the consumer namespace"
  type        = map(string)
  default     = {
    cpu    = "100m"
    memory = "256Mi"
  }
}

variable "consumer_default_limits" {
  description = "Default CPU and memory limits for the consumer namespace"
  type        = map(string)
  default     = {
    cpu    = "1"
    memory = "1000Mi"
  }
}

variable "consumer_default_requests" {
  description = "Default CPU and memory requests for the consumer namespace"
  type        = map(string)
  default     = {
    cpu    = "0.5"
    memory = "500Mi"
  }
}

variable "kafka_max_limits" {
  description = "Maximum CPU and memory limits for the kafka namespace"
  type        = map(string)
  default     = {
    cpu    = "1"
    memory = "1Gi"
  }
}

variable "kafka_min_limits" {
  description = "Minimum CPU and memory limits for the kafka namespace"
  type        = map(string)
  default     = {
    cpu    = "10m"
    memory = "16Mi"
  }
}

variable "kafka_default_limits" {
  description = "Default CPU and memory limits for the kafka namespace"
  type        = map(string)
  default     = {
    cpu    = "250m"
    memory = "256Mi"
  }
}

variable "kafka_default_requests" {
  description = "Default CPU and memory requests for the kafka namespace"
  type        = map(string)
  default     = {
    cpu    = "125m"
    memory = "128Mi"
  }
}