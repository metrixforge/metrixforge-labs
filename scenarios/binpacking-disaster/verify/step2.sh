#!/usr/bin/env bash
# Step 2 (Right-size): checkout CPU requests reduced to 2 cores or less.
set -e
cpu=$(kubectl -n shop get deploy checkout -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
m=$(python3 -c "v='${cpu:-9}'; print(int(float(v[:-1])) if v.endswith('m') else int(float(v)*1000))")
[ "$m" -le 2000 ] || { echo "checkout still requests ${cpu} CPU — right-size it to 2 cores or less"; exit 1; }
echo "ok: checkout right-sized to ${cpu}"
