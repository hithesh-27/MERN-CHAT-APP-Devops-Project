# MERN Chat App — End-to-End DevOps / GitOps Project

A MERN-based real-time chat application containerized with Docker and deployed to **AWS EKS** through **GitHub Actions + Docker Hub + Kubernetes + Argo CD**. The repository also contains **Terraform** infrastructure code, **Ansible** EC2/Docker automation assets, **SonarQube**, **OWASP Dependency-Check**, **Trivy**, and an Argo CD-managed **Prometheus + Grafana + Alertmanager + kube-state-metrics + Node Exporter** monitoring stack.

> **Verified status:** The active CI/CD → GitOps → EKS application path and the Kubernetes monitoring stack were deployed and verified in the AWS environment. Terraform is the infrastructure-as-code layer for the EKS/VPC environment. Ansible is an alternative/legacy EC2 + Docker deployment path and is not part of the active EKS/Argo CD delivery chain.

## Architecture

```text
Developer
   |
   | git push to main
   v
GitHub Repository
   |
   +------------------------------+
   |                              |
   | CI/CD                        | Infrastructure as Code
   v                              v
GitHub Actions                  Terraform
   |                              |
   +--> Node.js 18               +--> AWS VPC
   +--> npm install              +--> Private/Public subnets
   +--> React build              +--> NAT Gateway
   +--> SonarQube                +--> AWS EKS cluster
   +--> OWASP Dependency-Check   +--> EKS managed node group
   +--> Trivy                    |
   +--> Docker build/push        v
   |                          AWS Infrastructure
   v
Docker Hub
   |
   | SHA-tagged image
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

## Active End-to-End Delivery Chain

```text
Git push
   ↓
GitHub Actions
   ↓
Build + SonarQube + OWASP + Trivy
   ↓
Docker build
   ↓
Docker Hub
   ↓
Update k8s/backend/deployment.yaml with GITHUB_SHA
   ↓
Commit [skip ci]
   ↓
Argo CD detects Git change
   ↓
AWS EKS
   ↓
Backend + MongoDB
   ↓
