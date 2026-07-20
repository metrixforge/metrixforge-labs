#!/usr/bin/env python3
"""Unit tests for costctl against fixed JSON fixtures (no cluster needed).
Expected values are hand-computed in testdata/ — see the lab RECON docs.
Run: python3 test_costctl.py
"""
import datetime, json, os, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
COSTCTL = os.path.join(HERE, "costctl")
N = os.path.join(HERE, "testdata", "nodes.json")
P = os.path.join(HERE, "testdata", "pods.json")
fails = []


def run(*cmd):
    r = subprocess.run([sys.executable, COSTCTL, "--nodes", N, "--pods", P, *cmd, "--json"],
                       capture_output=True, text=True)
    assert r.returncode == 0, r.stderr
    return json.loads(r.stdout)


def near(name, got, want, tol=1.5):
    if abs(got - want) > tol:
        fails.append(f"{name}: got {got}, want ~{want} (±{tol})")
    else:
        print(f"  ok  {name} = {got} (~{want})")


# nodes
n = run("nodes")
near("nodes.total_monthly_usd", n["total_monthly_usd"], 372.81, 1.0)
assert n["node_count"] == 2, n
node_a = next(x for x in n["nodes"] if x["node"] == "node-a")
near("node-a cpu%", node_a["cpu_pct"], 56.2)
near("node-a mem%", node_a["mem_pct"], 26.6)

# waste
w = run("waste")
near("waste_monthly_usd", w["waste_monthly_usd"], 221.1, 2.0)
near("total_monthly_usd", w["total_monthly_usd"], 372.81, 1.0)
near("waste_pct", w["waste_pct"], 59.3)

wd = run("waste", "--daemonsets")
near("daemonset_monthly_usd", wd["daemonset_monthly_usd"], 18.9, 1.0)
near("daemonset_pct", wd["daemonset_pct"], 5.1, 0.6)

# workloads
wl = run("workloads")["workloads"]
by = {(r["kind"], r["name"]): r for r in wl}
near("web $/mo", by[("Deployment", "web")]["monthly_usd"], 122.6, 1.5)
near("api $/mo", by[("Deployment", "api")]["monthly_usd"], 10.1, 1.0)
near("logshipper(DS) $/mo", by[("DaemonSet", "logshipper")]["monthly_usd"], 18.9, 1.0)
assert wl[0]["kind"] == "Deployment" and wl[0]["name"] == "web", "workloads must sort by $ desc"

# CONSISTENCY: sum(workloads) + waste == total node cost
sum_wl = sum(r["monthly_usd"] for r in wl)
near("consistency (Σworkloads + waste == total)", sum_wl + w["waste_monthly_usd"],
     n["total_monthly_usd"], 2.0)

# quantity parsing sanity via a spot node being ~3x cheaper than on-demand
near("spot node ≈ 24% of on-demand", node_a["monthly_usd"],
     next(x for x in n["nodes"] if x["node"] == "node-b")["monthly_usd"] / 0.33, 5.0)

# --- namespaces (zombie-namespaces lab) --------------------------------------
# Age is now-relative, so build the namespaces fixture off UTC-today for a
# deterministic age_days. shop=fresh (3d), preview-pr-1 + demo-old=stale (>90d),
# kube-system=old-but-PROTECTED (must never be flagged).
NSP = os.path.join(HERE, "testdata", "ns_pods.json")


def _days_ago(d):
    return (datetime.datetime.now(datetime.timezone.utc).date()
            - datetime.timedelta(days=d)).isoformat()


_ns_fixture = {"items": [
    {"metadata": {"name": "shop", "annotations": {"metrixforge.io/last-deploy": _days_ago(3)}}},
    {"metadata": {"name": "preview-pr-1", "annotations": {"metrixforge.io/last-deploy": _days_ago(140)}}},
    {"metadata": {"name": "demo-old", "annotations": {"metrixforge.io/last-deploy": _days_ago(200)}}},
    {"metadata": {"name": "kube-system", "creationTimestamp": _days_ago(200) + "T00:00:00Z"}},
    # old-but-ACTIVE infra with NO last-deploy annotation — must NOT be flagged stale
    # (staleness is gated on the explicit annotation, never on creation age).
    {"metadata": {"name": "legacy-infra", "creationTimestamp": _days_ago(400) + "T00:00:00Z"}},
]}
with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as _tf:
    json.dump(_ns_fixture, _tf)
    NSF = _tf.name
try:
    _r = subprocess.run([sys.executable, COSTCTL, "--nodes", N, "--pods", NSP,
                         "--namespaces", NSF, "namespaces", "--stale-days", "90", "--json"],
                        capture_output=True, text=True)
    assert _r.returncode == 0, _r.stderr
    ns = json.loads(_r.stdout)
finally:
    os.unlink(NSF)
nsby = {r["namespace"]: r for r in ns["namespaces"]}
# costs: shop 2x(1cpu+1Gi)=56.94; preview 2x(1cpu+2Gi)=61.32; demo 1x(2cpu+2Gi)=56.94
near("shop $/mo", nsby["shop"]["monthly_usd"], 56.94, 1.0)
near("preview-pr-1 $/mo", nsby["preview-pr-1"]["monthly_usd"], 61.32, 1.0)
near("demo-old $/mo", nsby["demo-old"]["monthly_usd"], 56.94, 1.0)
near("shop age_days", nsby["shop"]["age_days"], 3, 1.5)
near("demo-old age_days", nsby["demo-old"]["age_days"], 200, 1.5)
near("legacy-infra age_days (from creationTimestamp)", nsby["legacy-infra"]["age_days"], 400, 1.5)
assert nsby["shop"]["stale"] is False, "fresh namespace must not be stale"
assert nsby["preview-pr-1"]["stale"] is True, "old namespace must be stale"
assert nsby["demo-old"]["stale"] is True, "old namespace must be stale"
assert nsby["kube-system"]["stale"] is False, "kube-system is protected, never stale"
assert nsby["legacy-infra"]["stale"] is False, "no last-deploy annotation → never stale (even at 400d)"
assert set(ns["stale_namespaces"]) == {"preview-pr-1", "demo-old"}, ns["stale_namespaces"]
# reclaimable = preview 61.32 + demo 56.94 = 118.26 (kube-system + legacy-infra excluded)
near("reclaimable_monthly_usd", ns["reclaimable_monthly_usd"], 118.26, 1.0)
assert ns["namespaces"][0]["monthly_usd"] >= ns["namespaces"][-1]["monthly_usd"], "sort by $ desc"

if fails:
    print("\nFAILURES:")
    for f in fails:
        print("  ✗", f)
    sys.exit(1)
print("\n✅ all costctl tests passed")
