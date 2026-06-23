# Terraform state backend bootstrap (Phase 0)

This sub-config creates the **S3 bucket** that holds the *root* `lablumen-terraform` state. It exists
separately because of a chicken-and-egg: the backend cannot store its own state inside the backend it
is creating. This config therefore uses **local state** and is applied **once**.

State **locking is S3-native** (`use_lockfile = true` in the root `../backend.tf`) — no DynamoDB table
is needed; the lock is a short-lived `<key>.tflock` object in this same bucket.

## Apply order (run from `lablumen-terraform/`)

```bash
# 1. Create the state backend bucket (local state, one time). The name is DERIVED:
#    <project>-tfstate-<account_id>, so it is globally unique with no manual naming.
cd bootstrap
terraform init
terraform apply                       # creates the state bucket
terraform output -raw state_bucket    # <- copy this name into ../backend.tf `bucket`
cd ..

# 2. Init the root config against that bucket (no args — backend.tf holds the literal)
terraform init
```

After step 2, all root state lives in S3 with native locking. Subsequent `terraform` runs from
`lablumen-terraform/` reuse the initialized backend automatically.

## Notes

- `../backend.tf` holds the bucket name as a **literal** (Terraform evaluates the backend block before
  variables/locals exist). The bootstrap stack **derives** the same name from the account ID
  (`<project>-tfstate-<account_id>`) — keep `../backend.tf` `bucket` equal to `terraform output -raw
  state_bucket`. On a new account, update that one line.
- Set `state_bucket_name` here to override the derived name.
- This is a **create-once** stack; it is not part of the normal plan/apply loop.
- A new account repeats steps 1–2 (and the one-line `backend.tf` update).

## Migrating off DynamoDB (if you bootstrapped earlier)

Earlier revisions created a `lablumen-tflock` DynamoDB table. It is no longer used. After pulling these
changes, run `terraform apply` here once — Terraform will delete the now-removed table — then you may
also drop `dynamodb_table` from any old local backend config (already done in `../backend.tf`).
