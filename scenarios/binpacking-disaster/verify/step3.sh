#!/usr/bin/env bash
# Step 3: fleet shrunk to <=7 fake nodes and checkout still 24/24. consolidate.sh
# already waited for the reschedule, so this settles immediately — keep it WELL under
# Killercoda's ~10s verify budget (3x2s), or the runner times out ("could not verify").
for _ in 1 2 3; do
  n=$(kubectl get nodes -l type=kwok --no-headers 2>/dev/null | wc -l | tr -d ' ')
  ready=$(kubectl -n shop get deploy checkout -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  ready=${ready:-0}
  if [ "${n:-99}" -le 7 ] && [ "$ready" -eq 24 ]; then
    echo "ok: fleet ${n} nodes (from 12), checkout ${ready}/24 Running"
    exit 0
  fi
  sleep 2
done
echo "not there yet: fleet=${n:-?} (want <=7), checkout=${ready:-0}/24 — run: bash /opt/lab/consolidate.sh"
exit 1
