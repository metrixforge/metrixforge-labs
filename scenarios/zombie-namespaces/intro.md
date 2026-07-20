# Nobody ever deletes a namespace.

Namespaces are born constantly — a PR preview, a sales demo, a load-test, a one-off
migration. They're supposed to be temporary. But deleting one is nobody's job, so
they linger for months, quietly running pods that reserve real CPU and memory.

Your cluster autoscaled up to fit that footprint. Half of it is now dead code that
nobody has looked at since last quarter — and you're paying for the nodes holding it.

The reason it hides: **`kubectl` has no cost-by-namespace view.** You can list
namespaces, but not rank them by dollars or spot the one that's been idle for 187 days.

In 15 minutes you'll get that lens with `costctl`, find the abandoned namespaces by
**cost + age**, delete them, and watch the fleet shrink.

> Setup runs in the background while you read. Your first command waits for it.
