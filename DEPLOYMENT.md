# Kortix Deployment Guide

This guide covers various deployment options for the Kortix AI agent platform, from local Docker Compose setups to production cloud deployments.

## Table of Contents

- [Quick Start with Docker Compose](#quick-start-with-docker-compose)
- [Environment Configuration](#environment-configuration)
- [Cloud Deployment Options](#cloud-deployment-options)
  - [AWS Deployment](#aws-deployment)
  - [DigitalOcean Deployment](#digitalocean-deployment)
  - [General VPS Deployment](#general-vps-deployment)
- [Production Best Practices](#production-best-practices)
- [Monitoring and Maintenance](#monitoring-and-maintenance)
- [Troubleshooting](#troubleshooting)

## Quick Start with Docker Compose

The easiest way to deploy Kortix is using Docker Compose. This works for local development, testing, and small-scale production deployments.

### Prerequisites

- Docker Engine 20.10+ and Docker Compose v2.0+
- At least 4GB RAM and 20GB disk space
- A Supabase project (cloud or self-hosted)
- API keys for required services (see [Environment Configuration](#environment-configuration))

### Step 1: Clone and Configure

```bash
# Clone the repository
git clone https://github.com/kortix-ai/suna.git
cd suna

# Copy environment files
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env
```

### Step 2: Configure Environment Variables

Edit `backend/.env` and `frontend/.env` with your configuration. See [Environment Configuration](#environment-configuration) for details.

**Required minimum configuration:**

```bash
# backend/.env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
SUPABASE_JWT_SECRET=your_jwt_secret
ANTHROPIC_API_KEY=your_anthropic_key  # or another LLM provider
TAVILY_API_KEY=your_tavily_key
FIRECRAWL_API_KEY=your_firecrawl_key
```

```bash
# frontend/.env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key
NEXT_PUBLIC_BACKEND_URL=http://localhost:8000/v1
NEXT_PUBLIC_URL=http://localhost:3000
```

### Step 3: Deploy with Docker Compose

```bash
# Build and start all services
docker compose up -d

# View logs
docker compose logs -f

# Check service status
docker compose ps
```

Your Kortix instance will be available at:
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs

### Managing Your Deployment

```bash
# Stop services
docker compose down

# Restart services
docker compose restart

# Update to latest version
git pull
docker compose pull
docker compose up -d

# View logs for a specific service
docker compose logs -f backend
docker compose logs -f frontend
docker compose logs -f worker
```

## Environment Configuration

### Backend Environment Variables

#### Database (Required)

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
SUPABASE_JWT_SECRET=your_jwt_secret
```

#### Redis (Required for background jobs)

```bash
REDIS_HOST=redis          # Use "redis" with Docker Compose
REDIS_PORT=6379
REDIS_PASSWORD=           # Optional, recommended for production
REDIS_SSL=false           # Set to true for cloud Redis
```

#### LLM Providers (At least one required)

```bash
ANTHROPIC_API_KEY=sk-ant-...        # Recommended
OPENAI_API_KEY=sk-...
GROQ_API_KEY=gsk_...
OPENROUTER_API_KEY=sk-or-...
GEMINI_API_KEY=...
XAI_API_KEY=...
```

#### Data & Search (Required)

```bash
TAVILY_API_KEY=tvly-...             # Required for web search
FIRECRAWL_API_KEY=fc-...            # Required for web scraping
RAPID_API_KEY=...                   # Optional
```

#### Security (Recommended)

```bash
MCP_CREDENTIAL_ENCRYPTION_KEY=$(openssl rand -base64 32)
TRIGGER_WEBHOOK_SECRET=$(openssl rand -hex 32)
```

#### Optional Services

```bash
# Observability
LANGFUSE_PUBLIC_KEY=pk-lf-...
LANGFUSE_SECRET_KEY=sk-lf-...
LANGFUSE_HOST=https://cloud.langfuse.com

# Billing
STRIPE_SECRET_KEY=sk_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Integrations
COMPOSIO_API_KEY=...
EXA_API_KEY=...
CHUNKR_API_KEY=...
```

### Frontend Environment Variables

```bash
NEXT_PUBLIC_ENV_MODE=production     # or staging
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key
NEXT_PUBLIC_BACKEND_URL=https://api.yourdomain.com/v1
NEXT_PUBLIC_URL=https://yourdomain.com
NEXT_PUBLIC_GOOGLE_CLIENT_ID=...    # Optional
NEXT_PUBLIC_POSTHOG_KEY=...         # Optional analytics
```

## Cloud Deployment Options

### AWS Deployment

Kortix can be deployed to AWS using several approaches:

#### Option 1: AWS ECS (Elastic Container Service) - Production Ready

This is the recommended approach for production deployments.

**Prerequisites:**
- AWS CLI configured
- ECS cluster created
- ECR repositories for images
- Application Load Balancer configured
- RDS or Supabase for database
- ElastiCache Redis cluster

**Automated Deployment:**

The repository includes GitHub Actions workflows that automatically deploy to AWS ECS when code is pushed to the `PRODUCTION` branch.

**Manual ECS Setup:**

1. **Create ECR Repositories:**
```bash
aws ecr create-repository --repository-name kortix-backend --region us-west-2
aws ecr create-repository --repository-name kortix-frontend --region us-west-2
```

2. **Build and Push Images:**
```bash
# Login to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin YOUR_ACCOUNT.dkr.ecr.us-west-2.amazonaws.com

# Build and push backend
cd backend
docker build -t kortix-backend .
docker tag kortix-backend:latest YOUR_ACCOUNT.dkr.ecr.us-west-2.amazonaws.com/kortix-backend:latest
docker push YOUR_ACCOUNT.dkr.ecr.us-west-2.amazonaws.com/kortix-backend:latest

# Build and push frontend
cd ../frontend
docker build -t kortix-frontend .
docker tag kortix-frontend:latest YOUR_ACCOUNT.dkr.ecr.us-west-2.amazonaws.com/kortix-frontend:latest
docker push YOUR_ACCOUNT.dkr.ecr.us-west-2.amazonaws.com/kortix-frontend:latest
```

3. **Create ECS Task Definitions and Services:**

Use the AWS Console or infrastructure-as-code tools like Terraform or CloudFormation to create:
- Task definitions for backend, worker, and frontend
- ECS services with appropriate resource allocation
- Service auto-scaling policies
- Load balancer target groups

4. **Configure Environment Variables:**

Store sensitive environment variables in AWS Systems Manager Parameter Store or Secrets Manager:

```bash
aws secretsmanager create-secret --name kortix/backend/env \
    --secret-string file://backend/.env \
    --region us-west-2
```

#### Option 2: AWS EC2 with Docker Compose

For smaller deployments, you can use EC2 instances with Docker Compose.

**Setup:**

1. **Launch EC2 Instance:**
   - Ubuntu 22.04 LTS or Amazon Linux 2023
   - t3.large or larger (4GB+ RAM recommended)
   - 30GB+ EBS volume
   - Security group allowing ports 22, 80, 443

2. **Install Docker:**
```bash
# SSH into your instance
ssh -i your-key.pem ubuntu@your-instance-ip

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

3. **Deploy Kortix:**
```bash
# Clone repository
git clone https://github.com/kortix-ai/suna.git
cd suna

# Configure environment
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env
nano backend/.env  # Edit configuration
nano frontend/.env # Edit configuration

# Start services
docker compose up -d
```

4. **Configure Reverse Proxy (Optional but recommended):**

Install Nginx or Caddy as a reverse proxy:

```bash
sudo apt install nginx

# Example Nginx configuration
sudo nano /etc/nginx/sites-available/kortix
```

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
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/kortix /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

5. **Setup SSL with Let's Encrypt:**
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
```

### DigitalOcean Deployment

#### Option 1: DigitalOcean App Platform

DigitalOcean App Platform provides a PaaS solution for containerized applications.

**Steps:**

1. **Prepare Docker Images:**
   - Build and push your images to a container registry (Docker Hub, GHCR, or DigitalOcean Container Registry)

2. **Create App:**
   - Go to DigitalOcean Console → Apps → Create App
   - Choose "Docker Hub" or your registry
   - Add three components:
     - Backend (kortix-backend image, port 8000)
     - Worker (kortix-backend image with custom run command)
     - Frontend (kortix-frontend image, port 3000)

3. **Configure Environment Variables:**
   - Add all required environment variables in the App Platform console
   - Use DigitalOcean Managed Database for PostgreSQL (via Supabase)
   - Use DigitalOcean Managed Redis

4. **Deploy:**
   - Review and deploy
   - App Platform will handle SSL, load balancing, and auto-scaling

#### Option 2: DigitalOcean Droplet

Similar to AWS EC2 deployment:

1. **Create Droplet:**
   - Ubuntu 22.04 LTS
   - 4GB+ RAM (Production or higher)
   - Enable backups

2. **Follow EC2 Docker Compose instructions above**

### General VPS Deployment

Kortix can be deployed on any VPS provider (Linode, Vultr, Hetzner, etc.).

**Requirements:**
- Ubuntu 20.04+ or Debian 11+
- 4GB RAM minimum (8GB+ recommended for production)
- 30GB+ disk space
- Root or sudo access

**Deployment Steps:**

1. **Initial Server Setup:**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install basic tools
sudo apt install -y curl git ufw

# Configure firewall
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

2. **Install Docker:**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
```

3. **Clone and Deploy:**
```bash
git clone https://github.com/kortix-ai/suna.git
cd suna

# Configure
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env
nano backend/.env
nano frontend/.env

# Deploy
docker compose up -d
```

4. **Setup Domain and SSL:**
   - Point your domain's A record to your server's IP
   - Follow the Nginx + Let's Encrypt setup from AWS EC2 section

## Production Best Practices

### 1. Security

**Environment Variables:**
- Never commit `.env` files to version control
- Use secrets management (AWS Secrets Manager, HashiCorp Vault, etc.)
- Rotate API keys regularly
- Use strong random values for encryption keys:
  ```bash
  openssl rand -base64 32
  ```

**Network Security:**
- Use firewalls (AWS Security Groups, UFW, etc.)
- Only expose necessary ports (80, 443)
- Keep port 8000 (backend API) internal if using a reverse proxy
- Enable SSL/TLS for all public endpoints
- Use VPC/private networks for database and Redis

**Application Security:**
- Keep dependencies updated
- Enable CORS restrictions in production
- Use rate limiting
- Implement proper authentication and authorization
- Regular security audits

### 2. Scalability

**Horizontal Scaling:**
- Run multiple backend workers for parallel processing
- Use load balancers for frontend and API
- Scale Redis for high-throughput scenarios

**Resource Allocation:**
- Backend: 2-4 CPU cores, 4-8GB RAM per instance
- Worker: 2 CPU cores, 2-4GB RAM per instance
- Frontend: 1-2 CPU cores, 2GB RAM per instance
- Redis: 1-2GB RAM minimum

**Docker Compose Scaling:**
```bash
# Scale worker processes
docker compose up -d --scale worker=3
```

### 3. Database and Storage

**Supabase:**
- Use a production-tier Supabase plan
- Enable point-in-time recovery
- Regular backups
- Connection pooling (PgBouncer)

**Redis:**
- Enable persistence (AOF or RDB)
- Use Redis Sentinel or Cluster for high availability
- Monitor memory usage
- Set appropriate eviction policies

### 4. Monitoring and Logging

**Application Monitoring:**
- Set up Langfuse for LLM observability
- Use PostHog for user analytics
- Monitor API response times and error rates

**Infrastructure Monitoring:**
- CPU, memory, and disk usage
- Docker container health
- Network traffic and latency

**Logging:**
```bash
# Configure log rotation
docker compose logs --tail=1000 > logs/app.log

# Set up centralized logging (optional)
# Use tools like Grafana Loki, ELK stack, or cloud solutions
```

### 5. Backup and Disaster Recovery

**Database Backups:**
- Automated daily backups
- Store backups off-site
- Test restoration procedures regularly

**Configuration Backups:**
- Version control for all configuration files (excluding secrets)
- Document deployment procedures
- Keep encrypted backups of environment variables

**Docker Volumes:**
```bash
# Backup Redis data
docker run --rm -v suna_redis_data:/data -v $(pwd):/backup alpine tar czf /backup/redis-backup.tar.gz -C /data .

# Restore Redis data
docker run --rm -v suna_redis_data:/data -v $(pwd):/backup alpine tar xzf /backup/redis-backup.tar.gz -C /data
```

### 6. Performance Optimization

**Frontend:**
- Enable CDN for static assets
- Optimize images and bundle sizes
- Use HTTP/2 and compression

**Backend:**
- Connection pooling for database
- Cache frequently accessed data
- Optimize database queries
- Use async operations where possible

**Redis:**
- Use pipelining for batch operations
- Set appropriate memory limits
- Monitor slow queries

### 7. Updates and Maintenance

**Update Strategy:**
```bash
# Pull latest changes
git pull origin main

# Backup before updating
docker compose down
# Backup volumes and database

# Update and restart
docker compose pull
docker compose up -d

# Verify deployment
docker compose ps
docker compose logs -f
```

**Zero-Downtime Deployments:**
- Use blue-green deployment strategy
- Or rolling updates with load balancer
- Always test in staging first

## Monitoring and Maintenance

### Health Checks

**Backend Health Check:**
```bash
curl http://localhost:8000/health
```

**Check Service Status:**
```bash
docker compose ps
```

**View Resource Usage:**
```bash
docker stats
```

### Common Maintenance Tasks

**Update Dependencies:**
```bash
# Backend
cd backend
uv lock --upgrade

# Frontend
cd frontend
npm update
```

**Clean Up Docker Resources:**
```bash
# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Full cleanup (careful!)
docker system prune -a --volumes
```

**Database Maintenance:**
- Regular VACUUM operations on PostgreSQL
- Index optimization
- Monitor query performance

## Troubleshooting

### Services Won't Start

**Check Logs:**
```bash
docker compose logs backend
docker compose logs worker
docker compose logs frontend
```

**Common Issues:**
- Missing or incorrect environment variables
- Port conflicts (another service using 3000, 8000, or 6379)
- Insufficient resources (RAM, disk space)
- Database connection issues

**Solutions:**
```bash
# Check port availability
sudo lsof -i :3000
sudo lsof -i :8000
sudo lsof -i :6379

# Check disk space
df -h

# Check memory
free -h

# Restart services
docker compose down
docker compose up -d
```

### Backend Connection Issues

**Verify Environment Variables:**
```bash
docker compose exec backend env | grep SUPABASE
docker compose exec backend env | grep REDIS
```

**Test Database Connection:**
```bash
docker compose exec backend python -c "from core.db import get_client; print(get_client())"
```

**Test Redis Connection:**
```bash
docker compose exec redis redis-cli ping
```

### Performance Issues

**Monitor Resource Usage:**
```bash
docker stats --no-stream
```

**Check Backend Performance:**
- Review API logs for slow endpoints
- Monitor database query times
- Check Redis hit rates
- Review LLM API latency

**Scale Services:**
```bash
# Add more worker instances
docker compose up -d --scale worker=4
```

### Frontend Build Failures

**Common Causes:**
- Node version mismatch
- Missing environment variables
- Out of memory during build

**Solutions:**
```bash
# Clear build cache
docker compose build --no-cache frontend

# Increase Docker memory limit in Docker Desktop settings
# Or add swap space on Linux
```

### Database Migration Issues

**Check Migration Status:**
```bash
cd backend
npx supabase status
```

**Apply Migrations:**
```bash
cd backend
npx supabase db push
```

## Additional Resources

- [Kortix Documentation](https://github.com/kortix-ai/suna)
- [Docker Documentation](https://docs.docker.com/)
- [Supabase Documentation](https://supabase.com/docs)
- [AWS ECS Guide](https://docs.aws.amazon.com/ecs/)
- [DigitalOcean App Platform](https://docs.digitalocean.com/products/app-platform/)

## Getting Help

If you encounter issues:

1. Check the [GitHub Issues](https://github.com/kortix-ai/suna/issues)
2. Join the [Discord Community](https://discord.gg/RvFhXUdZ9H)
3. Review logs with `docker compose logs -f`
4. Create a new issue with:
   - Deployment method
   - Error messages
   - Environment (OS, Docker version, etc.)
   - Steps to reproduce

---

**Note:** This deployment guide assumes you're using the latest version from the main branch. For production deployments, consider using stable release tags.
