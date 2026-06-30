# lablumen-terraform

Infrastructure as Code for the LabLumen platform on AWS. Provisions all cloud resources using Terraform — networking, compute, database, storage, messaging, identity, and CI/CD IAM roles. One Terraform module per AWS service area.

---

## What Gets Created

| Module | AWS Resources |
|---|---|
| `vpc` | VPC (`10.0.0.0/16`), public/private/database subnets across 2 AZs, NAT Gateway, S3 gateway endpoint, interface endpoints for SSM, Secrets Manager, Bedrock, Textract, ECR, CloudWatch Logs, and SQS |
| `eks` | EKS cluster (Kubernetes 1.31), managed node group (`c7i-flex.large`), Karpenter supporting resources, EKS Access Entries auth mode |
| `rds` | PostgreSQL 16.4 on `db.t4g.micro` in isolated DB subnets, Secrets Manager-managed master password |
| `s3` | Reports bucket (private, KMS-encrypted, versioned, EventBridge-enabled) and SAM artifacts bucket |
| `ecr` | Container image repositories for all 4 services (immutable tags, scan-on-push, KMS encryption) |
| `cognito` | User Pool (`lablumen-users`), SPA app client (no secret), user groups (`PATIENT`, `LAB_STAFF`, `LAB_ADMIN`) |
| `sqs` | Notifications queue (`lablumen-notifications`, standard queue) |
| `ses` | Domain identity for `rnld101.xyz` with Easy DKIM CNAME records in Route 53 |
| `secretsmanager` | Empty secret shells for `lablumen/app/database-url` and `lablumen/app/grafana-admin` |
| `ssm` | 15 non-sensitive config parameters under `/lablumen/config/*` |
| `iam` | GitHub OIDC provider, 5 pipeline roles, and IRSA roles for pods |
| `lambda` | Lambda execution role and security group for the AI processing function |
| `kubernetes.tf` | Kubernetes namespaces (`lablumen`, `lablumen-dev`, `external-secrets`) and IRSA-annotated ServiceAccounts |

---

## Repository Layout

```
backend.tf             Remote state config (S3 bucket + S3-native locking, no DynamoDB needed)
versions.tf            Provider version pins (Terraform ≥1.6, AWS ~>5.60, Kubernetes ~>2.31)
providers.tf           AWS (with default_tags) + Kubernetes provider
variables.tf           All input variables
terraform.tfvars       Committed non-secret defaults (domain, region, sizing, queue names)
locals.tf              Derived values (cluster name, bucket names, common tags)
data.tf                Lookups for the existing Route 53 hosted zone and ACM certificate
main.tf                Root module — wires all child modules
kubernetes.tf          Kubernetes namespaces and IRSA ServiceAccounts (runs after EKS)
outputs.tf             Exposed values for use in other tools (registry URL, cluster name, etc.)
modules/               One directory per AWS service area (see table above)
bootstrap/             One-time setup — creates the S3 state bucket with local state
.github/workflows/
  terraform.yml          CI/CD pipeline: Checkov → plan → human approval → apply
  terraform-destroy.yml  Guarded teardown (manual trigger only, typed confirmation required)
.checkov.yaml          Documented suppressions for accepted Checkov findings
```

---

## Prerequisites

Before running Terraform:

- An AWS account with admin credentials for the initial bootstrap.
- A registered domain with an active Route 53 **hosted zone** for `rnld101.xyz`.
- An ACM **wildcard certificate** (`*.rnld101.xyz`) in `us-east-1` with status `ISSUED`.

Terraform looks these up via data sources — it does **not** create them. DNS and certificate management are a separate foundation layer done once manually.

---

## Initial Setup

```bash
# Step 1 — Bootstrap: create the S3 state bucket (run once per account, local state)
cd bootstrap
terraform init && terraform apply
terraform output -raw state_bucket   # copy this value into ../backend.tf bucket literal

# Step 2 — Apply the main stack
cd ..
terraform init
terraform apply
```

After `terraform apply`, two manual steps are required before the application can run:

1. Populate the Secrets Manager values in the AWS console:
   - `lablumen/app/database-url` — full PostgreSQL DSN
   - `lablumen/app/grafana-admin` — Grafana admin credentials

2. Bootstrap ArgoCD: `cd ../lablumen-k8s && bash scripts/bootstrap-argocd.sh`

---

## CI/CD Pipeline

All Terraform changes go through a gated pipeline. No one applies infrastructure changes manually after the initial setup.

| Stage | Trigger | IAM Role | What Happens |
|---|---|---|---|
| Scan | PR or push to `main` | — | Checkov IaC security scan; findings uploaded to GitHub Security tab |
| Plan | PR or push to `main` | `lablumen-tf-plan` (read-only) | `terraform fmt` → `terraform validate` → `terraform plan`; Infracost cost estimate posted to PR as a comment |
| Apply | Push to `main` after human approval | `lablumen-tf-apply` (admin) | `terraform apply` using the exact plan artifact from the plan job |

AWS credentials are obtained via GitHub OIDC — no static access keys anywhere.

**Important:** The first `terraform apply` must run locally (the OIDC roles are created by Terraform itself, so they do not exist yet). All subsequent applies go through the pipeline.

---

## GitHub Configuration Required

| Setting | Where | Value / Purpose |
|---|---|---|
| Variable `AWS_ACCOUNT_ID` | Org or repo | 12-digit AWS account ID (used to construct role ARNs) |
| Environment `production` | Repo settings | Required reviewers configured as the manual approval gate |
| Secret `INFRACOST_API_KEY` | Repo secrets | Infracost API key for PR cost estimates |
| Secret `BEDROCK_CROSS_ACCOUNT_ROLE_ARN` | Repo secrets | Cross-account Bedrock IAM role ARN (sensitive) |

---

## Key Variables

| Variable | Default in `terraform.tfvars` | Notes |
|---|---|---|
| `domain_name` | `rnld101.xyz` | Public, non-secret. Used for SES identity, Route 53 records, and ingress hostnames |
| `cluster_version` | `1.31` | EKS Kubernetes version |
| `node_instance_types` | `["c7i-flex.large"]` | Managed node group instance type |
| `db_instance_class` | `db.t4g.micro` | RDS instance class (org SCP allows micro only) |
| `ecr_repositories` | All 4 service repos | ECR repositories to create |
| `notifications_queue_name` | `lablumen-notifications` | SQS queue name |

---

## IAM Roles

| Role | Who Can Assume | Purpose |
|---|---|---|
| `lablumen-tf-plan` | Terraform repo on any branch | Read-only plan access |
| `lablumen-tf-apply` | Terraform repo in the `production` GitHub Environment only | Admin access for applies |
| `lablumen-app-ci-ecr` | Any `lablumen/*` service repo | ECR push for backend service images |
| `lablumen-frontend-build` | Frontend repo only | ECR push for the frontend image |
| `lablumen-ai-lambda-deploy` | AI service repo only | SAM deploy permissions |
| `lablumen-report-service` (IRSA) | `report-service` pods | S3 access + Bedrock InvokeModel |
| `lablumen-notification-service` (IRSA) | `notification-service` pods | SQS receive/delete + SES send |
| `lablumen-eso` (IRSA) | External Secrets Operator pod | Secrets Manager + SSM + KMS read |
| `lablumen-lbc` (IRSA) | AWS Load Balancer Controller | Manage ALBs from Ingress objects |
| `lablumen-external-dns` (IRSA) | ExternalDNS | Update Route 53 records from Ingress objects |
