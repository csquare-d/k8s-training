# Learn kubectl — Hands-On Exercises

This guide covers essential kubectl commands and workflows. Complete these exercises before moving on to the security-focused labs.

## Prerequisites

- A running Kubernetes cluster (k3s, minikube, kind, etc.)
- kubectl installed and configured

Verify your setup:

```bash
kubectl version
kubectl cluster-info
```

---

## Exercise 1: Exploring the Cluster

**Goal:** Learn how to inspect your cluster and its resources.

### Get cluster information

```bash
# Basic cluster info
kubectl cluster-info

# View all nodes
kubectl get nodes

# Get more details about nodes
kubectl get nodes -o wide

# Describe a specific node (replace with your node name)
kubectl describe node <node-name>
```

### Explore API resources

```bash
# List all available resource types
kubectl api-resources

# List only namespaced resources
kubectl api-resources --namespaced=true

# List only cluster-scoped resources
kubectl api-resources --namespaced=false

# Get short names for resources (useful for faster typing)
kubectl api-resources | grep -E "^NAME|pod|service|deployment"
```

### Check cluster health

```bash
# View all pods across all namespaces
kubectl get pods -A

# View system components
kubectl get pods -n kube-system

# Check component statuses (may be deprecated in newer versions)
kubectl get componentstatuses
```

### What you learned:
- `get` retrieves resources
- `-o wide` shows additional columns
- `describe` shows detailed information
- `-A` or `--all-namespaces` queries all namespaces
- `-n <namespace>` targets a specific namespace

---

## Exercise 2: Working with Namespaces

**Goal:** Understand how namespaces organize resources.

### List and create namespaces

```bash
# List all namespaces
kubectl get namespaces

# Create a new namespace
kubectl create namespace learning-lab

# Verify it was created
kubectl get ns learning-lab
```

### Set a default namespace

```bash
# View your current context
kubectl config current-context

# Set default namespace for your context
kubectl config set-context --current --namespace=learning-lab

# Verify (this should now target learning-lab by default)
kubectl config view --minify | grep namespace

# Reset to default namespace later
kubectl config set-context --current --namespace=default
```

### What you learned:
- Namespaces provide logical separation of resources
- You can set a default namespace to avoid typing `-n` repeatedly
- `ns` is the short name for `namespaces`

---

## Exercise 3: Creating and Managing Pods

**Goal:** Learn to create, inspect, and delete pods.

### Create a pod imperatively (quick and simple)

```bash
# Make sure you're in the learning-lab namespace
kubectl config set-context --current --namespace=learning-lab

# Create a simple pod
kubectl run my-nginx --image=nginx:latest

# Watch it start up
kubectl get pods -w
# (Press Ctrl+C to stop watching)
```

### Inspect the pod

```bash
# Basic info
kubectl get pod my-nginx

# More details
kubectl get pod my-nginx -o wide

# Full details
kubectl describe pod my-nginx

# View the pod's YAML definition
kubectl get pod my-nginx -o yaml

# View just specific fields using jsonpath
kubectl get pod my-nginx -o jsonpath='{.status.podIP}'
```

### Access the pod

```bash
# Execute a command in the pod
kubectl exec my-nginx -- nginx -v

# Get an interactive shell
kubectl exec -it my-nginx -- /bin/bash
# (Type 'exit' to leave)

# View logs
kubectl logs my-nginx

# Stream logs (like tail -f)
kubectl logs -f my-nginx
```

### Create a pod declaratively (the proper way)

```yaml
# Save as my-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-busybox
  labels:
    app: busybox
    environment: learning
spec:
  containers:
  - name: busybox
    image: busybox:latest
    command: ["sleep", "3600"]
```

```bash
# Apply the manifest
kubectl apply -f my-pod.yaml

# Verify
kubectl get pods
```

### Delete pods

```bash
# Delete a specific pod
kubectl delete pod my-nginx

# Delete using the manifest file
kubectl delete -f my-pod.yaml

# Delete all pods in the namespace (careful!)
kubectl delete pods --all
```

### What you learned:
- `run` creates pods quickly (imperative)
- `apply -f` creates resources from YAML files (declarative)
- `exec` runs commands inside containers
- `logs` shows container output
- `-o yaml` and `-o jsonpath` extract specific information

---

## Exercise 4: Deployments and Scaling

**Goal:** Learn to manage deployments and scale applications.

### Create a deployment

