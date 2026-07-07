# Notification Service

`services/notification-service` is a small Spring Boot consumer used to
demonstrate async behavior before splitting the main app into full
microservices.

It consumes:

```text
post.created
```

For now it logs the event:

```text
Received post.created event: postId=..., title=..., imageKey=...
```

## Build Locally

```bash
cd services/notification-service
mvn test
docker build -t reghub-notification-service:dev .
```

## EKS Image

The dev Kubernetes manifest expects:

```text
818916267011.dkr.ecr.us-east-1.amazonaws.com/reghub-notification-service:dev
```

## Deploy

From the repository root, after pushing the image:

```bash
kubectl apply -k k8s/overlays/dev
kubectl -n reghub rollout status deploy/notification-service
kubectl -n reghub logs deploy/notification-service
```
