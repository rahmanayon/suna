#!/bin/bash

# Kortix Quick Deploy Script
# This script helps you deploy Kortix quickly with Docker Compose

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌  $1${NC}"
}

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed!"
        echo "Please install Docker first: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed!"
        echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    print_success "Docker and Docker Compose are installed"
}

# Check if environment files exist
check_env_files() {
    local missing=0
    
    if [ ! -f "backend/.env" ]; then
        print_warning "backend/.env not found"
        missing=1
    fi
    
    if [ ! -f "frontend/.env" ]; then
        print_warning "frontend/.env not found"
        missing=1
    fi
    
    if [ $missing -eq 1 ]; then
        print_info "Creating .env files from examples..."
        [ ! -f "backend/.env" ] && cp backend/.env.example backend/.env && print_success "Created backend/.env"
        [ ! -f "frontend/.env" ] && cp frontend/.env.example frontend/.env && print_success "Created frontend/.env"
        echo ""
        print_warning "⚠️  IMPORTANT: Please edit the .env files with your configuration before proceeding!"
        print_info "Edit backend/.env and frontend/.env with your API keys and configuration"
        echo ""
        read -p "Press Enter after you've configured the .env files, or Ctrl+C to exit..."
    else
        print_success "Environment files found"
    fi
}

# Show deployment menu
show_menu() {
    print_header "Kortix Deployment Manager"
    echo "1) Deploy/Start Services"
    echo "2) Stop Services"
    echo "3) Restart Services"
    echo "4) View Logs"
    echo "5) Check Status"
    echo "6) Update and Redeploy"
    echo "7) Clean and Rebuild"
    echo "8) Scale Workers"
    echo "9) Backup Data"
    echo "0) Exit"
    echo ""
}

# Deploy services
deploy() {
    print_header "Deploying Kortix Services"
    
    print_info "Pulling latest images..."
    docker compose pull || print_warning "Could not pull images, will use local builds"
    
    print_info "Starting services..."
    docker compose up -d
    
    echo ""
    print_success "Deployment complete!"
    echo ""
    print_info "Services:"
    echo "  - Frontend: http://localhost:3000"
    echo "  - Backend API: http://localhost:8000"
    echo "  - API Docs: http://localhost:8000/docs"
    echo ""
    print_info "Check status with: docker compose ps"
    print_info "View logs with: docker compose logs -f"
}

# Stop services
stop() {
    print_header "Stopping Kortix Services"
    docker compose down
    print_success "Services stopped"
}

# Restart services
restart() {
    print_header "Restarting Kortix Services"
    docker compose restart
    print_success "Services restarted"
}

# View logs
view_logs() {
    print_header "Service Logs"
    echo "Which service logs do you want to view?"
    echo "1) All services"
    echo "2) Backend"
    echo "3) Worker"
    echo "4) Frontend"
    echo "5) Redis"
    read -p "Enter choice [1-5]: " log_choice
    
    case $log_choice in
        1)
            docker compose logs -f
            ;;
        2)
            docker compose logs -f backend
            ;;
        3)
            docker compose logs -f worker
            ;;
        4)
            docker compose logs -f frontend
            ;;
        5)
            docker compose logs -f redis
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
}

# Check status
check_status() {
    print_header "Service Status"
    docker compose ps
    echo ""
    print_header "Resource Usage"
    docker stats --no-stream
}

# Update and redeploy
update_and_redeploy() {
    print_header "Updating and Redeploying"
    
    print_info "Pulling latest code..."
    git pull origin main
    
    print_info "Pulling latest images..."
    docker compose pull
    
    print_info "Redeploying services..."
    docker compose up -d
    
    print_success "Update complete!"
}

# Clean and rebuild
clean_rebuild() {
    print_header "Clean Rebuild"
    
    print_warning "This will stop services, remove images, and rebuild from scratch"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Cancelled"
        return
    fi
    
    print_info "Stopping services..."
    docker compose down
    
    print_info "Removing images..."
    docker compose rm -f
    
    print_info "Rebuilding..."
    docker compose build --no-cache
    
    print_info "Starting services..."
    docker compose up -d
    
    print_success "Rebuild complete!"
}

# Scale workers
scale_workers() {
    print_header "Scale Workers"
    echo "Current worker count:"
    docker compose ps worker --format "table {{.Name}}\t{{.Status}}" 2>/dev/null || echo "No workers running"
    echo ""
    read -p "How many worker instances do you want? [1-10]: " worker_count
    
    if [[ ! $worker_count =~ ^[1-9][0-9]?$ ]] || [ $worker_count -gt 10 ]; then
        print_error "Invalid number. Please enter 1-10"
        return
    fi
    
    print_info "Scaling to $worker_count workers..."
    docker compose up -d --scale worker=$worker_count
    
    print_success "Workers scaled to $worker_count"
}

# Backup data
backup_data() {
    print_header "Backup Data"
    
    BACKUP_DIR="./backups"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$BACKUP_DIR"
    
    print_info "Backing up Redis data..."
    docker run --rm -v suna_redis_data:/data -v "$(pwd)/$BACKUP_DIR":/backup alpine \
        tar czf "/backup/redis_backup_${TIMESTAMP}.tar.gz" -C /data .
    
    print_info "Backing up environment files..."
    tar czf "$BACKUP_DIR/env_backup_${TIMESTAMP}.tar.gz" backend/.env frontend/.env 2>/dev/null || true
    
    print_success "Backup complete!"
    print_info "Backups saved in: $BACKUP_DIR"
    ls -lh "$BACKUP_DIR"
}

# Main script
main() {
    # Check prerequisites
    check_docker
    check_env_files
    
    # Interactive menu
    while true; do
        show_menu
        read -p "Enter your choice [0-9]: " choice
        
        case $choice in
            1)
                deploy
                ;;
            2)
                stop
                ;;
            3)
                restart
                ;;
            4)
                view_logs
                ;;
            5)
                check_status
                ;;
            6)
                update_and_redeploy
                ;;
            7)
                clean_rebuild
                ;;
            8)
                scale_workers
                ;;
            9)
                backup_data
                ;;
            0)
                print_info "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please select 0-9"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main function
main
