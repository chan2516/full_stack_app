# Activity 2 AWS Deployment with Terraform

This assignment has three independent Terraform configurations. Deploy them one at a time to control cost.

## Common setup

1. Install Terraform, AWS CLI, Docker, and Git.
2. Configure AWS credentials with `aws configure` or an AWS profile.
3. Fork/push this project to GitHub and use its HTTPS clone URL.
4. Copy each `terraform.tfvars.example` to `terraform.tfvars` and each `backend.hcl.example` to `backend.hcl`; replace placeholders.
5. Never commit `terraform.tfvars`, `.tfstate`, `.env`, or AWS keys.

For each part:

```powershell
terraform init -backend-config=backend.hcl
terraform fmt -check
terraform validate
terraform plan -out tfplan
terraform apply tfplan
terraform output
```

After screenshots, remove resources:

```powershell
terraform destroy
```

## Part 1 Single EC2

```powershell
cd assignments/activity-2-terraform-aws/part-1-single-ec2
Copy-Item terraform.tfvars.example terraform.tfvars
Copy-Item backend.hcl.example backend.hcl
terraform init -backend-config=backend.hcl
terraform apply
```

Open the `frontend_url` output. Both applications run as systemd services on one EC2 instance.

## Part 2 Separate EC2 Instances

```powershell
cd assignments/activity-2-terraform-aws/part-2-separate-ec2
Copy-Item terraform.tfvars.example terraform.tfvars
Copy-Item backend.hcl.example backend.hcl
terraform init -backend-config=backend.hcl
terraform apply
```

Open `frontend_url`. Terraform creates a VPC, subnet, route table, security groups, and two instances.

## Part 3 ECR ECS VPC and ALB

First create ECR repositories:

```powershell
cd assignments/activity-2-terraform-aws/part-3-ecs
Copy-Item terraform.tfvars.example terraform.tfvars
Copy-Item backend.hcl.example backend.hcl
terraform init -backend-config=backend.hcl
terraform apply -target=aws_ecr_repository.backend -target=aws_ecr_repository.frontend
```

Log in, build, and push. Replace region/account values using Terraform outputs:

```powershell
$region = "ap-south-1"
$account = aws sts get-caller-identity --query Account --output text
aws ecr get-login-password --region $region | docker login --username AWS --password-stdin "$account.dkr.ecr.$region.amazonaws.com"
docker build -t contact-app-backend:latest ../../../backend
docker build -t contact-app-frontend:latest ../../../frontend
docker tag contact-app-backend:latest "$account.dkr.ecr.$region.amazonaws.com/contact-app-backend:latest"
docker tag contact-app-frontend:latest "$account.dkr.ecr.$region.amazonaws.com/contact-app-frontend:latest"
docker push "$account.dkr.ecr.$region.amazonaws.com/contact-app-backend:latest"
docker push "$account.dkr.ecr.$region.amazonaws.com/contact-app-frontend:latest"
terraform apply
```

Open `alb_url`. Requests under `/api` go to Flask; all other requests go to Express.

## Remote state

Each part includes `backend.hcl.example`. Create an S3 bucket with versioning and encryption, copy the example to `backend.hcl`, and initialize with:

```powershell
terraform init -backend-config=backend.hcl
```

Use a different state key for each part. Do not create the state bucket in the same configuration that uses it.

## Required screenshots

Use the checklist in `screenshots/README.md`. Add actual URLs, resource IDs, `terraform plan/apply` output, and the GitHub link to the Word document before submission.

## Package

After all screenshots are present:

```powershell
powershell -ExecutionPolicy Bypass -File assignments/activity-2-terraform-aws/make-submission.ps1
```

This creates `Terraform_AWS_Chandan.zip`.
