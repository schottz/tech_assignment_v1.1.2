module "eks" {
  source                                    = "terraform-aws-modules/eks/aws"
  version                                   = "~> 20.0"
  cluster_name                              = var.cluster_name
  cluster_version                           = "1.32"
  vpc_id                                    = var.vpc_id
  subnet_ids                                = var.public_subnet_ids
  control_plane_subnet_ids                  = var.public_subnet_ids

  cluster_endpoint_public_access            = true
  cluster_endpoint_private_access           = true
  enable_cluster_creator_admin_permissions  = true

  eks_managed_node_groups                   = {
    initial = {
      min_size                      = 1
      max_size                      = 3
      desired_size                  = 1
      instance_types                = ["t3.medium"]
      capacity_type                 = "ON_DEMAND"
      iam_role_use_name_prefix      = false
      iam_role_name                 = "${var.cluster_name}-node-role"
      subnet_ids                    = var.public_subnet_ids
      ami_type                      = "AL2_x86_64"
      
      
      iam_role_additional_policies  = {
        AmazonEKSWorkerNodePolicy           = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
        AmazonEC2ContainerRegistryReadOnly  = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        AmazonEKS_CNI_Policy                = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
        AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      tags                          = {
        "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      }
    }
  }


  tags = {
    Environment = "startup"
    Terraform   = "true"
  }
}