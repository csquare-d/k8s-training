#!/bin/bash

# k3s + Calico Setup Script for Kubernetes Training Labs
# This script installs k3s without Flannel, installs Calico CNI, and configures kubectl to work without sudo.

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

# Must run as regular user
if [[ $EUID -eq 0 ]]; then
    log_error "Please run this script as a regular user (not root)."
    log_error "The script will use sudo when needed."
    exit 1
fi

# Check for existing installation
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

# Install k3s without Flannel CNI
# --write-kubeconfig-mode=644 makes the config world-readable (we'll copy and secure it anyway)
log_info "Installing k3s without Flannel CNI..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--flannel-backend=none --disable-network-policy --disable=traefik --write-kubeconfig-mode=644" sh -

log_info "Waiting for k3s to start..."
sleep 5

# Set up kubeconfig for non-root user
log_info "Setting up kubeconfig for user: $USER"
mkdir -p "$HOME/.kube"

# Copy and fix ownership
sudo cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
sudo chown "$USER":"$USER" "$HOME/.kube/config"
chmod 600 "$HOME/.kube/config"

# Add KUBECONFIG to shell rc files
KUBECONFIG_LINE='export KUBECONFIG="$HOME/.kube/config"'

add_to_rc_file() {
    local rcfile="$1"
    if [[ -f "$rcfile" ]]; then
        # Check if already configured (various formats)
        if grep -q 'KUBECONFIG=' "$rcfile"; then
            log_info "KUBECONFIG already configured in $rcfile"
        else
            echo "" >> "$rcfile"
            echo "# Kubernetes config" >> "$rcfile"
            echo "$KUBECONFIG_LINE" >> "$rcfile"
            log_info "Added KUBECONFIG to $rcfile"
        fi
    fi
}

add_to_rc_file "$HOME/.bashrc"
add_to_rc_file "$HOME/.zshrc"

# Also add to .profile for login shells
if [[ -f "$HOME/.profile" ]]; then
    if ! grep -q 'KUBECONFIG=' "$HOME/.profile"; then
        echo "" >> "$HOME/.profile"
        echo "# Kubernetes config" >> "$HOME/.profile"
        echo "$KUBECONFIG_LINE" >> "$HOME/.profile"
        log_info "Added KUBECONFIG to ~/.profile"
    fi
fi

# Export for current script execution
export KUBECONFIG="$HOME/.kube/config"

# Wait for API server
log_info "Waiting for Kubernetes API server to be ready..."
until kubectl get nodes &> /dev/null; do
    sleep 2
done

# Install Calico CNI
log_info "Installing Calico CNI..."
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml

log_info "Waiting for Tigera operator to be ready..."
sleep 10

# Apply Calico configuration
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

# Wait for calico-system namespace
until kubectl get namespace calico-system &> /dev/null; do
    sleep 2
done

# Wait for Calico pods
kubectl wait --for=condition=Ready pods --all -n calico-system --timeout=300s 2>/dev/null || true

# Wait for node to be ready
log_info "Waiting for node to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Verify installation
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

# Quick connectivity test
log_info "Running quick connectivity test..."
kubectl run test-pod --image=busybox --restart=Never --command -- sleep 10 &> /dev/null || true
sleep 5
kubectl delete pod test-pod --ignore-not-found &> /dev/null

# Verify kubectl works without sudo
echo ""
echo "=========================================="
echo "  Verifying kubectl Configuration"
echo "=========================================="
echo ""

# Test that config file exists and is readable
if [[ -r "$HOME/.kube/config" ]]; then
    echo -e "${GREEN}✓${NC} Kubeconfig exists at ~/.kube/config"
else
    echo -e "${RED}✗${NC} Kubeconfig not readable at ~/.kube/config"
fi

# Check file permissions
PERMS=$(stat -c "%a" "$HOME/.kube/config" 2>/dev/null || stat -f "%OLp" "$HOME/.kube/config" 2>/dev/null)
if [[ "$PERMS" == "600" ]]; then
    echo -e "${GREEN}✓${NC} Kubeconfig has correct permissions (600)"
else
    echo -e "${YELLOW}!${NC} Kubeconfig permissions: $PERMS (should be 600)"
fi

# Check ownership
OWNER=$(stat -c "%U" "$HOME/.kube/config" 2>/dev/null || stat -f "%Su" "$HOME/.kube/config" 2>/dev/null)
if [[ "$OWNER" == "$USER" ]]; then
    echo -e "${GREEN}✓${NC} Kubeconfig owned by $USER"
else
    echo -e "${RED}✗${NC} Kubeconfig owned by $OWNER (should be $USER)"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}  Setup Complete!${NC}"
echo "=========================================="
echo ""
echo "Your k3s cluster with Calico is ready."
echo ""
echo -e "${YELLOW}IMPORTANT: To use kubectl without sudo, do ONE of the following:${NC}"
echo ""
echo "  Option 1: Open a new terminal window"
echo ""
echo "  Option 2: Reload your shell config:"
echo -e "            ${GREEN}source ~/.bashrc${NC}   (for bash)"
echo -e "            ${GREEN}source ~/.zshrc${NC}    (for zsh)"
echo ""
echo "  Option 3: Set the variable manually for this session:"
echo -e "            ${GREEN}export KUBECONFIG=~/.kube/config${NC}"
echo ""
echo "Then verify kubectl works without sudo:"
echo -e "  ${GREEN}kubectl get nodes${NC}"
echo ""
echo "You should see your node listed with STATUS 'Ready'."
echo ""
echo "To uninstall later, run:"
echo "  /usr/local/bin/k3s-uninstall.sh"
echo ""
