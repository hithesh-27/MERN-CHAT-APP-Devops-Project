# MERN Chat App — End-to-End DevOps / GitOps Project

A MERN-based real-time chat application packaged with Docker and deployed to **AWS EKS** using **GitHub Actions, Docker Hub, Kubernetes, and Argo CD**. The repository also contains code-quality/security scanning and a Kubernetes monitoring stack with **Prometheus, Grafana, Alertmanager, kube-state-metrics, and Node Exporter**.

> **Current status:** The core CI/CD + GitOps delivery path and the Kubernetes monitoring stack have been deployed and verified in the AWS environment. The repository also contains older Ansible-based EC2 deployment assets; those are not the active EKS/Argo CD deployment path.

## Architecture

```text
Developer
   |
   | git push to main
   v
GitHub Repository
   |
   v
GitHub Actions
   |
   +--> Checkout
   +--> Node.js 18 + npm install
   +--> React production build
   +--> SonarQube analysis
   +--> OWASP Dependency-Check
   +--> Trivy filesystem scan
   +--> Docker build
   +--> Docker Hub push
   +--> Replace Kubernetes image with GITHUB_SHA
   +--> Commit deployment manifest with [skip ci]
   |
   v
GitHub main (GitOps source of truth)
   |
   v
Argo CD
   |
   +--> chat-app Application
   |       |
   |       v
   |     AWS EKS
   |       |
   |       +--> Backend Deployment
   |       +--> Backend LoadBalancer Service
   |       +--> MongoDB Deployment
   |       +--> MongoDB ClusterIP Service
   |
   +--> monitoring Application
           |
           v
     kube-prometheus-stack
           |
           +--> Prometheus
           +--> Grafana
           +--> Alertmanager
           +--> kube-state-metrics
           +--> Node Exporter
```

## Application Stack

| Component | Technology | Verified repository usage |
|---|---|---|
| Frontend | React.js | `frontend/` |
| Backend | Node.js + Express.js | `backend/` |
| Database | MongoDB | `mongo:7` |
| Real-time communication | Socket.io | Backend/frontend dependencies |
| Authentication | JWT + bcryptjs | Backend dependencies/configuration |
| Containerization | Docker | `Dockerfile`, `docker-compose.yml` |

The application implements authentication, chat functionality, user search, group-chat functionality, notifications and real-time communication through Socket.io.

## DevOps / Cloud Stack

| Layer | Technology | Purpose |
|---|---|---|
| Source control | Git + GitHub | Version control and GitOps source of truth |
| CI/CD | GitHub Actions | Build, analysis, security scanning, image publishing and GitOps manifest update |
| Code quality | SonarQube | Static analysis |
| Dependency security | OWASP Dependency-Check | Dependency vulnerability scanning |
| Filesystem security | Trivy | HIGH/CRITICAL filesystem vulnerability scanning |
| Containerization | Docker | Build application image |
| Registry | Docker Hub | Store immutable SHA-tagged and `latest` images |
| Orchestration | Kubernetes | Application and database workloads |
| Cloud | AWS EKS | Managed Kubernetes cluster |
| GitOps CD | Argo CD | Automated synchronization and self-healing |
| Monitoring | Prometheus | Metrics collection and alert evaluation |
| Visualization | Grafana | Metrics dashboards |
| Alerting | Alertmanager | Prometheus alert routing |
| Kubernetes metrics | kube-state-metrics | Kubernetes object/state metrics |
| Node metrics | Node Exporter | Node-level metrics |
| Automation assets | Ansible | Legacy/alternative EC2 Docker deployment assets |

## Repository Structure

