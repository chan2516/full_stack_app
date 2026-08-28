# AWS Deployment Assignment

**Student:** `Chandan Vishwakarma `  
**GitHub repository:**   
**AWS Region:** `<ap-south-1 or your selected region>`  
**Application:** Express frontend + Flask backend + MongoDB Atlas

 Replace every value in angle brackets. Never put AWS access keys, MongoDB passwords, or real `.env` files in this folder or in GitHub.

## 1. Application Details

This repository contains:

- Express frontend: port `3000`
- Flask API: port `5000`
- Backend health check: `/health`
- Frontend health check: `/health`
- MongoDB: MongoDB Atlas, configured through `MONGODB_URI`

The frontend reads the backend address from the Express `/config` endpoint. For an EC2 deployment, set `BACKEND_URL` to the backend's reachable HTTP URL. Set Flask `CORS_ORIGINS` to the frontend URL.

## 2. AWS Safety and Prerequisites

1. Select one AWS Region and use it consistently.
2. Enable billing alerts in **Billing and Cost Management > Budgets**.
3. Create or confirm a key pair, for example `<aws-key>.pem`.
4. Use an Ubuntu 24.04 LTS EC2 AMI and a `t2.micro` or `t3.micro` instance only where the Free Tier eligibility shown in your account allows it.
5. In each security group, allow:
   - SSH `22` from **My IP only**
   - TCP `3000` from `0.0.0.0/0` when the Express page is public
   - TCP `5000` only from the frontend security group when possible; use `0.0.0.0/0` temporarily only for testing
6. MongoDB Atlas **Network Access** must allow the EC2 public IP, or a deliberately configured development CIDR.

**Screenshot to capture:** EC2 instance summary, security-group inbound rules, selected Region, and the billing budget.

## 3. Common EC2 Preparation

SSH into the instance:

```bash
chmod 400 <aws-key>.pem
ssh -i <aws-key>.pem ubuntu@<EC2_PUBLIC_IP>
```

Install the runtime and Docker tools needed by the chosen deployment:

```bash
sudo apt update
sudo apt install -y git curl python3-venv python3-pip nodejs npm
node --version
python3 --version
```

Clone the project:

```bash
git clone <GITHUB_REPOSITORY_URL> app
cd app
```

Create the backend environment file. Use a strong secret and the real MongoDB Atlas URI only on the server:

```bash
nano backend/.env
```

```env
MONGODB_URI=mongodb+srv://<user>:<password>@<cluster>/<database>?retryWrites=true&w=majority
MONGODB_DATABASE=first_project
MONGODB_COLLECTION=submissions
FLASK_SECRET_KEY=<long-random-secret>
FLASK_DEBUG=false
CORS_ORIGINS=http://<FRONTEND_HOST>:3000
```

## Task 1: Single EC2 Instance

### 1.1 Start Flask

On one EC2 instance:

```bash
cd ~/app/backend
python3 -m venv venv
. venv/bin/activate
pip install -r requirements.txt
nohup gunicorn --bind 0.0.0.0:5000 --workers 2 --timeout 60 app:app > ~/backend.log 2>&1 &
curl http://localhost:5000/health
```

Expected response:

```json
{"service":"backend","status":"ok"}
```

### 1.2 Start Express

Set Express to call the Flask service through the same EC2 public IP:

```bash
cd ~/app/frontend
printf 'PORT=3000\nBACKEND_URL=http://<EC2_PUBLIC_IP>:5000\n' > .env
npm install --omit=dev
nohup npm start > ~/frontend.log 2>&1 &
curl http://localhost:3000/health
```

Open `http://<EC2_PUBLIC_IP>:3000` in a browser and test search, backend status, and form submission.

**Required screenshots:**

- `single-01-ec2.png`: running EC2 instance and public IPv4 address
- `single-02-security-group.png`: ports `22`, `3000`, and `5000`
- `single-03-commands.png`: installation and startup commands
- `single-04-health.png`: both `curl` health responses
- `single-05-browser.png`: application open at `http://<EC2_PUBLIC_IP>:3000`

**Record in the submission:**

- Frontend URL: `http://<EC2_PUBLIC_IP>:3000`
- Backend URL: `http://<EC2_PUBLIC_IP>:5000`
- Result: `<working / issue and resolution>`

## Task 2: Separate EC2 Instances

Create two EC2 instances in the same Region:

