# Java-reghub

A small Spring Boot tutorial app for Jenkins CI/CD practice. It lets a user create a post with a title and image upload.

## What Is Included 

- Spring Boot web UI with Thymeleaf
- Controller, service, repository, and entity layers
- MySQL database support
- AWS S3 image upload support
- Unit tests and a Testcontainers-based MySQL integration test
- `Dockerfile`, `docker-compose.yml`, and `Jenkinsfile`

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
```

Do not commit `.env`; it is ignored by Git.
