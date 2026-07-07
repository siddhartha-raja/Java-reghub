# Deploy Kafka on EKS

This deploys a small development Kafka cluster in EKS with Strimzi.

## Installed Values

```text
STRIMZI_VERSION=1.1.0
KAFKA_NAMESPACE=kafka
KAFKA_CLUSTER_NAME=reghub-kafka
KAFKA_VERSION=4.3.0
BOOTSTRAP_SERVICE=reghub-kafka-kafka-bootstrap.kafka.svc.cluster.local:9092
```

## Shape

- One dual-role KRaft node: broker and controller.
- One 8Gi `gp2` persistent volume.
- Internal plaintext listener on port `9092`.
- Strimzi Topic Operator manages `post.created` and `post.deleted`.

This is deliberately small for dev and learning. Production should use at least
three brokers, multiple zones, tuned storage, TLS/auth, monitoring, and backups.

## Deploy

From the repository root:

```bash
chmod +x infra/kafka/deploy.sh infra/kafka/destroy.sh
infra/kafka/deploy.sh
```

The script rewrites the upstream Strimzi sample RoleBinding subject namespace
from `myproject` to `kafka` before applying the operator YAML.

## Verify

```bash
kubectl -n kafka wait kafka/reghub-kafka '--for=condition=Ready' --timeout=600s
kubectl -n kafka get kafka
kubectl -n kafka get kafkanodepool
kubectl -n kafka get kafkatopic
kubectl -n kafka get pods,svc,pvc
```

The in-cluster bootstrap address for Spring Boot apps is:

```text
reghub-kafka-kafka-bootstrap.kafka.svc.cluster.local:9092
```

## Remove

```bash
infra/kafka/destroy.sh
```

The Kafka persistent volume claim uses `deleteClaim: false`, so data can remain
after deleting the Kafka custom resources.
