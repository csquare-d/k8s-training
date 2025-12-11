# Kubernetes Security Hands-On Exercises

These exercises will help you learn core Kubernetes security concepts through practice. You'll need a Kubernetes cluster (minikube, kind, or k3s work well for learning).

## Prerequisites

```bash
# Verify you have kubectl installed and a cluster running
kubectl version
kubectl get nodes
```

---

## Exercise 1: RBAC — Create a Restricted User

**Goal:** Create a service account that can only view pods in a specific namespace.

### Step 1: Create a namespace
```bash
kubectl create namespace security-lab
```

### Step 2: Create a service account
```bash
kubectl create serviceaccount pod-viewer -n security-lab
```

### Step 3: Create a Role (namespace-scoped permissions)
```yaml
# Save as pod-viewer-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: security-lab
  name: pod-viewer-role
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

```bash
kubectl apply -f pod-viewer-role.yaml
```

### Step 4: Bind the role to the service account
```yaml
# Save as pod-viewer-binding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-viewer-binding
  namespace: security-lab
subjects:
- kind: ServiceAccount
  name: pod-viewer
  namespace: security-lab
roleRef:
  kind: Role
  name: pod-viewer-role
  apiGroup: rbac.authorization.k8s.io
```

```bash
kubectl apply -f pod-viewer-binding.yaml
```

### Step 5: Test the permissions
```bash
# This should work (listing pods)
kubectl auth can-i list pods -n security-lab --as=system:serviceaccount:security-lab:pod-viewer

# This should fail (creating pods)
kubectl auth can-i create pods -n security-lab --as=system:serviceaccount:security-lab:pod-viewer

# This should fail (listing pods in default namespace)
kubectl auth can-i list pods -n default --as=system:serviceaccount:security-lab:pod-viewer
```

### What you learned:
- Roles define WHAT actions are allowed on WHICH resources
- RoleBindings connect WHO (subjects) to roles
- Permissions are namespace-scoped with Roles (use ClusterRoles for cluster-wide)

---

## Exercise 2: Pod Security Context — Run as Non-Root

**Goal:** Deploy a pod that runs as a non-root user with a read-only filesystem.

### Step 1: Deploy an insecure pod first (to compare)
```yaml
# Save as insecure-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: insecure-pod
  namespace: security-lab
spec:
  containers:
  - name: nginx
    image: nginx:latest
```

```bash
kubectl apply -f insecure-pod.yaml
```

### Step 2: Check what user it runs as
```bash
kubectl exec -n security-lab insecure-pod -- id
# Likely shows: uid=0(root)
```

### Step 3: Deploy a secure pod
```yaml
# Save as secure-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  namespace: security-lab
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
  containers:
  - name: app
    image: busybox:latest
    command: ["sleep", "3600"]
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
          - ALL
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  volumes:
  - name: tmp
    emptyDir: {}
```

```bash
kubectl apply -f secure-pod.yaml
```

### Step 4: Verify the security settings
```bash
# Check the user
kubectl exec -n security-lab secure-pod -- id
# Shows: uid=1000 gid=1000

# Try to write to the root filesystem (should fail)
kubectl exec -n security-lab secure-pod -- touch /test-file
# Error: Read-only file system

# Writing to /tmp should work (we mounted an emptyDir there)
kubectl exec -n security-lab secure-pod -- touch /tmp/test-file
```

### What you learned:
- `runAsNonRoot: true` prevents containers from running as root
- `readOnlyRootFilesystem: true` prevents filesystem modifications
- `allowPrivilegeEscalation: false` prevents gaining more privileges
- `capabilities.drop: [ALL]` removes Linux capabilities

---

## Exercise 3: Network Policies — Implement Zero Trust

**Goal:** Create a default-deny policy and then allow only specific traffic.

### Step 1: Deploy two test pods
```yaml
# Save as network-test-pods.yaml
apiVersion: v1
kind: Pod
metadata:
  name: client-pod
  namespace: security-lab
  labels:
    app: client
