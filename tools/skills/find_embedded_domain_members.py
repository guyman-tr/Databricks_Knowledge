"""
Find nodes that "feel like" a domain by name but were placed in OTHER Louvain
clusters by the partition. Surfaces Louvain leakage so the domain skill can
pull these nodes into its scope despite the partition.

For example: AML-named tables landed in clusters 1/2/3/10 (Customer/snapshot
family) because their dominant join evidence was to Customer dimension tables,
not to the small AML core cluster (35). The AML purpose is still real.

Algorithm:
  1. Load _join_graph.json nodes and _node_summary.csv (per-node weights).
  2. Load _domain_candidates.json (cluster assignments).
  3. Compile embedded_scan_patterns from the seed YAML into a regex.
  4. For every node whose name matches AND whose cluster_id is in
     embedded_clusters (or is NOT in primary_clusters), emit a row with:
       - the regex pattern that matched
       - the assigned cluster + top member of that cluster
       - the node's intra-cluster weight
       - the node's TOP NEIGHBORS in _join_graph.json
  5. Optionally cross-reference with seed_yaml.genie_seeds — if a matched node
     also appears in a seed Genie's table list, that's an extra-strong signal.

Usage:
  python tools/skills/find_embedded_domain_members.py --domain compliance

Output:
  knowledge/skills/_<domain>_embedded_members.md

Reads:
  tools/skills/_seeds/<domain>.yaml
  knowledge/skills/_join_graph.json
  knowledge/skills/_domain_candidates.json
  knowledge/skills/_genie_spaces_index.json
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
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
    ap.add_argument("--output", default=None)
    args = ap.parse_args()

    seed = load_seed(args.domain)
    patterns_raw = seed.get("embedded_scan_patterns") or []
    if not patterns_raw:
        print(f"Seed for {args.domain} has no embedded_scan_patterns; nothing to scan.", file=sys.stderr)
        return 1
    patterns = [(p, re.compile(p)) for p in patterns_raw]
    embedded_clusters = set(seed.get("embedded_clusters") or [])
    primary_clusters = set(seed.get("primary_clusters") or [])
    hub_tables = set(seed.get("hub_tables") or [])
    genie_seeds = [t.lower() for t in (seed.get("genie_seeds") or [])]

    cmap = json.loads((SKILLS / "_domain_candidates.json").read_text(encoding="utf-8"))
    g = json.loads((SKILLS / "_join_graph.json").read_text(encoding="utf-8"))

    node_to_cluster: dict[str, int] = {}
    cluster_top_member: dict[int, str] = {}
    for c in cmap:
        cid = c["cluster_id"]
        if c["top_members"]:
            cluster_top_member[cid] = c["top_members"][0]["node"]
        for m in c["all_members"]:
            node_to_cluster[m] = cid

    intra_w: dict[str, float] = defaultdict(float)
    inter_w: dict[str, float] = defaultdict(float)
    neighbors: dict[str, list[tuple[str, float]]] = defaultdict(list)
    for e in g["edges"]:
        a, b = e["a"], e["b"]
        ac = node_to_cluster.get(a)
        bc = node_to_cluster.get(b)
        if ac is not None and ac == bc:
            intra_w[a] += e["weight"]
            intra_w[b] += e["weight"]
        else:
            inter_w[a] += e["weight"]
            inter_w[b] += e["weight"]
        neighbors[a].append((b, e["weight"]))
        neighbors[b].append((a, e["weight"]))

    genie_table_set: dict[str, list[str]] = defaultdict(list)
    genie_idx = json.loads((SKILLS / "_genie_spaces_index.json").read_text(encoding="utf-8"))
    for sp in genie_idx:
        title_lc = sp.get("title", "").lower()
        if not any(t in title_lc for t in genie_seeds):
            continue
        for t in (sp.get("canonical_tables") or sp.get("tables") or []):
            genie_table_set[t].append(sp.get("title", ""))

    matches: list[dict] = []
    for node in g["nodes"]:
        name = node if isinstance(node, str) else node.get("id", "")
        if not name:
            continue
        if name in hub_tables:
            continue
        matched_patterns = [pat for pat, rx in patterns if rx.search(name)]
        if not matched_patterns:
            continue
        cid = node_to_cluster.get(name)
        if cid is None:
            continue
        is_primary_cluster = cid in primary_clusters
        is_embedded_cluster = cid in embedded_clusters
        is_in_seed_genie = name in genie_table_set
        if is_primary_cluster and not is_in_seed_genie:
            # already in the domain's primary cluster — not "embedded" elsewhere
            continue
        top_neighbors = sorted(neighbors[name], key=lambda kv: -kv[1])[:5]
        matches.append({
            "node": name,
            "cluster_id": cid,
            "cluster_top": cluster_top_member.get(cid, "?"),
            "is_embedded_cluster": is_embedded_cluster,
            "is_primary_cluster": is_primary_cluster,
            "is_in_seed_genie": is_in_seed_genie,
            "genie_hits": genie_table_set.get(name, []),
            "matched_patterns": matched_patterns,
            "intra_w": intra_w[name],
            "inter_w": inter_w[name],
            "top_neighbors": top_neighbors,
        })

    matches.sort(key=lambda m: (-int(m["is_in_seed_genie"]), -int(m["is_embedded_cluster"]), -m["intra_w"]))

    out_path = Path(args.output) if args.output else SKILLS / f"_{args.domain}_embedded_members.md"
    display = seed.get("display_name", args.domain)

    lines = []
    lines.append(f"# {display} — Embedded Domain Members")
    lines.append("")
    lines.append(f"_Generated by `tools/skills/find_embedded_domain_members.py --domain {args.domain}`_")
    lines.append("")
    lines.append("Nodes whose names match this domain's `embedded_scan_patterns` but were")
    lines.append("placed by Louvain in clusters OTHER than the domain's primary clusters.")
    lines.append("Each row is a candidate to pull into the domain's scope despite the")
    lines.append("partition. The `top_neighbors` column shows why Louvain placed it where")
    lines.append("it did (the heaviest joins from this node).")
    lines.append("")

    lines.append("## Summary")
    lines.append(f"- Patterns scanned: {len(patterns)}")
    lines.append(f"- Candidate embedded members: **{len(matches)}**")
    lines.append(f"  - In a seed Genie's tables: {sum(1 for m in matches if m['is_in_seed_genie'])} _(strongest signal)_")
    lines.append(f"  - In a listed embedded_cluster: {sum(1 for m in matches if m['is_embedded_cluster'])}")
    lines.append("")
    lines.append(f"- Patterns: {', '.join(repr(p) for p in patterns_raw)}")
    lines.append(f"- Primary clusters (excluded from scan): {sorted(primary_clusters) or 'none'}")
    lines.append(f"- Embedded clusters (flagged): {sorted(embedded_clusters) or 'none (all non-primary clusters in scope)'}")
    lines.append("")

    lines.append("## Candidates")
    lines.append("")
    lines.append("| Node | Cluster | Cluster top | Matched | In seed Genie | Intra weight | Top neighbors |")
    lines.append("|---|---|---|---|---|---|---|")
    for m in matches[:100]:
        in_genie = "**yes** (" + ", ".join(m["genie_hits"]) + ")" if m["is_in_seed_genie"] else "no"
        pat_str = ", ".join(f"`{p}`" for p in m["matched_patterns"])
        nb_str = "<br>".join(f"`{n}` ({w:.1f})" for n, w in m["top_neighbors"])
        cluster_tag = f"{m['cluster_id']}"
        if m["is_embedded_cluster"]:
            cluster_tag += " **(flagged)**"
        lines.append(f"| `{m['node']}` | {cluster_tag} | `{m['cluster_top']}` | {pat_str} | {in_genie} | {m['intra_w']:.1f} | {nb_str} |")
    lines.append("")

    if len(matches) > 100:
        lines.append(f"_(showing top 100 of {len(matches)} matches; rerun with custom output for full list)_")
        lines.append("")

    out_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {out_path.relative_to(ROOT)}")
    print(f"  {display}: {len(matches)} embedded-member candidates")
    return 0


if __name__ == "__main__":
    sys.exit(main())
