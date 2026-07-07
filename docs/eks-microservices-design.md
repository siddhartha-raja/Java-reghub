# Java Reghub EKS Microservices Design

This document is the first deployment design pass for moving Java Reghub from a
single Spring Boot tutorial app into an EKS-hosted, event-driven application.

## Current Application

Java Reghub is currently one Spring Boot service that owns:

- Thymeleaf web UI for creating and listing posts
- Post CRUD logic
- MySQL persistence
- S3 image upload, download, and delete logic

The first EKS deployment should keep this working service intact, then introduce
platform pieces and Kafka events before splitting runtime services. That gives us
a deployable baseline at every step.

## Target Architecture

```text
Internet
  |
  v
Amazon API Gateway
  |
  v
VPC Link
  |
  v
Internal AWS Load Balancer from Kubernetes Ingress
  |
  v
EKS cluster
  |
  +-- web-gateway service
  |     - Serves Thymeleaf UI or frontend API facade
  |     - Routes post requests to post-service
  |
  +-- post-service
  |     - Owns posts table
  |     - Produces post.created and post.deleted Kafka events
  |
  +-- media-service
  |     - Owns S3 image operations
  |     - Can consume post.deleted to clean up images
  |
  +-- notification-service
  |     - Example async consumer for future email/audit activity
  |
  +-- Kafka on EKS
        - Strimzi-managed Kafka cluster
        - Internal bootstrap service used by application pods
```

## AWS Entry Pattern

Use both API Gateway and Kubernetes ingress:

- API Gateway is the public edge for throttling, custom domains, auth, usage
  plans, and request policies.
- API Gateway connects through a VPC Link to an internal load balancer.
- The Kubernetes AWS Load Balancer Controller creates the internal ALB from an
  Ingress resource.
- Ingress routes traffic to the in-cluster web/API service.

This keeps Kubernetes services private while still giving the application a
managed public API edge.

## Service Boundaries

### Phase 1 Baseline Service

Deploy the existing application as `reghub-web` on EKS.

Responsibilities:

- Render current UI
- Handle post create/list/delete
- Store metadata in MySQL
- Store images in S3

This phase proves container build, image push, deployment, ingress, secrets,
health checks, and GitHub Actions.

### Phase 2 Kafka-Enabled Modular Monolith

Keep one deployable service, but add Kafka publishing inside the current post
workflow.

Events:

- `post.created`
- `post.deleted`

This lets the app start using Kafka without forcing a risky code split first.

### Phase 3 Service Split

Split the code into independent services:

- `web-gateway`: UI and request facade
- `post-service`: post metadata and post lifecycle events
- `media-service`: S3 object storage and image retrieval
- `notification-service`: async event consumer

At this point, `post-service` calls `media-service` for image storage, or the UI
uploads through a presigned URL flow owned by `media-service`.

## Kafka on EKS

Recommended operator: Strimzi.

Cluster layout:

- Namespace: `kafka`
- Kafka brokers: 3 replicas for production, 1 replica for a development cluster
- ZooKeeper-less KRaft mode if supported by the selected Strimzi/Kafka version
- Persistent volumes through the default EKS storage class or a dedicated gp3
  storage class
- Internal bootstrap service exposed only inside the cluster

Application config:

```text
SPRING_KAFKA_BOOTSTRAP_SERVERS=reghub-kafka-bootstrap.kafka.svc.cluster.local:9092
APP_KAFKA_TOPIC_POST_CREATED=post.created
APP_KAFKA_TOPIC_POST_DELETED=post.deleted
```

## Data and Secrets

Recommended production shape:

- MySQL should run as Amazon RDS, not inside EKS.
- Kafka runs on EKS as requested.
- Images stay in S3.
- AWS access should use IRSA instead of static access keys.
- Database credentials should come from Kubernetes Secrets or External Secrets
  backed by AWS Secrets Manager.

For a learning/dev environment, MySQL can temporarily run in EKS, but RDS is the
better target for a system-design deployment.

## Kubernetes Layout

Proposed repository layout:

```text
k8s/
  base/
    namespace.yaml
    deployment.yaml
    service.yaml
    ingress.yaml
    configmap.yaml
    secret.example.yaml
    serviceaccount.yaml
  overlays/
    dev/
      kustomization.yaml
    prod/
      kustomization.yaml
kafka/
  strimzi/
    namespace.yaml
    kafka-cluster.yaml
.github/
  workflows/
    ci.yml
    deploy-dev.yml
```

## GitHub Actions Flow

### CI

Runs on pull requests and pushes:

1. Check out code
2. Set up Java 17
3. Run `mvn test`
4. Build the Docker image

### Deploy

Runs on `main` or manually:

1. Configure AWS credentials through GitHub OIDC
2. Log in to Amazon ECR
3. Build and push image tagged with the Git SHA
4. Update kubeconfig for the EKS cluster
5. Apply Kubernetes manifests with Kustomize
6. Wait for rollout

## Implementation Order

1. Add production container/runtime readiness to the Spring Boot app.
2. Add Kubernetes manifests for the current app.
3. Add ECR + GitHub Actions CI image build.
4. Add GitHub Actions EKS deploy workflow.
5. Add API Gateway + internal ingress design/manifests or Terraform.
6. Deploy Kafka on EKS with Strimzi.
7. Add Kafka producer support to the current app.
8. Add a Kafka consumer service.
9. Split `media-service` and `post-service` when the event contract is stable.

## Decisions Needed

- AWS region: `us-east-1`
- AWS account ID: `818916267011`
- EKS cluster name: `java-reghub-dev` for the first dev cluster
- ECR repository name: `redis-db-demo`
- MySQL location: temporary MySQL in EKS for the first deployment
- Domain name for API Gateway, if any
- Whether infrastructure should be managed by Terraform, eksctl, or existing AWS
  resources
