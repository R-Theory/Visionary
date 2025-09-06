#!/bin/bash

# Visionary Development Environment Setup Script
# This script sets up the complete development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check for required tools
check_requirements() {
    print_info "Checking requirements..."

    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker Desktop."
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed."
        exit 1
    fi

    print_success "All requirements met!"
}

# Create .env file from example
setup_env() {
    print_info "Setting up environment variables..."

    if [ ! -f .env ]; then
        if [ -f .env.example ]; then
            cp .env.example .env
            print_success ".env file created from .env.example"
            print_warning "Please update .env with your actual values"
        else
            print_error ".env.example not found!"
            exit 1
        fi
    else
        print_info ".env file already exists"
    fi
}

# Create necessary directories
create_directories() {
    print_info "Creating necessary directories..."

    mkdir -p uploads
    mkdir -p backend/{data,cache,logs}
    mkdir -p frontend/public
    mkdir -p workers

    print_success "Directories created"
}

# Pull Docker images
pull_images() {
    print_info "Pulling Docker images..."

    if docker compose version &> /dev/null; then
        docker compose -f docker-compose.dev.yml pull
    else
        docker-compose -f docker-compose.dev.yml pull
    fi

    print_success "Docker images pulled"
}

# Build application image
build_app() {
    print_info "Building application image..."

    if docker compose version &> /dev/null; then
        docker compose -f docker-compose.dev.yml build
    else
        docker-compose -f docker-compose.dev.yml build
    fi

    print_success "Application image built"
}

# Initialize MinIO buckets
init_minio() {
    print_info "Initializing MinIO buckets..."

    # Start MinIO temporarily
    if docker compose version &> /dev/null; then
        docker compose -f docker-compose.dev.yml up -d minio
    else
        docker-compose -f docker-compose.dev.yml up -d minio
    fi

    # Wait for MinIO to be ready
    sleep 5

    # Create buckets using MinIO client
    docker run --rm --network visionary-network \
        -e MC_HOST_minio=http://minioadmin:minioadmin123@minio:9000 \
        minio/mc mb minio/visionary-media --ignore-existing

    docker run --rm --network visionary-network \
        -e MC_HOST_minio=http://minioadmin:minioadmin123@minio:9000 \
        minio/mc mb minio/visionary-knowledge --ignore-existing

    print_success "MinIO buckets initialized"
}

# Create sample main.py if it doesn't exist
create_sample_app() {
    if [ ! -f main.py ]; then
        print_info "Creating sample FastAPI application..."

        cat > main.py << 'EOF'
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import os
from typing import Dict, Any

# Create FastAPI app
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print("Starting Visionary application...")
    yield
    # Shutdown
    print("Shutting down Visionary application...")

app = FastAPI(
    title="Visionary API",
    description="Knowledge Management and Media Processing Platform",
    version="0.1.0",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {
        "message": "Welcome to Visionary API",
        "version": "0.1.0",
        "status": "running"
    }

@app.get("/health")
async def health_check() -> Dict[str, Any]:
    return {
        "status": "healthy",
        "service": "visionary-api",
        "environment": os.getenv("ENVIRONMENT", "development")
    }

@app.get("/api/v1/info")
async def get_info():
    return {
        "app": "Visionary",
        "features": {
            "media_library": "planned",
            "knowledge_manager": "planned",
            "study_page": "planned",
            "email_manager": "planned"
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
EOF

        print_success "Sample FastAPI application created"
    fi
}

# Start services
start_services() {
    print_info "Starting all services..."

    if docker compose version &> /dev/null; then
        docker compose -f docker-compose.dev.yml -f docker-compose.override.yml up -d
    else
        docker-compose -f docker-compose.dev.yml -f docker-compose.override.yml up -d
    fi

    print_success "All services started"
}

# Show service URLs
show_urls() {
    echo ""
    print_success "Development environment is ready!"
    echo ""
    echo -e "${GREEN}Service URLs:${NC}"
    echo "  - Visionary App:     http://localhost:3000"
    echo "  - MinIO Console:     http://localhost:9001"
    echo "  - MailHog:          http://localhost:8025"
    echo "  - Adminer:          http://localhost:8080"
    echo "  - Redis Commander:   http://localhost:8081"
    echo ""
    echo -e "${YELLOW}Default Credentials:${NC}"
    echo "  MinIO:"
    echo "    - Username: minioadmin"
    echo "    - Password: minioadmin123"
    echo "  MongoDB:"
    echo "    - Username: admin"
    echo "    - Password: password"
    echo ""
    echo -e "${BLUE}Useful Commands:${NC}"
    echo "  View logs:    docker compose -f docker-compose.dev.yml logs -f"
    echo "  Stop:         docker compose -f docker-compose.dev.yml down"
    echo "  Restart:      docker compose -f docker-compose.dev.yml restart"
    echo "  Clean:        docker compose -f docker-compose.dev.yml down -v"
}

# Main execution
main() {
    print_info "Starting Visionary Development Setup"
    echo "====================================="

    check_requirements
    setup_env
    create_directories
    create_sample_app
    pull_images
    build_app
    init_minio
    start_services
    show_urls
}

# Run main function
main
