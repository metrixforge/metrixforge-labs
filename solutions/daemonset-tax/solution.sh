#!/usr/bin/env bash
# Idempotent full solution — right-size the two over-provisioned agents.
set -euo pipefail
kubectl -n platform set resources ds/security-agent --requests=cpu=200m,memory=256Mi --limits=cpu=200m,memory=256Mi
kubectl -n platform set resources ds/log-shipper    --requests=cpu=150m,memory=256Mi --limits=cpu=150m,memory=256Mi
kubectl -n platform rollout status ds/security-agent --timeout=90s
kubectl -n platform rollout status ds/log-shipper    --timeout=90s
