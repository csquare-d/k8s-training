# Kubernetes Security Lab

A hands-on lab environment for learning Kubernetes fundamentals and security. This repo provides a setup script for a k3s cluster with full network policy support, kubectl exercises for beginners, and security-focused labs covering RBAC, pod security, network policies, secrets management, and cluster auditing.

## Overview

This lab is designed to take you from kubectl basics to Kubernetes security fundamentals. Whether you're new to Kubernetes or looking to strengthen your security knowledge, these exercises provide practical, hands-on experience.

**What you'll learn:**

- Essential kubectl commands and workflows
- How to inspect, create, and manage Kubernetes resources
- How RBAC controls access to cluster resources
- Hardening pods with security contexts
- Implementing zero-trust networking with network policies
- Why Kubernetes secrets aren't as secure as you might think
- How to audit a cluster for common security issues

## Prerequisites

- A Linux system (Ubuntu 20.04+, Debian 11+, RHEL 8+, or similar)
- `curl` installed
- `sudo` access
- At least 2GB of RAM available

## Repository Structure

```
k8s-training/
├── README.md
├── k8s-setup.sh
└── exercises/
    ├── k8s-basics.md
    └── security-exercises.md
```

## Quick Start

### 1. Set Up the Cluster

The setup script installs k3s with Calico CNI, which provides full network policy support.

```bash
# Make the script executable
chmod +x setup-k3s-calico.sh

# Run the setup (as a regular user, not root)
./setup-k3s-calico.sh
```

The script will:

- Remove any existing k3s installation (with your confirmation)
- Install k3s without the default Flannel CNI
- Install Calico for networking and network policy enforcement
- Configure `kubectl` to work without sudo
- Verify everything is working

Setup takes approximately 2-3 minutes.

### 2. Verify Installation

Open a new terminal (or run `source ~/.bashrc`), then:

```bash
kubectl get nodes
# Should show your node as "Ready"

kubectl get pods -n calico-system
# Should show Calico pods running
```

### 3. Start the Exercises

The exercises are located in the `exercises/` subdirectory. Start with kubectl basics if you're new to Kubernetes, then move on to security.

```bash
cd exercises/
ls -la
```

## Exercises

### Part 1: Learn kubectl (Prerequisite)

**File:** `exercises/learn-kubectl.md`

If you're new to Kubernetes or want a refresher, start here. This guide covers essential kubectl commands through nine hands-on exercises.

| Exercise | Topic | Time |
|----------|-------|------|
| 1 | Exploring the Cluster | 10 min |
| 2 | Working with Namespaces | 10 min |
| 3 | Creating and Managing Pods | 15 min |
| 4 | Deployments and Scaling | 15 min |
| 5 | Services and Networking | 15 min |
| 6 | ConfigMaps and Environment Variables | 15 min |
| 7 | Labels and Selectors | 10 min |
| 8 | Debugging and Troubleshooting | 15 min |
| 9 | Useful Output Formats | 10 min |

**Key skills you'll gain:**

- Navigating and inspecting a cluster
- Creating resources imperatively and declaratively
- Managing deployments and scaling
- Exposing applications with services
- Using labels to organize and filter resources
- Debugging failing pods
- Extracting data with JSONPath and custom output formats

### Part 2: Kubernetes Security

**File:** `exercises/k8s-security-exercises.md`

Once you're comfortable with kubectl, dive into security. These exercises cover the core concepts needed to secure a Kubernetes cluster.

| Exercise | Topic | Difficulty | Time |
|----------|-------|------------|------|
| 1 | RBAC — Restricted Service Accounts | Beginner | 15 min |
| 2 | Pod Security Contexts | Beginner | 15 min |
| 3 | Network Policies | Intermediate | 20 min |
| 4 | Secrets Management | Beginner | 10 min |
| 5 | Cluster Auditing | Intermediate | 15 min |

#### Exercise 1: RBAC

Create a service account with limited permissions and verify that it can only perform allowed actions. You'll learn how Roles, RoleBindings, and the principle of least privilege work in Kubernetes.

**Key concepts:** Roles vs ClusterRoles, RoleBindings vs ClusterRoleBindings, service accounts, `kubectl auth can-i`

#### Exercise 2: Pod Security Contexts

Deploy both an insecure and a hardened pod, then compare them. You'll see how to run containers as non-root, use read-only filesystems, and drop Linux capabilities.

**Key concepts:** `runAsNonRoot`, `readOnlyRootFilesystem`, `allowPrivilegeEscalation`, dropping capabilities

#### Exercise 3: Network Policies

Implement a default-deny network policy, then selectively allow traffic between specific pods. This exercise requires Calico (which the setup script installs).

**Key concepts:** Default-deny policies, ingress/egress rules, pod selectors, zero-trust networking

#### Exercise 4: Secrets Management

Explore how Kubernetes secrets work and understand their limitations. You'll see that secrets are only base64-encoded (not encrypted) and learn about better alternatives.

**Key concepts:** Base64 encoding vs encryption, accessing secrets from pods, RBAC for secrets, external secret managers

#### Exercise 5: Cluster Auditing

Use `kubectl` and `jq` to find common security issues in a cluster, such as pods running as root, privileged containers, and overly permissive service accounts.

**Key concepts:** Identifying insecure pods, finding privileged containers, auditing RBAC permissions

## Recommended Learning Path

```
┌─────────────────────────────────────────────────────────────┐
│  New to Kubernetes?                                         │
│                                                             │
│  1. Run setup-k3s-calico.sh                                 │
│  2. Complete exercises/learn-kubectl.md (Parts 1-9)         │
│  3. Complete exercises/k8s-security-exercises.md (Parts 1-5)│
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  Already know kubectl?                                      │
│                                                             │
│  1. Run setup-k3s-calico.sh                                 │
│  2. Skim exercises/learn-kubectl.md for any new tips        │
│  3. Complete exercises/k8s-security-exercises.md (Parts 1-5)│
└─────────────────────────────────────────────────────────────┘
```

## Cleanup

To delete all resources created during the exercises:

```bash
# Delete the learning lab namespace
kubectl delete namespace learning-lab

# Delete the security lab namespace
kubectl delete namespace security-lab
```

To completely remove k3s:

```bash
/usr/local/bin/k3s-uninstall.sh
```

## Next Steps

After completing these exercises, consider exploring:

- **[Kubernetes Goat](https://github.com/madhuakula/kubernetes-goat)** — An intentionally vulnerable cluster for practicing attacks and defenses
- **[Kyverno](https://kyverno.io/)** or **[OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)** — Policy engines for enforcing security policies automatically
- **[kubescape](https://github.com/kubescape/kubescape)** — Security scanning and compliance tool
- **[kube-bench](https://github.com/aquasecurity/kube-bench)** — CIS Kubernetes Benchmark checks
- **[Trivy](https://github.com/aquasecurity/trivy)** — Container image vulnerability scanner

## Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
