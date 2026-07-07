#!/usr/bin/env bash
set -euo pipefail

STRIMZI_VERSION="${STRIMZI_VERSION:-1.1.0}"
KAFKA_NAMESPACE="${KAFKA_NAMESPACE:-kafka}"
MANIFEST_DIR="${MANIFEST_DIR:-k8s/kafka/dev}"

kubectl delete -k "$MANIFEST_DIR" --ignore-not-found=true

echo "Removing Strimzi Cluster Operator $STRIMZI_VERSION from namespace $KAFKA_NAMESPACE"
curl -fsSL \
  "https://github.com/strimzi/strimzi-kafka-operator/releases/download/${STRIMZI_VERSION}/strimzi-cluster-operator-${STRIMZI_VERSION}.yaml" \
  | sed "s/namespace: myproject/namespace: ${KAFKA_NAMESPACE}/g" \
  | kubectl delete -n "$KAFKA_NAMESPACE" -f - --ignore-not-found=true

echo "Namespace $KAFKA_NAMESPACE is left in place if it still contains resources."
