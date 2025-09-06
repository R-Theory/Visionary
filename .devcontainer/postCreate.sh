#!/usr/bin/env bash
set -euo pipefail

echo "[postCreate] Starting post-create provisioning..."

# Ensure local CLI is executable
chmod +x "${PWD}/bin/claude" 2>/dev/null || true

# Try to start Docker if available (may be a no-op in some environments)
sudo service docker start 2>/dev/null || true

# Python tooling for repo-local CLI and future work
python3 -m pip install --user --upgrade pip anthropic 2>/dev/null || true

# Node + pnpm via Corepack
corepack enable 2>/dev/null || true
corepack prepare pnpm@latest --activate 2>/dev/null || true

# Base packages for tooling and app dependencies
sudo apt-get update -y 2>/dev/null || true
sudo apt-get install -y --no-install-recommends \
  git ca-certificates curl wget jq shellcheck \
  docker-compose-plugin docker-buildx-plugin \
  pkg-config libpoppler-cpp-dev tesseract-ocr tesseract-ocr-eng \
  libgl1 libglib2.0-0 libsm6 libxext6 libxrender-dev \
  libgomp1 ffmpeg nodejs npm 2>/dev/null || true

# Install Kubernetes toolchain (best-effort; skip on failure)
install_kubectl() {
  echo "[postCreate] Installing kubectl..."
  local ver
  ver=$(curl -fsSL https://dl.k8s.io/release/stable.txt) || return 0
  sudo curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/${ver}/bin/linux/amd64/kubectl" || return 0
  sudo chmod +x /usr/local/bin/kubectl || true
}

install_helm() {
  echo "[postCreate] Installing helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash 2>/dev/null || true
}

install_kustomize() {
  echo "[postCreate] Installing kustomize..."
  curl -fsSL https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh | bash -s -- -b /tmp 2>/dev/null || true
  if [ -x /tmp/kustomize ]; then
    sudo mv /tmp/kustomize /usr/local/bin/kustomize || true
  fi
}

install_skaffold() {
  echo "[postCreate] Installing skaffold..."
  sudo curl -fsSL -o /usr/local/bin/skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 2>/dev/null || true
  sudo chmod +x /usr/local/bin/skaffold || true
}

install_hadolint() {
  echo "[postCreate] Installing hadolint..."
  sudo curl -fsSL -o /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64 2>/dev/null || true
  sudo chmod +x /usr/local/bin/hadolint || true
}

install_claude_code() {
  echo "[postCreate] Installing Claude Code..."
  # Install Claude Code CLI
  curl -fsSL https://raw.githubusercontent.com/anthropics/claude-code/main/install.sh | bash 2>/dev/null || true
}

install_kubectl || true
install_helm || true
install_kustomize || true
install_skaffold || true
install_hadolint || true
install_claude_code || true

# Ensure ADR helper is executable if present
chmod +x "${PWD}/bin/new-adr" 2>/dev/null || true

echo "[postCreate] Provisioning complete."
