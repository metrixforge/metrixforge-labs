#!/usr/bin/env bash
# Async setup — runs while the user reads intro.md. Ends by touching /tmp/.setup-done.
# COMMON_DIR / SCENARIO_DIR are set by the e2e harness; defaults match Killercoda asset layout.
exec >/tmp/setup.log 2>&1
set -euo pipefail
COMMON_DIR="${COMMON_DIR:-/opt/labs/common}"
SCENARIO_DIR="${SCENARIO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export COMMON_DIR
# repo root (…/labs) holds tools/ — install costctl + helpers onto PATH so the
# lab steps are copy-paste. Best-effort; the e2e harness already puts them on PATH.
ROOT="$(cd "$COMMON_DIR/.." 2>/dev/null && pwd || true)"
if [ -n "$ROOT" ] && [ -f "$ROOT/tools/costctl" ]; then
  install -m 0755 "$ROOT/tools/costctl" /usr/local/bin/costctl 2>/dev/null || true
  cp "$ROOT/tools/pricing.json" /usr/local/bin/pricing.json 2>/dev/null || true
  install -m 0755 "$COMMON_DIR/wait-setup.sh" /usr/local/bin/wait-setup 2>/dev/null || true
fi

echo "== install kwok =="
bash "$COMMON_DIR/install-kwok.sh"

echo "== seed leak =="
bash "$SCENARIO_DIR/setup/seed-leak.sh"

echo "== wait for checkout to schedule onto the fleet =="
kubectl -n shop rollout status deploy/checkout --timeout=120s || true
# fake pods go Running via kwok stage-fast; give the scheduler a beat
for _ in $(seq 1 30); do
  running=$(kubectl -n shop get pods --field-selector=status.phase=Running -o name 2>/dev/null | wc -l | tr -d ' ')
  [ "$running" -ge 24 ] && break
  sleep 2
done

echo "== setup done =="
touch /tmp/.setup-done
