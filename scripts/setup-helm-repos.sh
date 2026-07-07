#!/usr/bin/env bash
# Registers the upstream Helm chart repositories used by this project's
# default-add-ons wrapper charts (ingress-nginx, bitnami/postgresql) and
# refreshes the local repo index.
#
# Usage: ./scripts/setup-helm-repos.sh

set -euo pipefail

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
