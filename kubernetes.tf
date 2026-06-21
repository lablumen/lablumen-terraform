# ---------------------------------------------------------------------------
# Kubernetes namespaces and IRSA-annotated ServiceAccounts
#
# Terraform creates these so the IRSA role ARN is wired to the annotation
# in the same apply — no manual copy-paste from terraform output needed.
# ArgoCD/Helm charts use serviceAccount.create: false and reference these
# pre-existing SAs by name.
# ---------------------------------------------------------------------------

resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = "external-secrets"
  }

  depends_on = [module.eks]
}

resource "kubernetes_namespace" "lablumen" {
  metadata {
    name = "lablumen"
  }

  depends_on = [module.eks]
}

# ---- ESO ServiceAccount -------------------------------------------------------

resource "kubernetes_service_account" "eso" {
  metadata {
    name      = "external-secrets"
    namespace = kubernetes_namespace.external_secrets.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.irsa.eso_irsa_role_arn
    }
  }
}

# ---- Karpenter controller ServiceAccount -------------------------------------

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

# ---- AWS Load Balancer Controller ServiceAccount -----------------------------

resource "kubernetes_service_account" "lbc" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.irsa.lbc_irsa_role_arn
    }
  }

  depends_on = [module.eks]
}

# ---- App-tier ServiceAccounts ------------------------------------------------

resource "kubernetes_service_account" "report_service" {
  metadata {
    name      = "report-service"
    namespace = kubernetes_namespace.lablumen.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.irsa.report_service_role_arn
    }
  }
}

resource "kubernetes_service_account" "notification_service" {
  metadata {
    name      = "notification-service"
    namespace = kubernetes_namespace.lablumen.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.irsa.notification_service_role_arn
    }
  }
}
