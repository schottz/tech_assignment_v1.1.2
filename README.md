# EKS Cluster with Karpenter Autoscaling

## Overview
This Terraform repository deploys an Amazon EKS cluster with Karpenter for autoscaling, optimized for cost and performance using AWS Graviton (arm64) and x86 spot instances. The cluster runs in an existing VPC and leverages the latest EKS version available at deployment time. Karpenter manages node pools to dynamically provision arm64 and x86 nodes based on workload requirements.

This guide explains how to deploy the infrastructure and how developers can run pods or deployments targeting specific architectures (x86 or Graviton).

## Prerequisites
- **Terraform**: Version 1.5+ installed.
- **AWS CLI**: Configured with credentials for your AWS account (`aws configure`).
- **kubectl**: Installed and configured to interact with Kubernetes.
- **Existing VPC**: A VPC with public and private subnets in at least two availability zones (e.g., `eu-west-1a`, `eu-west-1b`).

## Directory Structure
```
tech_assignment_v1.1.2/
.
├── README.md
├── data.tf
├── eks.tf
├── karpenter.tf
├── karpenter_nodepools
│   ├── arm64_spot.yaml
│   └── x86_spot.yaml
├── providers.tf
├── variables.tf
└── variables.tfvars
```
## Deploying the Infastructure

1. **Clone the Repository**:
   ```bash
   git clone git@github.com:schottz/tech_assignment_v1.1.2.git
   cd infrastructure
   ```

2. **Customize Variables**:
  - Edit variables.tfvars to set your VPC and subnet IDs:
```hcl
vpc_id             = "vpc-15615556166191"
private_subnet_ids = ["subnet-123...", "subnet-123..."]
public_subnet_ids  = ["subnet-123...", "subnet-123..."]
```

   - Adjust other variables (e.g., region, cluster name) as needed.

3. **Initialize Terraform**:
```bash
terraform Init
```

4. **Plan and Apply**:
  - Preview changes:
```bash
terraform plan -var-file=variables.tfvars
```
  - Deploy the cluster and Karpenter:
```bash
terraform apply -var-file=variables.tfvars
``` 
  - Confirm with yes when prompted.

## Running Pods/Deployments on x86 or Graviton Instances
Karpenter provisions nodes based on pod scheduling constraints. The cluster has two node pools:
- arm64_spot: Uses Graviton (ARM64) spot instances (e.g., t4g family).
- x86_spot: Uses x86 spot instances (e.g., t3 family).

Developers can target these architectures using nodeSelector or tolerations in their pod or deployment manifests.

### Examples

**Running a Pod on Graviton (arm64)**
```bash
$ cat nginx-arm64.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-arm64
spec:
  containers:
  - name: nginx
    image: nginx:latest
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
  nodeSelector:
    kubernetes.io/arch: arm64
```

- Apply it:
```bash
kubectl apply -f nginx-arm64.yaml
Karpenter will provision an arm64 spot instance if none exist.
```

- Verify:
```bash
kubectl get pod nginx-arm64 -o wide
kubectl describe node <node-name> | grep "Architecture"
```
**Running a Deployment on x86**

```bash
$ cat nginx-x86.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-x86
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-x86
  template:
    metadata:
      labels:
        app: nginx-x86
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
      nodeSelector:
        kubernetes.io/arch: amd64
```
 - Apply it:

```bash
kubectl apply -f nginx-x86.yaml
```
Karpenter will provision x86 spot instances as needed.
Verify:
```bash
kubectl get pods -l app=nginx-x86 -o wide
kubectl describe node <node-name> | grep "Architecture"
```

## Cleanup
To destroy the infrastructure:
```bash
terraform destroy -var-file=variables.tfvars
```
Confirm typinhg yes.