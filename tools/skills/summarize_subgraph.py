"""
Generic per-domain subgraph summarizer. Replaces tools/skills/summarize_payments_subgraph.py
(the original Payments-only script) per spec 011 reusability principle.

Given a domain seed YAML (tools/skills/_seeds/<domain>.yaml), this script:
  1. Loads _domain_candidates.json (Louvain clusters) and _join_graph.json.
  2. Identifies clusters whose all_members overlap the seed's hub_tables OR
     primary_clusters list. Each matched cluster becomes part of the domain's
     scope.
  3. Optionally widens scope by including nodes referenced by KPI views in
     kpi_seeds and tables in Genie spaces matched by genie_seeds (so the
     subgraph is Genie-seeded, not just Louvain-seeded).
  4. Emits intra-domain edges + cross-edges (sorted by weight) to sibling
     clusters / domains.
  5. Writes knowledge/skills/_<domain>_subgraph.md.

Usage:
  python tools/skills/summarize_subgraph.py --domain compliance
  python tools/skills/summarize_subgraph.py --domain payments  # back-compat regen

Reads:
  tools/skills/_seeds/<domain>.yaml
  knowledge/skills/_domain_candidates.json
  knowledge/skills/_join_graph.json
  knowledge/skills/_genie_spaces_index.json
  knowledge/skills/_kpi_views_index.json
"""
from __future__ import annotations

import argparse
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
SKILLS = ROOT / "knowledge" / "skills"
SEEDS = Path(__file__).resolve().parent / "_seeds"


