# Troubleshooting Guide

Solutions for common issues and problems in the DevOps Lab.

## Network & DNS Issues

### ❌ DNS Resolution Not Working

**Symptoms:** `nslookup service.lab.local` fails

**Solutions:**

1. **Verify `/etc/hosts` entries:**
 
   ```bash
   cat /etc/hosts | grep lab.local
   # Should show: 127.0.0.1 lab.local
   ```
 
2. **Clear DNS cache (macOS):**
 
   ```bash
   sudo dscacheutil -flushcache
   ```
 
3. **Manually add to `/etc/hosts`:**
   ```bash
   sudo nano /etc/hosts
   # Add: 127.0.0.1 traefik.lab.local portainer.lab.local ...
   ```

---

### ❌ Cannot Access Service at `service.lab.local`

**Symptoms:** Browser shows "This site can't be reached"

**Solutions:**

1. **Verify DNS is resolving:**

   ```bash
   ping -c 3 traefik.lab.local
   # Should get ICMP responses
   ```

2. **Check Traefik is running:**

   ```bash
   docker compose -f services/traefik/docker-compose.yml ps
   # Should show: Up X minutes
   ```

3. **Check container logs:**

   ```bash
   docker compose -f services/traefik/docker-compose.yml logs -f
   ```

4. **Verify network connectivity:**

   ```bash
   curl -v http://traefik.lab.local
   # Should show connection attempt
   ```

5. **Check `/etc/hosts` pointing to localhost:**
   ```bash
   cat /etc/hosts | grep "127.0.0.1"
   ```

---

## Container Issues

### ❌ Container Won't Start

**Symptoms:** `docker compose up -d` shows container exited

**Solutions:**

1. **Check container logs:**

   ```bash
   docker compose logs <service-name>
   ```

2. **Look for common errors:**

   - `Bind for 0.0.0.0:XXXX failed` → Port already in use
   - `Cannot connect to X` → Dependency not running
   - `No space left on device` → Disk full

3. **Verify dependencies are running:**

   ```bash
   docker ps | grep -E "mysql|pgsql"
   # Should show required services
   ```

4. **Check resource limits:**

   ```bash
   docker stats
   # Look for high CPU/Memory
   ```

5. **Try removing and recreating:**
   ```bash
   docker compose down -v  # Remove volumes too
   docker compose pull
   docker compose up -d
   ```

---

### ❌ Port Already in Use

**Symptoms:** Error like "Address already in use"

**Solutions:**

1. **Find process using port:**

   ```bash
   # macOS/Linux
   lsof -i :<PORT>
   # Example: lsof -i :3306
   ```

2. **Kill the process:**

   ```bash
   kill -9 <PID>
   ```

3. **Or change port in docker-compose.yml:**

   ```yaml
   ports:
     - "3307:3306" # Change from 3306 to 3307
   ```

4. **Check all ports in use:**
   ```bash
   netstat -tuln | grep LISTEN
   ```

---

### ❌ Container Crashes Repeatedly

**Symptoms:** Container keeps restarting

**Solutions:**

1. **Increase logs output:**

   ```bash
   docker compose logs --tail=50 <service>
   ```

2. **Check for `FATAL` errors:**

   ```bash
   docker compose logs | grep -i "fatal\|error\|panic"
   ```

3. **Verify environment variables:**

   ```bash
   docker inspect <container-id> | grep -A 20 "Env"
   ```

4. **Check disk space:**
   ```bash
   df -h
   # If < 1GB available, clean up
   docker system prune -a
   ```

---

## Database Issues

### ❌ MySQL Connection Refused

**Symptoms:** "Can't connect to MySQL server"

**Solutions:**

1. **Verify MySQL is running:**

   ```bash
   docker compose -f mysql/docker-compose.yml ps
   ```

2. **Check password:**

   ```bash
   # Test connection
   docker compose -f mysql/docker-compose.yml exec mysql \
     mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SELECT 1;"
   ```

3. **Check MySQL logs:**

   ```bash
   docker compose -f mysql/docker-compose.yml logs
   ```

4. **Verify network:**

   ```bash
   docker network inspect control-plane
   # Verify mysql container is in the network
   ```

5. **Reset password:**

   ```bash
   # Stop MySQL
   docker compose -f mysql/docker-compose.yml down

   # Remove volume
   docker volume rm devopslab_mysql_data

   # Update .env with new password
   nano mysql/.env

   # Restart
   docker compose -f mysql/docker-compose.yml up -d
   ```

---

### ❌ PostgreSQL Connection Issues

**Symptoms:** "psql: could not connect to server"

**Solutions:**

1. **Check PostgreSQL is running:**

   ```bash
   docker compose -f pgsql/docker-compose.yml ps
   ```

2. **Test connection:**

   ```bash
   docker compose -f pgsql/docker-compose.yml exec pgsql \
     psql -U postgres -c "SELECT 1;"
   ```

3. **Check connection string:**

   ```bash
   # Format: postgresql://user:password@host:port/database
   postgresql://postgres:password@pgsql:5432/postgres
   ```

