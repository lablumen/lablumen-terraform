# Terraform state backend bootstrap (Phase 0)

This sub-config creates the **S3 bucket** that holds the *root* `lablumen-terraform` state. It exists
separately because of a chicken-and-egg: the backend cannot store its own state inside the backend it
is creating. This config therefore uses **local state** and is applied **once**.

State **locking is S3-native** (`use_lockfile = true` in the root `../backend.tf`) — no DynamoDB table
is needed; the lock is a short-lived `<key>.tflock` object in this same bucket.

## Apply order (run from `lablumen-terraform/`)

```bash
# 1. Create the state backend bucket (local state, one time)
cd bootstrap
terraform init
terraform apply            # creates the lablumen-tfstate S3 bucket
cd ..

# 2. Migrate the root config onto the remote backend
terraform init -migrate-state   # uses the backend "s3" block in ../backend.tf
```

After step 2, all root state lives in S3 with native locking. Subsequent `terraform apply` runs from
`lablumen-terraform/` use the remote backend automatically.

## Notes

- The bucket name is a **literal** in `../backend.tf` (Terraform backend blocks cannot use variables).
  It must match `variables.tf` here: `lablumen-tfstate`.
- S3 bucket names are **globally unique**. If `lablumen-tfstate` is taken, set `state_bucket_name`
  here **and** the `../backend.tf` `bucket` to e.g. `lablumen-tfstate-130290476321`.
- The bucket carries `prevent_destroy` — destroying it would orphan all infra state.
- This is a **create-once** stack; it is not part of the normal plan/apply loop.

## Migrating off DynamoDB (if you bootstrapped earlier)

Earlier revisions created a `lablumen-tflock` DynamoDB table. It is no longer used. After pulling these
changes, run `terraform apply` here once — Terraform will delete the now-removed table — then you may
also drop `dynamodb_table` from any old local backend config (already done in `../backend.tf`).