```bash
# Create a deployment imperatively
kubectl create deployment web-app --image=nginx:latest --replicas=2

# Watch the rollout
kubectl rollout status deployment/web-app

# View the deployment
kubectl get deployment web-app

# View the pods created by the deployment
kubectl get pods -l app=web-app
```

### Scale the deployment

```bash
# Scale up
kubectl scale deployment web-app --replicas=4

# Watch pods being created
kubectl get pods -w

# Scale down
kubectl scale deployment web-app --replicas=2
```

### Update the deployment

```bash
# Change the image (triggers a rolling update)
kubectl set image deployment/web-app nginx=nginx:1.25

# Watch the rollout
kubectl rollout status deployment/web-app

# View rollout history
kubectl rollout history deployment/web-app

# Rollback to previous version
kubectl rollout undo deployment/web-app
```

### Inspect deployment details

```bash
# Describe the deployment
kubectl describe deployment web-app

# View the ReplicaSet created by the deployment
kubectl get replicasets

# View deployment as YAML
kubectl get deployment web-app -o yaml
```

### Create deployment from YAML

```yaml
# Save as web-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-server
  labels:
    app: web-server
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-server
  template:
    metadata:
      labels:
        app: web-server
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
```

```bash
kubectl apply -f web-deployment.yaml
kubectl get deployment web-server
```

### Cleanup

```bash
kubectl delete deployment web-app web-server
```

### What you learned:
- Deployments manage ReplicaSets which manage Pods
- `scale` changes the number of replicas
- `set image` updates container images
- `rollout` manages deployment updates and rollbacks
- Labels connect deployments to their pods

---

## Exercise 5: Services and Networking

**Goal:** Learn to expose applications with services.

### Create a deployment to expose

```bash
kubectl create deployment web --image=nginx:latest --replicas=3
kubectl get pods -l app=web
```

### Expose with a ClusterIP service (internal only)

```bash
# Create the service
kubectl expose deployment web --port=80 --target-port=80 --name=web-service

# View the service
kubectl get service web-service

# Get the ClusterIP
kubectl get svc web-service -o jsonpath='{.spec.clusterIP}'

# Test from within the cluster (create a temporary pod)
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- curl -s web-service
```

### Expose with a NodePort service (external access)

```bash
# Create a NodePort service
kubectl expose deployment web --port=80 --target-port=80 --type=NodePort --name=web-nodeport

# View the service (note the NodePort in the 30000-32767 range)
kubectl get svc web-nodeport

# Get the NodePort
NODE_PORT=$(kubectl get svc web-nodeport -o jsonpath='{.spec.ports[0].nodePort}')
echo "NodePort: $NODE_PORT"

# Access from your machine (if running locally)
curl localhost:$NODE_PORT
```

### View endpoints

```bash
# Endpoints show which pod IPs back the service
kubectl get endpoints web-service

# Compare with pod IPs
kubectl get pods -l app=web -o wide
```

### Create a service from YAML

```yaml
# Save as my-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-web-service
spec:
  selector:
    app: web
  ports:
  - protocol: TCP
    port: 8080        # Service port
    targetPort: 80    # Container port
  type: ClusterIP
```

```bash
kubectl apply -f my-service.yaml
kubectl get svc my-web-service
```

### Cleanup

```bash
kubectl delete deployment web
kubectl delete service web-service web-nodeport my-web-service
```

### What you learned:
- Services provide stable endpoints for pods
- ClusterIP is internal-only (default)
- NodePort exposes services on each node's IP
- Services use label selectors to find pods
- Endpoints track the actual pod IPs

---

## Exercise 6: ConfigMaps and Environment Variables

**Goal:** Learn to configure applications with ConfigMaps.

### Create a ConfigMap

```bash
# From literal values
kubectl create configmap app-config \
  --from-literal=APP_ENV=production \
  --from-literal=LOG_LEVEL=info \
  --from-literal=MAX_CONNECTIONS=100

# View it
kubectl get configmap app-config
kubectl describe configmap app-config

# View as YAML
kubectl get configmap app-config -o yaml
```

### Create a ConfigMap from a file

```bash
# Create a config file
cat <<EOF > app.properties
database.host=localhost
database.port=5432
database.name=myapp
EOF

# Create ConfigMap from file
kubectl create configmap app-properties --from-file=app.properties

# View it
kubectl describe configmap app-properties
```

### Use ConfigMap in a pod

```yaml
# Save as configmap-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: configured-pod
spec:
  containers:
  - name: app
    image: busybox:latest
    command: ["sleep", "3600"]
    env:
    # Single value from ConfigMap
    - name: ENVIRONMENT
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: APP_ENV
    envFrom:
    # All values from ConfigMap as env vars
    - configMapRef:
        name: app-config
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: app-properties
```

