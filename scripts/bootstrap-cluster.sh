#!/usr/bin/env bash
# Stands up the local `kind` cluster and installs Argo CD 3.4.4 for the
# app-of-apps experiment (Constitution Principle V: local verification
# before cluster sync).
#
# Usage: ./scripts/bootstrap-cluster.sh

set -euo pipefail

CLUSTER_NAME="argocd-playground"
ARGOCD_VERSION="v3.4.4"

if kind get clusters 2>/dev/null | grep -qx "${CLUSTER_NAME}"; then
  echo "kind cluster '${CLUSTER_NAME}' already exists, skipping create"
else
  kind create cluster --name "${CLUSTER_NAME}"
fi

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# --server-side avoids the client-side "last-applied-configuration"
# annotation, which exceeds the 262144-byte annotation limit for the large
# applicationsets.argoproj.io CRD in this manifest.
kubectl apply -n argocd --server-side --force-conflicts -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

kubectl -n argocd wait --for=condition=available deploy/argocd-server --timeout=180s
