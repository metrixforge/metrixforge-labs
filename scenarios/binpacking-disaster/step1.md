# Which nodes are you paying for — and how full are they?

Wait for setup, then read the per-node bill:

```bash
wait-setup && costctl nodes
```

`costctl` prices each node from its instance type and shows how much of it your
pods actually **request** (what the scheduler reserves, and what you pay for).

**What to look for:** 12 identical `m5.2xlarge` nodes at **~$280/mo each ≈ $3,364/mo**.
Look at the two utilization columns:

- **CPU% ≈ 89** — nearly full on CPU.
- **MEM% ≈ 13** — almost empty on memory.

That lopsided shape is the tell. The nodes are "full" only because a few large
**CPU requests** don't leave room for more pods — not because the work needs it.
See who's asking for all that CPU:

```bash
costctl workloads -n shop
```

One deployment, `checkout` (24 pods), is booking **3.5 CPU each**. On an 8-CPU node
that's **2 pods per node** — so 24 pods spread across all 12 nodes. Next: is 3.5 real?
