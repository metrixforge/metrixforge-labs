#!/usr/bin/env bash
# Block until the async background.sh finishes (touches /tmp/.setup-done).
# First lab command is prefixed with this so the user never hits a half-built cluster.
set -euo pipefail
printf "Preparing the cluster"
for _ in $(seq 1 120); do
  [ -f /tmp/.setup-done ] && { echo " ready."; exit 0; }
  printf "."; sleep 2
done
echo; echo "Setup is taking longer than expected — check: cat /tmp/setup.log"; exit 1
