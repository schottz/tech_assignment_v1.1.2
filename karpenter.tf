module "karpenter_role" {
  source                                      = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version                                     = "5.44.0"

  role_name                                   = "${module.eks.cluster_name}_karpenter_karpenter"
  attach_karpenter_controller_policy          = true
  karpenter_controller_cluster_name           = module.eks.cluster_name
  karpenter_tag_key                           = "karpenter.sh/cluster"
  enable_karpenter_instance_profile_creation  = true

  oidc_providers                              = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:karpenter"]
    }
  }
}

resource "helm_release" "karpenter" {
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "v0.34.13"
  namespace        = "kube-system"

  set {
    name  = "settings.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter_role.iam_role_arn
  }

}

resource "kubectl_manifest" "arm64_nodepool" {
  yaml_body  = file("${path.module}/karpenter_nodepools/arm64_spot.yaml")
  depends_on = [helm_release.karpenter]
}

resource "kubectl_manifest" "x86_nodepool" {
  yaml_body  = file("${path.module}/karpenter_nodepools/x86_spot.yaml")
  depends_on = [helm_release.karpenter]
}