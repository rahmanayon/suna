# Quick Deployment Guide

Get Kortix deployed in under 10 minutes! This guide covers the fastest path to production.

## Prerequisites

- Docker and Docker Compose installed
- A server or VPS with 4GB+ RAM
- Domain name (optional but recommended)
- Supabase account (free tier works)
- API keys ready:
  - Anthropic/OpenAI/Groq (LLM provider)
  - Tavily (web search)
  - Firecrawl (web scraping)

## 5-Minute Deployment

### Step 1: Clone Repository (30 seconds)

```bash
git clone https://github.com/kortix-ai/suna.git
cd suna
```

### Step 2: Configure Environment (3 minutes)

```bash
# Copy environment templates
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env
```

**Edit `backend/.env`** - Add these required values:

```bash
# Database (from Supabase dashboard)
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJxxx...
SUPABASE_SERVICE_ROLE_KEY=eyJxxx...
SUPABASE_JWT_SECRET=your-jwt-secret

# LLM Provider (choose one)
ANTHROPIC_API_KEY=sk-ant-xxx
# OR
OPENAI_API_KEY=sk-xxx

# Required services
TAVILY_API_KEY=tvly-xxx
FIRECRAWL_API_KEY=fc-xxx

# Generate secure keys
MCP_CREDENTIAL_ENCRYPTION_KEY=$(openssl rand -base64 32)
TRIGGER_WEBHOOK_SECRET=$(openssl rand -hex 32)
```

**Edit `frontend/.env`** - Add these values:

```bash
NEXT_PUBLIC_ENV_MODE=production
NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJxxx...
NEXT_PUBLIC_BACKEND_URL=http://your-server-ip:8000/v1
NEXT_PUBLIC_URL=http://your-server-ip:3000
```

### Step 3: Deploy (1 minute)

```bash
# Start all services
docker compose up -d

# Verify deployment
docker compose ps
```

### Step 4: Access Your Instance

- **Frontend**: http://your-server-ip:3000
- **Backend API**: http://your-server-ip:8000
- **API Docs**: http://your-server-ip:8000/docs

✅ **Done!** Your Kortix instance is now running.

## One-Line Deploy (Using Helper Script)

```bash
git clone https://github.com/kortix-ai/suna.git && cd suna && ./deploy.sh
```

The interactive script will:
- Check prerequisites
- Guide you through configuration
- Deploy all services
- Show you the management menu

## Post-Deployment Steps

### 1. Set Up Domain (Optional, 5 minutes)

**Point DNS to your server:**
```
Type: A
Name: @
Value: your-server-ip
```

**Install Nginx and SSL:**
```bash
sudo apt install nginx certbot python3-certbot-nginx

# Create Nginx config
sudo nano /etc/nginx/sites-available/kortix
```

Paste this configuration:
```nginx
server {
    listen 80;
    server_name yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /v1 {
        proxy_pass http://localhost:8000/v1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

```bash
# Enable site and get SSL
sudo ln -s /etc/nginx/sites-available/kortix /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
sudo certbot --nginx -d yourdomain.com
```

**Update frontend URL:**
```bash
# Edit frontend/.env
NEXT_PUBLIC_URL=https://yourdomain.com
NEXT_PUBLIC_BACKEND_URL=https://yourdomain.com/v1

# Restart frontend
docker compose restart frontend
```

### 2. Enable Monitoring (Optional, 2 minutes)

Add to `backend/.env`:
```bash
# LLM observability
LANGFUSE_PUBLIC_KEY=pk-lf-xxx
LANGFUSE_SECRET_KEY=sk-lf-xxx
LANGFUSE_HOST=https://cloud.langfuse.com

# User analytics
NEXT_PUBLIC_POSTHOG_KEY=phc-xxx
```

Restart services:
```bash
docker compose restart backend frontend
```

### 3. Set Up Backups (5 minutes)

Create backup script:
```bash
#!/bin/bash
# backup-kortix.sh

BACKUP_DIR="/home/backups/kortix"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup Redis
docker run --rm -v suna_redis_data:/data -v $BACKUP_DIR:/backup alpine \
    tar czf /backup/redis_$DATE.tar.gz -C /data .

