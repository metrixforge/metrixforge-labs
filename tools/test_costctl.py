#!/usr/bin/env python3
"""Unit tests for costctl against fixed JSON fixtures (no cluster needed).
Expected values are hand-computed in testdata/ — see the lab RECON docs.
Run: python3 test_costctl.py
"""
import json, os, subprocess, sys

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

if fails:
    print("\nFAILURES:")
    for f in fails:
        print("  ✗", f)
    sys.exit(1)
print("\n✅ all costctl tests passed")
