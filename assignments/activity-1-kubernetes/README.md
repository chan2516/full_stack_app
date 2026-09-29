# Activity 1 Local Kubernetes Deployment

## Objective

Run the existing Express frontend and Flask backend in a local Minikube cluster. The frontend is exposed with a NodePort; the backend stays inside the cluster.

## Prerequisites

- Docker Desktop
- Minikube
- kubectl
- PowerShell

Verify the tools:

```powershell
docker --version
minikube version
kubectl version --client
```

## Fast deployment

Run these commands from the project root:

```powershell
minikube start --driver=docker
minikube image build -t contact-app-backend:local ./backend
minikube image build -t contact-app-frontend:local ./frontend
kubectl apply -f assignments/activity-1-kubernetes/k8s/
kubectl get pods
kubectl get services
minikube service contact-frontend --url
```

Open the URL printed by the final command. Search works without MongoDB. Form submission requires a MongoDB connection string.

## Enable form submission

Create the secret directly in Kubernetes. Do not save the real value in a YAML file:

```powershell
kubectl create secret generic contact-app-secrets --from-literal=MONGODB_URI='mongodb+srv://USER:PASSWORD@CLUSTER/' --from-literal=FLASK_SECRET_KEY='replace-with-a-long-random-value' --dry-run=client -o yaml | kubectl apply -f -
kubectl rollout restart deployment/contact-backend
kubectl rollout status deployment/contact-backend
```

## Verification

```powershell
kubectl get pods,services,deployments
kubectl logs deployment/contact-backend --tail=30
kubectl logs deployment/contact-frontend --tail=30
kubectl port-forward service/contact-backend 5000:5000
```

In a second terminal:

```powershell
curl.exe http://localhost:5000/health
```

Expected backend response: `{"service":"backend","status":"ok"}`.

## Screenshots to add

Put these files in `screenshots/`:

1. `01-minikube-status.png` - `minikube status`
2. `02-images.png` - `minikube image ls` showing both app images
3. `03-pods-services.png` - `kubectl get pods,services,deployments`
4. `04-health.png` - successful backend health response
5. `05-browser.png` - working frontend in the browser

## Cleanup

```powershell
kubectl delete -f assignments/activity-1-kubernetes/k8s/
minikube stop
```

Use `minikube delete` only when the cluster is no longer needed.

## Submission

Fill in your GitHub link in `STUDENT_DETAILS.txt`, insert the real screenshots into the Word document, and then run:

```powershell
powershell -ExecutionPolicy Bypass -File assignments/activity-1-kubernetes/make-submission.ps1
```

The script creates `Kubernetes_Chandan.zip` in the project root.
