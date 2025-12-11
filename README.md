# Kubernetes Security Lab

A hands-on lab environment for learning Kubernetes fundamentals and security. This repo provides a setup script for a k3s cluster with full network policy support, kubectl exercises for beginners, security-focused labs, and an attack simulation to tie it all together.

## Overview

This lab is designed to take you from kubectl basics to Kubernetes security fundamentals, culminating in a hands-on attack scenario where you exploit real misconfigurations. Whether you're new to Kubernetes or looking to strengthen your security knowledge, these exercises provide practical experience.

**What you'll learn:**

- Essential kubectl commands and workflows
- How to inspect, create, and manage Kubernetes resources
- How RBAC controls access to cluster resources
- Hardening pods with security contexts
- Implementing zero-trust networking with network policies
- Why Kubernetes secrets aren't as secure as you might think
- How attackers exploit misconfigurations (and how to prevent it)

## Prerequisites

- A Linux system (Ubuntu 20.04+, Debian 11+, RHEL 8+, or similar)
- `curl` installed
- `sudo` access
- At least 2GB of RAM available

## Repository Structure

```
k8s-training/
├── README.md
├── setup-k3s.sh
└── exercises/
    ├── learn-kubectl.md
    ├── k8s-security-exercises.md
    ├── attack-scenario.md
    ├── attack-setup.sh
    └── attack-cleanup.sh
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

The exercises are located in the `exercises/` subdirectory. Start with kubectl basics if you're new to Kubernetes, then progress through security and finally the attack scenario.

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

**Key concepts covered:**

- Roles, ClusterRoles, and RoleBindings
- Security contexts (`runAsNonRoot`, `readOnlyRootFilesystem`, capabilities)
- Network policies and zero-trust networking
- Secrets and their limitations
- Auditing clusters for misconfigurations

### Part 3: Attack Scenario

**File:** `exercises/attack-scenario.md`

Put your knowledge to the test! This capture-the-flag style exercise deploys an intentionally vulnerable environment where you'll exploit common misconfigurations.

| Flag | Objective | Vulnerability |
|------|-----------|---------------|
| 1 | Find database credentials | Secrets in environment variables |
| 2 | Access another namespace's secrets | Overly permissive RBAC |
| 3 | Escape to the host | Privileged container + hostPath mount |
| 4 | Gain cluster-admin | Node credential theft |

**How to run:**

```bash
cd exercises/

# Deploy the vulnerable environment
chmod +x attack-scenario-setup.sh
./attack-scenario-setup.sh

# Start your attack from the compromised pod
kubectl exec -it -n webapp deploy/vulnerable-app -- /bin/sh

# When finished, clean up
chmod +x attack-scenario-cleanup.sh
./attack-scenario-cleanup.sh
```

The scenario walks you through a realistic attack chain, from initial pod access to full cluster compromise. Each flag teaches you a specific vulnerability and how to defend against it.

## Recommended Learning Path

```
┌─────────────────────────────────────────────────────────────────┐
│  New to Kubernetes?                                             │
│                                                                 │
│  1. Run setup-k3s.sh                                            │
│  2. Complete exercises/learn-kubectl.md (Parts 1-9)             │
│  3. Complete exercises/k8s-security-exercises.md (Parts 1-5)    │
│  4. Run the attack scenario to test your knowledge              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Already know kubectl?                                          │
│                                                                 │
│  1. Run setup-k3s.sh                                            │
│  2. Skim exercises/learn-kubectl.md for any new tips            │
│  3. Complete exercises/k8s-security-exercises.md (Parts 1-5)    │
│  4. Run the attack scenario to test your knowledge              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Straight to the good stuff?                                    │
│                                                                 │
│  1. Run setup-k3s.sh                                            │
│  2. Jump straight to the attack scenario                        │
│  3. Use the security exercises as reference when stuck          │
└─────────────────────────────────────────────────────────────────┘
```

## Cleanup

To delete all resources created during the exercises:

```bash
# Delete the learning lab namespace
kubectl delete namespace learning-lab --ignore-not-found

# Delete the security lab namespace
kubectl delete namespace security-lab --ignore-not-found

# Clean up attack scenario (if deployed)
./exercises/attack-scenario-cleanup.sh
```

To completely remove k3s:

```bash
/usr/local/bin/k3s-uninstall.sh
```

## Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