Prometheus → Grafana / Alertmanager
```

This is the **active connected production-style application delivery path**. Terraform creates the underlying AWS infrastructure; Argo CD manages Kubernetes application/monitoring state from Git.

## Application Stack

| Component | Implementation |
|---|---|
| Frontend | React 17 + React Router + Chakra UI + Axios |
| Backend | Node.js + Express.js |
| Database | MongoDB 7 / Mongoose |
| Real-time communication | Socket.IO |
| Authentication | JWT + bcryptjs |
| UI/animation | Chakra UI, Font Awesome, Framer Motion, Lottie |
| Containerization | Docker |
| Local orchestration | Docker Compose |

The application contains authentication, user search, one-to-one/group chat, chat history, notifications and real-time messaging components. The backend contains controllers, routes, models, authentication/error middleware and MongoDB configuration.

## DevOps / Cloud / Security Stack

| Layer | Technology | Implemented in |
|---|---|---|
| Source control | Git + GitHub | Repository |
| CI/CD | GitHub Actions | `.github/workflows/ci-cd.yml` |
| Code quality | SonarQube | Workflow + `sonar-project.properties` |
| Dependency security | OWASP Dependency-Check | GitHub Actions |
| Filesystem security | Trivy | GitHub Actions |
| Containerization | Docker | `Dockerfile` |
| Container registry | Docker Hub | GitHub Actions |
| Infrastructure as Code | Terraform | `terraform/` |
| Configuration/deployment automation | Ansible | `ansible/` |
| Orchestration | Kubernetes | `k8s/` |
| Cloud platform | AWS EKS | Terraform + AWS |
| GitOps CD | Argo CD | `argocd/` |
| Metrics | Prometheus | `monitoring/` |
| Dashboards | Grafana | `monitoring/` |
| Alerting | Alertmanager | `monitoring/` |
| Kubernetes state metrics | kube-state-metrics | kube-prometheus-stack |
| Node metrics | Node Exporter | kube-prometheus-stack |

## Repository Structure

```text
.
├── .github/workflows/
│   ├── ci-cd.yml                         # Active CI/CD pipeline
│   └── .ci-cd-test                       # Verification marker
├── ansible/
│   ├── ansible.cfg
│   ├── deploy.yml                        # EC2/Docker deployment playbook
│   ├── inventory/hosts
│   └── playbooks/deploy.yml              # Empty placeholder playbook
├── argocd/
│   └── application.yaml                  # Argo CD app for k8s/
├── backend/                              # Node.js/Express backend
├── frontend/                             # React frontend
├── k8s/
│   ├── namespace.yaml
│   ├── backend/deployment.yaml
│   ├── backend/service.yaml
│   ├── mongodb/deployment.yaml
│   └── mongodb/service.yaml
├── monitoring/
│   └── prometheus-grafana-argocd.yaml    # Argo CD monitoring app
├── terraform/
│   ├── main.tf                           # AWS VPC + EKS
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfstate                 # Current local Terraform state artifact
│   ├── terraform.tfstate.backup           # Terraform backup state artifact
│   └── tfplan                             # Saved Terraform plan artifact
├── screenshots/                           # Application screenshots
├── Dockerfile
├── docker-compose.yml
├── sonar-project.properties
├── package.json
├── package-lock.json
├── .dockerignore
├── .gitignore
└── README.md
```

## Terraform — AWS Infrastructure as Code

Terraform is **implemented in the repository** under `terraform/` and is the IaC layer for the AWS environment.

### Terraform provisions

- AWS VPC
- Three Availability Zones
- Public and private subnets
- NAT Gateway (single NAT gateway)
- DNS hostnames/support
- AWS EKS cluster
- EKS managed node group
- EKS add-ons: CoreDNS, kube-proxy and VPC CNI
- Cluster creator admin permissions

The configuration uses:

- AWS provider `~> 6.0`
- `terraform-aws-modules/eks/aws` `~> 21.0`
- `terraform-aws-modules/vpc/aws` `~> 6.0`
- Kubernetes version `1.33`
- Default node type `t3.small`

Default Terraform variables are:

```text
AWS region:   us-east-1
EKS cluster:  mern-chat-devops
```

Terraform outputs include the EKS cluster name, cluster endpoint, VPC ID and private subnet IDs.

### Important Terraform/runtime distinction

Terraform declares the default managed node group with:

```text
min = 1
max = 1
desired = 1
```

During final application deployment verification, the EKS node group was manually scaled to **2 nodes** to solve Kubernetes pod scheduling capacity. Therefore, the currently verified runtime node count and the Terraform desired configuration are not identical. A future `terraform apply` can reconcile the node group back to the declared Terraform configuration unless the Terraform values are updated first.

### Terraform state warning

`terraform.tfstate`, `terraform.tfstate.backup`, and `tfplan` are currently tracked in the repository. For a real production setup, Terraform state should be stored in a secure remote backend with locking and sensitive values must not be committed to Git.

## GitHub Actions CI/CD

The active workflow is `.github/workflows/ci-cd.yml` and runs on pushes to `main`. It has `contents: write` permission because it updates the Kubernetes GitOps manifest after publishing the Docker image.

### Pipeline stages

1. Checkout source with `actions/checkout@v4`.
2. Configure Node.js 18 with npm caching.
3. Install backend dependencies.
4. Install frontend dependencies.
5. Build the React application.
6. Test SonarQube connectivity through `/api/system/status`.
7. Run SonarQube analysis.
8. Run OWASP Dependency-Check.
9. Run Trivy filesystem scanning for `HIGH` and `CRITICAL` findings while ignoring unfixed findings.
10. Authenticate to Docker Hub using GitHub repository secrets.
11. Build Docker image with both `GITHUB_SHA` and `latest` tags.
12. Push both image tags to Docker Hub.
13. Replace the Kubernetes backend image with the immutable `GITHUB_SHA` tag.
14. Commit the Kubernetes change using `[skip ci]`.
15. Push the GitOps manifest back to `main`.

### GitHub repository secrets

The workflow expects:

```text
SONAR_HOST_URL
SONAR_TOKEN
DOCKER_USERNAME
DOCKER_PASSWORD
```

These values are stored as GitHub repository secrets, not in the workflow file.

## SonarQube

A dedicated SonarQube server is running on an EC2 host and GitHub Actions connects to it through `SONAR_HOST_URL` and `SONAR_TOKEN`.

The workflow explicitly tests:

```text
/api/system/status
```

before running the SonarQube scanner.

The repository also contains `sonar-project.properties` with backend/frontend source paths and exclusions for dependencies, builds, coverage and test files. The workflow supplies its own project key/source arguments at scan time, so the workflow configuration is the authoritative CI scan configuration.

## OWASP Dependency-Check

GitHub Actions runs `dependency-check/Dependency-Check_Action@main` against the repository and generates HTML dependency-analysis output during CI.

## Trivy

GitHub Actions runs the Trivy filesystem scanner against the repository with:

```text
scan-type: fs
severity: CRITICAL,HIGH
ignore-unfixed: true
```

## Docker

The root `Dockerfile` uses `node:18-alpine`, installs root/frontend dependencies, copies the application source, builds the React frontend, sets production mode, exposes port `5000`, and starts the backend with `npm start`.

The CI pipeline publishes:

```text
hitheshgowda10docker/chat-app:<GITHUB_SHA>
hitheshgowda10docker/chat-app:latest
```

The Kubernetes deployment consumes the **SHA-tagged image**, not `latest`, which provides a direct mapping between a deployed image and the source commit that produced it.

## Docker Compose — Local Environment

`docker-compose.yml` runs:

- MongoDB 7
- Chat application

The application container receives:

```text
NODE_ENV=production
PORT=5000
MONGO_URI=mongodb://mongodb:27017/chat-app
```

Docker Compose is a **local/single-host deployment option**, not the active EKS production delivery path.

Run locally with:

```bash
docker compose up --build
```

> The current Compose/Kubernetes examples contain development/demo credentials. Do not reuse them for production.

## Ansible — EC2/Docker Automation

Ansible is **present and implemented** under `ansible/`.

`ansible/deploy.yml`:

- Updates APT packages
- Installs Docker
- Starts/enables Docker
- Creates a Docker network
- Removes previous MongoDB/chat containers
- Runs MongoDB 7
- Pulls `hitheshgowda10docker/chat-app:latest`
- Runs the chat application container

The playbook targets the `app` inventory group and is designed for an EC2-style Ubuntu host.

### Ansible relationship to the active pipeline

Ansible is **not currently invoked by GitHub Actions or Argo CD**. It is an alternative/legacy single-host Docker deployment method retained in the repository for automation demonstration.

Active EKS path:

```text
GitHub Actions → Docker Hub → Argo CD → EKS
```

Alternative Ansible path:

```text
Ansible → EC2 host → Docker → MongoDB + Chat App
```

## Kubernetes

The `k8s/` directory is the GitOps source consumed by the `chat-app` Argo CD Application.

### Backend

`k8s/backend/deployment.yaml` runs one backend replica with:

- Docker Hub SHA-tagged image
- `imagePullPolicy: Always`
- `NODE_ENV=production`
- Port `5000`
- MongoDB connection through the `mongodb` Kubernetes Service

`k8s/backend/service.yaml` exposes the backend as an AWS `LoadBalancer` on port `80`, forwarding to container port `5000`.

### MongoDB

`k8s/mongodb/deployment.yaml` runs `mongo:7` and mounts `/data/db` using `emptyDir`.

`k8s/mongodb/service.yaml` exposes MongoDB internally through a `ClusterIP` service.

**Important:** `emptyDir` is ephemeral storage and is not durable production database storage. For hardened production, use a managed/persistent database solution and proper secret management.

## Argo CD — GitOps Continuous Delivery

`argocd/application.yaml` defines the `chat-app` Argo CD Application.

It watches:

```text
Repository: hithesh-27/MERN-CHAT-APP-Devops-Project
Branch:     main
Path:       k8s/
```

Argo CD is configured for:

- Automated sync
- Automatic pruning
- Self-healing
- Namespace creation

The GitOps loop is:

```text
GitHub Actions
      ↓
