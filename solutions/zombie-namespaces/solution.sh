#!/usr/bin/env bash
# Idempotent full solution — delete the 5 abandoned namespaces, then consolidate the
# now-oversized fleet. LAB dir holds the fetched consolidate.sh (fallback: repo path).
set -euo pipefail
LAB="${LAB_DIR:-/opt/lab}"
ZOMBIES=(preview-pr-2841 preview-pr-2903 demo-acme-poc load-test-jan migration-v2)

kubectl delete namespace "${ZOMBIES[@]}" --ignore-not-found --wait=true

CONS="$LAB/consolidate.sh"
[ -f "$CONS" ] || CONS="$(dirname "$0")/../../scenarios/zombie-namespaces/assets/consolidate.sh"
bash "$CONS"
