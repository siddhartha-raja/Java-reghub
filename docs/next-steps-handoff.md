# Java Reghub EKS Handoff and Next Steps

Use this file to continue the project in a new chat.

## Repository

```text
/home/ubuntu/Java-reghub
```

## AWS and Cluster Values

```text
AWS_ACCOUNT_ID=818916267011
AWS_REGION=us-east-1
EKS_CLUSTER_NAME=java-reghub-dev
ECR_REPOSITORY=redis-db-demo
ECR_IMAGE=818916267011.dkr.ecr.us-east-1.amazonaws.com/redis-db-demo:dev
VPC_ID=vpc-04b5af3d5d94287ae
NAMESPACE=reghub
```

## What Is Already Done

### 1. Design Docs

Created:

- `docs/eks-microservices-design.md`
- `docs/create-low-cost-eks.md`
- `docs/deploy-current-app-to-eks.md`
- `docs/deploy-ingress-alb.md`
- `docs/deploy-api-gateway.md`
- `docs/deploy-kafka-eks.md`
- `docs/notification-service.md`

### 2. Low-Cost EKS Cluster

Cluster was created with:

```text
java-reghub-dev
```

The cluster uses a low-cost dev posture:

- Spot worker nodes
- `t3.medium` / `t3a.medium`
- MySQL running inside EKS for now
- No RDS yet

Cluster config file:

```text
infra/eks/cluster-low-cost.yaml
```

### 3. EBS CSI Driver

MySQL initially failed because EBS provisioning was unavailable.

Installed the managed EBS CSI add-on:

```bash
eksctl create addon \
  --cluster java-reghub-dev \
  --region us-east-1 \
  --name aws-ebs-csi-driver \
  --force
```

Current add-on status:

```text
aws-ebs-csi-driver ACTIVE
```

### 4. Current App Deployed to EKS

Kubernetes manifests were added under:

```text
k8s/base/
k8s/overlays/dev/
```

Current deployed resources:

```text
namespace/reghub
deployment/mysql
deployment/reghub-web
service/mysql
service/reghub-web
persistentvolumeclaim/mysql-data
ingress/reghub-web
```

Current status at handoff:

```text
mysql        1/1 Running
reghub-web   1/1 Running
mysql-data   Bound, 8Gi, gp2
```

### 5. Spring Boot Readiness

Added Spring Boot Actuator:

- `pom.xml`
- `src/main/resources/application.properties`

Health endpoints enabled:

```text
/actuator/health/liveness
/actuator/health/readiness
```

Tests were run after this change:

```text
mvn test
Tests run: 9, failures: 0
```

### 6. AWS Load Balancer Controller

Installed Helm locally.

Created IAM policy:

```text
arn:aws:iam::818916267011:policy/AWSLoadBalancerControllerIAMPolicy
```

Created IRSA service account:

```text
kube-system/aws-load-balancer-controller
```

Installed AWS Load Balancer Controller:

```text
chart version: 1.14.0
controller image: public.ecr.aws/eks/aws-load-balancer-controller:v2.14.0
```

Current status:

```text
aws-load-balancer-controller 2/2 Ready
```

AWS docs used:

```text
https://docs.aws.amazon.com/eks/latest/userguide/lbc-helm.html
```

### 7. Internal ALB Ingress

Created:

```text
k8s/base/app-ingress.yaml
```

Ingress annotations:

```text
alb.ingress.kubernetes.io/scheme: internal
alb.ingress.kubernetes.io/target-type: ip
alb.ingress.kubernetes.io/listen-ports: [{"HTTP": 80}]
alb.ingress.kubernetes.io/healthcheck-path: /actuator/health/readiness
alb.ingress.kubernetes.io/success-codes: 200
```

Current internal ALB DNS:

```text
internal-k8s-reghub-reghubwe-146da59bb5-209527896.us-east-1.elb.amazonaws.com
```

Current ALB status:

```text
Scheme: internal
State: active
```

Target group:

