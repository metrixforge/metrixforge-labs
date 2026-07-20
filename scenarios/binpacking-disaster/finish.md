# You just found ~$1,400/mo. In one deployment.

**The leak:** `checkout` reserved 3.5 CPU but used ~1.5. Over-sized requests capped
each 8-CPU node at 2 pods, so 24 pods sprawled across 12 nodes — memory sitting 87%
idle the whole time.

**The fix:** right-size requests to reality → 4 pods/node → consolidate 12 → 7 nodes.

| | Before | After |
|---|---|---|
| Nodes | 12 | 7 |
| Monthly | $3,364 | $1,962 |
| **Savings** | | **−$1,400/mo** |

---

You found this in ~20 minutes, on one service you already knew to look at.

**MetrixForge finds it in 30 seconds — across every workload, in every cluster.**
It watches requests-vs-usage continuously, flags the over-provisioned deployments,
and shows the exact right-sized number (p95 + tier-aware headroom) with the dollar
impact — the same math you just did by hand, on your whole estate.

<!-- screenshot: MetrixForge efficiency/diagnostics view (assets/finish.webp) -->

**→ [See your own cluster's bin-packing waste](https://app.metrixforge.io/diagnostics?utm_source=killercoda&utm_medium=lab&utm_campaign=binpacking-disaster)** — free trial, no agent-to-AWS credentials, connects in one `helm install`.

---

*Next lab:* **The $1,400 Ghost — Find the Overprovisioned Deployment** → deep-dive on
a single workload's rightsizing with live usage metrics.
