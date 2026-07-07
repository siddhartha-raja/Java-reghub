# Java-reghub

A small Spring Boot tutorial app for Jenkins CI/CD practice. It lets a user create a post with a title and image upload.

## What Is Included

- Spring Boot web UI with Thymeleaf
- Controller, service, repository, and entity layers
- MySQL database support
- AWS S3 image upload support
- Unit tests and a Testcontainers-based MySQL integration test
- `Dockerfile`, `docker-compose.yml`, and `Jenkinsfile`

## EKS Deployment Design

The first-pass EKS, API Gateway, ingress, Kafka, and GitHub Actions deployment
plan is documented in [docs/eks-microservices-design.md](docs/eks-microservices-design.md).

For the first low-cost development cluster, use
[docs/create-low-cost-eks.md](docs/create-low-cost-eks.md).

After the cluster is created, deploy the current app with
[docs/deploy-current-app-to-eks.md](docs/deploy-current-app-to-eks.md).

Then expose the service inside the VPC with an internal ALB using
[docs/deploy-ingress-alb.md](docs/deploy-ingress-alb.md).

Put API Gateway in front of the internal ALB with
[docs/deploy-api-gateway.md](docs/deploy-api-gateway.md).

Deploy Kafka with Strimzi using
[docs/deploy-kafka-eks.md](docs/deploy-kafka-eks.md).

The first async consumer lives under `services/notification-service`; see
[docs/notification-service.md](docs/notification-service.md).

For a continuation summary and remaining roadmap, see
[docs/next-steps-handoff.md](docs/next-steps-handoff.md).

## Local Setup

Start MySQL:

```bash
docker compose up -d mysql
```

Create a local environment file:

```bash
cp .env.example .env
```

Set real AWS credentials in `.env` or export them in your shell. The default S3 bucket is:

```text
design-genesis-dev
```

Run the app:

```bash
mvn clean package
set -a
source .env
set +a
java -jar target/java-reghub-0.0.1-SNAPSHOT.jar
```

Open:

```text
http://localhost:8080
```

Logs are written to the console by default. To store them in a file during a local run:

```bash
java -jar target/java-reghub-0.0.1-SNAPSHOT.jar > app.log 2>&1
```

## Tests

Run unit tests:

```bash
mvn test
```

Run unit and integration tests:

```bash
mvn verify
```

The integration test uses Testcontainers with MySQL, so Docker must be running.

## Useful Environment Variables

```text
SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/reghub
SPRING_DATASOURCE_USERNAME=reghub
SPRING_DATASOURCE_PASSWORD=reghub_password
AWS_REGION=us-east-1
AWS_S3_BUCKET=design-genesis-dev
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
SPRING_KAFKA_BOOTSTRAP_SERVERS=localhost:9092
APP_KAFKA_TOPIC_POST_CREATED=post.created
APP_KAFKA_TOPIC_POST_DELETED=post.deleted
```

Do not commit `.env`; it is ignored by Git.
