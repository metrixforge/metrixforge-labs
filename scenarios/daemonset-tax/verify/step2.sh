#!/usr/bin/env bash
# Step 2: the two fat agents are right-sized (security-agent <=200m, log-shipper <=150m).
milli() { local v="${1:-9}"; python3 -c "v='$v';print(int(float(v[:-1])) if v.endswith('m') else int(float(v)*1000))"; }
sec=$(milli "$(kubectl -n platform get ds security-agent -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null)")
log=$(milli "$(kubectl -n platform get ds log-shipper   -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null)")
[ "$sec" -le 200 ] || { echo "security-agent still ${sec}m CPU — right-size it to 200m"; exit 1; }
[ "$log" -le 150 ] || { echo "log-shipper still ${log}m CPU — right-size it to 150m"; exit 1; }
echo "ok: security-agent=${sec}m, log-shipper=${log}m"
