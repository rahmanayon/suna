# Kortix Deployment Checklist

Use this checklist to ensure you've configured everything correctly before deploying Kortix to production.

## Pre-Deployment Checklist

### 1. Infrastructure Setup

- [ ] Server/Cloud instance provisioned (4GB+ RAM, 30GB+ disk)
- [ ] Docker and Docker Compose installed
- [ ] Domain name configured (A record pointing to server)
- [ ] Firewall configured (ports 22, 80, 443 open)
- [ ] SSL certificate ready or Let's Encrypt configured

### 2. Database and Services

- [ ] Supabase project created (cloud or self-hosted)
  - [ ] Database connection string obtained
  - [ ] Anon key obtained
  - [ ] Service role key obtained
  - [ ] JWT secret obtained
- [ ] Redis instance configured
  - [ ] Connection string ready
  - [ ] Password set (if using managed Redis)
  - [ ] Persistence enabled

### 3. API Keys and Credentials

Required services:
- [ ] At least one LLM provider configured:
  - [ ] Anthropic API key (recommended)
  - [ ] OpenAI API key
  - [ ] Groq API key
  - [ ] or other provider
- [ ] Tavily API key (web search)
- [ ] Firecrawl API key (web scraping)

Optional but recommended:
- [ ] Langfuse keys (LLM observability)
- [ ] Stripe keys (if using billing)
- [ ] Composio API key (integrations)
- [ ] PostHog key (analytics)

### 4. Environment Configuration

Backend (`backend/.env`):
- [ ] `ENV_MODE=production`
- [ ] All Supabase credentials configured
- [ ] Redis connection configured
- [ ] LLM provider keys added
- [ ] Required service keys added (Tavily, Firecrawl)
- [ ] Security keys generated:
  ```bash
  MCP_CREDENTIAL_ENCRYPTION_KEY=$(openssl rand -base64 32)
  TRIGGER_WEBHOOK_SECRET=$(openssl rand -hex 32)
  ```

Frontend (`frontend/.env`):
- [ ] `NEXT_PUBLIC_ENV_MODE=production`
- [ ] `NEXT_PUBLIC_SUPABASE_URL` set
- [ ] `NEXT_PUBLIC_SUPABASE_ANON_KEY` set
- [ ] `NEXT_PUBLIC_BACKEND_URL` set to production API URL
- [ ] `NEXT_PUBLIC_URL` set to production frontend URL

### 5. Security Configuration

- [ ] All `.env` files excluded from version control (in `.gitignore`)
- [ ] Strong passwords used for all services
- [ ] API keys stored securely (not in code)
- [ ] CORS configured properly in backend
- [ ] Rate limiting enabled
- [ ] Webhook secrets configured

### 6. Testing

- [ ] Test local deployment with Docker Compose first
- [ ] Verify all services start successfully
- [ ] Test user registration and login
- [ ] Test creating and running an agent
- [ ] Test file upload/download
- [ ] Test web search functionality
- [ ] Check logs for errors

## Deployment Steps

### Quick Docker Compose Deployment

```bash
# 1. Clone repository
git clone https://github.com/kortix-ai/suna.git
cd suna

# 2. Configure environment
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env
# Edit both .env files with your configuration

# 3. Deploy
docker compose up -d

# 4. Verify
docker compose ps
docker compose logs -f
```

### Post-Deployment Verification

- [ ] Frontend accessible at configured URL
- [ ] Backend API responding at `/v1/health`
- [ ] API documentation accessible at `/docs`
- [ ] User can register/login
- [ ] Agent creation works
- [ ] Background jobs processing (check worker logs)
- [ ] Redis connected (check backend logs)
- [ ] Database queries working

## Production Best Practices

### Monitoring Setup

- [ ] Configure application monitoring
  - [ ] Langfuse for LLM tracking
  - [ ] PostHog for user analytics (optional)
- [ ] Set up infrastructure monitoring
  - [ ] CPU and memory usage alerts
  - [ ] Disk space alerts
  - [ ] Docker container health checks
- [ ] Configure log aggregation
  - [ ] Centralized logging (optional)
  - [ ] Log rotation configured

### Backup Strategy

- [ ] Database backup scheduled
  - [ ] Automated daily backups
  - [ ] Backup retention policy defined
  - [ ] Tested restoration procedure
- [ ] Configuration backup
  - [ ] `.env` files backed up securely
  - [ ] Deployment scripts versioned
- [ ] Docker volume backup (Redis data)

### Performance Optimization

- [ ] CDN configured for static assets (optional)
- [ ] Reverse proxy configured (Nginx/Caddy)
- [ ] Gzip/Brotli compression enabled
- [ ] Resource limits set appropriately
- [ ] Connection pooling configured

### Security Hardening

- [ ] SSL/TLS certificate installed and auto-renewal configured
- [ ] Security headers configured (HSTS, CSP, etc.)
- [ ] Regular dependency updates scheduled
- [ ] Security scanning enabled
- [ ] Intrusion detection configured (optional)

## Scaling Checklist

When you need to scale:

- [ ] Load balancer configured
- [ ] Multiple backend instances deployed
- [ ] Worker scaling configured (`docker compose up -d --scale worker=3`)
- [ ] Database connection pooling enabled
- [ ] Redis cluster or Sentinel configured (for HA)
- [ ] CDN for static assets
- [ ] Database read replicas (if needed)

## Maintenance Schedule

Weekly:
- [ ] Review application logs for errors
- [ ] Check resource usage (CPU, memory, disk)
- [ ] Monitor API response times

Monthly:
- [ ] Update dependencies
- [ ] Review and rotate API keys if needed
- [ ] Test backup restoration
- [ ] Review security alerts

Quarterly:
- [ ] Security audit
- [ ] Performance optimization review
- [ ] Disaster recovery drill

## Troubleshooting Quick Checks

If something goes wrong:

```bash
# Check service status
docker compose ps

# View logs
docker compose logs -f backend
docker compose logs -f worker
docker compose logs -f frontend

# Check resource usage
docker stats

# Verify environment variables
docker compose exec backend env | grep SUPABASE
docker compose exec backend env | grep REDIS

# Test Redis connection
docker compose exec redis redis-cli ping

# Restart services
docker compose restart

# Full restart
docker compose down && docker compose up -d
```

## Support Resources

- [ ] Documentation bookmarked: [DEPLOYMENT.md](DEPLOYMENT.md)
- [ ] Discord community joined: https://discord.gg/RvFhXUdZ9H
- [ ] GitHub issues tracked: https://github.com/kortix-ai/suna/issues

## Sign-off

Deployment completed by: ________________  
Date: ________________  
Environment: [ ] Staging [ ] Production  
Verified by: ________________  

---

**Note:** Keep this checklist updated as your deployment evolves. Store it securely as part of your deployment documentation.
