#!/usr/bin/env bash
# "drain empty" — after right-sizing requests, pack the workload onto the minimum
# number of nodes and remove the rest. Deterministic: target = ceil(total requested
# CPU / node CPU); cordon the surplus fleet nodes, evict their pods (rescheduled
# onto the kept nodes), delete the emptied fake nodes.
set -euo pipefail

mapfile -t FLEET < <(kubectl get nodes -l type=kwok -o name | sed 's|node/||' | sort)
[ "${#FLEET[@]}" -eq 0 ] && { echo "no fleet nodes"; exit 0; }
NODE_CPU=$(kubectl get node "${FLEET[0]}" -o jsonpath='{.status.allocatable.cpu}')

# total CPU requested by pods that target the fleet (nodeSelector type=kwok)
TOTAL_CPU=$(kubectl get pods -A -o json | python3 -c '
import json,sys
def cpu(v):
    v=str(v or 0)
    return float(v[:-1])/1000 if v.endswith("m") else float(v)
d=json.load(sys.stdin); t=0.0
for p in d["items"]:
    if p.get("spec",{}).get("nodeSelector",{}).get("type")!="kwok": continue
    for c in p["spec"].get("containers",[]):
        t+=cpu(c.get("resources",{}).get("requests",{}).get("cpu"))
print(t)')

# target = min nodes to hold the requests, keeping ~10% headroom so the scheduler
# isn't asked to pack to 100% (which leaves stragglers Pending).
TARGET=$(python3 -c "import math;print(math.ceil($TOTAL_CPU/(max($NODE_CPU,1)*0.9)))")
echo "[consolidate] requested=${TOTAL_CPU} CPU, node=${NODE_CPU} CPU → target ${TARGET} of ${#FLEET[@]} nodes"

DRAIN=("${FLEET[@]:$TARGET}")
[ "${#DRAIN[@]}" -eq 0 ] && { echo "[consolidate] already minimal"; exit 0; }

# Remove the surplus nodes in one shot. Pods on them are garbage-collected and the
# Deployment recreates them onto the kept nodes — a single reschedule, then settle.
for n in "${DRAIN[@]}"; do kubectl delete node "$n" --wait=false >/dev/null; done
for _ in $(seq 1 60); do
  ready=$(kubectl -n shop get deploy checkout -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)
  [ "${ready:-0}" -eq 24 ] && break
  sleep 2
done
echo "[consolidate] fleet ${#FLEET[@]} → ${TARGET} nodes (checkout ready=${ready:-?}/24)"