GitHub main
      ↓
Argo CD
      ↓
Kubernetes manifests
      ↓
AWS EKS
```

The verified application state reached:

```text
SYNC=Synced
HEALTH=Healthy
```

## Prometheus + Grafana + Alertmanager Monitoring

Monitoring is defined as a second Argo CD Application in:

```text
monitoring/prometheus-grafana-argocd.yaml
```

It deploys the Prometheus Community `kube-prometheus-stack` Helm chart version `79.5.0` into the `monitoring` namespace and enables:

- Prometheus
- Grafana
- Alertmanager
- kube-state-metrics
- Node Exporter

Configuration includes:

- Prometheus retention: `7d`
- Prometheus request: `100m CPU / 256Mi memory`
- Prometheus limit: `500m CPU / 1Gi memory`
- Alertmanager request: `50m CPU / 64Mi memory`
- Alertmanager limit: `200m CPU / 256Mi memory`
- Grafana `LoadBalancer` service
- Grafana persistence disabled
- Argo CD automated sync/prune/self-heal

The final EKS verification showed:

```text
Argo CD monitoring:       SYNCED / HEALTHY
Prometheus:                READY 1/1
Alertmanager:              READY 1/1
Prometheus Operator:       Running
Grafana:                   Running
kube-state-metrics:        Running
Node Exporter:             Running on both worker nodes
```

Prometheus and Alertmanager reported `RECONCILED=True` and `AVAILABLE=True` after operator reconciliation.

### Grafana access

Get the current Grafana LoadBalancer endpoint:

```bash
kubectl get svc monitoring-grafana -n monitoring \
  -o jsonpath='http://{.status.loadBalancer.ingress[0].hostname}{"\n"}'
