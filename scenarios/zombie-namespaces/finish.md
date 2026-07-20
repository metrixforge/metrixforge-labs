# You just deleted $1,121/mo of dead code.

**The leak:** five abandoned namespaces — old PR previews, a sales demo, a leftover
load-test, a one-off migration — kept running pods for months. They reserved capacity,
so the cluster held nodes to fit them.

| | Before | After |
|---|---|---|
| Fleet | 6 × m5.2xlarge ($1,682/mo) | 2 × m5.2xlarge ($561/mo) |
| Stale-namespace requests | $565/mo | $0 |
| **Savings** | | **~−$1,121/mo** |

The reason it stayed hidden: `kubectl` can't rank namespaces by cost or age. You need
a tool that joins **pricing × requests × last-activity** — which is exactly what you
just did by hand.

---

Doing this by hand is a once-a-quarter cleanup you'll forget to run. And age alone is a
blunt signal — delete the wrong namespace and you've taken down something low-traffic
but load-bearing, so you still have to confirm each one is really idle before you pull it.

**MetrixForge gives you this lens continuously.** It ranks every namespace by real cost
— so a namespace creeping up the bill gets noticed the week it happens, not next quarter
— and once you reclaim the capacity, it **tracks the realized savings** over time, so the
$1,121/mo lands on a chart instead of evaporating into "we cleaned some stuff up."

<!-- screenshot: MetrixForge namespace cost breakdown + savings-history (assets/finish.webp) -->

**→ [Track your reclaimed savings](https://app.metrixforge.io/savings-history?utm_source=killercoda&utm_medium=lab&utm_campaign=zombie-namespaces)** — free trial, connects in one `helm install`.

---

*Next lab:* **The Agent Army: DaemonSets Eating 18% of Every Node** → when the waste
isn't a dead namespace, but a per-node agent multiplied across your whole fleet.
