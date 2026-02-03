#!/bin/bash
# cleanup-workshop.sh
# Clean up workshop resources after the event

set -e

# Configuration
CLUSTER_PREFIX="${CLUSTER_PREFIX:-claude-code-workshop}"
DRY_RUN="${DRY_RUN:-true}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
    echo "Usage: $0 [--dry-run|--execute]"
    echo ""
    echo "Cleans up workshop clusters and resources."
    echo ""
    echo "Options:"
    echo "  --dry-run      Show what would be deleted (default)"
    echo "  --execute      Actually delete resources"
    echo ""
    echo "Environment variables:"
    echo "  CLUSTER_PREFIX    Cluster name prefix to match (default: claude-code-workshop)"
    exit 1
}

# Parse arguments
case "${1:-}" in
    --execute)
        DRY_RUN="false"
        warn "EXECUTE MODE - Resources will be permanently deleted!"
        echo ""
        read -p "Are you sure? (type 'yes' to confirm) " -r
        if [ "$REPLY" != "yes" ]; then
            info "Aborted"
            exit 0
        fi
        ;;
    --dry-run|"")
        DRY_RUN="true"
        info "DRY RUN MODE - No resources will be deleted"
        ;;
    --help|-h)
        usage
        ;;
    *)
        error "Unknown option: $1"
        usage
        ;;
esac

echo ""

# Find workshop clusters
info "Finding clusters matching prefix: $CLUSTER_PREFIX"

clusters=$(databricks clusters list --output JSON | \
    jq -r ".[] | select(.cluster_name | startswith(\"$CLUSTER_PREFIX\")) | \"\(.cluster_id)|\(.cluster_name)|\(.state)\"")

if [ -z "$clusters" ]; then
    info "No matching clusters found"
else
    cluster_count=$(echo "$clusters" | wc -l | tr -d ' ')
    info "Found $cluster_count clusters to clean up:"
    echo ""

    while IFS='|' read -r cluster_id cluster_name state; do
        if [ "$DRY_RUN" = "true" ]; then
            info "[DRY RUN] Would delete: $cluster_name ($cluster_id) - $state"
        else
            info "Deleting: $cluster_name ($cluster_id)"

            # Terminate if running
            if [ "$state" = "RUNNING" ] || [ "$state" = "PENDING" ]; then
                info "  Terminating cluster..."
                databricks clusters delete --cluster-id "$cluster_id" 2>/dev/null || true
                sleep 2
            fi

            # Permanently delete
            info "  Permanently deleting..."
            databricks clusters permanent-delete --cluster-id "$cluster_id"
        fi
    done <<< "$clusters"
fi

echo ""

# Find and cleanup instance pool
info "Finding workshop instance pool..."

pool_id=$(databricks instance-pools list --output JSON | \
    jq -r '.[] | select(.instance_pool_name == "claude-code-workshop-pool") | .instance_pool_id')

if [ -z "$pool_id" ]; then
    info "No workshop instance pool found"
else
    if [ "$DRY_RUN" = "true" ]; then
        info "[DRY RUN] Would delete instance pool: claude-code-workshop-pool ($pool_id)"
    else
        info "Deleting instance pool: claude-code-workshop-pool ($pool_id)"
        databricks instance-pools delete --instance-pool-id "$pool_id"
    fi
fi

echo ""

# Summary
if [ "$DRY_RUN" = "true" ]; then
    info "========================================"
    info "DRY RUN COMPLETE"
    info "========================================"
    info "Run with --execute to delete resources"
else
    info "========================================"
    info "CLEANUP COMPLETE"
    info "========================================"
fi

# Note about things not cleaned up
echo ""
warn "The following are NOT automatically cleaned up:"
warn "  - Cluster policy (may be reused)"
warn "  - Unity Catalog volume and init scripts (may be reused)"
warn "  - Any files created by attendees in their workspaces"
