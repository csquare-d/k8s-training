#!/bin/bash

# Advanced Attack Scenario Cleanup Script
# Removes all resources created by advanced-attack-setup.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║       ADVANCED ATTACK SCENARIO CLEANUP                        ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

read -p "Remove all advanced attack scenario resources? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

log_info "Deleting namespaces..."
for ns in external-apps internal-apps payments database secrets-vault; do
    kubectl delete namespace $ns --ignore-not-found &
done
wait

log_info "Deleting ClusterRoles and ClusterRoleBindings..."
kubectl delete clusterrolebinding internal-api-binding legacy-app-binding --ignore-not-found
kubectl delete clusterrole internal-api-role legacy-app-role --ignore-not-found

log_info "Deleting cluster-admin flag..."
kubectl delete secret cluster-admin-flag -n kube-system --ignore-not-found

log_info "Removing host flag files..."
sudo rm -f /etc/flag-host.txt 2>/dev/null || log_warn "Could not remove /etc/flag-host.txt"
sudo rm -rf /var/secrets 2>/dev/null || log_warn "Could not remove /var/secrets"

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    CLEANUP COMPLETE                           ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "All advanced attack scenario resources have been removed."
echo ""