```text
.
├── .github/
│   └── workflows/
│       ├── ci-cd.yml                 # Active GitHub Actions pipeline
│       └── .ci-cd-test               # Verification marker file
├── ansible/
│   ├── ansible.cfg
│   ├── deploy.yml                    # Older EC2/Docker deployment playbook
│   └── inventory/
├── argocd/
│   └── application.yaml              # Argo CD Application for chat-app
├── backend/                          # Node.js + Express application
├── frontend/                         # React application
├── k8s/
│   ├── backend/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   └── mongodb/
│       ├── deployment.yaml
│       └── service.yaml
├── monitoring/
│   └── prometheus-grafana-argocd.yaml # Argo CD Application for kube-prometheus-stack
├── screenshots/                       # Application screenshots/assets
├── Dockerfile
├── docker-compose.yml
├── sonar-project.properties
├── package.json
├── .dockerignore
├── .gitignore
└── README.md
```

## CI/CD Pipeline

The active workflow is `.github/workflows/ci-cd.yml` and runs on pushes to `main`. It has `contents: write` permission because the workflow updates the Kubernetes GitOps manifest after publishing the image.

### Pipeline stages

1. Checkout source with `actions/checkout@v4`.
2. Configure Node.js 18 with npm caching.
3. Install backend dependencies.
4. Install frontend dependencies.
5. Build the React frontend.
6. Verify connectivity to the SonarQube server through `/api/system/status`.
7. Run SonarQube analysis against `backend` and `frontend`.
8. Run OWASP Dependency-Check.
9. Run Trivy filesystem scanning for `HIGH,CRITICAL` findings while ignoring unfixed findings.
10. Authenticate to Docker Hub using GitHub repository secrets.
11. Build the application image with both an immutable Git SHA tag and `latest`.
12. Push both tags to Docker Hub.
13. Replace the Kubernetes backend image reference with `${GITHUB_SHA}`.
14. Commit the changed Kubernetes manifest using `[skip ci]`.
15. Push the GitOps manifest back to `main`.

### GitHub repository secrets

The active workflow expects these repository secrets:

```text
SONAR_HOST_URL
SONAR_TOKEN
DOCKER_USERNAME
DOCKER_PASSWORD
```

Secrets are not stored in the repository.

## Immutable Docker Image Deployment

The CI pipeline publishes:

```text
hitheshgowda10docker/chat-app:<GITHUB_SHA>
hitheshgowda10docker/chat-app:latest
```

The Kubernetes backend deployment is updated to the SHA-tagged image rather than `latest`. This provides a direct mapping between a deployed container and the source commit that produced it.

Example:

```text
hitheshgowda10docker/chat-app:<commit-sha>
```

## GitOps with Argo CD

The active Argo CD application is defined in `argocd/application.yaml` and watches the repository's `k8s/` directory on `main`.

Argo CD is configured with:

- Automated synchronization
- Automatic pruning
- Self-healing
- Namespace creation

The delivery loop is therefore:

```text
GitHub Actions
      |
      | updates image tag
      v
GitHub main
      |
      | Argo CD detects Git change
      v
Argo CD
      |
      | automated sync + self-heal
      v
AWS EKS
```

The application deployment is GitOps-managed; application Kubernetes changes should be made in Git rather than by manually applying the application manifests.

## AWS EKS Environment

Verified environment:

```text
Region:       us-east-1
Cluster:      mern-chat-devops
Kubernetes:   AWS EKS
Worker nodes: 2 during final deployment verification
```

### Application workloads

The `chat-app` namespace contains:

- Backend Deployment
- Backend `LoadBalancer` Service
- MongoDB Deployment
- MongoDB `ClusterIP` Service

The backend listens on container port `5000`; the Kubernetes Service exposes port `80` and forwards to `5000`.

MongoDB listens on `27017` and is reachable inside the cluster through the `mongodb` Service.

## Kubernetes Configuration

### Backend

`k8s/backend/deployment.yaml` uses:

- 1 replica in Git
- Docker Hub SHA-tagged image
- `imagePullPolicy: Always`
- `NODE_ENV=production`
- Port `5000`
- MongoDB connection through the Kubernetes `mongodb` Service

`k8s/backend/service.yaml` exposes the backend through an AWS `LoadBalancer`.

### MongoDB

`k8s/mongodb/deployment.yaml` runs `mongo:7` and mounts `/data/db` using `emptyDir`.

`k8s/mongodb/service.yaml` exposes MongoDB internally as a `ClusterIP` service.

