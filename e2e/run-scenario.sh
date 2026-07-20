#!/usr/bin/env bash
# Local/CI e2e: kind up → background setup → verify step1 → solution → verify 2/3.
# Proves setup timing + that the fix actually clears every verify. Usage: run-scenario.sh <slug>
set -euo pipefail
SLUG="${1:?usage: run-scenario.sh <slug>}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export COMMON_DIR="$ROOT/common"
export SCENARIO_DIR="$ROOT/scenarios/$SLUG"
export PATH="$ROOT/tools:$PATH"
CLUSTER="labs-e2e"
V="$SCENARIO_DIR/verify"

step() { echo; echo "── $* ──"; }
cleanup() { kind delete cluster --name "$CLUSTER" >/dev/null 2>&1 || true; }
trap cleanup EXIT

start=$(date +%s)
cleanup
kind create cluster --name "$CLUSTER" --config "$ROOT/e2e/kind-config.yaml" >/dev/null 2>&1
echo "kind up"

step "setup (async background.sh)"
rm -f /tmp/.setup-done /tmp/setup.log
bash "$SCENARIO_DIR/setup/background.sh" &
bash "$COMMON_DIR/wait-setup.sh" || { echo "--- setup.log ---"; cat /tmp/setup.log; exit 1; }
setup_s=$(( $(date +%s) - start ))
echo "setup: ${setup_s}s  (budget 120s)"

step "costctl nodes — BEFORE"; costctl nodes
step "verify step1"; bash "$V/step1.sh"
step "solution.sh"; bash "$ROOT/solutions/$SLUG/solution.sh"
step "verify step2"; bash "$V/step2.sh"
step "verify step3"; bash "$V/step3.sh"
step "costctl nodes — AFTER"; costctl nodes

total_s=$(( $(date +%s) - start ))
echo; echo "✅ E2E GREEN — setup ${setup_s}s, total ${total_s}s"
# 120s budget is measured on the real Killercoda free tier (kind ≠ Killercoda);
# locally we only WARN so the e2e still gates on correctness, not host speed.
[ "$setup_s" -le 120 ] || echo "⚠ setup ${setup_s}s > 120s budget — verify on Killercoda staging (M-DoD)"
