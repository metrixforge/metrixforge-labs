# Pack the work onto fewer nodes — and read the new bill.

Now that each pod fits 4-to-a-node, drain the surplus nodes so the pods re-pack
onto the minimum needed. The provided script computes that minimum and removes the
rest (this is what Karpenter's consolidation does automatically):

```bash
bash /opt/lab/consolidate.sh
```

Watch it converge, then re-read the bill:

```bash
costctl nodes
```

**What to look for:** the fleet drops from **12 → 7 nodes**, every `checkout` pod is
still `Running` (24/24), and the total falls from **~$3,364/mo to ~$1,962/mo**.

You just cut **~$1,400/mo** off one deployment's footprint — no new hardware, no
code change, just requests that match reality.

*(Push further: at 1.5-CPU requests the same work packs onto ~5 nodes. The trade-off
is headroom for spikes — that's the judgment call rightsizing is really about.)*