```bash
kubectl apply -f configmap-pod.yaml

# Verify environment variables
kubectl exec configured-pod -- env | grep -E "APP_ENV|LOG_LEVEL|MAX_CONNECTIONS"

# Verify mounted file
kubectl exec configured-pod -- cat /etc/config/app.properties
```

### Cleanup

```bash
kubectl delete pod configured-pod
kubectl delete configmap app-config app-properties
rm app.properties
```

### What you learned:
- ConfigMaps store non-sensitive configuration
- Values can be injected as environment variables
- ConfigMaps can be mounted as files
- `envFrom` imports all keys as environment variables

---

## Exercise 7: Labels and Selectors

**Goal:** Master filtering and organizing resources with labels.

### Create resources with labels

```bash
# Create pods with various labels
kubectl run frontend-v1 --image=nginx --labels="app=frontend,version=v1,env=prod"
kubectl run frontend-v2 --image=nginx --labels="app=frontend,version=v2,env=prod"
kubectl run backend-v1 --image=nginx --labels="app=backend,version=v1,env=prod"
kubectl run test-pod --image=nginx --labels="app=frontend,version=v1,env=test"
```

### Filter with label selectors

```bash
# Get all pods (shows labels with --show-labels)
kubectl get pods --show-labels

# Filter by single label
kubectl get pods -l app=frontend

# Filter by multiple labels (AND)
kubectl get pods -l app=frontend,version=v1

# Filter by label existence
kubectl get pods -l env

# Filter by label non-existence
kubectl get pods -l '!env'

# Filter using set-based selectors
kubectl get pods -l 'app in (frontend, backend)'
kubectl get pods -l 'version notin (v2)'
kubectl get pods -l 'env=prod,app in (frontend)'
```

### Modify labels

```bash
# Add a label
kubectl label pod frontend-v1 team=web

# Update an existing label
kubectl label pod frontend-v1 version=v1.1 --overwrite

# Remove a label
kubectl label pod frontend-v1 team-

# Verify
kubectl get pod frontend-v1 --show-labels
```

### Use labels for bulk operations

```bash
# Delete all test pods
kubectl delete pods -l env=test

# Get remaining pods
kubectl get pods --show-labels
```

### Cleanup

```bash
kubectl delete pods -l app
```

### What you learned:
- Labels are key-value pairs for organizing resources
- `-l` or `--selector` filters resources
- Multiple selectors create AND conditions
- `in`, `notin` provide set-based selection
- Labels enable bulk operations

---

## Exercise 8: Debugging and Troubleshooting

**Goal:** Learn techniques for diagnosing issues.

### Create a problem to debug

```bash
# Create a pod with a bad image
kubectl run broken-pod --image=nginx:nonexistent

# Create a pod that crashes
kubectl run crasher --image=busybox --command -- /bin/false
```

### Investigate pod issues

```bash
# Check pod status
kubectl get pods

# Get detailed status information
kubectl describe pod broken-pod | grep -A 10 "Events:"

# Check why a pod is failing
kubectl describe pod crasher | grep -A 5 "State:"
```

### View logs

```bash
# Logs from current container
kubectl logs crasher

# Logs from previous container instance (after crash)
kubectl logs crasher --previous

# Logs from a specific container in multi-container pod
kubectl logs <pod-name> -c <container-name>
```

### Debug with ephemeral containers

```bash
# Create a working pod first
kubectl run debug-target --image=nginx

# Attach a debug container (Kubernetes 1.25+)
kubectl debug -it debug-target --image=busybox --target=nginx
# (Type 'exit' to leave)
```

### Debug with a copy of the pod

```bash
# Create a debug copy with a different command
kubectl debug debug-target -it --image=busybox --copy-to=debug-copy -- sh
# (Type 'exit' to leave)

kubectl delete pod debug-copy
```

### Check resource usage

```bash
# Node resource usage (requires metrics-server)
kubectl top nodes

# Pod resource usage
kubectl top pods

# If metrics-server isn't installed, you'll see an error
# k3s doesn't include it by default
```

### Useful troubleshooting commands

```bash
# Get events sorted by time
kubectl get events --sort-by='.lastTimestamp'

# Get events for a specific pod
kubectl get events --field-selector involvedObject.name=broken-pod

# Check if a pod can reach a service
kubectl run test-curl --image=curlimages/curl --rm -it --restart=Never -- curl -s <service-name>

# Check DNS resolution
kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup kubernetes
```

