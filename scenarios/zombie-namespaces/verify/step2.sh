#!/usr/bin/env bash
# Step 2: all 5 abandoned namespaces are gone (deleted or fully Terminating away),
# and production (shop/web, payments/api) is untouched.
still=""
for ns in preview-pr-2841 preview-pr-2903 demo-acme-poc load-test-jan migration-v2; do
  if kubectl get namespace "$ns" -o jsonpath='{.status.phase}' 2>/dev/null | grep -q Active; then
    still="$still $ns"
  fi
done
[ -z "$still" ] || { echo "still-active abandoned namespaces:$still — delete them"; exit 1; }
for ns in shop payments; do
  kubectl get namespace "$ns" >/dev/null 2>&1 || { echo "production namespace $ns is gone — only delete the abandoned ones!"; exit 1; }
done
echo "ok: 5 abandoned namespaces cleared, production intact"
