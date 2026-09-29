# Activity 3 EC2 Deployment and Jenkins CI CD

## Architecture

```text
GitHub push -> webhook -> Jenkins pipeline -> install dependencies -> restart service
                                      |
Internet -> EC2 public IP:3000 -> Express -> localhost:5000 -> Flask -> MongoDB Atlas
```

The fastest assignment setup uses one Ubuntu EC2 instance for Jenkins, Express, and Flask. A small instance may be slow; `t3.small` is more practical than free-tier sizes for Jenkins, but check current AWS pricing before launch.

## 1 Launch EC2

Use Ubuntu 24.04. Allow SSH 22 from your IP, TCP 3000 from the internet, and TCP 5000 from your IP temporarily for evidence. Port 8080 can be restricted to your IP during setup, but it must be reachable from GitHub when testing the webhook; expose it only temporarily and restrict it again after capturing evidence.

```bash
ssh -i YOUR_KEY.pem ubuntu@EC2_PUBLIC_IP
sudo apt update
sudo apt install -y git python3-venv python3-pip nodejs npm fontconfig openjdk-17-jre
sudo npm install -g pm2
```

Install Jenkins using the current official Jenkins Ubuntu instructions, then:

```bash
sudo systemctl enable --now jenkins
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Open `http://EC2_PUBLIC_IP:8080`, install suggested plugins, and add the Git and NodeJS plugins if missing.

## 2 Prepare application directories

```bash
sudo mkdir -p /opt/contact-app
sudo chown -R jenkins:jenkins /opt/contact-app
sudo cp systemd/contact-backend.service /etc/systemd/system/contact-backend.service
sudo systemctl daemon-reload
sudo touch /opt/contact-app/backend.env
sudo chown jenkins:jenkins /opt/contact-app/backend.env
sudo chmod 600 /opt/contact-app/backend.env
```

Put the real MongoDB values in `/opt/contact-app/backend.env`. Do not put them in Git:

```env
MONGODB_URI=mongodb+srv://USER:PASSWORD@CLUSTER/
MONGODB_DATABASE=first_project
MONGODB_COLLECTION=submissions
FLASK_SECRET_KEY=LONG_RANDOM_VALUE
CORS_ORIGINS=*
```

Allow Jenkins to restart only the required services:

```bash
sudo visudo -f /etc/sudoers.d/contact-app-jenkins
```

Add:

```text
jenkins ALL=(root) NOPASSWD: /usr/bin/systemctl restart contact-backend, /usr/bin/systemctl status contact-backend
```

## 3 Create two Jenkins pipelines

Create pipeline `contact-backend` using `Jenkinsfile.backend`, and pipeline `contact-frontend` using `Jenkinsfile.frontend`. For each job select **Pipeline script from SCM**, choose Git, enter your repository URL, and set the matching script path.

The pipelines copy application files into `/opt/contact-app`, install dependencies, run health checks, and restart the services. The frontend uses PM2 under the Jenkins account.

## 4 Add webhook

In GitHub open **Settings > Webhooks > Add webhook**:

- Payload URL: `http://EC2_PUBLIC_IP:8080/github-webhook/`
- Content type: `application/json`
- Event: push

Enable **GitHub hook trigger for GITScm polling** in both Jenkins jobs. Port 8080 must be reachable by GitHub; restrict access after capturing evidence. A safer long-term setup uses HTTPS and a reverse proxy.

## 5 Verify

```bash
curl http://localhost:5000/health
curl http://localhost:3000/health
sudo systemctl status contact-backend --no-pager
sudo -u jenkins pm2 list
```

Open `http://EC2_PUBLIC_IP:3000`. Push a harmless README change and capture both successful pipeline builds.

## Screenshots

Add all screenshots listed in `screenshots/README.md`, update `STUDENT_DETAILS.txt`, insert the images into the Word guide, then run:

```powershell
powershell -ExecutionPolicy Bypass -File assignments/activity-3-ec2-jenkins/make-submission.ps1
```

## Cleanup

Stop or terminate the EC2 instance after grading evidence is captured. Delete unused security groups and storage, and check AWS Billing.
