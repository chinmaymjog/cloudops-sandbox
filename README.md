# 🎮 DevOps Lab
 
[![Docker](https://img.shields.io/badge/Docker-Enabled-2496ED?logo=docker)](https://docker.com)
[![K3s](https://img.shields.io/badge/K3s-Enabled-FFC61C?logo=kubernetes)](https://k3s.io)
[![GitLab CI](https://img.shields.io/badge/GitLab-CI/CD-FC6D26?logo=gitlab)](https://gitlab.com)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
 
A comprehensive local development environment designed for **GitLab CI/CD** workflows. Simulate production-like infrastructure on a single machine using **Docker**, **K3d**, and industry-standard tools like Traefik, Prometheus, Grafana.

**Perfect for:** Learning Kubernetes, practicing CI/CD, monitoring setups, infrastructure-as-code, and DevOps automation.

---

## 📚 Table of Contents

- [🎮 DevOps Lab](#-devops-lab)
  - [📚 Table of Contents](#-table-of-contents)
  - [📋 Quick Start](#-quick-start)
    - [Prerequisites](#prerequisites)
    - [Access Services](#access-services)
  - [🏗️ Architecture](#️-architecture)
    - [Infrastructure Setup](#infrastructure-setup)
    - [🌐 Networking](#-networking)
      - [DNS Configuration](#dns-configuration)
  - [🛠️ Services & Tools](#️-services--tools)
  - [📂 Directory Structure](#-directory-structure)
  - [🚀 Getting Started](#-getting-started)
    - [1. Clone the Repository](#1-clone-the-repository)
    - [2. Review Configuration](#2-review-configuration)
    - [3. Start Services](#3-start-services)
    - [4. Verify Deployment](#4-verify-deployment)
  - [🚚 Deployment](#-deployment)
    - [GitLab CI/CD Pipeline](#gitlab-cicd-pipeline)
    - [CI/CD Variables](#cicd-variables)
  - [💡 Use Cases](#-use-cases)
  - [🤝 Contributing](#-contributing)
  - [📝 License](#-license)
  - [📞 Support](#-support)

---

## 📋 Quick Start

### Prerequisites

- **macOS/Linux** with Docker installed (or [Rancher Desktop](https://rancherdesktop.io) for macOS)
- Minimum: **4 CPU cores, 8GB RAM** allocated to Docker
- `K3d` installed
- Bash shell

### Access Services

Services are accessible at:

- **Traefik Dashboard:** http://traefik.lab.local
 - **Portainer:** http://portainer.lab.local
 - **Prometheus:** http://prometheus.lab.local
 - **Grafana:** http://grafana.lab.local
 - **n8n:** http://n8n.lab.local
 - **WUD:** http://wud.lab.local/

---

## 📚 Overview

This document describes a local development environment, or "lab," designed for practicing DevOps skills. It uses **Docker** and **K3d** to create isolated, interconnected environments for various projects. The setup enables you to simulate a production-like infrastructure on a single machine.

## 🏗️ Architecture

### Infrastructure Setup

The lab is built on a laptop with **Docker** installed. For macOS, **Rancher Desktop** is used as an alternative to Docker Desktop, with at least 4 CPU cores and 8 GB of RAM allocated to it. **K3d**, a lightweight tool for running **K3s** (a stripped-down Kubernetes distribution) in Docker, is installed to create and manage multiple Kubernetes clusters on the same machine. This setup allows for the creation of multiple clusters, like `dev` and `prod`, which can be used to simulate different environments.

### 🌐 Networking

A key component of this lab is the custom **Docker network** named `control-plane`. This network facilitates communication between all containers. The K3d clusters are attached to this network, allowing services within the clusters to communicate with other standalone containers.

#### DNS Configuration

To access services running on the laptop using a custom domain name, DNS entries are configured:

- **For a registered domain:** A DNS record is created (e.g., `*.lab.example.com`) to point to the loopback address `127.0.0.1`. This ensures that traffic for this domain name is routed to the local machine.
- **For a made-up domain:** An entry is added to the `/etc/hosts` file (e.g., `lab.somedomain.com 127.0.0.1`). This method doesn't allow for the use of Let's Encrypt for SSL certificates, as it only works for public domains.

---

## 🛠️ Services & Tools
 
| Service | Purpose | Access |
| --- | --- | --- |
| **Traefik** | Reverse proxy & load balancer for routing traffic | http://traefik.local |
| **Portainer** | Web UI for Docker & Kubernetes management | http://portainer.local |
| **Prometheus** | Metrics collection and time-series database | http://prometheus.local |
| **Grafana** | Visualization and monitoring dashboards | http://grafana.local |
| **MySQL** | Relational database | N/A |
| **PostgreSQL** | Advanced relational database | N/A |
| **n8n** | Workflow automation & integration platform | http://n8n.local |
| **WUD** | Docker image update monitoring | http://wud.local |
 
---
 
## 📂 Directory Structure
 
```
.
├── traefik/              # Reverse proxy & load balancer
├── portainer/            # Container management UI
├── prometheus/           # Metrics database
├── grafana/              # Monitoring dashboards
├── mysql/                # MySQL database
├── pgsql/                # PostgreSQL database
├── n8n/                  # Workflow automation
├── wud/                  # Docker image update monitoring
├── docs/                 # Documentation
├── init.sh               # Setup script
└── README.md             # This file
```

---

## 🚀 Getting Started

### 1. Clone the Repository
 
```bash
# Clone via SSH (Recommended)
git clone git@gitlab.com:your-username/devops-lab.git
cd devops-lab
```
 
### 2. Initialize Environment
 
Run the initialization script to generate your local environment files from templates.
 
```bash
./init.sh
```
 
This will create `.env` files in each service directory (e.g., `services/traefik/.env`).
 
### 3. Configure Secrets
 
Review and edit the generated `.env` files to set your own passwords and domains.
 
```bash
nano services/traefik/.env
# Set CF_API_EMAIL, CF_DNS_API_TOKEN, BASIC_AUTH
```
 
### 4. Start Services
 
Start a specific service using `docker compose`:
 
```bash
cd services/traefik
docker compose up -d
```
 
### 5. Verify Deployment

```bash
docker ps  # List running containers
```

---

## 🧪 Internal Testing (Maintainer Only)
 
This project includes a `.gitlab-ci.yml` configuration used by the maintainer to verify deployments on a private lab environment.
 
### GitLab CI/CD Pipeline
 
The pipeline uses `envsubst` to inject secrets from GitLab Variables into `env.sample` templates, generating temporary `.env` files for deployment to a remote server via SSH.
 
This is **not required** for local usage but serves as a reference for how to deploy this stack using CI/CD.

### 🛡️ Remote Server Setup

If you are using the maintainer's CI/CD pipeline, your remote server MUST be initialized as a Git repository in the target deployment directory (e.g., `/services`) for the `git pull` step to work.

**Initial Setup on Remote Server:**
```bash
mkdir -p /services && cd /services
git init
git remote add origin git@gitlab.com:platforms4105702/tooling/platform-tooling-stack.git
git fetch origin
git checkout -b develop
git reset --mixed origin/develop
git branch --set-upstream-to=origin/develop develop
```

### CI/CD Variables
 
Configure these in GitLab -> Settings -> CI/CD -> Variables:
 
| Variable | Description |
| --- | --- |
| `SSH_PRIVATE_KEY` | Private key for remote access |
| `SSH_UNKNOWN_HOSTS` | Remote server host keys |
| `SSH_USER` | Remote username |
| `CONTROLLER` | Remote IP/Hostname |
| `*_TAG` | specific versions (e.g., `MYSQL_TAG`) |
| `APP_DOMAIN` | Production domain |
| *Service Secrets* | `MYSQL_ROOT_PASSWORD`, `CF_API_EMAIL`, etc. |

---

## 💡 Use Cases

- **Learning Kubernetes** - Practice with K3d clusters
- **CI/CD Experimentation** - Build and test GitLab pipelines
- **Monitoring Practice** - Set up Prometheus & Grafana monitoring
- **IAM Learning** - Configure Keycloak for authentication
- **Workflow Automation** - Automate tasks with n8n
- **Infrastructure as Code** - Define services as Docker Compose

---

## 🤝 Contributing

This is a personal learning project, but improvements are welcome! Feel free to:

- Report issues
- Suggest improvements
- Add new services or configurations

---

## 📝 License

MIT License - See [LICENSE](LICENSE) file for details

---

## 📞 Support

For questions or issues:

1. Check documentation in `docs/`
2. Review service-specific logs
3. Open an issue on GitHub

**Happy DevOps Learning!** 🚀
