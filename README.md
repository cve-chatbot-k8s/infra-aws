# infra-aws
Steps:
1. terraform plan
2. terraform destroy

Destroy:
terraform destroy

terraform apply will create the following resources:

1) EKS Cluster
2) Cloudwatch Monitoring for EKS
3) Autoscaling Group
4) Kafka Cluster
5) Istio Service Mesh
6) Prometheus Monitoring
7) Grafana Monitoring