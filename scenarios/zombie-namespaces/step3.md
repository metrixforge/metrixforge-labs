# Shrink the fleet to match.

Deleting the namespaces freed ~19 CPU of requests, so the 6-node fleet is now mostly
empty. Pack the survivors onto the minimum nodes and drop the rest:

```bash
bash /opt/lab/consolidate.sh
```

Then re-read the bill:

```bash
costctl nodes
```

**What to look for:** the fleet falls from **6 nodes ($1,682/mo) to 2 ($561/mo)** —
a recurring **−$1,121/mo**.

Notice the gap: the zombies *requested* only **$565/mo**, but killing them saved
**$1,121/mo** — nearly 2×. That's the hidden multiplier of abandoned namespaces: they
don't just waste their own requests, they pin whole **nodes** in place, and you pay
for every idle core on those nodes too. Five forgotten namespaces were holding up
**four m5.2xlarge instances**.
