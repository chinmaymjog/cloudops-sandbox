# Services Guide

Detailed documentation for each service in the DevOps Playground.

## 🌐 Reverse Proxy & Networking

### Traefik

**Purpose:** Reverse proxy and load balancer for routing external traffic to services

**Key Features:**

- Dynamic service discovery
- SSL/TLS termination
- Dashboard for monitoring
- Support for multiple routing protocols

**Configuration:**

- Location: `traefik/`
- Files: `docker-compose.yml`, `conf/traefik.yml`, `certs/acme.json`
- Environment: `traefik/.env.example`

**Access:**

- Dashboard: `http://traefik.local` (requires basic auth)
- API: `http://traefik.local:8080/api`

**Key Environment Variables:**

```bash
CF_API_EMAIL        # Cloudflare API email (for DNS challenges)
CF_DNS_API_TOKEN    # Cloudflare API token
BASIC_AUTH          # Basic auth credentials (format: user:password)
APP_DOMAIN          # Application domain (e.g., lab.local)
```

**Common Tasks:**

- Add new route: Update `traefik.yml` with new service rule
- Update SSL: Modify `acme.json` or regenerate
- View logs: `docker compose logs traefik`


### Portainer

**Purpose:** Web-based UI for managing Docker containers and Kubernetes clusters

**Key Features:**

- Container & image management
- Registry integration
- Docker & Kubernetes support
- Backup and recovery

**Configuration:**

- Location: `portainer/`
- Files: `docker-compose.yml`, `data/portainer.db`
- Environment: `portainer/.env.example`

**Access:**

- UI: `http://portainer.local:9000`
- Default User: `admin` (set on first login)

**Common Tasks:**

- Manage containers: Start, stop, restart, remove
- View logs: Real-time container output
- Monitor stats: CPU, memory, network usage
- Manage volumes: Create, inspect, manage data

---


## 📊 Monitoring & Observability

### Prometheus

**Purpose:** Time-series metrics database for collecting and storing application metrics

**Key Features:**

- Time-series data storage
- Multi-dimensional metrics
- Powerful query language (PromQL)
- Built-in alerting

**Configuration:**

- Location: `prometheus/`
- Config: `prometheus/conf/prometheus.yml`
- Data: Stored in `prometheus/data/` (TSDB format)

**Access:**

- UI: `http://prometheus.local:9090`
- Query API: `http://prometheus.local:9090/api/v1/query`

**Key Configuration (prometheus.yml):**

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: "docker"
    static_configs:
      - targets: ["localhost:9323"]
```

**Common Tasks:**

- Query metrics: PromQL in web interface
- View targets: Status → Targets
- Check alerts: Alerts section
- Retention settings: Modify `--storage.tsdb.retention.time`

**Popular Metrics to Monitor:**

- `container_cpu_usage_seconds_total` - CPU usage
- `container_memory_usage_bytes` - Memory usage
- `container_network_receive_bytes_total` - Network I/O

---

### Grafana

**Purpose:** Visualization and dashboarding platform for metrics and logs

**Key Features:**

- Beautiful dashboards
- Multi-source data integration
- Alerting and notifications
- User management

**Configuration:**

- Location: `grafana/`
- Dashboards: `grafana/data/dashboards/`
- Datasources: Configured via UI or provisioning
- Plugins: `grafana/data/plugins/`

**Access:**

- UI: `http://grafana.local:3000`
- Default Credentials: `admin` / `admin` (change on first login)

**Setup Steps:**

1. Add Prometheus as datasource: Configuration → Data Sources
2. Import dashboards: + → Import
3. Create custom dashboards: + → Dashboard
4. Configure alerts: Alerts → Notification channels

**Common Dashboards:**

- Docker Stats Dashboard
- Node Exporter Dashboard
- Custom Application Metrics

**Common Tasks:**

- Create dashboard: + → Dashboard → Add panels
- Add visualization: Panel → Choose visualization type
- Set alerts: Alert tab in panel
- Share dashboard: Share button (generate link)

---

## 💾 Databases

### MySQL

**Purpose:** Relational database for applications requiring SQL

**Configuration:**

- Location: `mysql/`
- Files: `docker-compose.yml`
- Data: Stored in `mysql/data/`
- Environment: `mysql/.env.example`

**Access:**

- Host: `mysql` (from other containers)
- Port: `3306`
- Root Password: Set via `MYSQL_ROOT_PASSWORD`

**Connection String:**

```
mysql://root:password@mysql:3306/database
```

**Common Tasks:**

- Connect: `docker compose exec mysql mysql -u root -p`
- Create database: `CREATE DATABASE myapp;`
- Backup: `docker compose exec mysql mysqldump -u root -p --all-databases > backup.sql`
- Restore: `cat backup.sql | docker compose exec -T mysql mysql -u root -p`

---

### PostgreSQL

**Purpose:** Advanced relational database with rich features

**Configuration:**

- Location: `pgsql/`
- Files: `docker-compose.yml`
- Data: Stored in `pgsql/data/`
- Environment: `pgsql/.env.example`

**Access:**

- Host: `pgsql` (from other containers)
- Port: `5432`
- User: `postgres`
- Password: Set via `POSTGRES_PASSWORD`

**Connection String:**

```
postgresql://postgres:password@pgsql:5432/database
```

**Common Tasks:**

- Connect: `docker compose exec pgsql psql -U postgres`
- Create database: `CREATE DATABASE myapp;`
- Backup: `docker compose exec pgsql pg_dump -U postgres -d database > backup.sql`
- Restore: `cat backup.sql | docker compose exec -T pgsql psql -U postgres -d database`

---


## 🤖 Automation & Workflows

### n8n

**Purpose:** Workflow automation and integration platform (like Zapier)

**Key Features:**

- Visual workflow builder
- 400+ integrations
- Scheduling and triggers
- Error handling and retry logic

**Configuration:**

- Location: `n8n/`
- Files: `docker-compose.yml`
- Data: Stored in `n8n/data/` (SQLite by default)
- Environment: `n8n/.env.example`

**Access:**

- UI: `http://n8n.local:5678`

**Common Tasks:**

- Create workflow: + → New Workflow
- Add nodes: Search and drag nodes
- Connect nodes: Link nodes to build workflow
- Test workflow: Execute and view logs
- Schedule workflow: Trigger → Cron

**Example Workflow:**

```
Webhook Trigger → Parse JSON → Send Email → Log Result
```

---

### wud (What's Up Docker)

**Purpose:** Monitor and notify about Docker image updates

**Key Features:**

- Automatic image update detection
- Notification webhooks
- Registry monitoring
- Update scheduling

**Configuration:**

- Location: `wud/`
- Files: `docker-compose.yml`
- Environment: `wud/.env.example`

**Access:**

- API: `http://wud.local:3000/api`

**Common Tasks:**

- Check for updates: API endpoint `/api/images`
- Configure notifications: Set webhook URLs
- Monitor images: View update status in UI

---

## 🔄 Workflow Overview

### Typical DevOps Workflow

```
1. Developer commits code
   ↓
2. GitLab detects push (webhook)
   ↓
3. CI/CD pipeline triggered
   ↓
4. GitLab Runner executes jobs:
   - Build Docker image
   - Run tests
   - Deploy containers
   ↓
5. Services updated
   ↓
6. Prometheus scrapes metrics
   ↓
7. Grafana displays dashboards
   ↓
8. wud detects new image versions
   ↓
9. Notifications via n8n workflows
```

---

For architecture details, see [ARCHITECTURE.md](ARCHITECTURE.md)
For setup instructions, see [SETUP.md](SETUP.md)
