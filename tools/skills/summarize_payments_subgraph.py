"""
Identify the Payments super-domain by cluster (manual seed: cluster IDs that
together form Payments) and emit a curated subgraph view ready for subdomain
partitioning at the next phase.

Reads:  knowledge/skills/_domain_candidates.json
        knowledge/skills/_join_graph.json
Writes: knowledge/skills/_payments_subgraph.md
"""
from __future__ import annotations

import json
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SKILLS = ROOT / "knowledge" / "skills"

# Manually selected Payments-adjacent seed hubs (we'll iterate with user).
PAYMENTS_SEED_HUBS = {
    "DWH_dbo.Fact_BillingDeposit",
    "DWH_dbo.Fact_BillingWithdraw",
    "BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms",
    "EXW_Wallet.CryptoTypes",
    "eMoney_dbo.eMoney_Dim_Account",
    "EXW_dbo.EXW_FinanceReportsBalancesNew",
    "FiatDwhDB.Tribe",
    "Dealing_dbo.Dealing_IGReconEODHolding",
}


def main() -> int:
    cmap = json.loads((SKILLS / "_domain_candidates.json").read_text(encoding="utf-8"))
    g = json.loads((SKILLS / "_join_graph.json").read_text(encoding="utf-8"))

    payments_clusters = []
    for c in cmap:
        members = set(c["all_members"])
        seed_hits = [h for h in PAYMENTS_SEED_HUBS if h in members]
        if seed_hits:
            payments_clusters.append((c, seed_hits))

    payments_nodes = set()
    for c, _ in payments_clusters:
        payments_nodes.update(c["all_members"])

    sub_edges = []
    for e in g["edges"]:
        if e["a"] in payments_nodes and e["b"] in payments_nodes:
            sub_edges.append(e)

    src_counts: Counter = Counter()
    for e in sub_edges:
        for s, n in e["by_source"].items():
            src_counts[s] += n

    genie_idx = json.loads((SKILLS / "_genie_spaces_index.json").read_text(encoding="utf-8"))
    genie_hits = []
    for sp in genie_idx:
        tables = sp.get("canonical_tables") or sp.get("tables", [])
        overlap = sum(1 for t in tables if t in payments_nodes)
        if overlap >= 2:
            genie_hits.append({
                "title": sp["title"],
                "overlap": overlap,
                "n_tables": sp.get("n_tables", 0),
                "description": sp.get("description", "")[:200],
            })
    genie_hits.sort(key=lambda x: -x["overlap"])

    lines = []
    lines.append("# Payments Super-Domain — Subgraph Profile")
    lines.append("")
    lines.append(f"_Selected by manual seed hubs: {sorted(PAYMENTS_SEED_HUBS)}_")
    lines.append("")
    lines.append("## Scope")
    lines.append(f"- Member clusters: {len(payments_clusters)}")
    lines.append(f"- Total nodes: {len(payments_nodes)}")
    lines.append(f"- Total internal edges: {len(sub_edges)}")
    lines.append(f"- Edge sources: {dict(src_counts)}")
    lines.append("")

    lines.append("## Member clusters")
    lines.append("")
    lines.append("| Cluster | Hub | Size | Seed hubs in cluster | Genie spaces |")
    lines.append("|---|---|---|---|---|")
    for c, seeds in payments_clusters:
        hub = c["top_members"][0]["node"] if c["top_members"] else ""
        gn = ", ".join(f"{g['title']}({g['overlap']})" for g in c["genie_overlap"][:3])
        lines.append(f"| {c['cluster_id']} | `{hub}` | {c['size']} | {len(seeds)} | {gn} |")
    lines.append("")

    lines.append("## Top hubs across the Payments super-domain")
    lines.append("")
    deg = defaultdict(float)
    for e in sub_edges:
        deg[e["a"]] += e["weight"]
        deg[e["b"]] += e["weight"]
    for n, w in sorted(deg.items(), key=lambda kv: -kv[1])[:30]:
        lines.append(f"- `{n}` — {w:.1f}")
    lines.append("")

    lines.append("## Genie spaces intersecting Payments (>=2 tables)")
    lines.append("")
    for g_ in genie_hits[:25]:
        lines.append(f"- `{g_['title']}` — {g_['overlap']}/{g_['n_tables']} tables")
        if g_["description"]:
            lines.append(f"  > {g_['description']}")
    lines.append("")

    lines.append("## Cluster details (members)")
    for c, _ in payments_clusters:
        lines.append("")
        lines.append(f"### Cluster {c['cluster_id']} — `{c['top_members'][0]['node']}` ({c['size']} members)")
        lines.append("")
        lines.append("**Top members:**")
        for m in c["top_members"][:15]:
            lines.append(f"- `{m['node']}` — {m['weight']}")
        if c.get("genie_overlap"):
            lines.append("")
            lines.append("**Genie spaces in this cluster:**")
            for g_ in c["genie_overlap"]:
                lines.append(f"- `{g_['title']}` ({g_['overlap']}/{g_['n_tables']})")
        if c.get("kpi_views_in_cluster"):
            lines.append("")
            lines.append("**KPI views in this cluster:**")
            for v in c["kpi_views_in_cluster"][:10]:
                lines.append(f"- `{v}`")
        if c["size"] <= 80:
            lines.append("")
            lines.append("<details><summary>All members</summary>")
            lines.append("")
            for m in c["all_members"]:
                lines.append(f"- `{m}`")
            lines.append("")
            lines.append("</details>")

    out = SKILLS / "_payments_subgraph.md"
    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {out.relative_to(ROOT)}")
    print(f"Payments super-domain: {len(payments_clusters)} clusters, {len(payments_nodes)} nodes, {len(sub_edges)} edges")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
