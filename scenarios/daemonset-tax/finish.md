# You just cut ~$520/mo off your fleet tax.

**The leak:** two agents (`security-agent`, `log-shipper`) reserved ~5-7x their real
usage. Harmless on one node — but as DaemonSets they ran on all 20, so the waste was
multiplied 20x into a ~18% tax on every node.

| | Before | After |
|---|---|---|
| Per-node agent CPU | ~1.65 | ~0.75 |
| Fleet tax | ~18% (~$1,000/mo) | ~9% (~$490/mo) |
| **Savings** | | **~−$520/mo** |

---

DaemonSet waste is invisible in most tooling — it's spread one-thin-slice-per-node, so
no single pod looks expensive. You had to know to sum it across the fleet.

**MetrixForge surfaces it for you — every agent, every node, every cluster.** Once
your metrics are flowing it breaks cost down by workload (DaemonSets included), flags
the over-provisioned ones with their real-usage-based right-size, and shows the
fleet-multiplied dollar impact — so the "agent army" stops hiding.

<!-- screenshot: MetrixForge workload cost breakdown (assets/finish.webp) -->

**→ [See your fleet's DaemonSet tax](https://app.metrixforge.io/cost?utm_source=killercoda&utm_medium=lab&utm_campaign=daemonset-tax)** — free trial, connects in one `helm install`.

---

*Next lab:* **12 Nodes Doing the Work of 7: A Bin-Packing Post-Mortem** → when it's the
*app* requests, not the agents, fragmenting your fleet.
