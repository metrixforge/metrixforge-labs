#!/usr/bin/env bash
# Idempotent "solve the whole lab" — for CI e2e + honest public solutions.
set -euo pipefail
SDIR="${SCENARIO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scenarios/binpacking-disaster" && pwd)}"

# 1) right-size checkout: 3.5 → 2.0 CPU (real usage is ~1.5), so 4 pods fit per 8-CPU node.
kubectl -n shop set resources deploy/checkout \
  --requests=cpu=2000m,memory=2Gi --limits=cpu=2000m,memory=2Gi
kubectl -n shop rollout status deploy/checkout --timeout=120s

# 2) pack onto the minimum nodes and drop the rest.
bash "$SDIR/assets/consolidate.sh"
