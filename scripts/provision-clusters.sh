#!/bin/bash
# provision-clusters.sh
# Pre-provision clusters for workshop attendees

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSHOP_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration
CLUSTER_PREFIX="${CLUSTER_PREFIX:-claude-code-workshop}"
USERS_FILE="${1:-}"
SPARK_VERSION="${SPARK_VERSION:-17.3.x-cpu-ml-scala2.13}"
NODE_TYPE="${NODE_TYPE:-Standard_D4ds_v5}"
INIT_SCRIPT_PATH="${INIT_SCRIPT_PATH:-/Volumes/main/default/coding_assistants/install-claude.sh}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
    echo "Usage: $0 <users-file>"
    echo ""
    echo "Pre-provisions clusters for workshop attendees."
    echo ""
    echo "Arguments:"
    echo "  users-file     File with one email per line"
    echo ""
    echo "Environment variables:"
    echo "  CLUSTER_PREFIX       Cluster name prefix (default: claude-code-workshop)"
    echo "  SPARK_VERSION        DBR version (default: 14.3.x-scala2.12)"
    echo "  NODE_TYPE            VM type (default: Standard_DS3_v2)"
    echo "  INIT_SCRIPT_PATH     Path to init script"
    echo ""
    echo "Example:"
    echo "  $0 attendees.txt"
    exit 1
}

if [ -z "$USERS_FILE" ] || [ ! -f "$USERS_FILE" ]; then
    error "Users file not provided or doesn't exist"
    usage
fi

# Count users
USER_COUNT=$(wc -l < "$USERS_FILE" | tr -d ' ')
info "Found $USER_COUNT users in $USERS_FILE"

# Confirm before proceeding
echo ""
read -p "Provision $USER_COUNT clusters? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Aborted"
    exit 0
fi

# Track results
SUCCESS_COUNT=0
FAIL_COUNT=0
FAILED_USERS=()

# Create cluster for each user
while IFS= read -r user_email; do
    # Skip empty lines and comments
    [[ -z "$user_email" || "$user_email" =~ ^# ]] && continue

    # Create sanitized cluster name
    cluster_name="${CLUSTER_PREFIX}-$(echo "$user_email" | cut -d@ -f1 | tr '.' '-')"

    info "Creating cluster: $cluster_name for $user_email"

    # Create cluster JSON
    cluster_json=$(cat <<EOF
{
    "cluster_name": "$cluster_name",
    "spark_version": "$SPARK_VERSION",
    "node_type_id": "$NODE_TYPE",
    "num_workers": 0,
    "autotermination_minutes": 30,
    "data_security_mode": "SINGLE_USER",
    "single_user_name": "$user_email",
    "spark_conf": {
        "spark.databricks.cluster.profile": "singleNode",
        "spark.master": "local[*]"
    },
    "spark_env_vars": {
        "MLFLOW_EXPERIMENT_NAME": "/Workspace/Shared/claude-code-tracing"
    },
    "custom_tags": {
        "Workshop": "ClaudeCodeVibeCoding",
        "ResourceClass": "SingleNode",
        "Owner": "$user_email"
    },
    "init_scripts": [
        {
            "volumes": {
                "destination": "$INIT_SCRIPT_PATH"
            }
        }
    ]
}
EOF
)

    # Create the cluster
    if result=$(echo "$cluster_json" | databricks clusters create --json @- 2>&1); then
        cluster_id=$(echo "$result" | jq -r '.cluster_id')
        info "Created cluster $cluster_name (ID: $cluster_id)"
        ((SUCCESS_COUNT++))
    else
        error "Failed to create cluster for $user_email: $result"
        FAILED_USERS+=("$user_email")
        ((FAIL_COUNT++))
    fi

    # Small delay to avoid rate limiting
    sleep 1

done < "$USERS_FILE"

# Summary
echo ""
info "========================================"
info "Provisioning complete"
info "========================================"
info "Success: $SUCCESS_COUNT"
info "Failed: $FAIL_COUNT"

if [ ${#FAILED_USERS[@]} -gt 0 ]; then
    warn "Failed users:"
    for user in "${FAILED_USERS[@]}"; do
        warn "  - $user"
    done
fi
