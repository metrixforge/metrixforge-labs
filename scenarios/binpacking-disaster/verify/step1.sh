#!/usr/bin/env bash
# Step 1 (Read the bill): the fragmented fleet is present and untouched.
set -e
n=$(kubectl get nodes -l type=kwok --no-headers 2>/dev/null | wc -l | tr -d ' ')
[ "$n" -eq 12 ] || { echo "expected a 12-node fleet, found $n"; exit 1; }
kubectl -n shop get deploy checkout >/dev/null 2>&1 || { echo "checkout deployment missing"; exit 1; }
echo "ok: 12-node fleet + checkout present"
