"""
Given a cluster id, emit a concise brief used to draft that sub-domain's SKILL.md.

Brief contains:
  1. Top members of the cluster, ranked by intra-cluster weight
  2. Canonical JOINs from each member's wiki §3.3 (raw markdown rows)
  3. KPI views in or referencing the cluster, with their DDL excerpts
  4. Genie spaces overlapping the cluster, with description + tables list
  5. Sample lineage edges (§5.1) that go OUT of the cluster - useful to
     identify cross-domain skill needs

Usage:
  python tools/skills/extract_subdomain_brief.py --cluster 7
Output:
  knowledge/skills/_brief_cluster_<id>.md
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SKILLS = ROOT / "knowledge" / "skills"
WIKI_ROOT = ROOT / "knowledge" / "synapse" / "Wiki"


def find_wiki_path(canonical: str) -> Path | None:
    if "." not in canonical:
        return None
    schema, obj = canonical.split(".", 1)
    for sub in ("Tables", "Views", "Functions", "External Tables"):
        p = WIKI_ROOT / schema / sub / f"{obj}.md"
        if p.exists():
            return p
    return None


def section_text(content: str, header_re: re.Pattern) -> str:
    m = header_re.search(content)
    if not m:
        return ""
    nxt = re.search(r"^#{1,4}\s", content[m.end():], re.MULTILINE)
    end = m.end() + (nxt.start() if nxt else len(content) - m.end())
    return content[m.end():end]


def parse_md_table(text: str) -> list[dict]:
    lines = text.splitlines()
    table_lines = []
    in_table = False
    for line in lines:
        s = line.strip()
        if s.startswith("|") and s.endswith("|"):
            table_lines.append(s)
            in_table = True
        elif in_table:
            break
    if len(table_lines) < 2:
        return []
    headers = [h.strip() for h in table_lines[0].strip("|").split("|")]
    rows = []
    for line in table_lines[2:]:
        cells = [c.strip() for c in line.strip("|").split("|")]
        if len(cells) != len(headers):
            continue
        rows.append(dict(zip(headers, cells)))
    return rows


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--cluster", type=int, required=True)
    args = ap.parse_args()

    candidates = json.loads((SKILLS / "_domain_candidates.json").read_text(encoding="utf-8"))
    target = next((c for c in candidates if c["cluster_id"] == args.cluster), None)
    if not target:
        print(f"Cluster {args.cluster} not found", file=sys.stderr)
        return 2

    members = sorted(set(target["all_members"]))
    member_set = set(members)
    graph = json.loads((SKILLS / "_join_graph.json").read_text(encoding="utf-8"))

    intra_w: dict[str, float] = defaultdict(float)
    inter_edges_by_member: dict[str, list[dict]] = defaultdict(list)
    for e in graph["edges"]:
        a, b = e["a"], e["b"]
        if a in member_set and b in member_set:
            intra_w[a] += e["weight"]
            intra_w[b] += e["weight"]
        elif a in member_set:
            inter_edges_by_member[a].append({"other": b, "weight": e["weight"], "by_source": e["by_source"]})
        elif b in member_set:
            inter_edges_by_member[b].append({"other": a, "weight": e["weight"], "by_source": e["by_source"]})

    ranked = sorted(members, key=lambda n: -intra_w[n])

    joins_section = re.compile(r"^#{2,4}\s*3\.3\s+Common\s+JOINs\b", re.IGNORECASE | re.MULTILINE)

    member_joins: dict[str, list[dict]] = {}
    for m in ranked[:30]:
        wp = find_wiki_path(m)
        if not wp:
            continue
        try:
            content = wp.read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue
        sec = section_text(content, joins_section)
        if not sec:
            continue
        rows = parse_md_table(sec)
        if rows:
            member_joins[m] = rows

    kpi_views_in = []
    kpi_idx = json.loads((SKILLS / "_kpi_views_index.json").read_text(encoding="utf-8"))
    for v in kpi_idx:
        if v["self_ref"] in member_set:
            kpi_views_in.append(v)

    genie_idx = json.loads((SKILLS / "_genie_spaces_index.json").read_text(encoding="utf-8"))
    space_hits = []
    for sp in genie_idx:
        ct = sp.get("canonical_tables", []) or sp.get("tables", [])
        overlap = [t for t in ct if t in member_set]
        if len(overlap) >= 2:
            space_hits.append({
                "title": sp["title"],
                "description": sp.get("description", ""),
                "n_tables": sp.get("n_tables", 0),
                "overlap": overlap,
                "join_specs": sp.get("n_join_specs", 0),
            })
    space_hits.sort(key=lambda x: -len(x["overlap"]))

    out_neighbors: Counter = Counter()
    for m, edges in inter_edges_by_member.items():
        for e in edges:
            out_neighbors[e["other"]] += e["weight"]

    lines = []
    lines.append(f"# Cluster {args.cluster} brief — `{ranked[0] if ranked else '(empty)'}`")
    lines.append("")
    lines.append(f"_Size: {len(members)}, intra-cluster weight: {target['internal_weight']}_")
    lines.append(f"_Schema mix: {target['schema_breakdown']}_")
    lines.append(f"_Edge sources: {target['src_breakdown']}_")
    lines.append("")

    lines.append("## Top members (ranked by intra-cluster weight)")
    lines.append("")
    for n in ranked[:25]:
        wp = find_wiki_path(n)
        link = f"[wiki]({wp.relative_to(ROOT).as_posix()})" if wp else "(no wiki)"
        lines.append(f"- `{n}` — w {intra_w[n]:.1f} {link}")
    lines.append("")

    lines.append("## Wiki §3.3 Common JOINs (top members)")
    lines.append("")
    for m in ranked[:15]:
        if m not in member_joins:
            continue
        lines.append(f"### `{m}`")
        lines.append("")
        lines.append("| Join To | Join Condition | Purpose |")
        lines.append("|---|---|---|")
        for r in member_joins[m]:
            join_to = r.get("Join To") or r.get("To") or r.get("Object") or ""
            cond = (r.get("Join Condition") or r.get("Condition") or "").replace("|", "\\|")
            purpose = (r.get("Purpose") or "").replace("|", "\\|")[:80]
            lines.append(f"| {join_to} | {cond} | {purpose} |")
        lines.append("")

    lines.append("## KPI views in this cluster")
    lines.append("")
    for v in kpi_views_in[:15]:
        lines.append(f"### `{v['self_ref']}`  ({v['ddl_chars']} chars)")
        lines.append("")
        lines.append("Refs:")
        for r in v["refs"][:8]:
            lines.append(f"- `{r}`")
        lines.append("")

    lines.append("## Genie spaces overlapping this cluster")
    lines.append("")
    for sp in space_hits[:10]:
        lines.append(f"### `{sp['title']}`  ({len(sp['overlap'])}/{sp['n_tables']} tables, {sp['join_specs']} join_specs)")
        if sp.get("description"):
            lines.append(f"> {sp['description'][:300]}")
        lines.append("")
        lines.append("Tables in cluster:")
        for t in sp["overlap"]:
            lines.append(f"- `{t}`")
        lines.append("")

    lines.append("## Out-cluster neighbors (likely cross-domain candidates)")
    lines.append("")
    for n, w in out_neighbors.most_common(20):
        lines.append(f"- `{n}` — outflow weight {w:.1f}")
    lines.append("")

    out_path = SKILLS / f"_brief_cluster_{args.cluster}.md"
    out_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {out_path.relative_to(ROOT)}  ({len(members)} members)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