spec:
  containers:
  - name: client
    image: busybox:latest
    command: ["sleep", "3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: server-pod
  namespace: security-lab
  labels:
    app: server
spec:
  containers:
  - name: server
    image: nginx:latest
```

```bash
kubectl apply -f network-test-pods.yaml
```

### Step 2: Verify connectivity works (before any policies)
```bash
# Get the server pod's IP
SERVER_IP=$(kubectl get pod server-pod -n security-lab -o jsonpath='{.status.podIP}')

# Test connectivity from client to server
kubectl exec -n security-lab client-pod -- wget -qO- --timeout=3 http://$SERVER_IP
# Should return nginx HTML
```

### Step 3: Apply a default-deny ingress policy
```yaml
# Save as default-deny.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: security-lab
spec:
  podSelector: {}  # Applies to all pods in namespace
  policyTypes:
  - Ingress
```

```bash
kubectl apply -f default-deny.yaml
```

### Step 4: Test connectivity again (should fail now)
```bash
kubectl exec -n security-lab client-pod -- wget -qO- --timeout=3 http://$SERVER_IP
# Should timeout/fail
```

### Step 5: Allow traffic from client to server
```yaml
# Save as allow-client-to-server.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-client-to-server
  namespace: security-lab
spec:
  podSelector:
    matchLabels:
      app: server
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: client
    ports:
    - protocol: TCP
      port: 80
```

```bash
kubectl apply -f allow-client-to-server.yaml
```

### Step 6: Test again (should work now)
```bash
kubectl exec -n security-lab client-pod -- wget -qO- --timeout=3 http://$SERVER_IP
# Should return nginx HTML again
```

### What you learned:
- Default-deny policies block all traffic not explicitly allowed
- Network policies use label selectors to target pods
- You can control traffic by source (from) and destination (podSelector)

**Note:** Network policies require a CNI that supports them (Calico, Cilium, etc.). Minikube with the default CNI may not enforce these.

---

## Exercise 4: Secrets — Understanding the Risks

**Goal:** See why default Kubernetes secrets aren't truly secure.

### Step 1: Create a secret
```bash
kubectl create secret generic my-secret \
  --from-literal=password=SuperSecret123 \
  -n security-lab
```

### Step 2: View the secret (it's only base64 encoded!)
```bash
# Get the secret
kubectl get secret my-secret -n security-lab -o yaml

# Decode it easily
kubectl get secret my-secret -n security-lab -o jsonpath='{.data.password}' | base64 -d
# Output: SuperSecret123
```

### Step 3: See how easily a pod can access secrets
```yaml
# Save as secret-reader-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-reader
  namespace: security-lab
spec:
  containers:
  - name: reader
    image: busybox:latest
    command: ["sleep", "3600"]
    env:
    - name: MY_PASSWORD
      valueFrom:
        secretKeyRef:
          name: my-secret
          key: password
```

```bash
kubectl apply -f secret-reader-pod.yaml
kubectl exec -n security-lab secret-reader -- env | grep MY_PASSWORD
# Shows the secret in plain text
```

### Key Security Takeaways for Secrets:
1. Base64 is encoding, NOT encryption
2. Anyone with `get secrets` permission can read all secrets
3. Secrets are stored in etcd — enable encryption at rest
4. Consider external secret managers (Vault, AWS Secrets Manager, etc.)
5. Use RBAC to limit who can read secrets

---

## Exercise 5: Audit Your Cluster

**Goal:** Use kubectl to find security issues.

### Check for pods running as root
```bash
kubectl get pods -A -o json | jq -r '
  .items[] |
  select(.spec.containers[].securityContext.runAsNonRoot != true) |
  "\(.metadata.namespace)/\(.metadata.name)"
'
```

### Check for pods with privileged containers
```bash
kubectl get pods -A -o json | jq -r '
  .items[] |
  select(.spec.containers[].securityContext.privileged == true) |
  "\(.metadata.namespace)/\(.metadata.name)"
'
```

### Check for service accounts with cluster-admin
```bash
kubectl get clusterrolebindings -o json | jq -r '
  .items[] |
  select(.roleRef.name == "cluster-admin") |
  "\(.metadata.name): \(.subjects)"
'
```

### List all pods using the default service account
```bash
kubectl get pods -A -o json | jq -r '
  .items[] |
  select(.spec.serviceAccountName == "default" or .spec.serviceAccountName == null) |
  "\(.metadata.namespace)/\(.metadata.name)"
'
```

---

## Cleanup

```bash
kubectl delete namespace security-lab
```

---

## Next Steps

1. **Install a policy engine**: Try Kyverno or OPA/Gatekeeper to enforce policies automatically
2. **Set up Pod Security Standards**: Configure the built-in admission controller
3. **Practice with vulnerable clusters**: Try platforms like [Kubernetes Goat](https://github.com/madhuakula/kubernetes-goat)
4. **Scan your cluster**: Use tools like `kubescape`, `trivy`, or `kube-bench`

---

## Useful Commands Reference

```bash
# Check if you can perform an action
kubectl auth can-i <verb> <resource> -n <namespace>

# Check what a service account can do
kubectl auth can-i --list --as=system:serviceaccount:<ns>:<sa>

# View all roles in a namespace
kubectl get roles,rolebindings -n <namespace>

# View cluster-wide roles
kubectl get clusterroles,clusterrolebindings

# Describe a network policy
kubectl describe networkpolicy <name> -n <namespace>
```
