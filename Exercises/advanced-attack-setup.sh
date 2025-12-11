#!/bin/bash

# Advanced Attack Scenario Setup Script
# Deploys multiple vulnerable applications with different attack paths

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }
log_target() { echo -e "${PURPLE}[TARGET]${NC} $1"; }

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║       ADVANCED KUBERNETES ATTACK SCENARIO SETUP               ║"
echo "║                    Multi-Path Edition                         ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================================
# NAMESPACES
# ============================================================================
log_step "Creating namespaces..."
for ns in external-apps internal-apps payments database secrets-vault; do
    kubectl create namespace $ns --dry-run=client -o yaml | kubectl apply -f -
done

# ============================================================================
# APPLICATION CODE (ConfigMaps)
# ============================================================================
log_step "Creating application code ConfigMaps..."

kubectl create configmap admin-panel-code -n external-apps \
    --from-file=app.py="${SCRIPT_DIR}/advanced-vulnerable-apps/admin-panel.py" \
    --dry-run=client -o yaml | kubectl apply -f -

kubectl create configmap internal-api-code -n internal-apps \
    --from-file=app.py="${SCRIPT_DIR}/advanced-vulnerable-apps/internal-api.py" \
    --dry-run=client -o yaml | kubectl apply -f -

kubectl create configmap legacy-app-code -n external-apps \
    --from-file=app.py="${SCRIPT_DIR}/advanced-vulnerable-apps/legacy-app.py" \
    --dry-run=client -o yaml | kubectl apply -f -

# ============================================================================
# SECRETS (Multiple Flags)
# ============================================================================
log_step "Creating secrets (flags)..."

# Flag: Database credentials (found multiple ways)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: database
type: Opaque
stringData:
  host: "postgres.database.svc"
  username: "app_user"
  password: "flag-db-cr3d5-4r3-s3cr3t"
EOF

# Flag: Payment API key
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: payment-gateway-key
  namespace: payments
type: Opaque
stringData:
  api-key: "flag-p4ym3nt-k3y-9876"
  merchant-id: "ACME-12345"
EOF

# Flag: Internal API key
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: internal-api-key
  namespace: internal-apps
type: Opaque
stringData:
  key: "flag-1nt3rn4l-4p1-k3y"
EOF

# Flag: Crown Jewels - CEO credentials
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: executive-credentials
  namespace: secrets-vault
type: Opaque
stringData:
  ceo-email: "ceo@acme.corp"
  ceo-password: "flag-cr0wn-j3w3ls-c30-p4ss"
  board-access-token: "flag-b04rd-4cc3ss-t0k3n"
EOF

# Flag: Backup encryption key
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: backup-encryption-key
  namespace: database
type: Opaque
stringData:
  encryption-key: "flag-b4ckup-3ncrypt10n-k3y"
EOF

# Flag: Cluster admin (final flag)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: cluster-admin-flag
  namespace: kube-system
type: Opaque
stringData:
  flag: "flag-CLUSTER-ADMIN-ACHIEVED"
  message: "Congratulations! You have achieved full cluster compromise."
EOF

# ============================================================================
# SERVICE ACCOUNTS WITH VARYING PERMISSIONS
# ============================================================================
log_step "Creating service accounts with different privilege levels..."

# Admin Panel SA - Can exec into pods in external-apps only
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-panel-sa
  namespace: external-apps
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: admin-panel-role
  namespace: external-apps
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: admin-panel-binding
  namespace: external-apps
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: admin-panel-role
subjects:
- kind: ServiceAccount
  name: admin-panel-sa
  namespace: external-apps
EOF

# Internal API SA - Can read secrets in multiple namespaces (overprivileged)
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: internal-api-sa
  namespace: internal-apps
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: internal-api-role
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
  # Overprivileged: can read secrets across namespaces
