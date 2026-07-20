#!/usr/bin/env bash
# Step 1: the 20-node fleet and its 4 agents are present.
n=$(kubectl get nodes -l type=kwok --no-headers 2>/dev/null | wc -l | tr -d ' ')
[ "${n:-0}" -eq 20 ] || { echo "expected a 20-node fleet, found ${n:-0}"; exit 1; }
have=$(kubectl -n platform get ds --no-headers 2>/dev/null | wc -l | tr -d ' ')
[ "${have:-0}" -ge 4 ] || { echo "expected 4 agent DaemonSets, found ${have:-0}"; exit 1; }
echo "ok: 20-node fleet + ${have} agents present"
