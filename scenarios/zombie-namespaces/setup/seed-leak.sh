#!/usr/bin/env bash
# The leak: a cluster where ~half the footprint is ABANDONED namespaces — old PR
# previews, a sales demo, a leftover load-test, a one-off migration — nobody ever
# deleted. They run real pods that reserve real capacity, so the fleet is sized for
# them. kubectl gives you no per-namespace cost lens, so they hide in plain sight.
set -euo pipefail
COMMON="${COMMON_DIR:?COMMON_DIR unset}"

# 6x m5.2xlarge (8 CPU / 32Gi) on-demand fleet
bash "$COMMON/gen-nodes.sh" 6 8 32 m5.2xlarge fleet on-demand

# portable "N days ago" as an ISO date (GNU vs BSD `date` differ — use python3)
ld() { python3 -c "import datetime,sys;print((datetime.datetime.now(datetime.timezone.utc).date()-datetime.timedelta(days=int(sys.argv[1]))).isoformat())" "$1"; }

# seed NS DAYS NAME REPLICAS CPU MEM — a namespace (with a last-deploy age) + a Deployment on the fleet
seed() {
  local ns=$1 days=$2 name=$3 rep=$4 cpu=$5 mem=$6
  cat <<EOF | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Namespace
metadata:
  name: ${ns}
  annotations: { metrixforge.io/last-deploy: "$(ld "$days")" }
---
apiVersion: apps/v1
kind: Deployment
metadata: { name: ${name}, namespace: ${ns} }
spec:
  replicas: ${rep}
  selector: { matchLabels: { app: ${name} } }
  template:
    metadata: { labels: { app: ${name} } }
    spec:
      nodeSelector: { type: kwok }
      tolerations:
        - { key: kwok.x-k8s.io/node, value: fake, effect: NoSchedule }
      containers:
        - name: app
          image: registry.k8s.io/pause:3.9
          resources:
            requests: { cpu: "${cpu}", memory: "${mem}" }
            limits:   { cpu: "${cpu}", memory: "${mem}" }
EOF
}

# --- live production (recently deployed — KEEP) ---
seed shop     2 web         8 1   1Gi
seed payments 5 api         4 1   1Gi
seed platform 4 controllers 2 1   2Gi

# --- abandoned (old last-deploy — the zombies) ---
seed preview-pr-2841 134 web    4 1 2Gi
seed preview-pr-2903 121 web    3 1 2Gi
seed demo-acme-poc   187 app    3 2 2Gi
seed load-test-jan   168 worker 2 2 4Gi
seed migration-v2     96 runner 2 1 1Gi

echo "[seed] fleet + 3 prod + 5 abandoned namespaces applied"
