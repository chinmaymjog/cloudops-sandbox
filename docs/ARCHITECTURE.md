# System Architecture

## Overview

DevOps Lab is a containerized lab environment designed to simulate production-like infrastructure on a single machine. It uses Docker containers and optional Kubernetes (K3s) clusters orchestrated through a central network.

## Architecture Diagram

```
  ┌─────────────────────────────────────────────────────────────┐
  │                    Host Machine (Docker)                     │
  │                                                               │
  │  ┌──────────────────────────────────────────────────────┐   │
  │  │         Docker Network: "control-plane"             │   │
  │  │                                                      │   │
  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────┐  │   │
  │  │  │   Traefik    │  │  Portainer   │  │    wud   │  │   │
  │  │  │ (Rev Proxy)  │  │ (Management) │  │(Updates) │  │   │
  │  │  └──────────────┘  └──────────────┘  └──────────┘  │   │
  │  │                                                      │   │
  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────┐  │   │
  │  │  │ Prometheus   │  │   Grafana    │  │    n8n   │  │   │
  │  │  │ (Metrics)    │  │ (Dashboards) │  │(Workflow)│  │   │
  │  │  └──────────────┘  └──────────────┘  └──────────┘  │   │
  │  │                                                      │   │
  │  │  ┌──────────────┐  ┌──────────────┐                │   │
  │  │  │   MySQL      │  │ PostgreSQL   │                │   │
  │  │  │ (Database)   │  │ (Database)   │                │   │
  │  │  └──────────────┘  └──────────────┘                │   │
  │  │                                                      │   │
  │  └──────────────────────────────────────────────────────┘   │
  │                                                               │
  │  DNS Resolution (via /etc/hosts)                             │
  │  ┌─────────────────────────────────────────────────────┐    │
  │  │ traefik.local -> 127.0.0.1                          │    │
  │  │ portainer.local -> 127.0.0.1                        │    │
  │  │ ... all services routed through Traefik            │    │
  │  └─────────────────────────────────────────────────────┘    │
  └─────────────────────────────────────────────────────────────┘
  ```

## Component Layers

### 1. **Ingress Layer (Traefik)**

- **Role:** Reverse proxy and load balancer
- **Function:** Routes incoming traffic to appropriate services
- **SSL/TLS:** Handles certificate management and termination
- **Configuration:** YAML-based routing rules


### 3. **Container Orchestration Layer**

- **Docker Network:** `control-plane` network connects all containers
- **Docker Compose:** Defines service definitions and dependencies
- **K3d (Optional):** Lightweight Kubernetes for cluster simulation

### 4. **Services Layer**


#### Monitoring & Observability

- **Prometheus:** Time-series metrics database
- **Grafana:** Visualization and dashboarding
- **Application Insights:** Performance monitoring

#### Data Storage

- **MySQL:** Relational database for applications
- **PostgreSQL:** Advanced relational database
- **SQLite:** Embedded database (used by some services)

#### Management & Operations

- **Portainer:** Docker/Kubernetes UI management
- **n8n:** Workflow automation and integrations
- **wud:** Container image update notifications

## Data Flow

### 1. **External Request**

```
External Request → Traefik (Reverse Proxy) → Service Container
```

### 2. **Inter-container Communication**

```
Container A → Docker Network (control-plane) → Container B
```

### 3. **Observability Pipeline**
 
```
Services → Prometheus (scrapes metrics) → Grafana (visualizes)
```

## Network Connectivity

### Docker Network: `control-plane`

```yaml
Name: control-plane
Type: bridge
Subnet: 172.20.0.0/16 # Example CIDR
Services Connected:
  - traefik (172.20.0.2)
  - portainer (172.20.0.3)
  - gitlab (172.20.0.4)
  - ... (dynamically assigned)
```

### DNS Routing

- **Local domain:** `*.lab.local` or custom domain
- **Resolution:** Points to `127.0.0.1` (localhost)
- **Traefik intercepts:** Routes based on hostname rules

## Storage Architecture

### Volume Types

#### Named Volumes (Persistent Data)

```yaml
volumes:
  grafana_data: # Grafana dashboards & datasources
  prometheus_data: # Time-series metrics
  mysql_data: # Database files
  pgsql_data: # Database files
  n8n_data: # Workflows & credentials
  portainer_data: # Configuration & backups
```

#### Bind Mounts (Config Files)

```yaml
volumes:
  - ./conf/:/config/ # Config files from host
  - ./data/:/data/ # Data directory
```

## Resource Allocation

### Minimum Requirements

```
CPU: 4 cores
RAM: 8 GB
Disk: 50 GB (for container images & volumes)
```

### Recommended for Heavy Usage

```
CPU: 6-8 cores
RAM: 16+ GB
Disk: 100+ GB
```

## Security Considerations

### Current Setup

- Services accessible on localhost only
- Basic authentication on Traefik dashboard (optional)
- Keycloak for IAM integration

### Best Practices

- Use `.env` files for secrets (not committed to git)
- Regular backups of volumes
- Keep Docker and images updated (wud service)
- Restrict network access to trusted sources

## Deployment Scenarios

### 1. **Local Development**

- All services run on personal laptop
- Direct access via `service.local` domains
- Perfect for learning and experimentation

### 2. **Remote Deployment** (via GitLab Runner)

- Push to GitLab triggers CI/CD pipeline
- Runner deploys to remote server via SSH
- Automated via `.gitlab-ci.yml`

### 3. **Kubernetes Clusters** (with K3d)

- Deploy services to K3s clusters
- Multiple clusters (dev, prod) on same machine
- Learning Kubernetes without cloud costs

## Scaling Considerations

### Vertical Scaling

- Increase CPU/RAM allocation to Docker
- Adjust service resource limits

### Horizontal Scaling

- Use multiple K3d clusters
- Deploy services to multiple instances
- Load balance with Traefik

---

For detailed service information, see [SERVICES.md](SERVICES.md)
