#!/usr/bin/env bash
# Async setup. SELF-CONTAINED (Killercoda copies only this file) — fetch the shared
# tools + this scenario's seed + consolidate scripts into /opt/lab, from raw github
# (curl) or the local repo when LABS_ROOT is set (kind e2e). Ends by touching
# /tmp/.setup-done.
exec >/tmp/setup.log 2>&1
set -euo pipefail
LAB="${LAB_DIR:-/opt/lab}"
RAW="${RAW_BASE:-https://raw.githubusercontent.com/metrixforge/metrixforge-labs/main}"
LABS_ROOT="${LABS_ROOT:-}"
mkdir -p "$LAB"
get() { if [ -n "$LABS_ROOT" ] && [ -f "$LABS_ROOT/$1" ]; then cp "$LABS_ROOT/$1" "$2"; else curl -fsSL "$RAW/$1" -o "$2"; fi; }

echo "== fetch tools + scenario scripts =="
get tools/costctl      "$LAB/costctl"
get tools/pricing.json "$LAB/pricing.json"
for f in install-kwok.sh gen-nodes.sh wait-setup.sh versions.env; do get "common/$f" "$LAB/$f"; done
get scenarios/zombie-namespaces/setup/seed-leak.sh    "$LAB/seed-leak.sh"
get scenarios/zombie-namespaces/assets/consolidate.sh "$LAB/consolidate.sh"
chmod +x "$LAB/costctl" "$LAB"/*.sh
install -m 0755 "$LAB/costctl" /usr/local/bin/costctl 2>/dev/null || true
cp "$LAB/pricing.json" /usr/local/bin/pricing.json 2>/dev/null || true
install -m 0755 "$LAB/wait-setup.sh" /usr/local/bin/wait-setup 2>/dev/null || true

echo "== install kwok =="
bash "$LAB/install-kwok.sh"

echo "== seed leak =="
COMMON_DIR="$LAB" bash "$LAB/seed-leak.sh"

echo "== wait for prod + zombies to schedule =="
kubectl -n shop rollout status deploy/web --timeout=120s || true
kubectl -n demo-acme-poc rollout status deploy/app --timeout=120s || true

echo "== setup done =="
touch /tmp/.setup-done
