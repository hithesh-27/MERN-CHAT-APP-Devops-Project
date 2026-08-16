# MERN Chat App — End-to-End DevOps / GitOps Project

A real-time MERN chat application deployed on **AWS EKS** with an automated **GitHub Actions CI/CD + Docker Hub + Argo CD GitOps** pipeline.

The project combines application delivery, code-quality analysis, dependency and filesystem security scanning, containerization, Kubernetes deployment, and GitOps-based continuous delivery.

## Architecture

```text
Developer
   |
   | git push to main
   v
GitHub Repository
   |
   v
GitHub Actions CI/CD
   |
   +--> Install dependencies + React build
   +--> SonarQube code analysis
   +--> OWASP Dependency-Check
   +--> Trivy filesystem security scan
   +--> Docker build
   +--> Push image to Docker Hub
   +--> Update k8s/backend/deployment.yaml with Git SHA
   +--> Commit + push Kubernetes manifest
   |
   v
GitHub main (GitOps source of truth)
   |
   v
Argo CD
   |
   | automated sync / self-heal
   v
AWS EKS
   |
   +--> Backend Deployment / LoadBalancer
   |
   +--> MongoDB Deployment / ClusterIP
   |
   v
MERN Chat Application
```

## Application Stack

- **Frontend:** React.js
- **Backend:** Node.js + Express.js
- **Database:** MongoDB
- **Real-time communication:** Socket.io
- **Authentication:** JWT + bcryptjs
- **Containerization:** Docker

Application features include authentication, one-to-one and group chats, typing indicators, notifications, user search, and group administration.

## DevOps / Cloud Stack

| Layer | Technology | Purpose |
|---|---|---|
| Source Control | Git + GitHub | Version control and GitOps source |
| CI/CD | GitHub Actions | Automated build, security checks, image publishing and manifest update |
| Code Quality | SonarQube | Static code analysis |
| Dependency Security | OWASP Dependency-Check | Dependency CVE scanning |
| Security | Trivy | Filesystem vulnerability scanning |
| Containerization | Docker | Build application container |
| Registry | Docker Hub | Store and publish versioned images |
| Orchestration | Kubernetes | Run application workloads |
| Cloud | AWS EKS | Managed Kubernetes cluster |
| GitOps CD | Argo CD | Automatically synchronize Git manifests to EKS |
| Database | MongoDB | Application persistence |

## CI/CD Pipeline

The workflow is `.github/workflows/ci-cd.yml` and runs automatically on pushes to `main`.

### CI stages

1. Checkout source using `actions/checkout@v4`
2. Setup Node.js 18 with npm caching
3. Install backend dependencies
4. Install frontend dependencies
5. Build the React application
6. Test connectivity to the SonarQube server
7. Run SonarQube analysis
8. Run OWASP Dependency-Check
9. Run Trivy filesystem scan for HIGH/CRITICAL vulnerabilities while ignoring unfixed findings
10. Authenticate to Docker Hub
11. Build the Docker image
12. Tag the image with the immutable GitHub commit SHA and `latest`
13. Push both tags to Docker Hub
14. Update the Kubernetes backend manifest to the Git SHA image
15. Commit and push the Kubernetes manifest back to `main`

The workflow uses `contents: write` so GitHub Actions can update the GitOps manifest.

### Image versioning

Deployments use the immutable Git commit SHA rather than relying on `latest`:

```text
hitheshgowda10docker/chat-app:<GITHUB_SHA>
```

This makes each deployment traceable to an exact source commit and allows Argo CD to detect manifest changes reliably.

## GitOps / Argo CD

Argo CD watches the Kubernetes manifests in this repository and continuously reconciles the EKS cluster with Git.

The intended flow is:

```text
GitHub Actions
     |
     | update Kubernetes image tag
     v
GitHub main
     |
     | Argo CD detects commit
     v
Argo CD
     |
     | automated sync
     v
AWS EKS
```

Argo CD is the CD layer; application Kubernetes changes should be made through Git rather than manually applying the application manifests.

## AWS EKS

Current deployment environment:

- **AWS Region:** `us-east-1`
- **EKS Cluster:** `mern-chat-devops`
- **Kubernetes:** EKS managed Kubernetes
- **Backend:** Kubernetes `LoadBalancer` service on port 80 → container port 5000
- **MongoDB:** Kubernetes `ClusterIP` service on port 27017

The cluster was configured with two worker nodes during the final rolling deployment verification so Kubernetes could schedule the new backend replica while replacing the old replica.

