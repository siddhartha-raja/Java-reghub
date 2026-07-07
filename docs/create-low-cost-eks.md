# Create a Low-Cost EKS Cluster

This runbook creates a development EKS cluster for Java Reghub in `us-east-1`.
It is intentionally cost-conscious and is not the final production shape.

## Selected Values

```text
AWS_ACCOUNT_ID=818916267011
AWS_REGION=us-east-1
EKS_CLUSTER_NAME=java-reghub-dev
ECR_REPOSITORY=redis-db-demo
```

## Cost Posture

This config keeps worker cost low by using:

- One managed node group
- Spot instances
- `t3.medium` / `t3a.medium` workers
- No NAT Gateway
- Public worker networking for the dev cluster
- The EBS CSI driver add-on for MySQL persistent volume provisioning

Kafka and MySQL can run on this for a learning/dev setup, but stateful workloads
on Spot capacity are not production-safe. For production, move MySQL to RDS and
use on-demand or mixed-capacity nodes for Kafka.

## Prerequisites

Install and configure:

- AWS CLI
- `eksctl`
- `kubectl`
- Docker

Confirm AWS access:

```bash
aws sts get-caller-identity
```

Confirm the default region:

```bash
aws configure set region us-east-1
```

## Create the Cluster

From the repository root:

```bash
eksctl create cluster -f infra/eks/cluster-low-cost.yaml
```

Update local kubeconfig:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name java-reghub-dev
```

Verify nodes:

```bash
kubectl get nodes -o wide
```

Confirm the EBS CSI add-on is active. MySQL needs this for its EBS-backed
PersistentVolumeClaim.

```bash
eksctl get addon \
  --cluster java-reghub-dev \
  --region us-east-1 \
  --name aws-ebs-csi-driver
```

If the cluster was created before this add-on was added to the config, install it
manually:

```bash
eksctl create addon \
  --cluster java-reghub-dev \
  --region us-east-1 \
  --name aws-ebs-csi-driver \
  --force
```

## Confirm ECR Repository

The repository already exists according to the provided AWS console URL:

```text
818916267011.dkr.ecr.us-east-1.amazonaws.com/redis-db-demo
```

Verify from the CLI:

```bash
aws ecr describe-repositories \
  --region us-east-1 \
  --repository-names redis-db-demo
```

## Optional Manual Image Push

This is useful before GitHub Actions is ready.

```bash
aws ecr get-login-password --region us-east-1 \
  | docker login \
      --username AWS \
      --password-stdin 818916267011.dkr.ecr.us-east-1.amazonaws.com

docker build -t redis-db-demo:dev .

docker tag \
  redis-db-demo:dev \
  818916267011.dkr.ecr.us-east-1.amazonaws.com/redis-db-demo:dev

docker push 818916267011.dkr.ecr.us-east-1.amazonaws.com/redis-db-demo:dev
```

## Delete the Cluster

Use this when the dev environment is not needed. This is the most important
cost-control command.

```bash
eksctl delete cluster \
  --region us-east-1 \
  --name java-reghub-dev
```

## Next Step

After the cluster exists, install the platform components:

1. AWS Load Balancer Controller
2. MySQL manifests for the dev namespace
3. Java Reghub Kubernetes manifests
4. Strimzi Kafka operator and a small Kafka cluster