**Important:** `emptyDir` is ephemeral storage. It is suitable for this project/demo environment but is **not durable production database storage**. A hardened production deployment should use MongoDB Atlas or another persistent/managed database solution and keep database credentials in a secrets manager.

## Prometheus + Grafana Monitoring

Monitoring is defined as an Argo CD Application in:

```text
monitoring/prometheus-grafana-argocd.yaml
```

It deploys the Prometheus Community `kube-prometheus-stack` Helm chart and enables:

- Prometheus
- Grafana
- Alertmanager
- kube-state-metrics
- Node Exporter

Configuration currently includes:

- Prometheus retention: `7d`
- Prometheus request: `100m CPU / 256Mi memory`
- Prometheus limit: `500m CPU / 1Gi memory`
- Alertmanager request: `50m CPU / 64Mi memory`
- Alertmanager limit: `200m CPU / 256Mi memory`
- Grafana exposed through an AWS `LoadBalancer`
- Grafana persistence disabled
- Argo CD automated sync, prune and self-heal

### Verified monitoring state

The monitoring stack was successfully reconciled in EKS. Final verification showed:

```text
Argo CD monitoring: SYNCED / HEALTHY
Prometheus:         READY 1/1
Alertmanager:       READY 1/1
Prometheus Operator: Running
Grafana:            Running
kube-state-metrics: Running
Node Exporter:      Running on both worker nodes
```

The Prometheus and Alertmanager custom resources reported `RECONCILED=True` and `AVAILABLE=True` after the Prometheus Operator restarted and reconciled them.

### Monitoring access

Grafana is exposed through the `monitoring-grafana` LoadBalancer service. Retrieve the current endpoint with:

```bash
kubectl get svc monitoring-grafana -n monitoring \
  -o jsonpath='http://{.status.loadBalancer.ingress[0].hostname}{"\n"}'
```

Retrieve the generated/current Grafana admin password from Kubernetes rather than assuming a value:

```bash
kubectl get secret monitoring-grafana -n monitoring \
  -o jsonpath='{.data.admin-password}' | base64 -d && echo
```

> **Security note:** The current repository manifest contains a development/demo Grafana password. This must be moved to a Kubernetes Secret or external secrets mechanism before a real production deployment. Do not reuse the demo credential in production.

### Prometheus CRD note

The `kube-prometheus-stack` CRDs were installed server-side during cluster setup because the large CRD annotations exceeded the Kubernetes client-side annotation limit. Argo CD is configured with `skipCrds: true`, while the CRDs are present in the cluster.

For a fully reproducible production GitOps environment, CRD lifecycle management should be made an explicit, version-controlled bootstrap step rather than depending on a manually prepared cluster.

## SonarQube

SonarQube runs on a dedicated EC2 instance and is accessed by GitHub Actions through `SONAR_HOST_URL` and `SONAR_TOKEN` secrets.

The workflow also performs a connectivity check before starting the SonarQube scanner.

The repository contains `sonar-project.properties` with source paths for the backend and frontend and exclusions for generated/dependency content.

## Docker

The root `Dockerfile`:

1. Uses Node.js 18 Alpine.
2. Sets `/app` as the working directory.
3. Installs root and frontend dependencies.
4. Copies the application source.
5. Builds the React frontend.
6. Sets `NODE_ENV=production`.
7. Exposes port `5000`.
8. Starts the Node.js backend with `npm start`.

### Local Docker Compose

`docker-compose.yml` provides a simple local environment containing:

- MongoDB 7
- The chat application

Run it with:

```bash
docker compose up --build
```

## Local Development

### Docker Compose

```bash
git clone https://github.com/hithesh-27/MERN-CHAT-APP-Devops-Project.git
cd MERN-CHAT-APP-Devops-Project
docker compose up --build
```

### Without Docker

Backend:

```bash
npm install --legacy-peer-deps
npm run start
```

Frontend:

```bash
cd frontend
npm install --legacy-peer-deps
npm start
```

