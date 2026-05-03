"""
Run community detection on the merged graph and write a candidate domain map.

- Loads knowledge/skills/_join_graph.json
- Filters to nodes with weight >= MIN_WEIGHT (drops singletons / hapaxes)
- Runs Louvain (python-louvain) for partition; reports modularity
- For each cluster, annotates with:
    * member count, top 10 by degree
    * dominant edge sources (wiki vs UC vs tableau)
    * Genie spaces overlapping the cluster
    * KPI views overlapping the cluster
    * coarse "BU guess" by schema dominance
- Writes knowledge/skills/_domain_candidates.md
"""
from __future__ import annotations

import csv
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

import networkx as nx
try:
    import community as community_louvain  # python-louvain
except ImportError:
    print("Install: pip install python-louvain", file=sys.stderr)
    sys.exit(1)

ROOT = Path(__file__).resolve().parents[2]
SKILLS = ROOT / "knowledge" / "skills"
GRAPH_PATH = SKILLS / "_join_graph.json"
GENIE_INDEX = SKILLS / "_genie_spaces_index.json"
KPI_INDEX = SKILLS / "_kpi_views_index.json"
OUT_MD = SKILLS / "_domain_candidates.md"
OUT_JSON = SKILLS / "_domain_candidates.json"

MIN_NODE_WEIGHT = 1.5  # drop hapax (single weak edge) noise
RESOLUTION = 1.1  # louvain resolution; >1 = more communities


def schema_of(node: str) -> str:
    if "." in node:
        return node.split(".")[0]
    return "(bare)"


def normalize_to_canonical(name: str, canonical_set: set[str]) -> str:
    """Best-effort: if name lower matches a canonical form, return canonical."""
    if name in canonical_set:
        return name
    low = name.lower()
    for c in canonical_set:
        if c.lower() == low:
            return c
    return name


def load_uc_node_to_canonical_map() -> dict[str, str]:
    """Map UC bronze/gold names to canonical Synapse forms — reuse merge_graph normalizer."""
    alias_path = SKILLS / "_node_alias_map.json"
    out: dict[str, str] = {}
    if alias_path.exists():
        aliases = json.loads(alias_path.read_text(encoding="utf-8"))
        for canonical, alist in aliases.items():
            for a in alist:
                out[a] = canonical
                out[a.lower()] = canonical

    # Also apply the live merge_graph normalizer for tables not in the alias map
    sys.path.insert(0, str(Path(__file__).parent))
    try:
        from merge_graph import (  # type: ignore
            build_uc_canonical_index,
            build_wiki_canonical_index,
            normalize_node,
        )
        wiki_idx = build_wiki_canonical_index()
        uc_idx = build_uc_canonical_index()

        def normalize(name: str) -> str:
            v = normalize_node(name, wiki_idx, uc_idx)
            return v or name

        out["__live_normalize__"] = normalize  # type: ignore[assignment]
    except Exception as exc:
        print(f"  WARN: live normalizer not available: {exc}", flush=True)
    return out


