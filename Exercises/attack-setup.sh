#!/bin/bash

# Attack Scenario Setup Script
# Deploys intentionally vulnerable resources for learning Kubernetes security

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
echo "  Kubernetes Attack Scenario Setup"
echo "=========================================="
echo ""
log_warn "This script deploys INTENTIONALLY VULNERABLE resources."
log_warn "Only run this in a lab/test environment!"
echo ""
read -p "Continue? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Check kubectl access
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}[ERROR]${NC} Cannot connect to Kubernetes cluster."
    exit 1
fi

log_info "Creating namespaces..."
kubectl create namespace webapp --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace payments --dry-run=client -o yaml | kubectl apply -f -

log_info "Creating Flag 1: Database credentials in environment variables..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: webapp
type: Opaque
stringData:
  password: "flag1-sup3r-s3cr3t-passw0rd"
EOF

log_info "Creating Flag 2: Payment API secret in payments namespace..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: payment-api-key
  namespace: payments
type: Opaque
stringData:
  api-key: "flag2-payment-api-key-12345"
EOF

log_info "Creating overly permissive ClusterRole..."
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: webapp-overprivileged
rules:
# DANGEROUS: Can read secrets across all namespaces
- apiGroups: [""]
  resources: ["secrets", "pods", "namespaces"]
  verbs: ["get", "list"]
# DANGEROUS: Can exec into pods
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
EOF

log_info "Creating ServiceAccount with overprivileged binding..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: webapp-sa
  namespace: webapp
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: webapp-overprivileged-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: webapp-overprivileged
subjects:
- kind: ServiceAccount
  name: webapp-sa
  namespace: webapp
EOF

log_info "Deploying vulnerable web application..."
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vulnerable-app
  namespace: webapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vulnerable-app
  template:
    metadata:
      labels:
        app: vulnerable-app
    spec:
      serviceAccountName: webapp-sa
      containers:
      - name: app
        image: alpine:latest
        command: ["/bin/sh", "-c", "apk add --no-cache curl && sleep infinity"]
        env:
        # VULNERABLE: Secrets passed as environment variables
        - name: DB_HOST
          value: "database.internal"
        - name: DB_USER
          value: "admin"
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
        - name: APP_ENV
          value: "production"
EOF

log_info "Creating Flag 3: Host flag file..."
# Create flag on host (requires sudo)
if sudo sh -c 'echo "flag3-h0st-f1l3syst3m-acc3ss" > /etc/flag3.txt'; then
    log_info "Created /etc/flag3.txt on host"
else
    log_warn "Could not create host flag (may need sudo). Skipping Flag 3 setup."
fi

log_info "Deploying privileged debug pod (the backdoor)..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: debug-pod
  namespace: webapp
  labels:
    app: debug
spec:
  # VULNERABLE: Using overprivileged service account
  serviceAccountName: webapp-sa
  containers:
  - name: debug
    image: alpine:latest
    command: ["/bin/sh", "-c", "sleep infinity"]
    securityContext:
      # VULNERABLE: Privileged container
      privileged: true
    volumeMounts:
    # VULNERABLE: Host filesystem mounted
    - name: host-fs
      mountPath: /host
  volumes:
  - name: host-fs
    hostPath:
      path: /
      type: Directory
EOF

log_info "Creating Flag 4: Cluster admin flag..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: cluster-admin-flag
  namespace: kube-system
type: Opaque
stringData:
  flag: "flag4-full-cluster-compromise"
EOF

log_info "Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pod -l app=vulnerable-app -n webapp --timeout=120s
kubectl wait --for=condition=Ready pod/debug-pod -n webapp --timeout=120s

echo ""
echo "=========================================="
echo -e "${GREEN}  Setup Complete!${NC}"
echo "=========================================="
echo ""
echo "Vulnerabilities deployed:"
echo "  • Webapp with credentials in env vars"
echo "  • Overprivileged ServiceAccount (cross-namespace secret access)"
echo "  • Privileged debug pod with host filesystem mount"
echo "  • Flag secrets in multiple namespaces"
echo ""
echo "Start the attack:"
echo ""
echo "  kubectl exec -it -n webapp deploy/vulnerable-app -- /bin/sh"
echo ""
echo "Your objectives:"
echo "  Flag 1: Find the database password"
echo "  Flag 2: Read a secret from the payments namespace"
echo "  Flag 3: Read a file from the host filesystem"
echo "  Flag 4: Gain cluster-admin access"
echo ""
echo "Good luck!"
echo ""
