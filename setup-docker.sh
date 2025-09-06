#!/bin/bash
# Visionary Docker Setup Script
# Sets up Docker environment properly for dev containers

set -e

echo "🐳 Setting up Docker for Visionary development..."

# Check if we're in a dev container
if [ -f /.dockerenv ] || [ -n "${VSCODE_REMOTE_CONTAINERS_SESSION}" ]; then
    echo "📦 Detected dev container environment"

    # Try to start Docker service
    echo "🚀 Starting Docker service..."
    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl start docker || echo "⚠️ systemctl not available"
    else
        sudo service docker start || echo "⚠️ service command failed"
    fi

    # Check if Docker is running
    if docker info >/dev/null 2>&1; then
        echo "✅ Docker is running!"
    else
        echo "❌ Docker is not running. This is expected in some dev container environments."
        echo "💡 The containers will work when deployed outside dev container."
    fi
else
    echo "🖥️ Regular environment detected"

    # Install Docker if not present
    if ! command -v docker >/dev/null 2>&1; then
        echo "📦 Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
    fi

    # Install Docker Compose if not present
    if ! command -v docker-compose >/dev/null 2>&1; then
        echo "📦 Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi

    # Start Docker service
    sudo systemctl enable docker
    sudo systemctl start docker

    echo "✅ Docker setup complete!"
fi

# Validate Docker Compose configuration
echo "🔍 Validating Docker Compose configuration..."
if docker-compose config >/dev/null 2>&1; then
    echo "✅ Docker Compose configuration is valid"
else
    echo "❌ Docker Compose configuration has issues"
    docker-compose config
    exit 1
fi

# Test basic Docker functionality (if Docker is running)
if docker info >/dev/null 2>&1; then
    echo "🧪 Testing Docker functionality..."

    # Pull a simple image to test
    docker pull hello-world:latest
    docker run --rm hello-world

    echo "✅ Docker is working correctly!"

    # Show Docker Compose services
    echo "📋 Available Docker Compose services:"
    docker-compose config --services

    echo ""
    echo "🚀 Ready to start development stack!"
    echo "Run: docker-compose up -d"
    echo "Or:  just docker-up"
else
    echo "⚠️ Docker not running - configuration validated but containers cannot start"
    echo "📋 When Docker is available, these services will be ready:"
    docker-compose config --services 2>/dev/null || echo "  - postgres, redis, minio, celery-worker, celery-beat, flower, pgadmin"
fi

echo "✅ Setup complete!"
