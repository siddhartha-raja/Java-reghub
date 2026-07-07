# Deploy Internal ALB Ingress

This installs AWS Load Balancer Controller and creates an internal Application
Load Balancer for `reghub-web`.

The ALB is internal because the target architecture puts Amazon API Gateway in
front of the VPC entry point.

## Installed Values

```text
AWS_ACCOUNT_ID=818916267011
AWS_REGION=us-east-1
EKS_CLUSTER_NAME=java-reghub-dev
VPC_ID=vpc-04b5af3d5d94287ae
AWS_LOAD_BALANCER_CONTROLLER_CHART_VERSION=1.14.0
AWS_LOAD_BALANCER_CONTROLLER_APP_VERSION=2.14.0
```

## Install Helm

```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## Create IAM Policy

```bash
mkdir -p /tmp/reghub-alb
cd /tmp/reghub-alb

curl -fsSLO \
  https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.14.1/docs/install/iam_policy.json

aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json
```

If the policy already exists, reuse:

```text
arn:aws:iam::818916267011:policy/AWSLoadBalancerControllerIAMPolicy
```

## Create IAM Service Account

```bash
eksctl create iamserviceaccount \
  --cluster=java-reghub-dev \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::818916267011:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --region us-east-1 \
  --approve
```

## Install Controller

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks

helm upgrade --install aws-load-balancer-controller \
  eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=java-reghub-dev \
  --set region=us-east-1 \
  --set vpcId=vpc-04b5af3d5d94287ae \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --version 1.14.0
```

Verify:

```bash
kubectl -n kube-system rollout status deploy/aws-load-balancer-controller
kubectl -n kube-system get deploy aws-load-balancer-controller
```

## Apply Ingress

From the repository root:

```bash
kubectl apply -k k8s/overlays/dev
```

Watch the Ingress until an ALB DNS name appears:

```bash
kubectl -n reghub get ingress reghub-web -w
```

Describe the Ingress if the address does not appear:

```bash
kubectl -n reghub describe ingress reghub-web
kubectl -n kube-system logs deploy/aws-load-balancer-controller
```

## Notes

- This ALB is internal, so it is not reachable directly from the public internet.
- The next architecture step is to connect API Gateway to this internal ALB
  through a VPC Link.

