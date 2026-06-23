# lablumen-terraform

Infrastructure-as-Code for the **LabLumen** platform on AWS. Provisions everything the application
needs — network, EKS, data, storage, messaging, identity, and the CI/CD + workload IAM roles — with
one Terraform module per AWS service.

## Layout

```
.
├── backend.tf            # S3 remote state + S3-native locking (bucket created by scripts/bootstrap-state.sh)
├── providers.tf          # aws (default_tags) + kubernetes (EKS exec auth)
├── versions.tf           # terraform >=1.6; aws ~>5.60; kubernetes ~>2.31
├── data.tf               # LOOKUPS ONLY: existing Route53 hosted zone + ACM cert (never created)
├── locals.tf             # cluster name, common tags, derived FQDNs
├── variables.tf          # all root inputs
├── terraform.tfvars      # committed non-secret defaults (NOT the domain)
├── main.tf               # module wiring
├── kubernetes.tf         # namespaces + IRSA ServiceAccounts (the lablumen-k8s contract)
├── outputs.tf
├── bootstrap/             # create-once: S3 state bucket (local state; see bootstrap/README.md)
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

## Prerequisites
- AWS account + admin credentials for the one-time bootstrap.
- A registered **domain** with a Route53 **hosted zone** and an **ISSUED ACM certificate** (wildcard
  `*.<domain>`) in **us-east-1**. Terraform looks these up — it does **not** create them.
- The domain is a public, non-secret value committed in `terraform.tfvars` as `domain_name`
  (variable-driven — never baked into module code). Change it there to retarget a different domain.

## Bootstrap & run order
```bash
# 1. One-time: create the state bucket (local state). Locking is S3-native (no DynamoDB).
cd bootstrap && terraform init && terraform apply && cd ..

# 2. Init (migrate state into S3 when prompted) and apply (domain_name comes from terraform.tfvars)
terraform init -migrate-state
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
| `TF_PLAN_ROLE_ARN` | output `tf_plan_role_arn` |
| `TF_APPLY_ROLE_ARN` | output `tf_apply_role_arn` |

(`domain_name` lives in `terraform.tfvars`, so no `DOMAIN_NAME` variable is needed.)

Plus a GitHub Environment named `production` with required reviewers.

> Chicken-and-egg: the OIDC roles are created by Terraform, so the very first apply runs locally;
> thereafter the pipeline uses the roles. The app/frontend pipelines consume `app_ci_ecr_role_arn`
> and `frontend_deploy_role_arn`.

## Key variables
| Variable | Default | Notes |
|---|---|---|
| `domain_name` | `rnld101.xyz` | Public, non-secret; in `terraform.tfvars`. Variable-driven, not baked into code. |
| `acm_certificate_domain` | `*.<domain_name>` | Cert lookup domain. |
| `frontend_subdomain` / `api_subdomain` | `app` / `api` | → `app.<domain>`, `api.<domain>`. |
| `cluster_admin_access_entries` | `{}` | name→IAM ARN granted EKS cluster-admin (your bootstrap role). |
| `environment` / `owner` | `shared` / `rnld101` | Tag values on every resource. |
| `reports_bucket_name` / `frontend_bucket_name` | `*-change-me` | Must be globally unique. |


##