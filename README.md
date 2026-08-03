# MERN Chat App — DevOps Project

A real-time MERN stack chat application (Socket.io + MongoDB) with a GitHub Actions CI pipeline built around it — dependency install, build, static analysis, dependency/filesystem vulnerability scanning, and a Docker image published to Docker Hub on every push to `main`. Kubernetes, ArgoCD, and Ansible assets are included in the repo for cluster deployment.

## Application

- **Client:** React JS
- **Server:** Node.js, Express.js
- **Database:** MongoDB (MongoDB Atlas in production)
- **Real-time:** Socket.io
- Features: authentication, one-to-one and group chats, typing indicators, notifications, user search, group admin controls

## CI Pipeline (GitHub Actions — `ci-cd.yml`)

Triggered on every push to `main`. Job: **build-and-scan**

1. **Checkout** source (`actions/checkout@v4`)
2. **Setup Node.js 18** (`actions/setup-node@v4`)
3. **Install backend dependencies** — `npm install --legacy-peer-deps`
4. **Install frontend dependencies** — `cd frontend && npm install --legacy-peer-deps`
5. **Build React app** — `npm run build`
6. **SonarQube scan** (`SonarSource/sonarqube-scan-action@v5`) — static code analysis, authenticated via `SONAR_TOKEN` / `SONAR_HOST_URL` secrets
7. **OWASP Dependency-Check** (`dependency-check/Dependency-Check_Action@main`) — scans project dependencies for known CVEs, outputs an HTML report, Yarn audit disabled (`--disableYarnAudit`)
8. **Trivy filesystem scan** (`aquasecurity/trivy-action@master`) — scans the repo filesystem (`scan-type: fs`) for vulnerabilities
9. **Docker Hub login** (`docker/login-action@v3`)
10. **Build Docker image** — `docker build -t hitheshgowda10docker/chat-app:latest .`
11. **Push Docker image** to Docker Hub

## Deployment Assets

These are present in the repo for deploying the built image to a Kubernetes cluster, but are **not** invoked by the CI workflow above — they're run/applied separately:

- `k8s/` — Kubernetes manifests (Deployments, Services, etc.), intended for an AWS EKS cluster
- `argocd/` — ArgoCD application definitions for GitOps-style syncing of the cluster to this repo
- `ansible/` — playbooks for configuration/provisioning tasks

## Repository Structure

```
.
├── .github/workflows/   # ci-cd.yml — GitHub Actions CI pipeline
├── ansible/             # Configuration management playbooks
├── argocd/              # ArgoCD application manifests
├── backend/             # Express + Node.js API server
├── frontend/            # React client
├── k8s/                 # Kubernetes manifests
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
npm install --legacy-peer-deps
npm run start

# Frontend
cd frontend
npm install --legacy-peer-deps
npm start
```

## Pulling the Published Image

```bash
docker pull hitheshgowda10docker/chat-app:latest
```

## Kubernetes / EKS Deployment

```bash
kubectl apply -f k8s/
```

Or via ArgoCD using the application definitions in `argocd/`.

## Screenshots

See the `screenshots/` directory for UI walkthroughs (auth, real-time chat, group chats, notifications, profile view).

## Notes

This project demonstrates a DevOps-hardened build pipeline — static analysis (SonarQube), dependency vulnerability scanning (OWASP Dependency-Check), and filesystem vulnerability scanning (Trivy) — gating a Docker image before it's published, layered on top of an existing MERN chat application. Kubernetes/ArgoCD/Ansible assets are included for cluster deployment as a separate step from CI.
