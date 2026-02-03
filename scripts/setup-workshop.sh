#!/bin/bash
# setup-workshop.sh
# Automated setup script for workshop infrastructure

set -e

echo "========================================"
echo "Databricks Claude Code Workshop Setup"
echo "========================================"

# Configuration
CATALOG="${CATALOG:-main}"
SCHEMA="${SCHEMA:-default}"
VOLUME_NAME="${VOLUME_NAME:-init_scripts}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSHOP_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check prerequisites
check_prerequisites() {
    info "Checking prerequisites..."

    if ! command -v databricks &> /dev/null; then
        error "Databricks CLI not found. Install with: pip install databricks-cli"
        exit 1
    fi

    if ! databricks auth describe &> /dev/null; then
        error "Not authenticated to Databricks. Run: databricks configure"
        exit 1
    fi

    info "Prerequisites OK"
}

# Create Unity Catalog volume if it doesn't exist
create_volume() {
    info "Creating Unity Catalog volume..."

    # Check if volume exists
    if databricks volumes get "${CATALOG}.${SCHEMA}.${VOLUME_NAME}" &> /dev/null; then
        info "Volume ${CATALOG}.${SCHEMA}.${VOLUME_NAME} already exists"
    else
        info "Creating volume ${CATALOG}.${SCHEMA}.${VOLUME_NAME}"
        databricks volumes create \
            --catalog-name "$CATALOG" \
            --schema-name "$SCHEMA" \
            --name "$VOLUME_NAME" \
            --volume-type MANAGED
    fi
}

# Upload init scripts
upload_init_scripts() {
    info "Uploading init scripts..."

    local volume_path="/Volumes/${CATALOG}/${SCHEMA}/${VOLUME_NAME}"

    # Upload main init script
    databricks fs cp \
        "${WORKSHOP_DIR}/init-scripts/install-claude-code.sh" \
        "dbfs:${volume_path}/install-claude-code.sh" \
        --overwrite

    info "Uploaded install-claude-code.sh"

    # Upload offline init script
    databricks fs cp \
        "${WORKSHOP_DIR}/init-scripts/install-claude-code-offline.sh" \
        "dbfs:${volume_path}/install-claude-code-offline.sh" \
        --overwrite

    info "Uploaded install-claude-code-offline.sh"
}

# Create cluster policy
create_cluster_policy() {
    info "Creating cluster policy..."

    local policy_name="Claude Code Workshop Policy"

    # Check if policy exists
    existing_policy=$(databricks cluster-policies list --output JSON | \
        jq -r ".[] | select(.name == \"$policy_name\") | .policy_id")

    if [ -n "$existing_policy" ]; then
        warn "Policy '$policy_name' already exists (ID: $existing_policy)"
        warn "Delete it manually if you want to recreate"
    else
        databricks cluster-policies create \
            --json-file "${WORKSHOP_DIR}/cluster-config/cluster-policy.json"
        info "Created cluster policy: $policy_name"
    fi
}

# Create instance pool
create_instance_pool() {
    info "Creating instance pool..."

    local pool_name="claude-code-workshop-pool"

    # Check if pool exists
    existing_pool=$(databricks instance-pools list --output JSON | \
        jq -r ".[] | select(.instance_pool_name == \"$pool_name\") | .instance_pool_id")

    if [ -n "$existing_pool" ]; then
        warn "Instance pool '$pool_name' already exists (ID: $existing_pool)"
    else
        databricks instance-pools create \
            --json-file "${WORKSHOP_DIR}/cluster-config/instance-pool-config.json"
        info "Created instance pool: $pool_name"
    fi
}

# Verify setup
verify_setup() {
    info "Verifying setup..."

    local volume_path="/Volumes/${CATALOG}/${SCHEMA}/${VOLUME_NAME}"

    # Check init script exists
    if databricks fs ls "dbfs:${volume_path}/install-claude-code.sh" &> /dev/null; then
        info "Init script uploaded OK"
    else
        error "Init script not found at ${volume_path}/install-claude-code.sh"
        exit 1
    fi

    # Check cluster policy
    if databricks cluster-policies list --output JSON | jq -e '.[] | select(.name == "Claude Code Workshop Policy")' &> /dev/null; then
        info "Cluster policy OK"
    else
        warn "Cluster policy not found"
    fi

    # Check instance pool
    if databricks instance-pools list --output JSON | jq -e '.[] | select(.instance_pool_name == "claude-code-workshop-pool")' &> /dev/null; then
        info "Instance pool OK"
    else
        warn "Instance pool not found"
    fi

    info "Setup verification complete"
}

# Main execution
main() {
    echo ""
    check_prerequisites
    echo ""
    create_volume
    echo ""
    upload_init_scripts
    echo ""
    create_cluster_policy
    echo ""
    create_instance_pool
    echo ""
    verify_setup
    echo ""

    info "========================================"
    info "Workshop setup complete!"
    info "========================================"
    echo ""
    info "Next steps:"
    info "1. Update cluster policy with proxy settings if needed"
    info "2. Configure Anthropic API key distribution"
    info "3. Run pre-workshop validation tests"
    info "4. Send attendee guide to participants"
    echo ""
}

# Parse arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --verify       Only run verification"
        echo ""
        echo "Environment variables:"
        echo "  CATALOG        Unity Catalog name (default: main)"
        echo "  SCHEMA         Schema name (default: default)"
        echo "  VOLUME_NAME    Volume name (default: init_scripts)"
        exit 0
        ;;
    --verify)
        check_prerequisites
        verify_setup
        exit 0
        ;;
    *)
        main
        ;;
esac
