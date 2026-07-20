# MetrixForge Labs

**Free, hands-on Kubernetes FinOps labs.** Each one drops you into a live cluster
that's quietly burning money. You find the leak with `kubectl`, fix it, and watch
the bill drop — in real dollars.

Run them in your browser on [Killercoda](https://killercoda.com/) (no signup, no
cloud account), or locally with `kind`.

> Built by [MetrixForge](https://metrixforge.io) — Kubernetes cost, capacity &
> reliability analytics. These labs teach the manual version of what MetrixForge
> does continuously across your whole estate.

## Labs

| Lab | What you'll find | Savings |
|-----|------------------|---------|
| [`binpacking-disaster`](scenarios/binpacking-disaster) — *12 Nodes Doing the Work of 7* | Over-sized CPU requests fragmenting a fleet | −$1,400/mo |

*More landing soon: overprovisioned deployments, sleeping Karpenter, zombie
namespaces, rogue CronJobs, spot mis-scheduling, storage graveyards, idle GPUs…*

## Run a lab locally

Needs `kind`, `kubectl`, `helm`, `python3`, `docker`:

```bash
bash e2e/run-scenario.sh binpacking-disaster
```

This spins up a kind cluster, runs the lab's setup, then proves the solution clears
every check. Teardown is automatic.

## What's inside

```
tools/costctl        # a tiny, deterministic cost lens (a stand-in for OpenCost/MetrixForge)
common/              # pinned kwok install + fake-fleet generator + helpers
scenarios/<slug>/    # Killercoda scenario: intro, steps, verify, setup
solutions/<slug>/    # the full solution (public on purpose)
e2e/                 # kind-based end-to-end runner
```

`costctl` reads node instance-type pricing (`tools/pricing.json`, synthetic ~us-east-1)
plus the cluster's requests/capacity and reports what you **pay** vs what you
**request** — `costctl nodes`, `costctl waste`, `costctl workloads`, `costctl report`.
Deterministic, offline, no cloud credentials. Run its tests: `python3 tools/test_costctl.py`.

Everything is version-pinned in [`common/versions.env`](common/versions.env) — labs
must be reproducible.

## Contributing / feedback

Found a bug or want a scenario? Open an issue. Solutions are public by design — the
goal is to teach the forensics, not gate it.

---

Ready to see your own clusters' waste in 30 seconds instead of 20 minutes?
**[Start a free MetrixForge trial →](https://app.metrixforge.io?utm_source=killercoda&utm_medium=lab&utm_campaign=readme)**