- Backend instance: `<BACKEND_PUBLIC_IP>`
- Frontend instance: `<FRONTEND_PUBLIC_IP>`

Use separate security groups. The frontend security group needs SSH and port `3000`. The backend security group needs SSH and port `5000` restricted to the frontend instance security group, plus SSH from your IP.

### 2.1 Backend instance

```bash
git clone <GITHUB_REPOSITORY_URL> app
cd app/backend
nano .env
```

Set:

```env
MONGODB_URI=mongodb+srv://<user>:<password>@<cluster>/<database>?retryWrites=true&w=majority
MONGODB_DATABASE=first_project
MONGODB_COLLECTION=submissions
FLASK_SECRET_KEY=<long-random-secret>
FLASK_DEBUG=false
CORS_ORIGINS=http://<FRONTEND_PUBLIC_IP>:3000
```

Start it:

```bash
python3 -m venv venv
. venv/bin/activate
pip install -r requirements.txt
nohup gunicorn --bind 0.0.0.0:5000 --workers 2 app:app > ~/backend.log 2>&1 &
curl http://localhost:5000/health
```

### 2.2 Frontend instance

```bash
git clone <GITHUB_REPOSITORY_URL> app
cd app/frontend
printf 'PORT=3000\nBACKEND_URL=http://<BACKEND_PUBLIC_IP>:5000\n' > .env
npm install --omit=dev
nohup npm start > ~/frontend.log 2>&1 &
curl http://localhost:3000/health
```

Open `http://<FRONTEND_PUBLIC_IP>:3000` and verify that the page can call the backend. If the browser reports a CORS error, confirm that backend `CORS_ORIGINS` exactly matches the frontend URL and restart Gunicorn.

**Required screenshots:**

- `separate-01-two-instances.png`: both EC2 instances and public IPs
- `separate-02-security-groups.png`: frontend and backend rules
- `separate-03-backend-health.png`: backend health response
- `separate-04-frontend-health.png`: frontend health response
- `separate-05-browser.png`: working application and backend-online status

**Record in the submission:**

- Frontend URL: `http://<FRONTEND_PUBLIC_IP>:3000`
- Backend URL: `http://<BACKEND_PUBLIC_IP>:5000`
- Result: `<working / issue and resolution>`

## Task 3: Docker with ECR, ECS, and VPC

This task uses the existing `backend/Dockerfile`, `frontend/Dockerfile`, and `docker-compose.yaml`. Build the images from the repository root. ECS tasks should receive the backend URL through the frontend container's `BACKEND_URL` environment variable.

### 3.1 Build and test locally

```bash
cd app
docker compose --profile local-mongo up --build -d
docker compose ps
curl http://localhost:5000/health
curl http://localhost:3000/health
docker compose --profile local-mongo down
```

If using MongoDB Atlas instead of the local Mongo container, create a root `.env` with `MONGODB_URI`, `MONGODB_DATABASE`, `MONGODB_COLLECTION`, `FLASK_SECRET_KEY`, and `CORS_ORIGINS` before starting Compose.

**Screenshot:** `ecs-01-local-docker-test.png` showing `docker compose ps` and both health checks.

### 3.2 Create ECR repositories and push images

Install and configure AWS CLI on the machine used to build the images:

```bash
aws configure
aws sts get-caller-identity
export AWS_REGION=<your-region>
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_HOST=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```

Create repositories and authenticate Docker:

```bash
aws ecr create-repository --repository-name contact-app-backend --region $AWS_REGION
aws ecr create-repository --repository-name contact-app-frontend --region $AWS_REGION
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_HOST
```

Build, tag, and push:

```bash
docker build -t contact-app-backend:latest ./backend
docker build -t contact-app-frontend:latest ./frontend
docker tag contact-app-backend:latest $ECR_HOST/contact-app-backend:latest
docker tag contact-app-frontend:latest $ECR_HOST/contact-app-frontend:latest
docker push $ECR_HOST/contact-app-backend:latest
docker push $ECR_HOST/contact-app-frontend:latest
aws ecr describe-images --repository-name contact-app-backend --region $AWS_REGION
aws ecr describe-images --repository-name contact-app-frontend --region $AWS_REGION
```

**Screenshot:** `ecs-02-ecr-images.png` showing both ECR repositories and pushed `latest` images.

### 3.3 Create the VPC and ECS resources

