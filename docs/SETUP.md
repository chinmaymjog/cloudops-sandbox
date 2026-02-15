# Setup Instructions

Step-by-step guide to setting up the DevOps Lab.

## Prerequisites

### System Requirements

- **OS:** macOS, Linux, or Windows (with WSL2)
- **CPU:** Minimum 4 cores (6+ recommended)
- **RAM:** Minimum 8 GB (16+ recommended)
- **Disk:** Minimum 50 GB free space

### Required Software

#### macOS

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Docker (or Rancher Desktop as alternative)
brew install --cask docker
# or
brew install --cask rancher-desktop

# Install K3d for Kubernetes
brew install k3d

# Verify installations
docker --version
k3d version
```

#### Linux (Ubuntu/Debian)

```bash
# Update package manager
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# Install K3d
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Verify installations
docker --version
k3d version
```

#### Windows (WSL2)

```powershell
# Install WSL2
wsl --install

# Install Docker Desktop with WSL2 backend
# https://www.docker.com/products/docker-desktop

# Inside WSL2, follow Linux instructions above
```

## Step 1: Clone the Repository

```bash
# Clone the lab repository
git clone https://github.com/chinmayjog/DevOps-Lab.git
cd DevOps-Lab

# Verify structure
ls -la
# Should see: traefik/, portainer/, gitlab-ce/, etc.
```

## Step 2: Configure Environment Variables
 
We use a standardized environment model. You will copy the *example* file to an *active* `.env` file.
 
### 1. Initialize `.env` files
 
```bash
# Copy templates to active config
for dir in services/*/; do
  if [ -f "$dir/.env.example" ]; then
    cp "$dir/.env.example" "$dir/.env"
  fi
done
```
 
### 2. Configure & Cleanup
 
Edit each `.env` file to set your secrets.
**Important:** For production consistency, we recommend stripping comments and keeping the exact order of keys.
 
```bash
# Example: Editing Traefik
nano services/traefik/.env
```
 
**Required Changes:**
- `TRAEFIK_TAG` (Default: v3.3)
- `CF_API_EMAIL` & `CF_DNS_API_TOKEN` (for Let's Encrypt)
- `BASIC_AUTH` (generate with `htpasswd`)
 
**Example Clean `.env` (Traefik):**
```env
TRAEFIK_TAG=v3.3
APP_DOMAIN=lab.local
CF_API_EMAIL=user@example.com
CF_DNS_API_TOKEN=secret-token
BASIC_AUTH=admin:$$2y$$...
```

## Step 3: Configure DNS

### Option A: Using `/etc/hosts` (Simple, Recommended for Local Development)

```bash
# Edit hosts file
sudo nano /etc/hosts

# Add entries (replace lab.local with your domain)
127.0.0.1 lab.local
127.0.0.1 traefik.lab.local
127.0.0.1 portainer.lab.local
127.0.0.1 gitlab.lab.local
127.0.0.1 grafana.lab.local
127.0.0.1 prometheus.lab.local
127.0.0.1 mysql.lab.local
127.0.0.1 pgsql.lab.local
127.0.0.1 keycloak.lab.local
127.0.0.1 n8n.lab.local
```

### Option B: Using Registered Domain (Advanced)

1. Go to your domain registrar (Namecheap, GoDaddy, etc.)
2. Add DNS A record: `*.lab.yourdomain.com` → Your Server IP
3. Update `APP_DOMAIN` in `.env` files


## Step 4: Verify Docker Setup

```bash
# Check Docker is running
docker --version
docker ps

# Check Docker network
docker network ls

# Create control-plane network (if not exists)
docker network create control-plane

# Verify network
docker network inspect control-plane
```

## Step 5: Start Services

### Using Bootstrap Script (Recommended)

```bash
# Run bootstrap script
bash bootstrap.sh

# Wait for services to start (2-5 minutes)
# Script will:
# - Create Docker network
# - Pull images
# - Start containers
# - Run health checks
```

### Manual Startup

```bash
# Navigate to each service and start

# 1. Start Traefik
cd traefik
docker compose up -d
cd ..

# 2. Start other services
cd portainer && docker compose up -d && cd ..
cd mysql && docker compose up -d && cd ..
cd prometheus && docker compose up -d && cd ..
cd grafana && docker compose up -d && cd ..

# Start remaining services as needed
```

### Monitor Startup

```bash
# View running containers
docker ps

# Check logs for specific service
docker compose -f traefik/docker-compose.yml logs -f

# View all logs
docker compose -f traefik/docker-compose.yml logs
docker compose -f portainer/docker-compose.yml logs
# ... repeat for each service
```

## Step 6: Verify Services are Running

### Check Container Health

```bash
# List all containers
docker ps --all

# Expected output:
# STATUS should be "Up X minutes" for all services
```

### Test Service Access

```bash
# Test DNS resolution
nslookup traefik.lab.local
# Should return: 127.0.0.1

# Test HTTP connectivity
curl -I http://traefik.lab.local
curl -I http://portainer.lab.local
```

### Access Web Interfaces

Open in browser:

| Service    | URL                              | Default Credentials          |
| ---------- | -------------------------------- | ---------------------------- |
| Traefik    | http://traefik.lab.local         | basic auth (from .env)       |
| Portainer  | http://portainer.lab.local:9000  | admin / (set on first login) |
| Prometheus | http://prometheus.lab.local:9090 | N/A                          |
| Grafana    | http://grafana.lab.local:3000    | admin / admin                |
| n8n        | http://n8n.lab.local:5678        | (set on first login)         |

## Step 7: Initial Configuration


### Grafana Setup

1. Access http://grafana.lab.local:3000
2. Login with admin/admin
3. Change default password (Settings → Change Password)
4. Add Prometheus datasource:
   - Configuration → Data Sources → Add
   - URL: `http://prometheus:9090`
   - Save


## Step 8: Verify Full Stack

### Run health check script

```bash
# Create simple health check
cat > health-check.sh << 'EOF'
#!/bin/bash
services=(
  "http://traefik.lab.local"
  "http://portainer.lab.local:9000"
  "http://gitlab.lab.local"
  "http://prometheus.lab.local:9090"
  "http://grafana.lab.local:3000"
)

for service in "${services[@]}"; do
  echo "Checking $service..."
  curl -s -I "$service" | head -n 1
done
EOF

chmod +x health-check.sh
./health-check.sh
```

## Troubleshooting

### Port Already in Use

```bash
# Find process using port (example: 3000)
lsof -i :3000

# Kill process
kill -9 <PID>

# Or use different port in docker-compose.yml
```

### DNS Not Resolving

```bash
# Clear DNS cache (macOS)
sudo dscacheutil -flushcache

# Test DNS
nslookup traefik.lab.local

# Check /etc/hosts is correct
cat /etc/hosts | grep lab.local
```

### Container Won't Start

```bash
# Check logs
docker compose logs <service>

# Check for port conflicts
netstat -tuln | grep LISTEN

# Try pulling fresh image
docker compose pull
docker compose up -d
```

### Out of Memory/Disk Space

```bash
# Check disk space
df -h

# Remove unused images/containers
docker system prune -a

# Check resource allocation
docker stats
```

## Common Tasks

### Restart All Services

```bash
# Stop all services
for dir in traefik portainer gitlab-ce mysql pgsql prometheus grafana; do
  cd $dir
  docker compose down
  cd ..
done

# Start all services
bash bootstrap.sh
```

### Backup Data

```bash
# Backup volumes
docker run --rm \
  -v devopslab_mysql_data:/source \
  -v /path/to/backup:/backup \
  alpine tar czf /backup/mysql-$(date +%Y%m%d).tar.gz -C /source .
```

### View Logs

```bash
# Follow logs
docker compose -f <service>/docker-compose.yml logs -f

# View last 100 lines
docker compose -f <service>/docker-compose.yml logs --tail=100
```

---

For service-specific documentation, see [SERVICES.md](SERVICES.md)
For troubleshooting common issues, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
