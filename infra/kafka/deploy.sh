#!/usr/bin/env bash
set -euo pipefail

STRIMZI_VERSION="${STRIMZI_VERSION:-1.1.0}"
KAFKA_NAMESPACE="${KAFKA_NAMESPACE:-kafka}"
KAFKA_CLUSTER_NAME="${KAFKA_CLUSTER_NAME:-reghub-kafka}"
MANIFEST_DIR="${MANIFEST_DIR:-k8s/kafka/dev}"

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require curl
require kubectl

kubectl apply -f "$MANIFEST_DIR/namespace.yaml"

echo "Installing Strimzi Cluster Operator $STRIMZI_VERSION in namespace $KAFKA_NAMESPACE"
curl -fsSL \
  "https://github.com/strimzi/strimzi-kafka-operator/releases/download/${STRIMZI_VERSION}/strimzi-cluster-operator-${STRIMZI_VERSION}.yaml" \
  | sed "s/namespace: myproject/namespace: ${KAFKA_NAMESPACE}/g" \
  | kubectl apply -n "$KAFKA_NAMESPACE" -f -

kubectl -n "$KAFKA_NAMESPACE" rollout status deploy/strimzi-cluster-operator --timeout=180s

echo "Applying Kafka cluster and topics"
kubectl apply -k "$MANIFEST_DIR"

echo "Waiting for Kafka cluster readiness"
kubectl -n "$KAFKA_NAMESPACE" wait "kafka/$KAFKA_CLUSTER_NAME" '--for=condition=Ready' --timeout=600s

kubectl -n "$KAFKA_NAMESPACE" get kafka
kubectl -n "$KAFKA_NAMESPACE" get kafkanodepool
kubectl -n "$KAFKA_NAMESPACE" get kafkatopic
kubectl -n "$KAFKA_NAMESPACE" get pods,svc,pvc
