#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:?usage: deploy.sh <environment> [--template]}"
MODE="${2:-install}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# shellcheck source=../versions.env
source "$ROOT/versions.env"

ESO_REPO=https://charts.external-secrets.io
CERT_MANAGER_REPO=https://charts.jetstack.io
REFLECTOR_REPO=https://emberstack.github.io/helm-charts
PROMETHEUS_REPO=https://prometheus-community.github.io/helm-charts

if [[ "$MODE" == "--template" ]]; then
  : "${TENANT_ID:=00000000-0000-0000-0000-000000000000}"
  : "${KV_URL:=https://example.vault.azure.net/}"
  : "${ESO_CLIENT_ID:=00000000-0000-0000-0000-000000000000}"
  : "${CERT_MANAGER_CLIENT_ID:=00000000-0000-0000-0000-000000000000}"
  : "${APP_HOST:=example.uaenorth.cloudapp.azure.com}"
  : "${ACME_EMAIL:=platform@example.com}"
fi
: "${TENANT_ID:?}" "${KV_URL:?}" "${ESO_CLIENT_ID:?}" "${CERT_MANAGER_CLIENT_ID:?}" "${APP_HOST:?}" "${ACME_EMAIL:?}"
: "${CLUSTER_ISSUER:=letsencrypt-prod}"
: "${EDGE_TLS_NAMESPACES:=boutique-app,monitoring}"
export TENANT_ID KV_URL ACME_EMAIL APP_HOST CLUSTER_ISSUER EDGE_TLS_NAMESPACES

log() { echo "==> $*"; }

values_args() {
  local dir="$ROOT/values/$1"
  echo "-f $dir/values.yaml"
  [[ -f "$dir/values-$ENVIRONMENT.yaml" ]] && echo "-f $dir/values-$ENVIRONMENT.yaml"
  return 0
}

identity_values() {
  local file="$WORK/$1-identity.yaml"
  cat >"$file" <<EOF
serviceAccount:
  annotations:
    azure.workload.identity/client-id: "$2"
EOF
  echo "$file"
}

grafana_host_values() {
  local file="$WORK/grafana-host.yaml"
  cat >"$file" <<EOF
grafana:
  ingress:
    hosts:
      - "$APP_HOST"
    tls:
      - secretName: edge-tls
        hosts:
          - "$APP_HOST"
  grafana.ini:
    server:
      root_url: "https://$APP_HOST/grafana"
EOF
  echo "$file"
}

render() {
  envsubst '${TENANT_ID} ${KV_URL} ${ACME_EMAIL} ${APP_HOST} ${CLUSTER_ISSUER} ${EDGE_TLS_NAMESPACES}' \
    <"$ROOT/manifests/$1"
}

apply_manifest() {
  local attempt
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if render "$1" | kubectl apply -f -; then
      return 0
    fi
    log "apply of $1 failed (attempt $attempt/10), retrying in 15s"
    sleep 15
  done
  return 1
}

helm_release() {
  local name="$1" namespace="$2" chart="$3" repo="$4" version="$5"
  shift 5
  if [[ "$MODE" == "--template" ]]; then
    # shellcheck disable=SC2046
    helm template "$name" "$chart" --repo "$repo" --version "$version" \
      -n "$namespace" $(values_args "$name") "$@" >"$WORK/$name.rendered.yaml"
    log "rendered $name $version ($(grep -c '^kind:' "$WORK/$name.rendered.yaml") objects)"
    return 0
  fi
  log "installing $name $version into $namespace"
  # shellcheck disable=SC2046
  helm upgrade --install "$name" "$chart" --repo "$repo" --version "$version" \
    -n "$namespace" --create-namespace $(values_args "$name") "$@" \
    --wait --timeout 10m
}