def load_seed(domain: str) -> dict:
    p = SEEDS / f"{domain}.yaml"
    if not p.exists():
        print(f"Seed not found: {p}", file=sys.stderr)
        sys.exit(2)
    return yaml.safe_load(p.read_text(encoding="utf-8"))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--domain", required=True)
    ap.add_argument("--no-genie-widen", action="store_true",
                    help="restrict scope to Louvain-cluster members only (no Genie/KPI widening); use for back-compat regen")
    ap.add_argument("--output", default=None)
    args = ap.parse_args()

    seed = load_seed(args.domain)
    hub_tables = set(seed.get("hub_tables") or [])
    primary_clusters = set(seed.get("primary_clusters") or [])
    kpi_seeds = set(seed.get("kpi_seeds") or [])
    genie_seeds = [t.lower() for t in (seed.get("genie_seeds") or [])]

    cmap = json.loads((SKILLS / "_domain_candidates.json").read_text(encoding="utf-8"))
    g = json.loads((SKILLS / "_join_graph.json").read_text(encoding="utf-8"))

    matched_clusters = []
    for c in cmap:
        members = set(c["all_members"])
        seed_hits = [h for h in hub_tables if h in members]
        is_primary = c["cluster_id"] in primary_clusters
        if seed_hits or is_primary:
            matched_clusters.append((c, seed_hits, is_primary))

    domain_nodes = set()
    for c, _, _ in matched_clusters:
        domain_nodes.update(c["all_members"])

    widened_by_genie: set[str] = set()
    widened_by_kpi: set[str] = set()
    if not args.no_genie_widen:
        genie_idx = json.loads((SKILLS / "_genie_spaces_index.json").read_text(encoding="utf-8"))
        for sp in genie_idx:
            title_lc = sp.get("title", "").lower()
            if not any(t in title_lc for t in genie_seeds):
                continue
            for t in (sp.get("canonical_tables") or sp.get("tables") or []):
                if t not in domain_nodes:
                    widened_by_genie.add(t)
                    domain_nodes.add(t)

        kpi_idx = json.loads((SKILLS / "_kpi_views_index.json").read_text(encoding="utf-8"))
        by_self = {v["self_ref"]: v for v in kpi_idx}
        seen: set[str] = set()
        def crawl(ref: str) -> None:
            if ref in seen:
                return
            seen.add(ref)
            rec = by_self.get(ref)
            if not rec:
                return
            for r in rec.get("refs", []):
                if r not in domain_nodes:
                    widened_by_kpi.add(r)
                    domain_nodes.add(r)
                crawl(r)
        for v in kpi_seeds:
            crawl(v)

    sub_edges = []
    cross_edges = []
    for e in g["edges"]:
        a_in = e["a"] in domain_nodes
        b_in = e["b"] in domain_nodes
        if a_in and b_in:
            sub_edges.append(e)
        elif a_in or b_in:
            cross_edges.append(e)

    src_counts: Counter = Counter()
    for e in sub_edges:
        for s, n in e["by_source"].items():
            src_counts[s] += n

    genie_idx_all = json.loads((SKILLS / "_genie_spaces_index.json").read_text(encoding="utf-8"))
    genie_hits = []
    for sp in genie_idx_all:
        tables = sp.get("canonical_tables") or sp.get("tables", [])
        overlap = sum(1 for t in tables if t in domain_nodes)
        if overlap >= 2:
            genie_hits.append({
                "title": sp["title"],
                "overlap": overlap,
                "n_tables": sp.get("n_tables", 0),
                "description": (sp.get("description") or "")[:200],
                "is_seed_match": any(t in sp.get("title", "").lower() for t in genie_seeds),
            })
    genie_hits.sort(key=lambda x: (-int(x["is_seed_match"]), -x["overlap"]))

    out_path = Path(args.output) if args.output else SKILLS / f"_{args.domain}_subgraph.md"
    display = seed.get("display_name", args.domain)

    lines = []
    lines.append(f"# {display} Super-Domain — Subgraph Profile")
    lines.append("")
    lines.append(f"_Generated by `tools/skills/summarize_subgraph.py --domain {args.domain}`_")
    lines.append("")
    lines.append(f"_Seed: `tools/skills/_seeds/{args.domain}.yaml`_")
    lines.append("")
    if hub_tables:
        lines.append(f"_Seed hubs: {sorted(hub_tables)}_")
        lines.append("")
    if primary_clusters:
        lines.append(f"_Primary clusters from seed: {sorted(primary_clusters)}_")
        lines.append("")

    lines.append("## Scope")
    lines.append(f"- Member clusters: {len(matched_clusters)}")
    lines.append(f"- Total nodes: {len(domain_nodes)}")
    lines.append(f"  - From Louvain clusters: {len(domain_nodes) - len(widened_by_genie) - len(widened_by_kpi)}")
    if widened_by_genie:
        lines.append(f"  - Widened by Genie seeds: {len(widened_by_genie)}")
    if widened_by_kpi:
        lines.append(f"  - Widened by KPI seeds: {len(widened_by_kpi)}")
    lines.append(f"- Total internal edges: {len(sub_edges)}")
    lines.append(f"- Total cross-domain edges: {len(cross_edges)}")
    lines.append(f"- Edge sources: {dict(src_counts)}")
    lines.append("")

    lines.append("## Member clusters")
    lines.append("")
    lines.append("| Cluster | Hub | Size | Seed hubs in cluster | Primary? | Genie spaces |")
    lines.append("|---|---|---|---|---|---|")
    for c, seeds, is_primary in matched_clusters:
        hub = c["top_members"][0]["node"] if c["top_members"] else ""
        gn = ", ".join(f"{g['title']}({g['overlap']})" for g in c.get("genie_overlap", [])[:3])
        primary_tag = "yes" if is_primary else "no"
        lines.append(f"| {c['cluster_id']} | `{hub}` | {c['size']} | {len(seeds)} | {primary_tag} | {gn} |")
    lines.append("")

    if widened_by_genie or widened_by_kpi:
        lines.append("## Nodes added by widening (not in any matched Louvain cluster)")
        lines.append("")
        if widened_by_genie:
            lines.append("**Added by Genie seed match:**")
            for n in sorted(widened_by_genie):
                lines.append(f"- `{n}`")
            lines.append("")
        if widened_by_kpi:
            lines.append("**Added by KPI seed closure:**")
            for n in sorted(widened_by_kpi):
                lines.append(f"- `{n}`")
            lines.append("")

    lines.append(f"## Top hubs across the {display} super-domain")
    lines.append("")
    deg: dict[str, float] = defaultdict(float)
    for e in sub_edges:
        deg[e["a"]] += e["weight"]
        deg[e["b"]] += e["weight"]
    for n, w in sorted(deg.items(), key=lambda kv: -kv[1])[:30]:
        lines.append(f"- `{n}` — {w:.1f}")
    lines.append("")

    lines.append(f"## Genie spaces intersecting {display} (>=2 tables)")
    lines.append("")
    for g_ in genie_hits[:25]:
        prefix = "**[SEED]** " if g_["is_seed_match"] else ""
        lines.append(f"- {prefix}`{g_['title']}` — {g_['overlap']}/{g_['n_tables']} tables")
        if g_["description"]:
            lines.append(f"  > {g_['description']}")
    lines.append("")

    lines.append("## Cross-domain edges (top by weight)")
    lines.append("")
    lines.append("Top 30 edges leaving this domain (one node in, one node out).")
    lines.append("")
    lines.append("| Inside node | Outside node | Weight | Sources |")
    lines.append("|---|---|---|---|")
    for e in sorted(cross_edges, key=lambda x: -x["weight"])[:30]:
        inside, outside = (e["a"], e["b"]) if e["a"] in domain_nodes else (e["b"], e["a"])
        srcs = ", ".join(f"{k}:{v}" for k, v in e["by_source"].items())
        lines.append(f"| `{inside}` | `{outside}` | {e['weight']:.1f} | {srcs} |")
    lines.append("")

    lines.append("## Cluster details (members)")
    for c, _, is_primary in matched_clusters:
        lines.append("")
        prim_tag = " **(PRIMARY from seed)**" if is_primary else ""
        hub = c["top_members"][0]["node"] if c["top_members"] else "(empty)"
        lines.append(f"### Cluster {c['cluster_id']} — `{hub}` ({c['size']} members){prim_tag}")
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

    out_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {out_path.relative_to(ROOT)}")
    print(f"  {display}: {len(matched_clusters)} clusters, {len(domain_nodes)} nodes, {len(sub_edges)} intra-edges, {len(cross_edges)} cross-edges")
    return 0


if __name__ == "__main__":
    sys.exit(main())
