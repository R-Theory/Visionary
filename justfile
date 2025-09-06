# Visionary Development Environment - Task Runner
# Complete development setup and management

# Default task - show help
default:
    @just --list

# ===== SETUP & INSTALLATION =====

# Install all development tools (macOS)
setup-dev:
    @echo "🚀 Setting up Visionary development environment..."
    @echo "📦 Installing system dependencies..."
    -brew install just pre-commit node python@3.11 redis postgresql
    @echo "🔧 Enabling corepack for pnpm..."
    corepack enable
    corepack prepare pnpm@latest --activate
    @echo "🐍 Installing Python tools..."
    python3 -m pip install --upgrade pip uv
    curl -LsSf https://astral.sh/uv/install.sh | sh
    @echo "✅ Development tools installed!"
    @echo "📝 Run 'just setup-project' to initialize project structure"

# Initialize project structure for implementation
setup-project:
    @echo "🏗️ Setting up project structure..."
    mkdir -p backend/{open_webui,tests,migrations,workers}
    mkdir -p frontend/{src,tests,public}
    mkdir -p services/{docling,nginx}
    mkdir -p workers/{tts,knowledge,ai-knowledge}
    mkdir -p tests/{unit,integration,e2e}
    mkdir -p docs/api
    touch backend/requirements.txt
    touch frontend/package.json
    @echo "✅ Project structure created!"

# Setup Python virtual environment
setup-python:
    @echo "🐍 Creating Python virtual environment..."
    python3 -m venv venv
    ./venv/bin/pip install --upgrade pip
    @echo "✅ Virtual environment ready!"
    @echo "💡 Activate with: source venv/bin/activate"

# Install pre-commit hooks
setup-hooks:
    @echo "🪝 Setting up pre-commit hooks..."
    pre-commit install
    pre-commit install --hook-type commit-msg
    @echo "✅ Pre-commit hooks installed!"

# ===== DEVELOPMENT TASKS =====

# Start development environment
dev:
    @echo "🚀 Starting development environment..."
    @echo "📚 Backend will be on: http://localhost:8080"
    @echo "🎨 Frontend will be on: http://localhost:3000"
    # This will be updated when we have actual implementation

# Install backend dependencies
install-backend:
    @echo "🐍 Installing backend dependencies..."
    ./venv/bin/pip install -r backend/requirements.txt

# Install frontend dependencies
install-frontend:
    @echo "🎨 Installing frontend dependencies..."
    cd frontend && pnpm install

# ===== QUALITY CHECKS =====

# Run all quality checks
check-all: check-docs check-python check-frontend
    @echo "✅ All checks completed!"

# Check documentation
check-docs:
    @echo "📚 Checking documentation..."
    @find my-notes -name "*.md" -exec echo "✓ {}" \;
    -markdownlint my-notes/**/*.md

# Check Python code (when implemented)
check-python:
    @echo "🐍 Checking Python code..."
    @if [ -f "backend/requirements.txt" ]; then \
        echo "Running ruff checks..."; \
        ./venv/bin/ruff check backend/ workers/ || true; \
    else \
        echo "⏳ Python code not yet implemented"; \
    fi

# Check frontend code (when implemented)
check-frontend:
    @echo "🎨 Checking frontend code..."
    @if [ -f "frontend/package.json" ]; then \
        echo "Running frontend checks..."; \
        cd frontend && pnpm lint || true; \
    else \
        echo "⏳ Frontend code not yet implemented"; \
    fi

# Run pre-commit on all files
check-hooks:
    @echo "🪝 Running pre-commit checks..."
    pre-commit run --all-files

# ===== TESTING =====

# Run all tests
test: test-backend test-frontend
    @echo "✅ All tests completed!"

# Run backend tests
test-backend:
    @echo "🧪 Running backend tests..."
    @if [ -d "backend/tests" ] && [ -f "backend/requirements.txt" ]; then \
        ./venv/bin/python -m pytest backend/tests/ -v; \
    else \
        echo "⏳ Backend tests not yet implemented"; \
    fi

# Run frontend tests
test-frontend:
    @echo "🧪 Running frontend tests..."
    @if [ -f "frontend/package.json" ]; then \
        cd frontend && pnpm test; \
    else \
        echo "⏳ Frontend tests not yet implemented"; \
    fi

# Run tests with coverage
test-coverage:
    @echo "📊 Running tests with coverage..."
    ./venv/bin/python -m pytest backend/tests/ --cov=backend --cov-report=html

# ===== DATABASE =====

# Run database migrations
migrate:
    @echo "🗄️ Running database migrations..."
    ./venv/bin/alembic upgrade head