install_external_secrets() {
  helm_release external-secrets external-secrets external-secrets "$ESO_REPO" "$EXTERNAL_SECRETS_VERSION" \
    -f "$(identity_values external-secrets "$ESO_CLIENT_ID")"
}
install_cert_manager() {
  helm_release cert-manager cert-manager cert-manager "$CERT_MANAGER_REPO" "$CERT_MANAGER_VERSION" \
    -f "$(identity_values cert-manager "$CERT_MANAGER_CLIENT_ID")"
}
install_reflector() {
  helm_release reflector reflector reflector "$REFLECTOR_REPO" "$REFLECTOR_VERSION"
}
monitoring_env_values() {
  local file="$WORK/monitoring-env.yaml"
  cat >"$file" <<EOF
prometheus:
  prometheusSpec:
    externalLabels:
      environment: "$ENVIRONMENT"
EOF
  echo "$file"
}

install_kube_prometheus_stack() {
  helm_release kube-prometheus-stack monitoring kube-prometheus-stack "$PROMETHEUS_REPO" "$KUBE_PROMETHEUS_STACK_VERSION" \
    -f "$(grafana_host_values)" -f "$(monitoring_env_values)"
}

if [[ "$MODE" == "--template" ]]; then
  install_external_secrets
  install_cert_manager
  install_reflector
  install_kube_prometheus_stack
  for manifest in "$ROOT"/manifests/*.yaml; do
    render "$(basename "$manifest")" >"$WORK/$(basename "$manifest")"
    log "rendered $(basename "$manifest")"
  done
  exit 0
fi

log "platform deploy for '$ENVIRONMENT' ($APP_HOST) on context $(kubectl config current-context)"

for ns in ${EDGE_TLS_NAMESPACES//,/ }; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done

install_external_secrets
apply_manifest cluster-secret-store.yaml
kubectl wait clustersecretstore/azure-store --for=condition=Ready --timeout=3m

install_cert_manager
apply_manifest cluster-issuers.yaml
kubectl wait clusterissuer/letsencrypt-staging clusterissuer/letsencrypt-prod --for=condition=Ready --timeout=3m

install_reflector
apply_manifest edge-certificate.yaml
if ! kubectl wait -n cert-manager certificate/edge-tls --for=condition=Ready --timeout=15m; then
  log "edge-tls was not issued; current ACME state:"
  kubectl describe -n cert-manager certificate/edge-tls || true
  kubectl get -n cert-manager certificaterequests,orders,challenges -o wide || true
  kubectl describe -n cert-manager challenges || true
  exit 1
fi
for ns in ${EDGE_TLS_NAMESPACES//,/ }; do
  log "waiting for edge-tls to be reflected into $ns"
  for _ in $(seq 1 24); do
    kubectl get secret edge-tls -n "$ns" >/dev/null 2>&1 && break
    sleep 5
  done
  kubectl get secret edge-tls -n "$ns" >/dev/null
done

apply_manifest externalsecret-grafana-admin.yaml
apply_manifest externalsecret-pagerduty.yaml
kubectl wait -n monitoring externalsecret/grafana-admin-secret externalsecret/pagerduty-secret \
  --for=condition=Ready --timeout=3m

if helm status kube-prometheus-stack -n monitoring >/dev/null 2>&1; then
  log "upgrading kube-prometheus-stack CRDs to $KUBE_PROMETHEUS_STACK_VERSION"
  helm pull kube-prometheus-stack --repo "$PROMETHEUS_REPO" --version "$KUBE_PROMETHEUS_STACK_VERSION" \
    --untar -d "$WORK"
  kubectl apply --server-side --force-conflicts -f "$WORK/kube-prometheus-stack/charts/crds/crds/"
fi
install_kube_prometheus_stack

log "platform deploy complete"
helm list -A --filter 'external-secrets|cert-manager|reflector|kube-prometheus-stack'
kubectl get clustersecretstore,clusterissuer
kubectl get -n cert-manager certificate/edge-tls
log "Grafana: https://$APP_HOST/grafana (App Gateway can take a few minutes to pick up new routes)"
