#!/usr/bin/env bash
# Render + apply N fake kwok nodes.
#   gen-nodes.sh COUNT CPU MEM_GI TYPE [PREFIX] [CAPACITY_TYPE]
# e.g. gen-nodes.sh 12 8 32 m5.2xlarge fleet on-demand
# Fake nodes carry the kwok taint; lab pods must set nodeSelector type=kwok +
# a matching toleration (see the seed manifests) or they stay Pending.
set -euo pipefail
COUNT="${1:?count}"; CPU="${2:?cpu}"; MEM="${3:?mem_gi}"; TYPE="${4:?instance-type}"
PREFIX="${5:-kwok}"; CAPTYPE="${6:-on-demand}"

# Build ALL node manifests into one document and apply once (fast — a per-node
# kubectl apply is the setup bottleneck).
{
for i in $(seq 1 "$COUNT"); do
  NAME=$(printf "%s-%s-%02d" "$PREFIX" "$TYPE" "$i")
  cat <<EOF
apiVersion: v1
kind: Node
metadata:
  name: ${NAME}
  annotations:
    kwok.x-k8s.io/node: fake
    node.alpha.kubernetes.io/ttl: "0"
  labels:
    type: kwok
    kubernetes.io/hostname: ${NAME}
    kubernetes.io/os: linux
    kubernetes.io/role: agent
    node.kubernetes.io/instance-type: ${TYPE}
    karpenter.sh/capacity-type: ${CAPTYPE}
    topology.kubernetes.io/zone: us-east-1a
spec:
  taints:
    - key: kwok.x-k8s.io/node
      value: fake
      effect: NoSchedule
status:
  allocatable:
    cpu: "${CPU}"
    memory: "${MEM}Gi"
    pods: "110"
  capacity:
    cpu: "${CPU}"
    memory: "${MEM}Gi"
    pods: "110"
  nodeInfo:
    architecture: amd64
    kubeletVersion: fake
    operatingSystem: linux
  phase: Running
---
EOF
done
} | kubectl apply -f - >/dev/null
echo "[gen-nodes] applied ${COUNT}x ${TYPE} (${CPU}CPU/${MEM}Gi, ${CAPTYPE}) prefix=${PREFIX}"