# Create new migration
migrate-create message:
    @echo "📝 Creating migration: {{message}}"
    ./venv/bin/alembic revision --autogenerate -m "{{message}}"

# ===== DOCKER =====

# Build Docker containers
docker-build:
    @echo "🐳 Building Docker containers..."
    docker-compose build

# Start Docker services
docker-up:
    @echo "🚀 Starting Docker services..."
    docker-compose up -d

# Stop Docker services
docker-down:
    @echo "⏹️ Stopping Docker services..."
    docker-compose down

# View Docker logs
docker-logs:
    @echo "📋 Docker service logs..."
    docker-compose logs -f

# ===== DOCUMENTATION =====

# Open vault in Obsidian (macOS)
vault:
    @open "obsidian://open?path=$(pwd)/my-notes"

# Update documentation index
update-index:
    @echo "📁 Documentation structure:"
    @find my-notes -type d -not -path "*/.obsidian*" -not -path "*/.space*" -not -path "*/.makemd*" | sort

# Count documentation files
stats:
    @echo "📊 Project Statistics:"
    @echo "Markdown files: $(find my-notes -name "*.md" -not -path "*/.obsidian/*" | wc -l)"
    @echo "Directories: $(find my-notes -type d -not -path "*/.obsidian*" | wc -l)"
    @echo "Python files: $(find . -name "*.py" -not -path "./venv/*" | wc -l 2>/dev/null || echo "0")"
    @echo "TypeScript files: $(find . -name "*.ts" -o -name "*.tsx" | wc -l 2>/dev/null || echo "0")"

# ===== IMPLEMENTATION HELPERS =====

# Prepare for OpenWebUI fork integration
prepare-fork:
    @echo "🍴 Preparing for OpenWebUI fork integration..."
    @echo "1. Fork https://github.com/open-webui/open-webui"
    @echo "2. Clone your fork"
    @echo "3. Copy documentation: cp -r my-notes/ ../your-fork/"
    @echo "4. Copy configs: cp CLAUDE.md ROADMAP.md justfile .env.example ../your-fork/"
    @echo "5. Follow implementation roadmap in ROADMAP.md"

# Clean build artifacts
clean:
    @echo "🧹 Cleaning build artifacts..."
    find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.pyc" -delete 2>/dev/null || true
    find . -name ".pytest_cache" -type d -exec rm -rf {} + 2>/dev/null || true
    rm -rf dist/ build/ *.egg-info/ 2>/dev/null || true
    @echo "✅ Cleanup completed!"

# Show current development status
status:
    @echo "📊 Visionary Development Status"
    @echo "================================"
    @echo "📁 Repository: Planning & Documentation Phase"
    @echo "🐍 Python env: $(if [ -d "venv" ]; then echo "✅ Ready"; else echo "❌ Run 'just setup-python'"; fi)"
    @echo "📦 Dependencies: $(if [ -f "backend/requirements.txt" ]; then echo "⏳ Implementation pending"; else echo "❌ Not set up"; fi)"
    @echo "🪝 Pre-commit: $(if [ -f ".git/hooks/pre-commit" ]; then echo "✅ Installed"; else echo "❌ Run 'just setup-hooks'"; fi)"
    @echo "📚 Documentation: ✅ Complete ($(find my-notes -name "*.md" -not -path "*/.obsidian/*" | wc -l) files)"
    @echo ""
    @echo "🎯 Next Steps:"
    @echo "  1. Run 'just setup-dev' to install development tools"
    @echo "  2. Run 'just setup-project' to create project structure"
    @echo "  3. Fork OpenWebUI repository for actual implementation"
    @echo "  4. Follow ROADMAP.md for feature development"

# ===== AI UTILITIES =====

# Claude CLI wrapper (for convenience)
claude args+:
    @bin/claude {{args}}

# ===== DOCS / ADRS =====

# Create a new ADR: just adr -- "Title here"
adr title:
    @bin/new-adr {{title}}

# ===== TOOLING DIAGNOSTICS =====

docker-ver:
    @docker --version || true
    @docker compose version || true
    @docker buildx version || true

k8s-ver:
    @kubectl version --client || true
    @helm version || true
    @kustomize version || true
    @skaffold version || true
    @hadolint --version || true

# ===== BMAD =====

# Install BMAD scaffolding per notes
bmad-install:
    @echo "🚧 Installing BMAD scaffolding (best-effort)..."
    corepack enable
    corepack prepare pnpm@latest --activate
    pnpm dlx bmad-method@latest install || echo "(Skipped/failed — check network or run on host)"
