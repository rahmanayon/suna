# Kortix Deployment Overview

This document provides an overview of all deployment resources available for Kortix.

## 📚 Documentation Structure

### For Quick Deployments
- **[QUICK_DEPLOY.md](../QUICK_DEPLOY.md)** - Get deployed in under 10 minutes
  - 5-minute deployment guide
  - One-line deploy command
  - Platform-specific quick starts
  - Common quick fixes

### For Production Deployments
- **[DEPLOYMENT.md](../DEPLOYMENT.md)** - Comprehensive deployment guide (18KB)
  - Docker Compose deployment
  - AWS deployment (ECS, EC2)
  - DigitalOcean deployment
  - General VPS deployment
  - Production best practices
  - Security guidelines
  - Monitoring and maintenance
  - Troubleshooting

### For Deployment Planning
- **[DEPLOYMENT_CHECKLIST.md](../DEPLOYMENT_CHECKLIST.md)** - Pre and post-deployment checklist
  - Infrastructure setup checklist
  - Configuration verification
  - Post-deployment validation
  - Maintenance schedule
  - Backup strategy

## 🛠️ Deployment Tools

### Interactive Deployment Script
- **[deploy.sh](../deploy.sh)** - Interactive deployment manager (executable)
  - Menu-driven interface
  - Deploy/stop/restart services
  - View logs by service
  - Scale workers
  - Backup data
  - Update and redeploy

Usage:
```bash
./deploy.sh
```

### Docker Compose
- **[docker-compose.yaml](../docker-compose.yaml)** - Production-ready compose file
  - Backend API service
  - Background worker service (scalable)
  - Frontend service
  - Redis service
  - Health checks and dependencies

## 🚀 Quick Start Paths

### Path 1: Fastest Deploy (5 minutes)
```bash
git clone https://github.com/kortix-ai/suna.git
cd suna
./deploy.sh
# Follow the interactive prompts
```

### Path 2: Manual Deploy (10 minutes)
```bash
# Clone and configure
git clone https://github.com/kortix-ai/suna.git
cd suna
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env
# Edit .env files with your configuration

# Deploy
docker compose up -d

# Verify
docker compose ps
```

### Path 3: Guided Setup (30 minutes)
```bash
# For local development with full setup
python setup.py
python start.py
```

## 🎯 Choose Your Deployment Method

### Local Development
- **Method**: Python setup.py
- **Use Case**: Development, testing
- **Guide**: README.md
- **Pros**: Automated setup wizard, local Supabase support
- **Cons**: Not suitable for production

### Docker Compose (Recommended for Most Users)
- **Method**: docker compose up -d
- **Use Case**: Production, staging, self-hosting
- **Guide**: QUICK_DEPLOY.md or DEPLOYMENT.md
- **Pros**: Simple, portable, scalable
- **Cons**: Requires cloud Supabase (local not supported)

### AWS ECS (Enterprise Production)
- **Method**: CI/CD pipeline or manual ECS deployment
- **Use Case**: Large-scale production
- **Guide**: DEPLOYMENT.md → AWS Deployment → Option 1
- **Pros**: Auto-scaling, managed infrastructure, HA
- **Cons**: More complex, higher cost

### VPS/Cloud VM
- **Method**: Docker Compose on EC2/Droplet/VPS
- **Use Case**: Small to medium production
- **Guide**: QUICK_DEPLOY.md or DEPLOYMENT.md
- **Pros**: Full control, cost-effective
- **Cons**: Manual infrastructure management

## 📋 Deployment Checklist

Before deploying, ensure you have:

1. ✅ **Infrastructure**
   - Server/cloud instance (4GB+ RAM)
   - Domain name (optional but recommended)
   - Docker and Docker Compose installed

2. ✅ **Services**
   - Supabase project created
   - Redis available (included in Docker Compose)

3. ✅ **API Keys**
   - LLM provider (Anthropic/OpenAI/Groq)
   - Tavily API (web search)
   - Firecrawl API (web scraping)

4. ✅ **Configuration**
   - backend/.env configured
   - frontend/.env configured
   - Security keys generated

## 🔒 Security Essentials

Always do these for production:

