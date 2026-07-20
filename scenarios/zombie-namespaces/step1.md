# Rank your namespaces by dollars.

Wait for setup, then get the cost-by-namespace lens `kubectl` never gives you:

```bash
wait-setup && costctl namespaces
```

Every namespace, its pod count, its **age** (days since last deploy), and its `$/mo`.
Anything older than 90 days that's still running pods gets a **⚠ stale** flag:

```
NAMESPACE              PODS  AGE(d)      $/MO
shop                      8       2      $228
demo-acme-poc             3     187      $171  ⚠ stale
load-test-jan             2     168      $123  ⚠ stale
preview-pr-2841           4     134      $123  ⚠ stale
payments                  4       5      $114
preview-pr-2903           3     121       $92  ⚠ stale
platform                  2       4       $61
migration-v2              2      96       $57  ⚠ stale
...
Reclaimable from 5 stale namespace(s) (>90d since last deploy, still running pods): $565/mo
```

Read that top to bottom. `shop` and `payments` are your real apps — deployed days ago.
But look what's mixed in:

- **`demo-acme-poc`** — a sales demo from **187 days** ago, costing **$171/mo** — *more
  than your entire `payments` namespace ($114).*
- **`load-test-jan`**, **`preview-pr-2841/2903`** — a leftover load-test and two PR
  previews whose branches merged months ago.
- **`migration-v2`** — a one-off migration that finished and was never torn down.

Five abandoned namespaces reserving **$565/mo** — more than your real `payments` +
`platform` stack **combined ($175)**. The age column is the tell: nobody's deployed to
any of them in 3-6 months.
