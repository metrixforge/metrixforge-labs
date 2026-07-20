# Every node pays a tax before your apps run a thing.

You run a **20-node fleet**. On every single node, four agents run as DaemonSets —
metrics, logging, security, service mesh. That's normal. What's not normal is how
much they *reserve*.

DaemonSet requests are the quietest cost in Kubernetes: you set them once, they
multiply across the whole fleet, and nobody ever looks at them again. A little too
much on one agent becomes a lot across 20 nodes — a "fleet tax" skimmed off the top
before a single request pod gets scheduled.

In 15 minutes you'll measure that tax with `costctl`, find the two agents that are
wildly over-provisioned, right-size them, and prove the drop.

> Setup runs in the background while you read. Your first command waits for it.
