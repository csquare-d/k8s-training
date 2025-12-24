#!/bin/bash

# Attack Setup Script
# Deploys intentionally vulnerable resources for learning Kubernetes security

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
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

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_step "Creating namespaces..."
kubectl create namespace webapp --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace payments --dry-run=client -o yaml | kubectl apply -f -

log_step "Creating vulnerable web application code (ConfigMap)..."
kubectl create configmap vulnerable-app-code -n webapp \
    --from-file=app.py="${SCRIPT_DIR}/vulnerable-app/app.py" \
    --dry-run=client -o yaml | kubectl apply -f -

log_step "Creating Flag 1: Database credentials in environment variables..."
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

log_step "Creating Flag 2: Payment API secret in payments namespace..."
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

log_step "Creating overly permissive ClusterRole..."
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

log_step "Creating ServiceAccount with overprivileged binding..."
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

log_step "Deploying vulnerable web application (Flag 0: Initial Access)..."
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
        image: python:3.11-slim
        command: ["/bin/bash", "-c"]
        args:
          - |
            apt-get update && apt-get install -y iputils-ping curl --no-install-recommends
            pip install flask --quiet --disable-pip-version-check
            python /app/app.py
        ports:
        - containerPort: 8080
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
        volumeMounts:
        - name: app-code
          mountPath: /app
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: app-code
        configMap:
          name: vulnerable-app-code
---
apiVersion: v1
kind: Service
metadata:
  name: vulnerable-app
  namespace: webapp
spec:
  type: NodePort
  selector:
    app: vulnerable-app
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
EOF

log_step "Creating Flag 3: Host flag file..."
if sudo sh -c 'echo "flag3-h0st-f1l3syst3m-acc3ss" > /etc/flag3.txt'; then
    log_info "Created /etc/flag3.txt on host"
else
    log_warn "Could not create host flag (may need sudo). Skipping Flag 3 setup."
fi

log_step "Deploying privileged debug pod (the backdoor)..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: debug-pod
  namespace: webapp
  labels:
    app: debug
spec:
  serviceAccountName: webapp-sa
  containers:
  - name: debug
    image: alpine:latest
    command: ["/bin/sh", "-c", "sleep infinity"]
    securityContext:
      privileged: true
    volumeMounts:
    - name: host-fs
      mountPath: /host
  volumes:
  - name: host-fs
    hostPath:
      path: /
      type: Directory
EOF

log_step "Creating Flag 4: Cluster admin flag..."
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

log_step "Waiting for pods to be ready..."
echo "Waiting for vulnerable-app deployment (this may take a minute for image pull)..."
kubectl wait --for=condition=Available deployment/vulnerable-app -n webapp --timeout=300s || {
    log_warn "Deployment taking longer than expected. Check pod status with:"
    echo "  kubectl get pods -n webapp"
    echo "  kubectl logs -n webapp -l app=vulnerable-app"
}
kubectl wait --for=condition=Ready pod/debug-pod -n webapp --timeout=120s

# Get access information
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
if [[ -z "$NODE_IP" ]]; then
    NODE_IP="localhost"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}  Setup Complete!${NC}"
echo "=========================================="
echo ""
echo "Vulnerabilities deployed:"
echo "  • Vulnerable web app with command injection (Flag 0)"
echo "  • Webapp with credentials in env vars (Flag 1)"
echo "  • Overprivileged ServiceAccount (Flag 2)"
echo "  • Privileged debug pod with host mount (Flag 3)"
echo "  • Cluster admin flag (Flag 4)"
echo ""
echo "=========================================="
echo -e "${CYAN}  TARGET INFORMATION${NC}"
echo "=========================================="
echo ""
echo "The vulnerable web application is exposed at:"
echo ""
echo -e "  ${GREEN}http://${NODE_IP}:30080${NC}"
echo ""
echo "If running locally, try:"
echo -e "  ${GREEN}http://localhost:30080${NC}"
echo ""
echo "=========================================="
echo ""
echo "Your objectives:"
echo " Flag 0: Gain initial access via the web application"
echo " Flag 1: Find the database password"
echo " Flag 2: Read a secret from the payments namespace"
echo " Flag 3: Read a file from the host filesystem"
echo " Flag 4: Gain cluster-admin access"
echo ""
echo "Start by exploring the web application!"
echo "  Flag 1: Find the database password"
echo "  Flag 2: Read a secret from the payments namespace"
echo "  Flag 3: Read a file from the host filesystem"
echo "  Flag 4: Gain cluster-admin access"
echo ""
echo "Good luck!"
echo ""
