#!/bin/bash
# install-claude-code-offline.sh
# Offline-capable init script for VNet-restricted environments
# Pre-downloads Node.js and Claude Code from internal artifact mirror
#
# Prerequisites:
# 1. Upload node-v20.x.x-linux-x64.tar.gz to Unity Catalog volume
# 2. Upload claude-code npm package tarball to Unity Catalog volume
#
# Store in Unity Catalog: /Volumes/main/default/init_scripts/install-claude-code-offline.sh

set -e

echo "=========================================="
echo "Installing Claude Code (offline mode)"
echo "=========================================="

# Configuration - update these paths to match your Unity Catalog volumes
ARTIFACT_VOLUME="/Volumes/main/default/artifacts"
NODE_TARBALL="${ARTIFACT_VOLUME}/node-v20.11.1-linux-x64.tar.gz"
CLAUDE_CODE_TARBALL="${ARTIFACT_VOLUME}/claude-code-latest.tgz"

# Check if artifacts exist
if [ ! -f "${NODE_TARBALL}" ]; then
    echo "ERROR: Node.js tarball not found at ${NODE_TARBALL}"
    echo "Please upload Node.js to the artifacts volume"
    exit 1
fi

# Install Node.js from local tarball
echo "Installing Node.js from local artifact..."
sudo mkdir -p /usr/local/lib/nodejs
sudo tar -xzf "${NODE_TARBALL}" -C /usr/local/lib/nodejs

# Get the extracted directory name
NODE_DIR=$(ls /usr/local/lib/nodejs | head -1)

# Create symlinks
sudo ln -sf "/usr/local/lib/nodejs/${NODE_DIR}/bin/node" /usr/local/bin/node
sudo ln -sf "/usr/local/lib/nodejs/${NODE_DIR}/bin/npm" /usr/local/bin/npm
sudo ln -sf "/usr/local/lib/nodejs/${NODE_DIR}/bin/npx" /usr/local/bin/npx

# Update PATH
export PATH="/usr/local/lib/nodejs/${NODE_DIR}/bin:$PATH"

# Verify Node.js installation
echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"

# Install Claude Code from local tarball (if available)
if [ -f "${CLAUDE_CODE_TARBALL}" ]; then
    echo "Installing Claude Code from local artifact..."
    sudo npm install -g "${CLAUDE_CODE_TARBALL}"
else
    echo "Claude Code tarball not found, attempting online install..."

    # Configure proxy if environment variables are set
    if [ -n "${DATABRICKS_HTTPS_PROXY:-}" ]; then
        export HTTPS_PROXY="${DATABRICKS_HTTPS_PROXY}"
        npm config set proxy "${DATABRICKS_HTTPS_PROXY}"
        npm config set https-proxy "${DATABRICKS_HTTPS_PROXY}"
    fi

    sudo npm install -g @anthropic-ai/claude-code
fi

# Create profile script
sudo tee /etc/profile.d/claude-code.sh > /dev/null << EOF
# Claude Code environment configuration
export PATH="/usr/local/lib/nodejs/${NODE_DIR}/bin:\$PATH"

# Proxy settings (if configured)
if [ -n "\${DATABRICKS_HTTPS_PROXY:-}" ]; then
    export HTTPS_PROXY="\${DATABRICKS_HTTPS_PROXY}"
    export HTTP_PROXY="\${DATABRICKS_HTTP_PROXY:-\$DATABRICKS_HTTPS_PROXY}"
fi

# CA certificate (if configured)
if [ -n "\${DATABRICKS_CA_CERT_PATH:-}" ]; then
    export NODE_EXTRA_CA_CERTS="\${DATABRICKS_CA_CERT_PATH}"
fi

# Helpful aliases
alias cc='claude'
EOF

source /etc/profile.d/claude-code.sh

# Verify installation
echo "=========================================="
echo "Installation complete"
echo "=========================================="
claude --version || echo "Claude Code binary not found - check installation"
