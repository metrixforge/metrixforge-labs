# How much of your fleet do the agents eat?

Wait for setup, then measure the tax:

```bash
wait-setup && costctl waste --daemonsets
```

**What to look for:** the `DaemonSet 'fleet tax'` line — roughly **$1,000/mo, ~18% of
every node**. That's the combined reservation of every per-node agent, multiplied
across 20 nodes, before your `web` app gets a single core.

Now see which agents are the greedy ones:

```bash
costctl workloads -n platform
```

Four DaemonSets. Two look reasonable (`node-exporter`, `mesh-proxy`). Two don't:

- **`security-agent`** — reserves **750m CPU + 1Gi** per node.
- **`log-shipper`** — reserves **500m CPU + 512Mi** per node.

A log shipper and a security sidecar using 3/4 of a core *each*, on every node? That's
the smell. In production you'd confirm with real usage — here they idle around 50-100m.
