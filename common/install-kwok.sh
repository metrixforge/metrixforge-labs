#!/usr/bin/env bash
# Install the kwok controller + fast stages at the pinned version, so fake Nodes
# report Ready and fake Pods go Running immediately. Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/versions.env"

REL="https://github.com/kubernetes-sigs/kwok/releases/download/${KWOK_VERSION}"
echo "[kwok] installing controller ${KWOK_VERSION}"
kubectl apply -f "${REL}/kwok.yaml"
# stage-fast: instantly transitions fake node/pod lifecycle (no real kubelet).
kubectl apply -f "${REL}/stage-fast.yaml"

echo "[kwok] waiting for controller"
kubectl -n kube-system rollout status deploy/kwok-controller --timeout=90s
echo "[kwok] ready"
