#!/bin/bash

# Attack Scenario Cleanup Script
# Removes all resources created by attack-scenario-setup.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo ""
echo "=========================================="
echo "  Kubernetes Attack Scenario Cleanup"
echo "=========================================="
echo ""

read -p "Remove all attack scenario resources? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

log_info "Deleting namespaces (webapp and payments)..."
kubectl delete namespace webapp --ignore-not-found
kubectl delete namespace payments --ignore-not-found

log_info "Deleting ClusterRole and ClusterRoleBinding..."
kubectl delete clusterrolebinding webapp-overprivileged-binding --ignore-not-found
kubectl delete clusterrole webapp-overprivileged --ignore-not-found

log_info "Deleting cluster-admin flag secret..."
kubectl delete secret cluster-admin-flag -n kube-system --ignore-not-found

log_info "Removing host flag file..."
if sudo rm -f /etc/flag3.txt 2>/dev/null; then
    log_info "Removed /etc/flag3.txt"
else
    log_warn "Could not remove /etc/flag3.txt (may need sudo or file doesn't exist)"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}  Cleanup Complete!${NC}"
echo "=========================================="
echo ""
echo "All attack scenario resources have been removed."
echo ""