#!/usr/bin/env bash
# Step 3: the fleet tax has dropped (DaemonSet cost < ~$600/mo, from ~$1,000). The tax
# includes system per-node DaemonSets (e.g. kube-proxy), not just the 4 seeded agents.
# Single fast costctl call — well under Killercoda's verify budget.
ds=$(costctl waste --daemonsets --json 2>/dev/null | python3 -c 'import json,sys;print(int(json.load(sys.stdin)["daemonset_monthly_usd"]))' 2>/dev/null)
if [ "${ds:-99999}" -lt 600 ]; then
  echo "ok: DaemonSet fleet tax down to \$${ds}/mo"
  exit 0
fi
echo "fleet tax still \$${ds:-?}/mo — right-size security-agent + log-shipper (step 2), then rollout"
exit 1