1. **Generate secure keys**:
   ```bash
   openssl rand -base64 32  # For MCP_CREDENTIAL_ENCRYPTION_KEY
   openssl rand -hex 32     # For TRIGGER_WEBHOOK_SECRET
   ```

2. **Enable SSL/TLS**:
   - Use Let's Encrypt for free certificates
   - Configure reverse proxy (Nginx/Caddy)

3. **Secure your environment files**:
   - Never commit .env files
   - Use secrets management in production
   - Backup .env files encrypted

4. **Configure firewall**:
   - Only open ports 80 (HTTP) and 443 (HTTPS)
   - Keep ports 8000, 6379 internal
   - Enable DDoS protection if available

## 📊 Scaling Guidelines

### Small Deployment (< 100 users)
- 1 backend instance
- 1 worker instance
- 4GB RAM, 2 CPU cores
- Basic Supabase plan
- Single Redis instance

### Medium Deployment (100-1000 users)
- 2 backend instances (behind load balancer)
- 3 worker instances
- 8GB RAM, 4 CPU cores
- Pro Supabase plan
- Redis with persistence

### Large Deployment (1000+ users)
- 3+ backend instances (auto-scaling)
- 5+ worker instances
- 16GB+ RAM, 8+ CPU cores
- Enterprise Supabase or dedicated PostgreSQL
- Redis cluster or Sentinel
- CDN for static assets

Scale workers with:
```bash
docker compose up -d --scale worker=5
```

## 🔧 Maintenance

### Daily
- Monitor logs for errors
- Check service health
- Verify background jobs processing

### Weekly
- Review resource usage
- Check disk space
- Review API response times

### Monthly
- Update dependencies
- Test backups
- Review security
- Rotate API keys (if needed)

## 📖 Additional Resources

### Documentation
- [Main README](../README.md) - Project overview
- [Contributing Guide](../CONTRIBUTING.md) - How to contribute
- [Backend README](../backend/README.md) - Backend specifics
- [Frontend README](../frontend/README.md) - Frontend specifics

### External Links
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Supabase Documentation](https://supabase.com/docs)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Let's Encrypt](https://letsencrypt.org/)

### Community & Support
- [Discord Community](https://discord.gg/RvFhXUdZ9H) - Get help fast
- [GitHub Issues](https://github.com/kortix-ai/suna/issues) - Report bugs
- [GitHub Discussions](https://github.com/kortix-ai/suna/discussions) - General questions

## 🆘 Getting Help

### Self-Service Troubleshooting
1. Check [DEPLOYMENT.md](../DEPLOYMENT.md) → Troubleshooting section
2. Review service logs: `docker compose logs -f`
3. Check [GitHub Issues](https://github.com/kortix-ai/suna/issues) for similar problems

### Community Support
1. Join [Discord](https://discord.gg/RvFhXUdZ9H) for real-time help
2. Create a [GitHub Discussion](https://github.com/kortix-ai/suna/discussions)
3. Open a [GitHub Issue](https://github.com/kortix-ai/suna/issues) for bugs

### Professional Support
For enterprise deployments or professional support, contact the Kortix team through:
- Discord (enterprise channel)
- Email (see main repository)

## 🎓 Deployment Learning Path

1. **Beginner**: Start with local setup
   - Follow main README.md
   - Use `python setup.py`
   - Understand the basics

2. **Intermediate**: Deploy with Docker Compose
   - Follow QUICK_DEPLOY.md
   - Deploy to a VPS
   - Set up SSL and domain

3. **Advanced**: Production deployment
   - Follow DEPLOYMENT.md
   - Implement monitoring
   - Configure auto-scaling
   - Set up CI/CD

4. **Expert**: Enterprise deployment
   - AWS ECS deployment
   - Multi-region setup
   - High availability configuration
   - Custom infrastructure

## 📝 Version History

- **v1.0** (2024) - Initial deployment documentation
  - Comprehensive deployment guide
  - Interactive deployment script
  - Quick deploy guide
  - Deployment checklist

## 🤝 Contributing

Help improve deployment documentation:
1. Test deployment on different platforms
2. Report issues or unclear instructions
3. Submit improvements via pull requests
4. Share your deployment experience

---

**Ready to deploy?** Start with [QUICK_DEPLOY.md](../QUICK_DEPLOY.md) for the fastest path to production!