### Cleanup

```bash
kubectl delete pod broken-pod crasher debug-target
```

### What you learned:
- `describe` shows events and state information
- `logs --previous` shows logs from crashed containers
- `kubectl debug` creates debug containers
- `get events` shows cluster events
- `top` shows resource usage (requires metrics-server)

---

## Exercise 9: Useful Output Formats

**Goal:** Learn different ways to format and extract kubectl output.

### Create a test pod

```bash
kubectl run output-test --image=nginx --labels="app=test,version=v1"
```

### Different output formats

```bash
# Default output
kubectl get pod output-test

# Wide output (more columns)
kubectl get pod output-test -o wide

# YAML output
kubectl get pod output-test -o yaml

# JSON output
kubectl get pod output-test -o json

# Name only
kubectl get pod output-test -o name

# Custom columns
kubectl get pod output-test -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,IP:.status.podIP
```

### JSONPath queries

```bash
# Get pod IP
kubectl get pod output-test -o jsonpath='{.status.podIP}'

# Get container image
kubectl get pod output-test -o jsonpath='{.spec.containers[0].image}'

# Get all pod names in namespace
kubectl get pods -o jsonpath='{.items[*].metadata.name}'

# Formatted output with newlines
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}'
```

### Combine with other tools

```bash
# Use jq for JSON processing
kubectl get pod output-test -o json | jq '.metadata.labels'

# Count pods
kubectl get pods -o json | jq '.items | length'

# Extract specific fields with jq
kubectl get pods -o json | jq -r '.items[] | "\(.metadata.name): \(.status.phase)"'
```

### Generate YAML templates

```bash
# Create YAML without actually creating the resource
kubectl run template-pod --image=nginx --dry-run=client -o yaml

# Save as a starting template
kubectl run template-pod --image=nginx --dry-run=client -o yaml > pod-template.yaml

# Create deployment template
kubectl create deployment template-deploy --image=nginx --dry-run=client -o yaml > deployment-template.yaml
```

### Cleanup

```bash
kubectl delete pod output-test
rm -f pod-template.yaml deployment-template.yaml
```

### What you learned:
- `-o yaml/json` exports full resource definitions
- JSONPath extracts specific fields
- `--dry-run=client -o yaml` generates templates
- Combine with `jq` for complex JSON processing

---

## Quick Reference

### Common Commands

```bash
# Cluster info
kubectl cluster-info
kubectl get nodes

# Resources
kubectl get <resource>                    # List resources
kubectl describe <resource> <name>        # Detailed info
kubectl create -f <file>                  # Create from file
kubectl apply -f <file>                   # Create or update from file
kubectl delete <resource> <name>          # Delete resource

# Pods
kubectl run <name> --image=<image>        # Create pod
kubectl exec -it <pod> -- <command>       # Execute command
kubectl logs <pod>                        # View logs
kubectl port-forward <pod> <local>:<pod>  # Forward port

# Deployments
kubectl create deployment <name> --image=<image>
kubectl scale deployment <name> --replicas=<n>
kubectl rollout status deployment/<name>
kubectl rollout undo deployment/<name>

# Debugging
kubectl describe pod <name>
kubectl logs <pod> --previous
kubectl get events --sort-by='.lastTimestamp'
kubectl debug -it <pod> --image=busybox
```

### Resource Short Names

| Full Name | Short Name |
|-----------|------------|
| namespaces | ns |
| pods | po |
| services | svc |
| deployments | deploy |
| replicasets | rs |
| configmaps | cm |
| secrets | sec |
| persistentvolumeclaims | pvc |
| nodes | no |

### Useful Flags

| Flag | Description |
|------|-------------|
| `-n <namespace>` | Target specific namespace |
| `-A` | All namespaces |
| `-l <selector>` | Filter by label |
| `-o wide` | Show more columns |
| `-o yaml` | Output as YAML |
| `-o json` | Output as JSON |
| `-w` | Watch for changes |
| `--dry-run=client` | Don't create, just preview |

---

## Cleanup

Remove everything created during these exercises:

```bash
# Delete the namespace (removes all resources in it)
kubectl delete namespace learning-lab

# Reset default namespace
kubectl config set-context --current --namespace=default
```

---

## Next Steps

Now that you're comfortable with kubectl, move on to the security exercises:

1. **RBAC** — Control who can do what
2. **Pod Security** — Harden your containers
3. **Network Policies** — Control traffic flow
4. **Secrets** — Manage sensitive data
5. **Auditing** — Find security issues
