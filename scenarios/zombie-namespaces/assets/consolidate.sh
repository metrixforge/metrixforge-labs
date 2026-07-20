#!/usr/bin/env bash
# After deleting the abandoned namespaces, the fleet is oversized for what's left.
# Pack the surviving pods onto the minimum nodes and remove the rest. Deterministic:
# target = ceil(remaining requested CPU / (node CPU x 0.9))  (~10% headroom so the
# scheduler isn't asked to pack to 100%, which would leave stragglers Pending).
set -euo pipefail

mapfile -t FLEET < <(kubectl get nodes -l type=kwok -o name | sed 's|node/||' | sort)
[ "${#FLEET[@]}" -eq 0 ] && { echo "no fleet nodes"; exit 0; }
NODE_CPU=$(kubectl get node "${FLEET[0]}" -o jsonpath='{.status.allocatable.cpu}')

# CPU still requested by pods targeting the fleet (after the zombie namespaces are gone)
TOTAL_CPU=$(kubectl get pods -A -o json | python3 -c '
import json,sys
def cpu(v):
    v=str(v or 0); return float(v[:-1])/1000 if v.endswith("m") else float(v)
d=json.load(sys.stdin); t=0.0
for p in d["items"]:
    if p.get("spec",{}).get("nodeSelector",{}).get("type")!="kwok": continue
    if p.get("metadata",{}).get("deletionTimestamp"): continue   # ignore terminating
    for c in p["spec"].get("containers",[]):
        t+=cpu(c.get("resources",{}).get("requests",{}).get("cpu"))
print(t)')

TARGET=$(python3 -c "import math;print(max(1,math.ceil($TOTAL_CPU/(max($NODE_CPU,1)*0.9))))")
echo "[consolidate] remaining=${TOTAL_CPU} CPU, node=${NODE_CPU} CPU → target ${TARGET} of ${#FLEET[@]} nodes"

DRAIN=("${FLEET[@]:$TARGET}")
[ "${#DRAIN[@]}" -eq 0 ] && { echo "[consolidate] already minimal"; exit 0; }

# Remove surplus nodes in one shot; GC deletes their pods and the Deployments
# recreate them onto the kept nodes — a single reschedule, then settle.
for n in "${DRAIN[@]}"; do kubectl delete node "$n" --wait=false >/dev/null; done

# podgc needs a moment to evict the orphaned pods off the deleted nodes; only then
# does the reschedule begin. (A Pending-only poll would race here: right after the
# node delete those pods are still phase=Running, not Pending, so it would "succeed"
# before anything moves.) Give it a beat, then wait for every Deployment to be
# fully Available again — the survivors landed on the kept nodes.
sleep 3
for _ in $(seq 1 60); do
  notready=$(kubectl get deploy -A -o json | python3 -c '
import json,sys
d=json.load(sys.stdin); n=0
for x in d["items"]:
    want=x["spec"].get("replicas",0) or 0
    got=x.get("status",{}).get("readyReplicas",0) or 0
    if got<want: n+=1
print(n)')
  [ "${notready:-1}" -eq 0 ] && break
  sleep 2
done
echo "[consolidate] fleet ${#FLEET[@]} → ${TARGET} nodes (deployments not-ready=${notready:-?})"