```

Get the current admin password from Kubernetes:

```bash
kubectl get secret monitoring-grafana -n monitoring \
  -o jsonpath='{.data.admin-password}' | base64 -d && echo
```

> The repository currently contains `adminPassword: admin123` as a development/demo Helm value. This is **not production-safe**. Move Grafana credentials to Kubernetes Secrets, AWS Secrets Manager/Parameter Store, External Secrets, or another secret-management mechanism before production use.

### Prometheus CRDs

The large `kube-prometheus-stack` CRDs exceeded Kubernetes client-side annotation limits during Argo CD synchronization. The CRDs were therefore installed server-side during cluster setup, and the Argo CD monitoring Application uses `skipCrds: true`.

This means the monitoring workload is GitOps-managed, while CRD bootstrap is currently a separate cluster prerequisite. A fully reproducible production implementation should version-control and automate this CRD bootstrap step.

## AWS EKS Environment

Verified deployment environment:

```text
Region:        us-east-1
Cluster:       mern-chat-devops
Platform:      AWS EKS
Kubernetes:    1.33
Worker nodes:  2 during final verification
```

The application was verified with two Ready worker nodes after the node group was temporarily scaled from one to two nodes because the original node reached its pod capacity and a backend replica became Pending with `Too many pods`.

## Verification Commands

```bash
# EKS nodes
kubectl get nodes -o wide

# Application pods
kubectl get pods -n chat-app -o wide

# Application services
kubectl get svc -n chat-app

# Running backend image
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

Expected successful Argo CD state:

```text
SYNC=Synced HEALTH=Healthy
```

## Production Hardening / Remaining Gaps

The project is an end-to-end production-style DevOps/GitOps demonstration, but these items should be addressed before calling it hardened enterprise production:

- Remove hard-coded JWT, MongoDB and Grafana demo credentials.
- Use Kubernetes Secrets plus AWS Secrets Manager/Parameter Store or External Secrets.
- Replace MongoDB `emptyDir` with durable managed/persistent storage.
- Use a managed MongoDB service such as MongoDB Atlas or another production database architecture.
- Add readiness and liveness probes to application workloads.
- Add CPU/memory requests and limits to application workloads.
- Add HPA where appropriate.
- Add HTTPS/TLS and a proper domain/Ingress/load-balancer configuration.
- Add PodDisruptionBudgets for critical workloads.
- Add persistent storage for Prometheus/Grafana when long-term retention is required.
- Make Prometheus CRD bootstrap fully reproducible through GitOps/IaC.
- Pin third-party GitHub Actions to reviewed commit SHAs.
- Use separate staging/production environments and protected branches/environments.
- Move Terraform state to a secure remote backend with locking and remove tracked local state/plan artifacts from Git.
- Align Terraform node-group desired/max/min values with the intended runtime capacity.
- Add custom application metrics and ServiceMonitor resources if application-level observability is required.

## Final Summary

Implemented and verified across the repository:

**MERN → Docker → GitHub → GitHub Actions → SonarQube → OWASP Dependency-Check → Trivy → Docker Hub → GitOps manifest update → Argo CD → AWS EKS → Kubernetes → Prometheus → Grafana → Alertmanager**

Infrastructure-as-code and alternative automation are also included:

**Terraform → AWS VPC + EKS**

**Ansible → EC2 + Docker + MongoDB + Chat App (alternative/legacy path)**

The important distinction is that these are **not random independent tools**: the active application delivery chain is connected end-to-end through GitHub Actions, Docker Hub, GitHub GitOps manifests, Argo CD and EKS. Terraform provides the AWS infrastructure layer, while the monitoring stack is connected through its own Argo CD Application. Ansible and Docker Compose are additional deployment paths rather than steps in the active EKS pipeline.
