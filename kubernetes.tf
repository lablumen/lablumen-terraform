# ---------------------------------------------------------------------------
# Kubernetes namespaces and IRSA-annotated ServiceAccounts
#
# Terraform creates these so each IRSA role ARN is wired to its SA annotation in the same apply — no
# copy-paste from `terraform output`. The Helm charts in lablumen-k8s use serviceAccount.create:false
# and reference these pre-existing SAs by name (in both prod `lablumen` and dev `lablumen-dev`).
# ---------------------------------------------------------------------------

locals {
  # App-tier ServiceAccounts that exist in BOTH the prod and dev namespaces (one IRSA role each,
  # trusted for both namespaces — see modules/iam).
  app_namespaces = ["lablumen", "lablumen-dev"]

  app_service_account_roles = {
    "report-service"       = module.iam.report_service_role_arn
    "notification-service" = module.iam.notification_service_role_arn
  }

  app_service_accounts = merge([
    for ns in local.app_namespaces : {
      for sa, role_arn in local.app_service_account_roles :
      "${ns}/${sa}" => { namespace = ns, name = sa, role_arn = role_arn }
    }
  ]...)
}

# ---- Namespaces ------------------------------------------------------------------
resource "kubernetes_namespace" "external_secrets" {
  metadata { name = "external-secrets" }
  depends_on = [module.eks]
}

resource "kubernetes_namespace" "lablumen" {
  metadata { name = "lablumen" }
  depends_on = [module.eks]
}

resource "kubernetes_namespace" "lablumen_dev" {
  metadata { name = "lablumen-dev" }
  depends_on = [module.eks]
}

# ---- Cluster controllers (kube-system / external-secrets) -------------------------
resource "kubernetes_service_account" "eso" {
  metadata {
    name      = "lablumen-eso"
    namespace = kubernetes_namespace.external_secrets.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam.eso_irsa_role_arn
    }
  }
}

resource "kubernetes_service_account" "karpenter" {
  metadata {
    name      = "karpenter"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.eks.karpenter_controller_role_arn
    }
  }
  depends_on = [module.eks]
}

resource "kubernetes_service_account" "lbc" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam.lbc_irsa_role_arn
    }
  }
  depends_on = [module.eks]
}

resource "kubernetes_service_account" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam.external_dns_role_arn
    }
  }
  depends_on = [module.eks]
}

# ---- App-tier ServiceAccounts (report + notification, in prod AND dev) ------------
resource "kubernetes_service_account" "app" {
  for_each = local.app_service_accounts

  metadata {
    name      = each.value.name
    namespace = each.value.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = each.value.role_arn
    }
  }

  depends_on = [
    kubernetes_namespace.lablumen,
    kubernetes_namespace.lablumen_dev,
  ]
}
