# terraform-aws-sample

A small AWS environment in modular Terraform. I wrote it as a public example of
how I structure modules, variables, outputs and environments. My production
Terraform belongs to my employer, so this repo stands in for it.

## What it builds

| Module | Resources |
|---|---|
| `modules/network` | VPC, public and private subnets across 2 or 3 AZs, internet gateway, NAT gateway (one shared for dev, or one per AZ), route tables |
| `modules/static-site` | Private S3 bucket behind CloudFront with Origin Access Control, a bucket policy scoped to the one distribution, and optional Route 53 A/AAAA alias records for a custom domain |
| `modules/media-pipeline` | Private upload bucket. An S3 ObjectCreated event runs a Python Lambda that calls Rekognition `DetectModerationLabels` and publishes the result as JSON to SQS. Failed invocations go to a dead-letter queue |

```
envs/
  dev/            root module: provider, backend, wiring, dev.tfvars
modules/
  network/
  static-site/
  media-pipeline/
    lambda/handler.py
```

## How it is put together

- **One root per environment.** `envs/dev` wires the modules. Staging and prod
  are copies of that folder with their own `.tfvars` and backend key, so
  promotion means changing values, not code.
- **No hardcoded secrets or account IDs.** Everything environment-specific lives
  in `.tfvars` or `backend.hcl`. The account ID used in the Lambda permission
  comes from `aws_caller_identity`.
- **Remote state in S3 with native locking** (`use_lockfile`, Terraform 1.10+),
  so no DynamoDB lock table is needed.
- **Least privilege.** The Lambda role can read the upload bucket, call one
  Rekognition API, send to its two queues, and write its own log group.
  Rekognition image APIs do not support resource-level permissions, so that one
  statement uses `*`.
- **The site bucket is never public.** Public access is blocked, ACLs are
  disabled, and the bucket policy allows `s3:GetObject` only for the
  `cloudfront.amazonaws.com` service principal when `AWS:SourceArn` matches this
  distribution.
- **Default tags** (Project, Environment, ManagedBy) are set once on the
  provider.

## Usage

```bash
cd envs/dev
cp backend.hcl.example backend.hcl   # set your state bucket and key
terraform init -backend-config=backend.hcl
terraform plan  -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

Upload a `.jpg` or `.png` to the media bucket, and a moderation result lands on
the results queue within a few seconds.

Running `terraform apply` creates billable resources, the NAT gateway
in particular. Run `terraform destroy -var-file=dev.tfvars` when you are done.

## Checks

```bash
terraform fmt -recursive -check
cd envs/dev && terraform init -backend=false && terraform validate
```

Both pass on Terraform 1.16 with the AWS provider 6.x.
