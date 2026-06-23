# Terraform state backend bootstrap (Phase 0)

This sub-config creates the **S3 bucket** that holds the *root* `lablumen-terraform` state. It exists
separately because of a chicken-and-egg: the backend cannot store its own state inside the backend it
is creating. This config therefore uses **local state** and is applied **once**.

State **locking is S3-native** (`use_lockfile = true` in the root `../backend.tf`) — no DynamoDB table
is needed; the lock is a short-lived `<key>.tflock` object in this same bucket.

## Apply order (run from `lablumen-terraform/`)

```bash
# 1. Create the state backend bucket (local state, one time). The name is DERIVED:
#    <project>-tfstate-<account_id>, so it is globally unique and account-portable.
cd bootstrap
terraform init
terraform apply                       # creates the state bucket
terraform output -raw backend_hcl > ../backend.hcl   # ready-to-use partial backend config
cd ..

# 2. Point the root config at that bucket (PARTIAL backend config — no literals in ../backend.tf)
terraform init -backend-config=backend.hcl
```

After step 2, all root state lives in S3 with native locking. Subsequent `terraform` runs from
`lablumen-terraform/` reuse the initialized backend automatically.

## Notes

- `../backend.tf` is a **partial** backend (`backend "s3" {}` — empty). The bucket name and other
  values come from `../backend.hcl` at `init` time, because Terraform evaluates the backend block
  before variables/locals are available. `backend.hcl` is gitignored; `backend.hcl.example` is the template.
- The bucket name is **derived** from the account ID here (`<project>-tfstate-<account_id>`), so it is
  globally unique with no manual naming. Set `state_bucket_name` to override.
- This is a **create-once** stack; it is not part of the normal plan/apply loop.
- A new account just repeats steps 1–2 — no code edits.

## Migrating off DynamoDB (if you bootstrapped earlier)

Earlier revisions created a `lablumen-tflock` DynamoDB table. It is no longer used. After pulling these
changes, run `terraform apply` here once — Terraform will delete the now-removed table — then you may
also drop `dynamodb_table` from any old local backend config (already done in `../backend.tf`).
