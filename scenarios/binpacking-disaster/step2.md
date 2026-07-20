# Is `checkout` really using 3.5 cores?

Requests are a *reservation*, not usage. `checkout` reserves 3.5 CPU but its real
steady-state usage is closer to **1.5 cores**.

> This lab has no metrics stack (so `kubectl top` won't work here) — in production
> you'd read real usage from Prometheus / your metrics server / MetrixForge over a
> p95 window. For this exercise we've given you the number.

A safe request covers the p95 with headroom — call it **2 cores**. Right-size it:

```bash
kubectl -n shop set resources deploy/checkout \
  --requests=cpu=2000m,memory=2Gi --limits=cpu=2000m,memory=2Gi
kubectl -n shop rollout status deploy/checkout
```

**What changes:** at 2 CPU, **4 pods now fit per 8-CPU node** instead of 2. The 24
pods can live on **6–7 nodes** instead of 12 — but they won't move on their own. The
scheduler places *new* pods tightly; it never re-packs *running* ones. That's the
next step.

> Rule of thumb: right-size to **p95 usage + ~30% headroom**, never to the peak.
> Over-sized requests are the #1 cause of "my cluster is full but idle."
