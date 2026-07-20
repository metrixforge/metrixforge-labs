#!/usr/bin/env bash
# Step 1: the 6-node fleet is present and the 5 abandoned namespaces are all there.
n=$(kubectl get nodes -l type=kwok --no-headers 2>/dev/null | wc -l | tr -d ' ')
[ "${n:-0}" -eq 6 ] || { echo "expected a 6-node fleet, found ${n:-0}"; exit 1; }
missing=""
for ns in preview-pr-2841 preview-pr-2903 demo-acme-poc load-test-jan migration-v2; do
  kubectl get namespace "$ns" >/dev/null 2>&1 || missing="$missing $ns"
done
[ -z "$missing" ] || { echo "abandoned namespaces missing:$missing"; exit 1; }
echo "ok: 6-node fleet + 5 abandoned namespaces present"
