# Terraform state backend bootstrap (Phase 0)

This sub-config creates the **S3 bucket + DynamoDB lock table** that hold the *root*
`lablumen-terraform` state. It exists separately because of a chicken-and-egg: the backend
cannot store its own state inside the backend it is creating. This config therefore uses
**local state** and is applied **once**.

## Apply order (run from `lablumen-terraform/`)

```bash
# 1. Create the state backend (local state, one time)
cd bootstrap
terraform init
terraform apply            # creates lablumen-tfstate (S3) + lablumen-tflock (DynamoDB)
cd ..

# 2. Migrate the root config onto the remote backend
terraform init -migrate-state   # reads the backend "s3" block now enabled in versions.tf
```

After step 2, all root state lives in S3 with DynamoDB locking. Subsequent `terraform apply`
runs from `lablumen-terraform/` use the remote backend automatically.

## Notes

- The bucket/table names are **literals** in `../versions.tf` (Terraform backend blocks cannot
  use variables). They must match `variables.tf` here: `lablumen-tfstate` / `lablumen-tflock`.
- S3 bucket names are **globally unique**. If `lablumen-tfstate` is taken, set
  `state_bucket_name` (and the `../versions.tf` backend `bucket`) to e.g.
  `lablumen-tfstate-130290476321`.
- Both resources carry `prevent_destroy` — destroying them would orphan all infra state.
- This is a **create-once** stack; it is not part of the normal plan/apply loop.

## Lock criteria (Phase 0 — Foundations)

State backend + secret scaffolding immutable and reviewed before any further phase begins.
