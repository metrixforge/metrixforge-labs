#!/usr/bin/env bash
# The leak: a 20-node fleet runs 4 per-node agents (DaemonSets). Two of them ask for
# far more than they use, so a fat "fleet tax" is skimmed off EVERY node before the
# app gets anything.
set -euo pipefail
COMMON="${COMMON_DIR:?COMMON_DIR unset}"

bash "$COMMON/gen-nodes.sh" 20 8 32 m5.2xlarge fleet on-demand

kubectl create namespace platform --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl create namespace shop --dry-run=client -o yaml | kubectl apply -f - >/dev/null

# 4 per-node agents. node-exporter + mesh-proxy are sized fine; log-shipper and
# security-agent are grossly over-requested (the leak).
ds() { # ds NAME CPU MEM
cat <<EOF | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: DaemonSet
metadata: { name: $1, namespace: platform }
spec:
  selector: { matchLabels: { app: $1 } }
  template:
    metadata: { labels: { app: $1 } }
    spec:
      nodeSelector: { type: kwok }
      tolerations:
        - { key: kwok.x-k8s.io/node, value: fake, effect: NoSchedule }
      containers:
        - name: agent
          image: registry.k8s.io/pause:3.9
          resources:
            requests: { cpu: "$2", memory: "$3" }
            limits:   { cpu: "$2", memory: "$3" }
EOF
}
ds node-exporter  100m 128Mi
ds mesh-proxy     300m 256Mi
ds log-shipper    500m 512Mi   # fat
ds security-agent 750m 1Gi     # very fat — the worst offender

# a modest app so the fleet isn't empty
cat <<'EOF' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata: { name: web, namespace: shop }
spec:
  replicas: 20
  selector: { matchLabels: { app: web } }
  template:
    metadata: { labels: { app: web } }
    spec:
      nodeSelector: { type: kwok }
      tolerations: [ { key: kwok.x-k8s.io/node, value: fake, effect: NoSchedule } ]
      containers:
        - name: app
          image: registry.k8s.io/pause:3.9
          resources: { requests: { cpu: "2", memory: "2Gi" }, limits: { cpu: "2", memory: "2Gi" } }
EOF
echo "[seed] 20-node fleet + 4 agents + web applied"