```text
arn:aws:elasticloadbalancing:us-east-1:818916267011:targetgroup/k8s-reghub-reghubwe-ded42cdebc/597fab440db6c9f6
```

Verified target health:

```text
current reghub-web pod target: healthy
```

### 8. API Gateway HTTP API and VPC Link

Created repeatable scripts:

```text
infra/api-gateway/deploy.sh
infra/api-gateway/destroy.sh
```

Created AWS resources:

```text
API_NAME=java-reghub-dev-http-api
API_ID=gtd7bcvrfl
API_ENDPOINT=https://gtd7bcvrfl.execute-api.us-east-1.amazonaws.com
VPC_LINK_NAME=java-reghub-dev-vpc-link
VPC_LINK_ID=plhudh
VPC_LINK_SECURITY_GROUP_ID=sg-044355a3f30040b17
```

Routes:

```text
ANY /
ANY /{proxy+}
```

Integration:

```text
HTTP_PROXY through VPC Link to the internal ALB HTTP listener ARN
```

Verification through API Gateway:

```text
GET / -> 200 text/html
GET /actuator/health/readiness -> 200 {"status":"UP"}
```

### 9. Kafka on EKS

Created repeatable scripts:

```text
infra/kafka/deploy.sh
infra/kafka/destroy.sh
```

Created Kubernetes manifests:

```text
k8s/kafka/dev/
```

Current Kafka values:

```text
STRIMZI_VERSION=1.1.0
KAFKA_NAMESPACE=kafka
KAFKA_CLUSTER_NAME=reghub-kafka
KAFKA_VERSION=4.3.0
BOOTSTRAP_SERVICE=reghub-kafka-kafka-bootstrap.kafka.svc.cluster.local:9092
```

Current status:

```text
Kafka reghub-kafka Ready=True
KafkaNodePool dual-role replicas=1 roles=["controller","broker"]
KafkaTopic post.created Ready=True
KafkaTopic post.deleted Ready=True
```

Important implementation note:

- The Strimzi upstream install YAML uses `myproject` in RoleBinding subjects.
  `infra/kafka/deploy.sh` rewrites that subject namespace to `kafka` before
  applying the operator.

### 10. Kafka Producer in Current App

Added:

```text
spring-kafka
src/main/java/com/reghub/event/PostCreatedEvent.java
src/main/java/com/reghub/event/PostDeletedEvent.java
src/main/java/com/reghub/event/PostEventPublisher.java
```

Behavior:

- `PostService.createPost` publishes `post.created`.
- `PostService.deletePost` publishes `post.deleted`.
- Kafka publish failures are logged and do not fail the user request.
- Producer JSON type headers are disabled so separate services can deserialize
  events without sharing Java package names.

Current EKS app config:

```text
SPRING_KAFKA_BOOTSTRAP_SERVERS=reghub-kafka-kafka-bootstrap.kafka.svc.cluster.local:9092
APP_KAFKA_TOPIC_POST_CREATED=post.created
APP_KAFKA_TOPIC_POST_DELETED=post.deleted
```

### 11. Notification Consumer Service

Created:

```text
services/notification-service/
k8s/base/notification-configmap.yaml
k8s/base/notification-deployment.yaml
```

ECR image:

```text
818916267011.dkr.ecr.us-east-1.amazonaws.com/reghub-notification-service:dev
```

Behavior:

- Consumes `post.created`.
- Logs the received event.
- Runs in namespace `reghub`.
- Uses `Recreate` deployment strategy for the single dev consumer replica.

End-to-end verification:

```text
Created post through API Gateway:
POST https://gtd7bcvrfl.execute-api.us-east-1.amazonaws.com/posts

notification-service log:
Received post.created event: postId=1, title=Kafka smoke test, imageKey=posts/086bf297-72b6-4eb6-aae0-03bfe5d60e79-reghub-kafka-smoke.png
```

## Useful Verification Commands

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name java-reghub-dev

kubectl -n reghub get ingress,targetgroupbindings.elbv2.k8s.aws,deploy,pods,svc,pvc

kubectl -n kube-system get deploy aws-load-balancer-controller