# Backup env files (encrypted)
tar czf - backend/.env frontend/.env | \
    openssl enc -aes-256-cbc -salt -pbkdf2 -out $BACKUP_DIR/env_$DATE.tar.gz.enc

# Delete backups older than 7 days
find $BACKUP_DIR -mtime +7 -delete

echo "Backup complete: $BACKUP_DIR"
```

Schedule daily backups:
```bash
chmod +x backup-kortix.sh
crontab -e

# Add this line:
0 2 * * * /home/ubuntu/suna/backup-kortix.sh
```

## Quick Management Commands

### Viewing Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f backend
docker compose logs -f worker
docker compose logs -f frontend
```

### Restarting Services
```bash
# All services
docker compose restart

# Specific service
docker compose restart backend
```

### Updating Kortix
```bash
git pull origin main
docker compose pull
docker compose up -d
```

### Scaling Workers
```bash
# Run 3 worker instances for better performance
docker compose up -d --scale worker=3
```

### Checking Health
```bash
# Service status
docker compose ps

# Resource usage
docker stats

# Backend health
curl http://localhost:8000/health
```

## Common Quick Fixes

### Services Won't Start
```bash
# Check logs
docker compose logs backend

# Common issues:
# 1. Port already in use
sudo lsof -i :3000
sudo lsof -i :8000

# 2. Disk space
df -h

# 3. Memory
free -h

# Fix: Restart
docker compose down
docker compose up -d
```

### Can't Connect to Database
```bash
# Verify Supabase credentials
docker compose exec backend env | grep SUPABASE

# Test connection
docker compose exec backend python -c "from core.db import get_client; print(get_client())"
```

### Frontend Not Loading
```bash
# Check frontend logs
docker compose logs frontend

# Verify environment
docker compose exec frontend env | grep NEXT_PUBLIC

# Rebuild if needed
docker compose build frontend
docker compose up -d frontend
```

## Platform-Specific Quick Deploys

### AWS EC2
```bash
# Launch Ubuntu 22.04 instance (t3.large or larger)
# SSH into instance
ssh -i your-key.pem ubuntu@your-ec2-ip

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker ubuntu

# Deploy Kortix
git clone https://github.com/kortix-ai/suna.git
cd suna
# Configure .env files
docker compose up -d
```

### DigitalOcean Droplet
```bash
# Create Ubuntu 22.04 droplet (4GB+ RAM)
# SSH into droplet
ssh root@your-droplet-ip

# Install Docker
curl -fsSL https://get.docker.com | sh

# Deploy Kortix
git clone https://github.com/kortix-ai/suna.git
cd suna
# Configure .env files
docker compose up -d
```

### Hetzner Cloud
```bash
# Create CX21 or larger instance
# SSH into server
ssh root@your-server-ip

# Install Docker
curl -fsSL https://get.docker.com | sh

# Deploy Kortix
git clone https://github.com/kortix-ai/suna.git
cd suna
# Configure .env files
docker compose up -d
```

## Getting Help Fast

**Logs not helpful?** Check these:

1. Environment variables are set correctly
2. Supabase project is accessible
3. API keys are valid
4. Ports 3000, 8000, 6379 are not in use
5. Docker has enough resources (4GB+ RAM)

**Still stuck?**
- [Discord Community](https://discord.gg/RvFhXUdZ9H) - Fastest support
- [GitHub Issues](https://github.com/kortix-ai/suna/issues) - Bug reports
- [Full Deployment Guide](DEPLOYMENT.md) - Detailed instructions

## Next Steps

Once deployed:

1. ✅ Create your first account at http://your-instance:3000
2. ✅ Create your first AI agent
3. ✅ Configure integrations (optional)
4. ✅ Set up monitoring (recommended for production)
5. ✅ Enable backups (essential for production)

---

**Pro Tip**: Use the `./deploy.sh` script for an interactive deployment and management experience!

For production deployments with advanced features, see the [Full Deployment Guide](DEPLOYMENT.md).
