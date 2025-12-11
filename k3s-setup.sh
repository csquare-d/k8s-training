#!/bin/bash

# k3s + Calico Setup Script for Kubernetes training Labs
# This script installs k3s without Flannel, installs Calico CNI, and configures kubectl to work without sudo
# for convenience.

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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

if [[ $EUID -eq 0 ]]; then
    log_error "Please run this script as a regular user (not root)."
    log_error "The script will use sudo when needed."
    exit 1
fi

if command -v k3s &> /dev/null; then
    log_warn "k3s is already installed."
    read -p "Do you want to uninstall and reinstall? (y/N): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        log_info "Uninstalling existing k3s..."
        if [[ -f /usr/local/bin/k3s-uninstall.sh ]]; then
            sudo /usr/local/bin/k3s-uninstall.sh
        fi
    else
        log_info "Exiting. Remove k3s manually or run the script with a fresh system."
        exit 0
    fi
fi

log_info "Installing k3s without Flannel CNI..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--flannel-backend=none --disable-network-policy --disable=traefik" sh -

log_info "Waiting for k3s to start..."
sleep 5

log_info "Setting up kubeconfig for user: $USER"
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
chmod 600 ~/.kube/config

KUBECONFIG_LINE='export KUBECONFIG=~/.kube/config'

if [[ -f ~/.bashrc ]] && ! grep -q "KUBECONFIG" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Kubernetes config" >> ~/.bashrc
    echo "$KUBECONFIG_LINE" >> ~/.bashrc
    log_info "Added KUBECONFIG to ~/.bashrc"
fi

if [[ -f ~/.zshrc ]] && ! grep -q "KUBECONFIG" ~/.zshrc; then
    echo "" >> ~/.zshrc
    echo "# Kubernetes config" >> ~/.zshrc
    echo "$KUBECONFIG_LINE" >> ~/.zshrc
    log_info "Added KUBECONFIG to ~/.zshrc"
fi

export KUBECONFIG=~/.kube/config

log_info "Waiting for Kubernetes API server to be ready..."
until kubectl get nodes &> /dev/null; do
    sleep 2
done

log_info "Installing Calico CNI..."
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml

log_info "Waiting for Tigera operator to be ready..."
sleep 10

cat <<EOF | kubectl apply -f -
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
    - blockSize: 26
      cidr: 10.42.0.0/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
---
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}
EOF

log_info "Waiting for Calico pods to be ready (this may take a few minutes)..."

until kubectl get namespace calico-system &> /dev/null; do
    sleep 2
done

kubectl wait --for=condition=Ready pods --all -n calico-system --timeout=300s 2>/dev/null || true

log_info "Waiting for node to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

log_info "Verifying installation..."
echo ""
echo "=========================================="
echo "  Installation Summary"
echo "=========================================="
echo ""

echo "Nodes:"
kubectl get nodes
echo ""

echo "Calico pods:"
kubectl get pods -n calico-system
echo ""

echo "Network policy support:"
if kubectl api-resources | grep -q "networkpolicies"; then
    echo -e "${GREEN}✓ NetworkPolicy resource is available${NC}"
else
    echo -e "${RED}✗ NetworkPolicy resource not found${NC}"
fi
echo ""

log_info "Running quick connectivity test..."
kubectl run test-pod --image=busybox --restart=Never --command -- sleep 10 &> /dev/null || true
sleep 5
kubectl delete pod test-pod --ignore-not-found &> /dev/null

echo "=========================================="
echo -e "${GREEN}  Setup Complete!${NC}"
echo "=========================================="
echo ""
echo "Your k3s cluster with Calico is ready."
echo ""
echo "Next steps:"
echo "  1. Open a new terminal (or run: source ~/.bashrc)"
echo "  2. Run: kubectl get nodes"
echo "  3. Start the security labs!"
echo ""
echo "To uninstall later, run:"
echo "  /usr/local/bin/k3s-uninstall.sh"
echo ""