aws elbv2 describe-load-balancers \
  --region us-east-1 \
  --names k8s-reghub-reghubwe-146da59bb5

aws elbv2 describe-target-health \
  --region us-east-1 \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:818916267011:targetgroup/k8s-reghub-reghubwe-ded42cdebc/597fab440db6c9f6

source infra/api-gateway/outputs.env
curl -i "$API_ENDPOINT/"
curl -i "$API_ENDPOINT/actuator/health/readiness"

infra/kafka/deploy.sh
kubectl -n kafka get kafka,kafkanodepool,kafkatopic,pods,svc,pvc

kubectl -n reghub get deploy,pods
kubectl -n reghub logs deploy/notification-service
```

## Known Caveats

- The ALB is internal and is not directly reachable from the public internet.
- API Gateway is public through its default execute-api endpoint. Add a custom
  domain and TLS certificate later for a production-style URL.
- MySQL is running inside EKS only for dev/learning. Production should use RDS.
- The app currently uses static AWS credentials in a Kubernetes Secret for S3.
  Replace this with IRSA later.
- Kafka is running inside EKS only for dev/learning. Production should use a
  multi-broker, multi-AZ, monitored Kafka posture.
- App and notification-service startup can take around 45-75 seconds on the
  current low-cost nodes.

## Remaining Steps

### Step 1. GitHub Actions CI

Goal:

- Build and test on PR/push.
- Build Docker image.

Add:

```text
.github/workflows/ci.yml
```

Pipeline:

```text
checkout
setup-java 17
mvn test
docker build
```

### Step 2. GitHub Actions EKS Deploy

Goal:

- Push image to ECR.
- Deploy to EKS.

Add:

```text
.github/workflows/deploy-dev.yml
```

Needed GitHub/AWS setup:

- GitHub OIDC provider in AWS
- IAM role that GitHub Actions can assume
- Permissions for ECR push and EKS deploy

Deploy flow:

```text
checkout
configure AWS credentials via OIDC
login to ECR
docker build
docker push with Git SHA tag
kubectl set image or kustomize image update
kubectl apply -k k8s/overlays/dev
kubectl rollout status deploy/reghub-web -n reghub
```

### Step 3. Split Toward Microservices

Target services:

```text
web-gateway
post-service
media-service
notification-service
```

Suggested order:

1. Extract `notification-service` first because it is event-only.
2. Extract `media-service` for S3 upload/download/delete.
3. Keep post metadata in `post-service`.
4. Let `web-gateway` serve UI and call backend services.

### Step 4. Replace Static AWS Keys with IRSA

Goal:

- Remove `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` from app secrets.
- Use IAM Roles for Service Accounts for S3 access.

Needed:

- IAM policy for S3 bucket access
- Kubernetes service account for `reghub-web`
- Annotate service account with IAM role ARN
- Update deployment to use that service account

### Step 5. Move MySQL to RDS

Goal:

- Production-grade database.

Tasks:

- Create RDS MySQL in private subnets
- Security group allows EKS app pods/nodes to connect on 3306
- Move credentials to AWS Secrets Manager or External Secrets
- Update `SPRING_DATASOURCE_URL`
- Remove MySQL Deployment/PVC from production overlay

### Step 6. Production Hardening

Add:

- TLS on API Gateway custom domain
- Auth if required
- Horizontal Pod Autoscaler
- PodDisruptionBudgets
- Separate dev/prod overlays
- Resource tuning
- Structured logging
- Metrics and dashboards
- Backup/restore plan
- Kafka persistence and monitoring

## Suggested Next Prompt

Use this prompt in the new chat:

```text
We are continuing /home/ubuntu/Java-reghub. Read docs/next-steps-handoff.md first.
The EKS cluster java-reghub-dev is running in us-east-1, the current app and
MySQL are healthy. API Gateway is live in front of the internal ALB. Kafka is
running on EKS with Strimzi, the current app publishes post events, and
notification-service consumes post.created. Next, add GitHub Actions CI for
Maven tests and Docker builds.
```