Configure application environment variables locally using the provided `.env.example` guidance. Do not commit real credentials.

## Ansible Assets

The repository contains an Ansible playbook under `ansible/` that installs Docker and runs MongoDB and the chat application directly on an EC2-style host.

This is a **legacy/alternative deployment path** and is not the active production delivery chain verified for this project. The active deployment path is:

```text
GitHub Actions → Docker Hub → Argo CD → AWS EKS
```

## Verification Commands

Run these from an EKS administration host to verify the application:

```bash
# Cluster nodes
kubectl get nodes -o wide

# Application pods
kubectl get pods -n chat-app -o wide

# Application service
kubectl get svc -n chat-app

# Deployed image
kubectl get deployment backend -n chat-app \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

# Argo CD application
kubectl get application chat-app -n argocd \
  -o jsonpath='SYNC={.status.sync.status} HEALTH={.status.health.status}{"\n"}'

# Monitoring Argo CD application
kubectl get application monitoring -n argocd \
  -o jsonpath='SYNC={.status.sync.status} HEALTH={.status.health.status}{"\n"}'

# Monitoring workloads
kubectl get pods -n monitoring -o wide

# Prometheus
kubectl get prometheus -n monitoring

# Alertmanager
kubectl get alertmanager -n monitoring

# Grafana endpoint
kubectl get svc monitoring-grafana -n monitoring \
  -o jsonpath='http://{.status.loadBalancer.ingress[0].hostname}{"\n"}'
```

Expected Argo CD application state after successful reconciliation:

```text
SYNC=Synced HEALTH=Healthy
```

## End-to-End Delivery Flow

```text
1. Developer pushes code to main
            |
            v
2. GitHub Actions starts
            |
            +--> npm install
            +--> React build
            +--> SonarQube
            +--> OWASP Dependency-Check
            +--> Trivy
            |
            v
3. Docker image built
            |
            v
4. SHA + latest pushed to Docker Hub
            |
            v
5. k8s/backend/deployment.yaml updated with GITHUB_SHA
            |
            v
6. GitHub Actions commits manifest with [skip ci]
            |
            v
7. Argo CD detects Git change
            |
            v
8. EKS rolling deployment
            |
            v
9. Backend + MongoDB run in chat-app namespace
            |
            v
10. Prometheus collects cluster/application metrics
            |
            v
11. Grafana visualizes metrics
            |
            v
12. Alertmanager handles Prometheus alerts
```

## Production Hardening Roadmap

The project demonstrates a strong production-style DevOps workflow, but the following items should be completed before describing the infrastructure as hardened enterprise production:

- Move `JWT_SECRET`, MongoDB credentials and Grafana credentials to AWS Secrets Manager/Parameter Store, External Secrets, or another secret-management solution.
- Remove hard-coded demo credentials from Kubernetes YAML.
- Replace MongoDB `emptyDir` with durable managed/persistent database storage.
- Add HTTPS/TLS and a domain through an AWS Load Balancer/Ingress configuration.
- Add readiness/liveness probes to application workloads.
- Add resource requests/limits and autoscaling where appropriate.
- Add PodDisruptionBudgets for critical workloads.
- Add persistent storage for Grafana/Prometheus where long-term retention is required.
- Make monitoring CRD installation a reproducible version-controlled bootstrap step.
- Pin third-party GitHub Actions to reviewed commit SHAs for stronger supply-chain security.
- Use separate staging and production environments and protected GitHub branches/environments.
- Add application-level ServiceMonitor/metrics endpoints if custom application metrics are required.

## Final Project Summary

This repository demonstrates an end-to-end DevOps/GitOps implementation for a MERN application using:

**Git → GitHub → GitHub Actions → SonarQube → OWASP Dependency-Check → Trivy → Docker → Docker Hub → Argo CD → AWS EKS → Kubernetes → Prometheus → Grafana → Alertmanager**

The active EKS deployment path is automated, the backend image is versioned using the source commit SHA, Argo CD provides continuous reconciliation/self-healing, and the Kubernetes monitoring stack has been successfully deployed and reconciled.