def main() -> int:
    print(f"Loading {GRAPH_PATH.relative_to(ROOT)}", flush=True)
    g = json.loads(GRAPH_PATH.read_text(encoding="utf-8"))
    nodes = g["nodes"]
    edges = g["edges"]
    print(f"  {len(nodes)} nodes, {len(edges)} edges", flush=True)

    # Build NX graph
    G = nx.Graph()
    for n in nodes:
        G.add_node(n)
    for e in edges:
        G.add_edge(e["a"], e["b"], weight=e["weight"], by_source=e["by_source"], n_edges=e["n_edges"])

    # Drop nodes with total weight < MIN_NODE_WEIGHT
    weights = {n: sum(d["weight"] for _, _, d in G.edges(n, data=True)) for n in G.nodes}
    weak = [n for n, w in weights.items() if w < MIN_NODE_WEIGHT]
    print(f"Dropping {len(weak)} nodes with weight < {MIN_NODE_WEIGHT}", flush=True)
    G.remove_nodes_from(weak)

    # Drop isolates
    iso = [n for n in G.nodes if G.degree(n) == 0]
    G.remove_nodes_from(iso)
    print(f"After pruning: {G.number_of_nodes()} nodes, {G.number_of_edges()} edges", flush=True)

    # Largest connected component (Louvain operates on a single graph; we'll partition each component)
    components = list(nx.connected_components(G))
    components.sort(key=len, reverse=True)
    print(f"Connected components (top 5): {[len(c) for c in components[:5]]}", flush=True)

    # Run louvain on the full graph
    partition = community_louvain.best_partition(G, weight="weight", resolution=RESOLUTION, random_state=42)
    n_clusters = len(set(partition.values()))
    modularity = community_louvain.modularity(partition, G, weight="weight")
    print(f"Louvain: {n_clusters} clusters, modularity={modularity:.3f}", flush=True)

    # Annotate clusters
    clusters: dict[int, list[str]] = defaultdict(list)
    for n, c in partition.items():
        clusters[c].append(n)

    # Genie space overlap
    canon_alias = load_uc_node_to_canonical_map()
    genie_spaces = []
    if GENIE_INDEX.exists():
        genie_spaces = json.loads(GENIE_INDEX.read_text(encoding="utf-8"))
    live_normalize = canon_alias.get("__live_normalize__")
    # normalize each genie space's tables to canonical
    for sp in genie_spaces:
        sp["canonical_tables"] = []
        for t in sp.get("tables", []):
            mapped = canon_alias.get(t) or canon_alias.get(t.lower()) or t
            if mapped == t and callable(live_normalize):
                mapped = live_normalize(t)
            sp["canonical_tables"].append(mapped)

    kpi_views = []
    if KPI_INDEX.exists():
        kpi_views = json.loads(KPI_INDEX.read_text(encoding="utf-8"))

    # For each cluster, annotate
    annotated: list[dict] = []
    for cid, members in sorted(clusters.items(), key=lambda kv: -len(kv[1])):
        # Internal weight + per-source contribution
        internal_w = 0.0
        src_count: Counter = Counter()
        for u, v, d in G.edges(data=True):
            if u in clusters[cid] and v in clusters[cid]:
                internal_w += d["weight"]
                for s, n in d["by_source"].items():
                    src_count[s] += n
        # Top-degree members
        member_set = set(members)
        member_deg = {n: weights[n] for n in members}
        top_members = sorted(member_deg.items(), key=lambda kv: -kv[1])[:15]
        # Schema breakdown
        schema_count = Counter(schema_of(n) for n in members)
        # Genie spaces overlapping this cluster
        space_hits = []
        for sp in genie_spaces:
            overlap = sum(1 for t in sp.get("canonical_tables", []) if t in member_set)
            if overlap >= 2:  # at least 2 tables of the space inside the cluster
                space_hits.append({"title": sp["title"], "overlap": overlap, "n_tables": sp.get("n_tables", 0)})
        space_hits.sort(key=lambda x: -x["overlap"])
        # KPI views inside this cluster
        kpi_hits = [v["self_ref"] for v in kpi_views if v["self_ref"] in member_set]
        annotated.append({
            "cluster_id": cid,
            "size": len(members),
            "internal_weight": round(internal_w, 1),
            "src_breakdown": dict(src_count),
            "schema_breakdown": dict(schema_count),
            "top_members": [{"node": n, "weight": round(w, 1)} for n, w in top_members],
            "all_members": sorted(members),
            "genie_overlap": space_hits[:8],
            "kpi_views_in_cluster": kpi_hits[:15],
        })

    OUT_JSON.write_text(json.dumps(annotated, indent=2), encoding="utf-8")
    print(f"Wrote {OUT_JSON.relative_to(ROOT)}", flush=True)

    # Render markdown
    lines = []
    lines.append("# Domain Candidate Map (Checkpoint A)")
    lines.append("")
    lines.append(f"_Generated by Louvain community detection on the merged graph_")
    lines.append(f"_Total nodes (post-prune): {G.number_of_nodes()}, edges: {G.number_of_edges()}, clusters: {n_clusters}, modularity: {modularity:.3f}_")
    lines.append(f"_Min node weight to keep: {MIN_NODE_WEIGHT}, Louvain resolution: {RESOLUTION}_")
    lines.append("")
    lines.append("## Cluster summary")
    lines.append("")
    lines.append("| # | Size | Top hub | Schema mix | Genie spaces | KPI views |")
    lines.append("|---|------|---------|------------|--------------|-----------|")
    for i, c in enumerate(annotated):
        top = c["top_members"][0]["node"] if c["top_members"] else ""
        schemas = ", ".join(f"{s}={n}" for s, n in sorted(c["schema_breakdown"].items(), key=lambda x: -x[1])[:3])
        gn = ", ".join(f"{g['title']}({g['overlap']})" for g in c["genie_overlap"][:3])
        kn = len(c["kpi_views_in_cluster"])
        lines.append(f"| {i} | {c['size']} | `{top}` | {schemas} | {gn} | {kn} |")
    lines.append("")

    for i, c in enumerate(annotated):
        lines.append(f"## Cluster {i} — {c['size']} members, weight {c['internal_weight']}")
        lines.append("")
        if c["top_members"]:
            lines.append(f"**Top hub:** `{c['top_members'][0]['node']}` (weight {c['top_members'][0]['weight']})")
        lines.append("")
        lines.append("**Top members:**")
        for m in c["top_members"]:
            lines.append(f"- `{m['node']}` — weight {m['weight']}")
        lines.append("")
        lines.append(f"**Schema mix:** {dict(sorted(c['schema_breakdown'].items(), key=lambda x: -x[1]))}")
        lines.append("")
        lines.append(f"**Edge source breakdown:** {c['src_breakdown']}")
        lines.append("")
        if c["genie_overlap"]:
            lines.append("**Genie spaces with >=2 tables in this cluster:**")
            for g in c["genie_overlap"]:
                lines.append(f"- `{g['title']}` — {g['overlap']}/{g['n_tables']} tables overlap")
            lines.append("")
        if c["kpi_views_in_cluster"]:
            lines.append("**KPI views in this cluster:**")
            for v in c["kpi_views_in_cluster"]:
                lines.append(f"- `{v}`")
            lines.append("")
        if c["size"] <= 60:
            lines.append("<details><summary>All members</summary>")
            lines.append("")
            for m in c["all_members"]:
                lines.append(f"- `{m}`")
            lines.append("")
            lines.append("</details>")
        lines.append("")

    OUT_MD.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT_MD.relative_to(ROOT)}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
