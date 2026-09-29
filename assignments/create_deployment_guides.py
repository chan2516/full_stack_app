from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


ROOT = Path(__file__).resolve().parent
BLACK = "000000"
NAVY = "17365D"
LIGHT = "EAF0F7"
BORDER = "D9D9D9"


def shade(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:fill"), fill)
    tc_pr.append(shd)


def borders(table):
    tbl_pr = table._tbl.tblPr
    element = OxmlElement("w:tblBorders")
    for name in ("top", "left", "bottom", "right", "insideH", "insideV"):
        edge = OxmlElement(f"w:{name}")
        edge.set(qn("w:val"), "single")
        edge.set(qn("w:sz"), "4")
        edge.set(qn("w:color"), BORDER)
        element.append(edge)
    tbl_pr.append(element)


def style_document(doc):
    section = doc.sections[0]
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.top_margin = Inches(0.72)
    section.bottom_margin = Inches(0.72)
    section.left_margin = Inches(0.8)
    section.right_margin = Inches(0.8)
    normal = doc.styles["Normal"]
    normal.font.name = "Aptos"
    normal.font.size = Pt(10.5)
    normal.font.color.rgb = RGBColor(0, 0, 0)
    normal.paragraph_format.space_after = Pt(6)
    normal.paragraph_format.line_spacing = 1.08
    for style_name, size in (("Title", 25), ("Heading 1", 16), ("Heading 2", 12)):
        style = doc.styles[style_name]
        style.font.name = "Aptos Display" if style_name != "Normal" else "Aptos"
        style.font.size = Pt(size)
        style.font.color.rgb = RGBColor(0, 0, 0)
        style.font.bold = True
        style.paragraph_format.keep_with_next = True
        style.paragraph_format.space_before = Pt(12)
        style.paragraph_format.space_after = Pt(6)


def add_cover(doc, title, subtitle):
    p = doc.add_paragraph(style="Title")
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.add_run(title)
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run(subtitle)
    r.bold = True
    r.font.size = Pt(13)
    doc.add_paragraph()
    table = doc.add_table(rows=4, cols=2)
    table.autofit = False
    table.columns[0].width = Inches(1.7)
    table.columns[1].width = Inches(4.9)
    for row, (key, value) in zip(table.rows, [
        ("Student", "Chandan Vishwakarma"),
        ("Project", "Express frontend and Flask backend"),
        ("GitHub", "https://github.com/YOUR-USERNAME/YOUR-REPOSITORY"),
        ("Status", "Replace placeholders and insert real screenshots before submission"),
    ]):
        row.cells[0].text = key
        row.cells[1].text = value
        shade(row.cells[0], LIGHT)
        row.cells[0].paragraphs[0].runs[0].bold = True
        for cell in row.cells:
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
    borders(table)
    doc.add_paragraph()
    doc.add_paragraph("This guide records the deployment procedure, verification commands, and mandatory evidence for this assignment. Do not include passwords, access keys, private keys, or real environment files.")
    doc.add_page_break()


def add_steps(doc, heading, steps):
    doc.add_heading(heading, level=1)
    for title, body, command in steps:
        p = doc.add_paragraph(style="Heading 2")
        p.add_run(title)
        doc.add_paragraph(body)
        if command:
            p = doc.add_paragraph()
            p.paragraph_format.left_indent = Inches(0.25)
            r = p.add_run(command)
            r.font.name = "Consolas"
            r.font.size = Pt(9)
            r.font.color.rgb = RGBColor(32, 32, 32)


def add_evidence(doc, items):
    doc.add_heading("Evidence and Results", level=1)
    doc.add_paragraph("Insert your own screenshots below each matching label. Keep the terminal command or AWS resource name visible, and hide all secrets.")
    for item in items:
        p = doc.add_paragraph(style="Heading 2")
        p.add_run(item)
        doc.add_paragraph("Screenshot: ______________________________________________")
        doc.add_paragraph("Result or URL: ___________________________________________")


def add_checklist(doc, items):
    doc.add_heading("Submission Checklist", level=1)
    for item in items:
        doc.add_paragraph(f"[ ] {item}")


def save_doc(filename, title, subtitle, intro, step_groups, evidence, checklist):
    doc = Document()
    style_document(doc)
    add_cover(doc, title, subtitle)
    doc.add_heading("Purpose", level=1)
    doc.add_paragraph(intro)
    for heading, steps in step_groups:
        add_steps(doc, heading, steps)
    add_evidence(doc, evidence)
    add_checklist(doc, checklist)
    output = ROOT / filename
    doc.save(output)
    return output


save_doc(
    "activity-1-kubernetes/Kubernetes_Deployment_Guide.docx",
    "Local Kubernetes Deployment Guide",
    "Activity 1 Minikube",
    "This assignment containerizes and runs the existing Express frontend and Flask backend in Minikube. Kubernetes Deployments keep the containers running, a ClusterIP connects the frontend to Flask, and a NodePort exposes the web page locally.",
    [
        ("Deployment Procedure", [
            ("Start Minikube", "Use Docker Desktop as the local cluster driver.", "minikube start --driver=docker"),
            ("Build images inside Minikube", "The manifests use local image names and do not require Docker Hub.", "minikube image build -t contact-app-backend:local ./backend\nminikube image build -t contact-app-frontend:local ./frontend"),
            ("Apply manifests", "Create the configuration, backend, frontend, and services.", "kubectl apply -f assignments/activity-1-kubernetes/k8s/"),
            ("Open the application", "Wait for both pods, then open the frontend service URL.", "kubectl get pods,services,deployments\nminikube service contact-frontend --url"),
        ]),
        ("Verification", [
            ("Check health", "Port-forward Flask and call its health endpoint.", "kubectl port-forward service/contact-backend 5000:5000\ncurl.exe http://localhost:5000/health"),
            ("Check logs", "Use logs to explain any failed readiness or form submission.", "kubectl logs deployment/contact-backend --tail=30\nkubectl logs deployment/contact-frontend --tail=30"),
        ]),
    ],
    ["Minikube status", "Container images", "Pods services and deployments", "Backend health response", "Working browser page"],
    ["Complete project source included", "All Kubernetes YAML files included", "Five real screenshots inserted", "GitHub repository link replaced", "No secrets or .env files included", "Kubernetes_Chandan.zip created"],
)

save_doc(
    "activity-2-terraform-aws/Terraform_AWS_Deployment_Guide.docx",
    "AWS Deployment with Terraform",
    "Activity 2 Three Configurations",
    "This assignment deploys the same application in three configurations: both services on one EC2 instance, the services on separate EC2 instances, and Docker containers on ECS Fargate using ECR, a VPC, and an Application Load Balancer.",
    [
        ("Common Terraform Workflow", [
            ("Configure values", "Copy terraform.tfvars.example and backend.hcl.example, then replace the repository, key pair, state bucket, IP range, and MongoDB placeholders.", "Copy-Item terraform.tfvars.example terraform.tfvars\nCopy-Item backend.hcl.example backend.hcl"),
            ("Validate and deploy", "Initialize the S3 backend and save the plan before applying it.", "terraform init -backend-config=backend.hcl\nterraform fmt -check\nterraform validate\nterraform plan -out tfplan\nterraform apply tfplan"),
        ]),
        ("Part 1 Single EC2", [
            ("Deploy", "Terraform creates one instance and starts Flask and Express as systemd services on ports 5000 and 3000.", "cd part-1-single-ec2\nterraform apply"),
        ]),
        ("Part 2 Separate EC2", [
            ("Deploy", "Terraform creates the VPC, public subnet, route table, security groups, and two instances. Express uses the backend private IP.", "cd part-2-separate-ec2\nterraform apply"),
        ]),
        ("Part 3 ECS", [
            ("Create ECR first", "Create the repositories, push both images, and then deploy the full ECS stack.", "terraform apply -target=aws_ecr_repository.backend -target=aws_ecr_repository.frontend\ndocker push ECR_BACKEND_URI:latest\ndocker push ECR_FRONTEND_URI:latest\nterraform apply"),
            ("Verify and clean up", "Open the ALB URL, capture evidence, then destroy chargeable resources.", "terraform output\nterraform destroy"),
        ]),
    ],
    ["Part 1 plan apply EC2 and browser", "Part 2 plan two EC2 VPC security groups and browser", "Part 3 ECR VPC ECS ALB targets and browser"],
    ["All three Terraform folders included", "variables and outputs included", "S3 backend configuration documented", "Thirteen real screenshots inserted", "Actual outputs and GitHub URL recorded", "No state secrets or tfvars included", "Terraform_AWS_Chandan.zip created"],
)

save_doc(
    "activity-3-ec2-jenkins/EC2_Jenkins_Deployment_Guide.docx",
    "EC2 and Jenkins Deployment Guide",
    "Activity 3 Continuous Deployment",
    "This assignment runs Express and Flask on one Ubuntu EC2 instance and uses two Jenkins pipelines. A GitHub push triggers dependency installation, a basic validation test, service restart, and a health check.",
    [
        ("EC2 Setup", [
            ("Install runtimes", "Install Git, Python, Node.js, Java, PM2, and Jenkins on Ubuntu.", "sudo apt update\nsudo apt install -y git python3-venv python3-pip nodejs npm openjdk-17-jre\nsudo npm install -g pm2"),
            ("Configure services", "Store backend secrets only in /opt/contact-app/backend.env and install the supplied systemd unit.", "sudo cp systemd/contact-backend.service /etc/systemd/system/\nsudo systemctl daemon-reload"),
        ]),
        ("Jenkins Pipelines", [
            ("Backend pipeline", "Create a Pipeline from SCM using Jenkinsfile.backend.", "Script path: assignments/activity-3-ec2-jenkins/Jenkinsfile.backend"),
            ("Frontend pipeline", "Create a second Pipeline from SCM using Jenkinsfile.frontend.", "Script path: assignments/activity-3-ec2-jenkins/Jenkinsfile.frontend"),
            ("GitHub webhook", "Add the Jenkins webhook and enable the GitHub hook trigger in both jobs.", "http://EC2_PUBLIC_IP:8080/github-webhook/"),
        ]),
        ("Verification", [
            ("Check both services", "Confirm the services and the browser before and after a test push.", "curl http://localhost:5000/health\ncurl http://localhost:3000/health\nsudo systemctl status contact-backend --no-pager\nsudo -u jenkins pm2 list"),
        ]),
    ],
    ["Running EC2 and security group", "Both service health responses", "Jenkins dashboard", "Successful backend pipeline", "Successful frontend pipeline", "Successful GitHub webhook", "Working browser page"],
    ["Project source and both Jenkinsfiles included", "Systemd and PM2 configuration included", "Eight real screenshots inserted", "GitHub link and EC2 URL recorded", "No passwords keys tokens or .env files included", "EC2_Jenkins_Chandan.zip created"],
)
