#!/usr/bin/env bash
# Async setup — runs while the user reads intro.md. Ends by touching /tmp/.setup-done.
# SELF-CONTAINED: on Killercoda the scenario only gets its own dir, so we fetch the
# shared tools (costctl + common/*) from the repo's raw URLs into $LAB. The kind e2e
# harness sets LABS_ROOT so we copy them locally instead of hitting the network.
exec >/tmp/setup.log 2>&1
set -euo pipefail
SCENARIO_DIR="${SCENARIO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
LAB="${LAB_DIR:-/opt/lab}"
RAW="${RAW_BASE:-https://raw.githubusercontent.com/metrixforge/metrixforge-labs/main}"
LABS_ROOT="${LABS_ROOT:-}"   # repo root (set by the kind e2e harness); empty on Killercoda
mkdir -p "$LAB"

get() { # get <repo-relpath> <dest>
  if [ -n "$LABS_ROOT" ] && [ -f "$LABS_ROOT/$1" ]; then cp "$LABS_ROOT/$1" "$2"
  else curl -fsSL "$RAW/$1" -o "$2"; fi
}

echo "== fetch tools + scenario scripts =="
# Killercoda copies ONLY background.sh into the env (not sibling files), so fetch
# everything this setup needs — shared tools AND the scenario's own scripts.
get tools/costctl      "$LAB/costctl"
get tools/pricing.json "$LAB/pricing.json"
for f in install-kwok.sh gen-nodes.sh wait-setup.sh versions.env; do get "common/$f" "$LAB/$f"; done
get scenarios/binpacking-disaster/setup/seed-leak.sh    "$LAB/seed-leak.sh"
get scenarios/binpacking-disaster/assets/consolidate.sh "$LAB/consolidate.sh"
chmod +x "$LAB/costctl" "$LAB"/*.sh
# put costctl + wait-setup on PATH (root on Killercoda; best-effort under local e2e)
install -m 0755 "$LAB/costctl" /usr/local/bin/costctl 2>/dev/null || true
cp "$LAB/pricing.json" /usr/local/bin/pricing.json 2>/dev/null || true
install -m 0755 "$LAB/wait-setup.sh" /usr/local/bin/wait-setup 2>/dev/null || true

echo "== install kwok =="
bash "$LAB/install-kwok.sh"          # sources $LAB/versions.env

echo "== seed leak =="
COMMON_DIR="$LAB" bash "$LAB/seed-leak.sh"   # uses $LAB/gen-nodes.sh

echo "== wait for checkout to schedule onto the fleet =="
kubectl -n shop rollout status deploy/checkout --timeout=120s || true
for _ in $(seq 1 30); do
  running=$(kubectl -n shop get pods --field-selector=status.phase=Running -o name 2>/dev/null | wc -l | tr -d ' ')
  [ "$running" -ge 24 ] && break
  sleep 2
done

echo "== setup done =="
touch /tmp/.setup-done
