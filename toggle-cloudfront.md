# Toggle: CloudFront / frontend hosting

## Why this exists
Account **261523981519** is a brand-new AWS account. AWS blocks CloudFront resource creation on
unverified new accounts:

```
Error: creating CloudFront Distribution: ... 403 AccessDenied:
Your account must be verified before you can add new CloudFront resources.
To verify your account, please contact AWS Support.
```

Because `module.ssm` referenced the CloudFront distribution ID, that failure also blocked **all
`/lablumen/config/*` SSM params**, which the backend's ESO depends on. To unblock the backend
(EKS / CI / CD / ArgoCD / API) immediately, CloudFront was made **toggleable** and turned **OFF**.

Current state: **`enable_cloudfront = false`** in `terraform.tfvars`.

## What "off" means
Disabled while off:
- The CloudFront SPA distribution (frontend at `https://app.rnld101.xyz`).
- The `cloudfront-distribution-id` SSM param.
- The `frontend-deploy` role's `cloudfront:CreateInvalidation` permission.
- The Route53 alias for `app.rnld101.xyz` (created inside the CloudFront module).
- Outputs `cloudfront_distribution_id` / `cloudfront_domain_name` (return `null`).

Still fully working while off: VPC, EKS, RDS, ECR, SQS, SES, Cognito, all OIDC + IRSA roles, the
**12 other `/lablumen/config/*` SSM params**, the backend **CI** (build/push to ECR), **CD**
(`cd-dev` → `lablumen-k8s`), **ArgoCD** GitOps, ESO, and the **API** at `https://api-dev.rnld101.xyz`
(ALB ingress — independent of CloudFront). The frontend **PR build** job also still runs; only the
frontend **deploy** job is blocked.

## Changes made to introduce the toggle (so they can be reviewed / reverted)
| File | Change |
|---|---|
| `variables.tf` | Added `variable "enable_cloudfront"` (bool, default **true**). |
| `terraform.tfvars` | Added `enable_cloudfront = false` (TEMP). |
| `main.tf` | `module.cloudfront` gets `count = var.enable_cloudfront ? 1 : 0`. |
| `main.tf` | `module.ssm.config` now `merge(...)`s `cloudfront-distribution-id` in **only** when enabled (decouples SSM from CloudFront). |
| `main.tf` | `module.iam.cloudfront_distribution_arn = var.enable_cloudfront ? module.cloudfront[0].distribution_arn : null`. |
| `outputs.tf` | `cloudfront_distribution_id` / `cloudfront_domain_name` use `try(module.cloudfront[0]..., null)`. |
| `modules/iam/main.tf` | `frontend-deploy` policy: `cloudfront:CreateInvalidation` statement is `concat`'d in **only** when the ARN is non-null. |
| `modules/iam/variables.tf` | `cloudfront_distribution_arn` made nullable (`default = null`). |

No other module code changed. Bringing CloudFront back is purely **additive** — no rework, no
destroy.

## Steps to bring CloudFront back online
1. **Get the account verified by AWS** (do this in parallel, it has lead time):
   - AWS Console → **Support** → Create case → *Account & billing*.
   - Subject: "Enable CloudFront / verify new account."
   - Body: paste the error above incl. the RequestID from your apply
     (e.g. `27f55db9-9caf-4548-b26d-40bcf73c08a3`).
   - Wait for AWS to confirm the account is verified (typically a few hours to ~1 day).

2. **Flip the flag** in `terraform.tfvars`:
   ```hcl
   enable_cloudfront = true
   ```

3. **Apply** (additive — creates the distribution + alias, adds the SSM param + invalidation perm):
   ```bash
   cd lablumen-terraform
   terraform apply
   terraform output cloudfront_distribution_id    # now non-null
   terraform output cloudfront_domain_name
   ```

4. **Deploy the frontend** (the previously-blocked slice):
   - Push a change under `frontend/**` in `lablumen-app` (or re-run the `frontend` workflow) →
     `frontend-deploy.yml` discovers bucket + distribution-id from SSM, builds the SPA, `s3 sync`s,
     and invalidates CloudFront.

5. **Verify**:
   ```bash
   curl -I https://app.rnld101.xyz        # served via CloudFront
   ```

## Optional cleanup
Once verified and stable, `enable_cloudfront = false` / this file can be considered historical.
Keep the `enable_cloudfront` variable — it's a useful, low-cost feature flag and mirrors
`enable_ai_lambda`.
