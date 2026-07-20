# Delete the zombies.

The five stale namespaces are confirmed dead by both signals — **age** (96-187 days
untouched) and **name** (`preview-pr-*`, `demo-*`, `load-test-*`, `migration-*` are
all disposable by convention). Delete them:

```bash
kubectl delete namespace \
  preview-pr-2841 preview-pr-2903 demo-acme-poc load-test-jan migration-v2
```

Deleting a namespace deletes everything inside it — Deployments, pods, services,
configmaps — in one shot. Your production namespaces (`shop`, `payments`, `platform`)
are untouched.

```bash
costctl namespaces
```

The ⚠ stale rows are gone and `Reclaimable` drops to `$0`. But the fleet is still
6 nodes — you've freed the *capacity*, not the *bill*, yet. That's the next step.

> Two signals beat one. Age alone can misfire (a low-traffic but critical namespace
> looks "idle"); naming alone is a guess. Requiring **both** — plus, in production, a
> glance at whether anything still talks to it — is how you delete safely.
