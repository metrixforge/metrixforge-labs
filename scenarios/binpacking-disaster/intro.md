# This cluster is burning ~$3,400/mo. Some of it is fragmentation.

You've inherited an EKS cluster running a single busy service, `checkout`. It sits
on a **12-node fleet of `m5.2xlarge`** instances. Finance is asking why the bill
keeps climbing when traffic is flat.

The pods aren't crashing. CPU graphs look "fine." But the node count feels high for
what this service actually does — and node count is what you pay for.

In the next 20 minutes you'll use a tiny cost tool (`costctl`, a stand-in for what
OpenCost / MetrixForge do continuously) to find the leak, fix it, and watch the
fleet — and the bill — shrink.

> Setup runs in the background while you read. Your first command waits for it.

**What you'll do:** read the per-node bill → spot the requests that don't fit →
right-size them → consolidate the fleet → prove the dollar delta.
