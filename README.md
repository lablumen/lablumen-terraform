# lablumen-terraform

Infrastructure-as-Code for the **LabLumen** platform on AWS. Provisions everything the application
needs — network, EKS, data, storage, messaging, identity, and the CI/CD + workload IAM roles — with
one Terraform module per AWS service.

## Layout

```
.
├── backend.tf            # S3 remote state + S3-native locking (bucket literal; created by bootstrap/)
├── providers.tf          # aws (default_tags) + kubernetes (EKS exec auth)
├── versions.tf           # terraform >=1.6; aws ~>5.60; kubernetes ~>2.31
├── data.tf               # LOOKUPS ONLY: existing Route53 hosted zone + ACM cert (never created)
├── locals.tf             # cluster name, common tags, derived FQDNs
├── variables.tf          # all root inputs
├── terraform.tfvars      # committed non-secret defaults (NOT the domain)
├── main.tf               # module wiring
├── kubernetes.tf         # namespaces + IRSA ServiceAccounts (the lablumen-k8s contract)
├── outputs.tf
├── bootstrap/             # create-once: derived S3 state bucket (local state; see bootstrap/README.md)
├── .github/workflows/terraform.yml   # scan → plan → approval → apply (OIDC)
└── modules/              # one per AWS service:
    vpc  eks  rds  s3  cloudfront  ecr  sqs  ses  lambda  cognito  secretsmanager  ssm  iam
```

## What gets created
- **vpc** — VPC, public/private/isolated-DB subnets, single NAT GW, S3 gateway endpoint + interface
  endpoints (ssm, secretsmanager, bedrock-runtime, textract, ecr.api/dkr, logs, sqs).
- **eks** — control plane (1.31) + managed node group + Karpenter; **Access Entries** auth; control-plane
  logs → CloudWatch.
- **rds** — PostgreSQL in isolated subnets, Secrets Manager-managed master password.
- **s3** — KMS reports bucket + private frontend SPA bucket.
- **cloudfront** — SPA distribution (OAC → frontend bucket, HTTPS via your ACM cert) + Route53 alias.
- **ecr** — immutable, scan-on-push repos (one per backend service).
- **sqs / ses** — notifications queue + verified sender identity.
- **lambda** — AI processing function + S3 trigger + CloudWatch log group.
- **cognito** — user pool, SPA client, role groups.
- **secretsmanager / ssm** — empty secret shells (hand-populated) + non-sensitive config params.
- **iam** — GitHub OIDC provider, 4 pipeline roles (`tf-plan`, `tf-apply`, `app-ci-ecr`,
  `frontend-deploy`), and IRSA roles (eso, report-service, notification-service, lbc, external-dns,
  ai-lambda).
- **kubernetes.tf** — namespaces `external-secrets` / `lablumen` / `lablumen-dev` and IRSA-annotated
  ServiceAccounts (`lablumen-eso`, karpenter, aws-load-balancer-controller, external-dns,
  report-service & notification-service in both prod and dev).

## Account portability
This config is **account-aware with minimal per-account edits**. The account ID is discovered via
`data.aws_caller_identity`, and the **reports/frontend bucket names** + **ECR registry URL** are derived
as `<project>-<purpose>-<account_id>` in `locals.tf`. The only per-account code edits are the
**`backend.tf` `bucket` literal** (Terraform can't derive backend values) and, in `lablumen-k8s`, the
one `global-values.yaml` registry line. To stand the platform up in a fresh account: (1) point
credentials at it, (2) bootstrap + set those two literals, (3) ensure the domain foundation (zone +
ISSUED cert) exists. See `extras/account-portability-plan.md`.

## Prerequisites
- AWS account + admin credentials for the one-time bootstrap.
- A registered **domain** with a Route53 **hosted zone** and an **ISSUED ACM certificate** (wildcard
  `*.<domain>`) in **us-east-1**. Terraform looks these up — it does **not** create them (DNS is a
  manually-owned foundation layer).
- The domain is a public, non-secret value committed in `terraform.tfvars` as `domain_name`
  (variable-driven — never baked into module code). Change it there to retarget a different domain.

## Bootstrap & run order
```bash
# 1. One-time: create the derived state bucket (local state). Locking is S3-native (no DynamoDB).
cd bootstrap && terraform init && terraform apply
terraform output -raw state_bucket     # copy this into ../backend.tf `bucket` (one-line, per account)
cd ..

# 2. Init against that bucket and apply (domain_name comes from terraform.tfvars)
terraform init
terraform fmt -check -recursive && terraform validate
terraform apply
```
Then: app CI pushes images to ECR → run `lablumen-k8s/scripts/bootstrap-argocd.sh` once → ArgoCD
takes over (subsequent changes flow through the pipelines automatically).

## CI/CD pipeline (`.github/workflows/terraform.yml`)
`scan (Checkov) → plan → manual approval → apply`, using GitHub OIDC (no static keys):
- **PR**: scan + plan (assumes `tf-plan`, read-only).
- **push to main**: scan + plan + **apply** behind the `production` GitHub Environment (required
  reviewers = the manual approval gate; assumes `tf-apply`, admin).

**Required repo configuration (Settings → Secrets and variables → Actions → Variables):**
| Variable | Value |
|---|---|
| `AWS_ACCOUNT_ID` | the 12-digit target account ID |

The pipeline constructs the role ARNs from `AWS_ACCOUNT_ID` (`…:role/lablumen-tf-plan` / `…-tf-apply`);
the state bucket comes from the literal in `backend.tf` (plain `terraform init`). `domain_name` lives in
`terraform.tfvars`, so no `DOMAIN_NAME` variable is needed.

Plus a GitHub Environment named `production` with required reviewers.

> Chicken-and-egg: the OIDC roles are created by Terraform, so the very first apply runs locally
> (plain `terraform init` against the `backend.tf` bucket); thereafter the pipeline uses the roles. The
> app/frontend pipelines likewise construct their role ARNs from `AWS_ACCOUNT_ID`.

## Key variables
| Variable | Default | Notes |
|---|---|---|
| `domain_name` | `rnld101.xyz` | Public, non-secret; in `terraform.tfvars`. Variable-driven, not baked into code. |
| `acm_certificate_domain` | `*.<domain_name>` | Cert lookup domain. |
| `frontend_subdomain` / `api_subdomain` | `app` / `api` | → `app.<domain>`, `api.<domain>`. |
| `cluster_admin_access_entries` | `{}` | name→IAM ARN granted EKS cluster-admin (your bootstrap role). |
| `environment` / `owner` | `shared` / `rnld101` | Tag values on every resource. |
| `reports_bucket_name` / `frontend_bucket_name` | `null` (derived) | Optional override; defaults to `<project>-<purpose>-<account_id>` (globally unique). |
| `state_bucket_name` | `null` (derived) | Optional override for the tf-plan IAM policy scope; defaults to `<project>-tfstate-<account_id>` (keep `backend.tf` `bucket` equal to this). |


###
#
#
#