In the AWS Console:

1. Open **VPC > Your VPCs** and create a VPC with at least two subnets in different Availability Zones. Create an internet gateway and route table for public subnets.
2. Open **EC2 > Security Groups** and create an ECS security group. Allow HTTP port `3000` from your test IP or the internet, and allow port `5000` only from the frontend task security group.
3. Open **IAM > Roles** and create an ECS task execution role with `AmazonECSTaskExecutionRolePolicy`. Do not put AWS keys in the application image.
4. Open **ECS > Clusters** and create `<contact-app-cluster>`.
5. Create a task definition with two containers:
   - `backend`: image `<ECR_BACKEND_URI>`, container port `5000`, environment variables from the task definition or Secrets Manager
   - `frontend`: image `<ECR_FRONTEND_URI>`, container port `3000`, `PORT=3000`, `BACKEND_URL=http://127.0.0.1:5000`
6. For a task definition using `awsvpc` and `bridge` networking, expose the frontend service on port `3000`. Keep both containers in the same task so `127.0.0.1:5000` reaches the backend container.
7. Create an ECS service in the cluster using the VPC subnets and ECS security group. Assign a public IP only for a temporary test deployment.
8. Wait for the task to become **Running**, then open the task's public IP at `http://<ECS_PUBLIC_IP>:3000`.

For a public production-style URL, add an Application Load Balancer and target the frontend service on port `3000`. An ALB may create additional charges, so remove it after taking screenshots.

**Screenshot checklist:**

- `ecs-03-vpc.png`: VPC, subnets, route table, and internet gateway
- `ecs-04-ecs-cluster.png`: ECS cluster and running service
- `ecs-05-task-definition.png`: both container images and ports
- `ecs-06-running-task.png`: task status, network details, and public IP
- `ecs-07-ecr-ecs-browser.png`: working application URL

**Record in the submission:**

- ECR backend URI: `<AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/contact-app-backend:latest`
- ECR frontend URI: `<AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/contact-app-frontend:latest`
- ECS application URL: `http://<ECS_PUBLIC_IP>:3000`
- VPC ID: `<vpc-id>`
- ECS cluster: `<cluster-name>`
- Result: `<working / issue and resolution>`

## 4. Cost Cleanup Checklist

After taking the required screenshots and recording URLs:

- Stop both EC2 instances from **EC2 > Instances**.
- Set ECS service desired count to `0`, then delete the ECS service and cluster.
- Delete the ECS task definition revision if no longer needed.
- Delete the ALB, target groups, NAT gateways, and unused Elastic IPs. NAT gateways and load balancers can cost money.
- Delete ECR repositories if the assignment does not require them to remain.
- Remove unused VPC resources after the ECS service is deleted.
- Check **Billing > Bills** and **Cost Explorer**.

A stopped EC2 instance may still incur charges for its EBS volume and allocated Elastic IP. Delete resources you no longer need.

## 5. Submission Folder and ZIP

The final folder must contain the complete source code, documentation, and screenshots. Use this structure:

```text
AWS_YourName/
├── backend/
├── frontend/
├── docs/
├── docker-compose.yaml
├── README.md
├── AWS_DEPLOYMENT.md
└── screenshots/
    ├── single-01-ec2.png
    ├── single-04-health.png
    ├── separate-01-two-instances.png
    ├── ecs-02-ecr-images.png
    └── ecs-07-ecr-ecs-browser.png
```

Copy the complete project into `AWS_YourName`, add the screenshots, update this document with actual URLs and results, and remove all real `.env` files before creating the ZIP. On Windows PowerShell:

```powershell
Compress-Archive -Path .\AWS_YourName -DestinationPath .\AWS_YourName.zip -Force
Get-ChildItem .\AWS_YourName.zip
```

Submit only `AWS_YourName.zip` through the portal. The ZIP must include the source code, screenshots and explanations, deployed URL(s), and GitHub repository link.

## 6. Final Verification

- [ ] Task 1 single EC2 deployment tested

- [ ] Task 2 separate EC2 deployment tested


- [ ] Task 3 Docker images pushed to ECR and run by ECS in the VPC
- [ ] Screenshots include commands and successful outputs
- [ ] URLs and GitHub link are filled in
- [ ] No secrets or `.env` files are included
- [ ] Resources are stopped or deleted after testing
- [ ] `AWS_YourName.zip` contains the complete project
