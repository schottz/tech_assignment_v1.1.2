data "aws_caller_identity" "current" {}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
  depends_on = [ module.eks ]
}