4. **View logs:**
   ```bash
   docker compose -f pgsql/docker-compose.yml logs
   ```

---

## Service-Specific Issues


### ❌ Grafana Dashboard Empty

**Symptoms:** No data in Grafana graphs

**Solutions:**

1. **Verify Prometheus datasource:**

   - Grafana → Configuration → Data Sources
   - Click Prometheus → Test

2. **Check Prometheus is scraping:**

   ```bash
   # Access Prometheus UI
   http://prometheus.lab.local:9090
   # Status → Targets (should show targets)
   ```

3. **Verify metrics are being collected:**

   ```bash
   # In Prometheus, query:
   # Count of scraped metrics
   count(up) > 0
   ```

4. **Wait for data collection:**
   - Prometheus collects metrics every 15 seconds
   - Dashboard needs 2-3 minutes to show data

---

### ❌ Portainer Shows No Containers

**Symptoms:** Portainer UI is empty or shows errors

**Solutions:**

1. **Reconnect Docker socket:**

   - Portainer → Home → Connect
   - Select "Docker"
   - Click Connect

2. **Verify Docker socket is mounted:**

   ```bash
   docker compose -f portainer/docker-compose.yml config | grep socket
   ```

3. **Check Docker permissions:**

   ```bash
   docker ps
   # Should work without sudo errors
   ```

4. **Restart Portainer:**
   ```bash
   docker compose -f portainer/docker-compose.yml restart
   ```

---


## Performance Issues

### ❌ Slow Container Startup

**Symptoms:** Services take > 5 minutes to start

**Solutions:**

1. **Check resource availability:**

   ```bash
   docker stats
   # CPU should not be at 100%
   # Memory should be available
   ```

2. **Increase Docker resources:**

   - Docker Desktop → Settings → Resources
   - Increase CPU cores and RAM allocation

3. **Check disk speed:**

   ```bash
   # Linux: Check I/O
   iostat -x 1 5
   ```

4. **Enable BuildKit for faster builds:**
   ```bash
   export DOCKER_BUILDKIT=1
   docker compose build
   ```

---

### ❌ High CPU/Memory Usage

**Symptoms:** System slow, fans running loud

**Solutions:**

1. **Identify resource hog:**

   ```bash
   docker stats --no-stream
   ```

2. **Check service logs:**

   ```bash
   docker compose -f <service>/docker-compose.yml logs
   ```

3. **Reduce polling intervals (if applicable):**

   - Edit prometheus.yml
   - Increase `scrape_interval` (slower data collection)

4. **Stop unnecessary services:**

   ```bash
   docker compose -f <service>/docker-compose.yml down
   ```

5. **Clean up old images/containers:**
   ```bash
   docker system prune -a
   ```

---

## Disk Space Issues

### ❌ Low Disk Space

**Symptoms:** "No space left on device"

**Solutions:**

1. **Check disk usage:**

   ```bash
   df -h
   du -sh /var/lib/docker/*
   ```

2. **Clean up Docker:**

   ```bash
   # Remove unused images
   docker image prune -a

   # Remove unused containers
   docker container prune -a

   # Remove unused volumes
   docker volume prune -a

   # Complete cleanup
   docker system prune -a --volumes
   ```

3. **Backup and remove old data:**

   ```bash
   # Backup MySQL
   docker compose -f mysql/docker-compose.yml exec mysql \
     mysqldump -u root -p --all-databases > backup.sql

   # Remove old volumes
   docker volume rm <volume-name>
   ```

---

## Log Analysis

### View Logs for Multiple Services

```bash
# All services
for dir in */; do
  echo "=== $dir ==="
  docker compose -f "$dir/docker-compose.yml" logs --tail=10
done

# Specific service
docker compose -f mysql/docker-compose.yml logs -f --tail=50

# By time
docker compose logs --since 10m  # Last 10 minutes
docker compose logs --until 1m   # Stop 1 minute ago
```

---

## Quick Diagnostics

### Run Full Health Check

```bash
#!/bin/bash
echo "=== Docker ==="
docker --version
docker ps

echo -e "\n=== Network ==="
docker network ls | grep control-plane

echo -e "\n=== DNS ==="
nslookup traefik.lab.local

echo -e "\n=== Services ==="
for service in traefik portainer n8n mysql pgsql prometheus grafana wud; do
  status=$(docker compose -f $service/docker-compose.yml ps -q | wc -l)
  echo "$service: $status containers"
done

echo -e "\n=== Resources ==="
docker stats --no-stream --all
```

---

## Contact & Support

- Check logs: `docker compose logs <service>`
- Review service docs: See [SERVICES.md](SERVICES.md)
- Check GitHub issues: Report problems
- Review configuration: See [SETUP.md](SETUP.md)

---

For more information, see:

- [ARCHITECTURE.md](ARCHITECTURE.md) - System design
- [SERVICES.md](SERVICES.md) - Service details
- [SETUP.md](SETUP.md) - Setup instructions
