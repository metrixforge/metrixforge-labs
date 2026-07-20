#!/usr/bin/env bash
# Step 3: the fleet has been consolidated (<= 3 nodes, from 6) now that the dead
# namespaces are gone — and production still runs. Fast checks, well under budget.
n=$(kubectl get nodes -l type=kwok --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [ "${n:-9}" -gt 3 ]; then
  echo "fleet still ${n:-?} nodes — delete the abandoned namespaces, then consolidate"
  exit 1
fi
# tolerate the brief reschedule settle after consolidation (4x1s, well under budget)
ok=0
for _ in 1 2 3 4; do
  ready=$(kubectl -n shop get deploy web -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)
  [ "${ready:-0}" -eq 8 ] && { ok=1; break; }
  sleep 1
done
[ "$ok" -eq 1 ] || { echo "production shop/web not healthy (ready=${ready:-0}/8)"; exit 1; }
echo "ok: fleet consolidated to ${n} nodes, production healthy"