- apiGroups: [""]
  resources: ["pods", "services", "namespaces"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: internal-api-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: internal-api-role
subjects:
- kind: ServiceAccount
  name: internal-api-sa
  namespace: internal-apps
EOF

# Legacy App SA - Very overprivileged (legacy mistake)
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: legacy-app-sa
  namespace: external-apps
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: legacy-app-role
rules:
- apiGroups: [""]
  resources: ["*"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: legacy-app-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: legacy-app-role
subjects:
- kind: ServiceAccount
  name: legacy-app-sa
  namespace: external-apps
EOF

# Backup SA - Has access to database secrets
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backup-sa
  namespace: database
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: backup-role
  namespace: database
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: backup-binding
  namespace: database
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: backup-role
subjects:
- kind: ServiceAccount
  name: backup-sa
  namespace: database
EOF

# ============================================================================
# DEPLOY APPLICATIONS
# ============================================================================
log_step "Deploying vulnerable applications..."

# Admin Panel (default creds: admin/admin)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: admin-panel
  namespace: external-apps
spec:
  replicas: 1
  selector:
    matchLabels:
      app: admin-panel
  template:
    metadata:
      labels:
        app: admin-panel
    spec:
      serviceAccountName: admin-panel-sa
      containers:
      - name: app
        image: python:3.11-slim
        command: ["/bin/bash", "-c"]
        args:
          - |
            pip install flask requests --quiet --disable-pip-version-check
            python /app/app.py
        ports:
        - containerPort: 8080
        env:
        - name: APP_ENV
          value: "production"
        - name: DB_HOST
          value: "postgres.database.svc"
        - name: DB_USER
          value: "admin_user"
        - name: DB_PASSWORD
          value: "flag-db-cr3d5-4r3-s3cr3t"
        - name: INTERNAL_API_KEY
          value: "flag-1nt3rn4l-4p1-k3y"
        volumeMounts:
        - name: app-code
          mountPath: /app
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: app-code
        configMap:
          name: admin-panel-code
---
apiVersion: v1
kind: Service
metadata:
  name: admin-panel
  namespace: external-apps
spec:
  type: NodePort
  selector:
    app: admin-panel
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30081
EOF

# Internal API (SSRF vulnerable)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: internal-api
  namespace: internal-apps
spec:
  replicas: 1
  selector:
    matchLabels:
      app: internal-api
  template:
    metadata:
      labels:
        app: internal-api
    spec:
      serviceAccountName: internal-api-sa
      containers:
      - name: app
        image: python:3.11-slim
        command: ["/bin/bash", "-c"]
        args:
          - |
            pip install flask requests --quiet --disable-pip-version-check
            python /app/app.py
        ports:
        - containerPort: 8080
        env:
        - name: APP_ENV
          value: "production"
        - name: DB_HOST
          value: "postgres.database.svc"
        - name: DB_USER
          value: "api_user"
        - name: DB_PASSWORD
          value: "flag-db-cr3d5-4r3-s3cr3t"
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        volumeMounts:
        - name: app-code
          mountPath: /app
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: app-code
        configMap:
          name: internal-api-code
---
apiVersion: v1
kind: Service
metadata:
  name: internal-api
  namespace: internal-apps
spec:
  selector:
    app: internal-api
  ports:
  - port: 80
    targetPort: 8080
EOF

# Legacy App (command injection)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: legacy-app
  namespace: external-apps
spec:
  replicas: 1
  selector:
    matchLabels:
      app: legacy-app
  template:
    metadata:
      labels:
        app: legacy-app
    spec:
      serviceAccountName: legacy-app-sa
      containers:
      - name: app
        image: python:3.11-slim
        command: ["/bin/bash", "-c"]
        args:
          - |
            apt-get update && apt-get install -y dnsutils curl --no-install-recommends
            pip install flask --quiet --disable-pip-version-check
            mkdir -p /app/files
            echo "This is a sample report." > /app/files/report.txt
            python /app/app.py
        ports:
        - containerPort: 8080
        env:
        - name: APP_ENV
          value: "production"
        - name: DB_HOST
          value: "postgres.database.svc"
        - name: DB_USER
          value: "legacy_user"
        - name: DB_PASSWORD
          value: "flag-db-cr3d5-4r3-s3cr3t"
        - name: BACKUP_API_KEY
          value: "flag-b4ckup-3ncrypt10n-k3y"
        volumeMounts:
        - name: app-code
          mountPath: /app
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: app-code
        configMap:
          name: legacy-app-code
---
apiVersion: v1
kind: Service
metadata:
  name: legacy-app
  namespace: external-apps
spec:
  type: NodePort
  selector:
    app: legacy-app
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30082
EOF

# ============================================================================
# PRIVILEGED/MISCONFIGURED PODS
# ============================================================================
log_step "Deploying misconfigured pods..."

# Debug pod (privileged with host mount)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: debug-tools
  namespace: internal-apps
  labels:
    app: debug-tools
spec:
  serviceAccountName: internal-api-sa
  containers:
  - name: debug
    image: alpine:latest
    command: ["/bin/sh", "-c", "apk add --no-cache curl jq && sleep infinity"]
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

# Backup pod (has host mount to /var/backups but not privileged)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: backup-agent
  namespace: database
  labels:
    app: backup-agent
spec:
  serviceAccountName: backup-sa
  containers:
  - name: backup
    image: alpine:latest
    command: ["/bin/sh", "-c", "apk add --no-cache curl && sleep infinity"]
    volumeMounts:
    - name: backup-volume
      mountPath: /backups
    - name: host-var
      mountPath: /host-var
      readOnly: true
  volumes:
  - name: backup-volume
    emptyDir: {}
  - name: host-var
    hostPath:
      path: /var
      type: Directory
EOF

# ============================================================================
# HOST FLAGS
# ============================================================================
log_step "Creating host flag files..."
if sudo sh -c 'echo "flag-h0st-4cc3ss-ach13v3d" > /etc/flag-host.txt'; then
    log_info "Created /etc/flag-host.txt"
fi
if sudo sh -c 'mkdir -p /var/secrets && echo "flag-v4r-s3cr3ts-f0und" > /var/secrets/sensitive.txt'; then
    log_info "Created /var/secrets/sensitive.txt"
fi

# ============================================================================
# WAIT FOR DEPLOYMENTS
# ============================================================================
log_step "Waiting for deployments to be ready (this may take a few minutes)..."

echo "Waiting for admin-panel..."
kubectl wait --for=condition=Available deployment/admin-panel -n external-apps --timeout=300s || true

echo "Waiting for internal-api..."
kubectl wait --for=condition=Available deployment/internal-api -n internal-apps --timeout=300s || true

echo "Waiting for legacy-app..."
kubectl wait --for=condition=Available deployment/legacy-app -n external-apps --timeout=300s || true

echo "Waiting for debug-tools pod..."
kubectl wait --for=condition=Ready pod/debug-tools -n internal-apps --timeout=120s || true

echo "Waiting for backup-agent pod..."
kubectl wait --for=condition=Ready pod/backup-agent -n database --timeout=120s || true

# ============================================================================
# OUTPUT TARGET INFORMATION
# ============================================================================
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
if [[ -z "$NODE_IP" ]]; then
    NODE_IP="localhost"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    SETUP COMPLETE                             ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "                    EXTERNAL TARGETS                            "
echo "═══════════════════════════════════════════════════════════════"
echo ""
log_target "Admin Panel:  http://${NODE_IP}:30081"
echo "              Default credentials: admin/admin, operator/operator123, guest/guest"
echo ""
log_target "Legacy App:   http://${NODE_IP}:30082"
echo "              Old-school vulnerable application"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "                    INTERNAL SERVICES                           "
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "  • internal-api.internal-apps.svc (ClusterIP only)"
echo "  • Various pods with different privilege levels"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "                    YOUR OBJECTIVES                             "
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "  🚩 Find the database credentials"
echo "  🚩 Access the payment gateway API key"
echo "  🚩 Retrieve the internal API key"
echo "  🚩 Obtain the CEO's credentials (crown jewels)"
echo "  🚩 Escape to the host filesystem"
echo "  🚩 Achieve cluster-admin access"
echo ""
echo "  Multiple paths exist to each objective."
echo "  Document the vulnerabilities you find!"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Good luck, and happy hacking!"
echo ""