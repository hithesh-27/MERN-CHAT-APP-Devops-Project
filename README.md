# MERN Chat App — DevOps Project

A real-time MERN stack chat application (Socket.io + MongoDB) wrapped in a full CI/CD and cloud-native deployment pipeline. The app itself is a full-stack chat platform; the focus of this repo is the DevOps layer built around it — containerization, automated pipelines, security scanning, and GitOps-based Kubernetes deployment on AWS.

## Application

- **Client:** React JS
- **Server:** Node.js, Express.js
- **Database:** MongoDB (MongoDB Atlas in production)
- **Real-time:** Socket.io
- Features: authentication, one-to-one and group chats, typing indicators, notifications, user search, group admin controls

## DevOps Pipeline

| Stage | Tool |
|---|---|
| Source control | Git / GitHub |
| CI/CD orchestration | GitHub Actions (`.github/workflows/ci-cd.yml`) |
| Containerization | Docker, Docker Compose |
| Code quality | SonarQube |
| Dependency / vulnerability scanning | OWASP Dependency-Check |
| Configuration management | Ansible |
| Container orchestration | Kubernetes (AWS EKS) |
| GitOps continuous deployment | ArgoCD |
| Database | MongoDB Atlas |

### Pipeline flow

1. Push to `main` triggers the **MERN Chat App CI/CD** GitHub Actions workflow.
2. Dependencies are installed and the app is built.
3. **SonarQube** runs static code analysis for code quality/maintainability gates.
4. **OWASP Dependency-Check** scans dependencies for known vulnerabilities.
5. Docker images are built for the app (see `Dockerfile`, `docker-compose.yml`).
6. **Ansible** playbooks handle configuration/provisioning steps.
7. Manifests in `k8s/` are deployed to an **AWS EKS** cluster.
8. **ArgoCD** (`argocd/`) syncs the cluster state with the Git repo for GitOps-based continuous delivery.
9. The app connects to **MongoDB Atlas** in production instead of a local Mongo container.

## Repository Structure

```
.
├── .github/workflows/   # GitHub Actions CI/CD pipeline
├── ansible/             # Configuration management playbooks
├── argocd/              # ArgoCD application manifests for GitOps deployment
├── backend/             # Express + Node.js API server
├── frontend/            # React client
├── k8s/                 # Kubernetes manifests (Deployments, Services, etc.)
├── screenshots/         # App UI screenshots
├── Dockerfile
├── docker-compose.yml
├── sonar-project.properties
└── package.json
```

## Running Locally (Docker Compose)

```bash
git clone https://github.com/hithesh-27/MERN-CHAT-APP-Devops-Project.git
cd MERN-CHAT-APP-Devops-Project
docker-compose up --build
```

This spins up:
- `mongodb` — MongoDB 7, exposed on `27017`
- `chat-app` — the built app, exposed on `5000`

## Running Locally (without Docker)

```bash
# Backend
cd backend
npm install
npm run start

# Frontend
cd frontend
npm install
npm start
```

## Kubernetes / EKS Deployment

Manifests live in `k8s/`. Apply directly:

```bash
kubectl apply -f k8s/
```

Or let **ArgoCD** manage it via GitOps using the application definitions in `argocd/` — ArgoCD watches this repo and syncs the cluster automatically on changes to `main`.

## CI/CD

The pipeline is defined in `.github/workflows/ci-cd.yml` and runs on every push to `main`:
- Build & test
- SonarQube static analysis
- OWASP dependency vulnerability scan
- Docker image build
- Deployment to EKS via Ansible/Kubernetes manifests, synced through ArgoCD

## Screenshots

See the `screenshots/` directory for UI walkthroughs (auth, real-time chat, group chats, notifications, profile view).

## Notes

This project was built to demonstrate an end-to-end DevOps workflow — from code commit to a running, monitored deployment on Kubernetes — layered on top of an existing MERN chat application, rather than to showcase the chat app's features themselves.
