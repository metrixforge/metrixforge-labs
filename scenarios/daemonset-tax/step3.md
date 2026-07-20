# Re-measure the tax.

```bash
costctl waste --daemonsets
```

**What to look for:** the fleet tax falls from **~18% to ~9%** — roughly **$1,000 → $490/mo**,
a recurring **~$520/mo** saved. The same per-node agents, same 20 nodes, same workloads
— you just stopped reserving capacity nobody was using.

Multiply this by every DaemonSet you've ever `helm install`ed and forgotten about,
across every cluster, and the "agent army" is often one of the biggest silent line
items on the bill.