## SonarQube

SonarQube runs on a dedicated AWS EC2 instance and is consumed by GitHub Actions through the `SONAR_HOST_URL` repository secret.

The pipeline verifies the SonarQube server before running the scanner.

**Do not commit SonarQube tokens or credentials to Git.** Configure these repository secrets in GitHub:

```text
SONAR_HOST_URL
SONAR_TOKEN
DOCKER_USERNAME
DOCKER_PASSWORD
```

## Kubernetes Resources

```text
k8s/
├── backend/
│   ├── deployment.yaml
│   └── service.yaml
└── mongodb/
    ├── deployment.yaml
    └── service.yaml
```

## Repository Structure

```text
.
├── .github/workflows/       # GitHub Actions CI/CD
├── argocd/                  # Argo CD application manifests
├── ansible/                 # Ansible configuration/provisioning assets
├── backend/                 # Node.js + Express backend
├── frontend/                # React frontend
├── k8s/                     # Kubernetes manifests
├── screenshots/             # Application screenshots
├── Dockerfile               # Application container image
├── docker-compose.yml       # Local Docker Compose setup
├── sonar-project.properties # SonarQube project configuration
├── package.json             # Node.js project configuration
└── README.md                # Project documentation
```

## Run Locally with Docker Compose

```bash
git clone https://github.com/hithesh-27/MERN-CHAT-APP-Devops-Project.git
cd MERN-CHAT-APP-Devops-Project
docker compose up --build
```

The Compose setup runs the application and MongoDB locally.

## Run Locally without Docker

```bash
# Backend
npm install --legacy-peer-deps
npm run start

# Frontend
cd frontend
npm install --legacy-peer-deps
npm start
```

Configure the required application environment variables locally according to the application's configuration before starting it.

## Docker Hub

The CI pipeline publishes:

```text
hitheshgowda10docker/chat-app:<GITHUB_SHA>
hitheshgowda10docker/chat-app:latest
```

Pull the latest image with:

```bash
docker pull hitheshgowda10docker/chat-app:latest
```

## Deployment Verification

Useful commands for verifying the complete pipeline from the EKS administration host:

```bash
# EKS nodes
kubectl get nodes -o wide

# Application pods
kubectl get pods -n chat-app -o wide

# Backend service / public LoadBalancer
kubectl get svc -n chat-app

# Running image
kubectl get deployment backend -n chat-app \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

# Argo CD application state
kubectl get application chat-app -n argocd \
  -o jsonpath='SYNC={.status.sync.status} HEALTH={.status.health.status}{"\n"}'
```

A successful deployment should report:

```text
SYNC=Synced HEALTH=Healthy
```

## Production-Readiness Notes

The project implements a production-style CI/CD and GitOps workflow with immutable image deployment, automated security checks, Docker image publishing, Argo CD reconciliation, and AWS EKS deployment.

For a hardened enterprise production environment, the next infrastructure hardening steps would be:

- Store application secrets in AWS Secrets Manager / AWS Systems Manager Parameter Store rather than Kubernetes YAML.
- Use a persistent MongoDB service such as MongoDB Atlas or a managed database instead of ephemeral `emptyDir` storage.
- Add HTTPS/TLS with a domain and AWS Load Balancer / Ingress configuration.
- Add Prometheus/Grafana monitoring and alerting.
- Add resource requests/limits, readiness/liveness probes, PodDisruptionBudgets, and autoscaling where appropriate.
- Pin third-party GitHub Actions to reviewed commit SHAs for a stricter supply-chain security posture.
- Use separate staging and production environments with protected GitHub branches/environments.

These are infrastructure-hardening improvements beyond the currently verified core CI/CD + GitOps deployment path.

## End-to-End Delivery

The verified delivery chain is:

```text
Code push to main
      ↓
GitHub Actions
      ↓
Build + SonarQube + OWASP + Trivy
      ↓
Docker image build
      ↓
Docker Hub
      ↓
Git SHA written to Kubernetes manifest
      ↓
Git commit to main
      ↓
Argo CD automated synchronization
      ↓
AWS EKS rolling deployment
      ↓
Backend pod Running
      ↓
Argo CD: Synced + Healthy
```

## Project Goal

This project demonstrates how a real MERN application can be delivered using modern DevOps practices: **Git-based CI/CD, automated security scanning, containerization, immutable image versioning, Kubernetes orchestration, AWS EKS, and GitOps with Argo CD**.
