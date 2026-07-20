#!/usr/bin/env bash
# The leak: a 12-node fake fleet running one deployment whose CPU requests are ~2x
# real usage, so only 2 pods fit per 8-CPU node → 12 nodes for work that fits in 6.
set -euo pipefail
COMMON="${COMMON_DIR:?COMMON_DIR unset}"

# 12x m5.2xlarge (8 CPU / 32Gi) on-demand fleet
bash "$COMMON/gen-nodes.sh" 12 8 32 m5.2xlarge fleet on-demand

# checkout: 24 replicas x 3.5 CPU request (real usage ~1.5) → 2 per node → 12 nodes.
kubectl create namespace shop --dry-run=client -o yaml | kubectl apply -f - >/dev/null
cat <<'EOF' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout
  namespace: shop
  annotations:
    metrixforge.io/lab: binpacking-disaster
spec:
  replicas: 24
  selector: { matchLabels: { app: checkout } }
  template:
    metadata: { labels: { app: checkout } }
    spec:
      # land on the fake fleet
      nodeSelector: { type: kwok }
      tolerations:
        - key: kwok.x-k8s.io/node
          value: fake
          effect: NoSchedule
      containers:
        - name: app
          image: registry.k8s.io/pause:3.9
          resources:
            requests: { cpu: "3500m", memory: "2Gi" }
            limits:   { cpu: "3500m", memory: "2Gi" }
EOF
echo "[seed] fleet + checkout applied"
