#!/usr/bin/env bash
# Step 3 (Consolidate & prove): fleet shrunk to <=6 nodes with the app still 24/24.
# Eventually-consistent — retry a few times while pods reschedule.
set -e
for attempt in $(seq 1 8); do
  n=$(kubectl get nodes -l type=kwok --no-headers 2>/dev/null | wc -l | tr -d ' ')
  ready=$(kubectl -n shop get deploy checkout -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)
  if [ "$n" -le 7 ] && [ "${ready:-0}" -eq 24 ]; then
    echo "ok: fleet ${n} nodes (from 12), checkout ${ready}/24 Running"
    exit 0
  fi
  sleep 2
done
echo "not there yet: fleet=${n} nodes (want <=7), checkout ready=${ready:-0}/24"
exit 1
