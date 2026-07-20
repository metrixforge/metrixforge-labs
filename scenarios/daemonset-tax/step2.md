# Right-size the two greedy agents.

`security-agent` and `log-shipper` are reserving ~5-7x their real usage. Because they
run on **every node**, trimming them pays back 20x. Right-size both:

```bash
kubectl -n platform set resources ds/security-agent \
  --requests=cpu=200m,memory=256Mi --limits=cpu=200m,memory=256Mi
kubectl -n platform set resources ds/log-shipper \
  --requests=cpu=150m,memory=256Mi --limits=cpu=150m,memory=256Mi

kubectl -n platform rollout status ds/security-agent
kubectl -n platform rollout status ds/log-shipper
```

**What changes:** per-node agent reservation drops from ~1.65 CPU to ~0.75 CPU. No
node removal, no app change — the same agents, sized to what they actually use.

> DaemonSet requests are a *per-node multiplier*. Always size agents to real p95 usage
> — an extra 300m on one agent is 300m × every node you'll ever run.
>
> For agents you don't need everywhere (e.g. a mesh proxy on batch nodes), a
> `nodeSelector` keeps them off whole pools entirely — even cheaper than right-sizing.
