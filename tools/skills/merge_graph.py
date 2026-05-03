"""
Merge all edge sources (wiki, Genie, KPI views, Tableau) into one canonical
weighted graph.

Key design choices:
1. CANONICAL NAMES — UC bronze/gold names are mapped back to their Synapse
   wiki canonical names so that wiki + UC edges fuse into one graph.
2. NOISE FILTERING — drop tokens like "ETL", "Generic", "SP", "Computed",
   "Unknown", "Fivetran", "Tribe" that come from misparsed wiki cells.
3. WEIGHTS — wiki and UC sources get equal weight. Tableau is half. Multiple
   edges of the same source between the same nodes count once each.

Outputs:
  knowledge/skills/_join_graph.json      — node list + edge list (canonical)
  knowledge/skills/_node_alias_map.json  — every alias seen and its canonical
  knowledge/skills/_node_summary.csv     — node, total_degree, breakdown by source
"""
from __future__ import annotations

import csv
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SKILLS = ROOT / "knowledge" / "skills"
WIKI_ROOT = ROOT / "knowledge" / "synapse" / "Wiki"

# Per-source CSVs (some may not exist yet)
SOURCES = [
    ("wiki", SKILLS / "_edges_wiki.csv", 1.0),
    ("genie", SKILLS / "_edges_genie.csv", 1.0),
    ("kpi", SKILLS / "_edges_kpi.csv", 1.0),
    ("kpi_prep", SKILLS / "_edges_kpi_prep.csv", 1.0),
    ("tableau", SKILLS / "_edges_tableau.csv", 0.5),
]

# Tokens to drop (these came from misparsing free-form wiki cells)
NOISE_NODES = {
    "ETL", "Generic", "Fivetran", "SP", "Computed", "Unknown",
    "Tribe", "etl", "sp", "computed", "unknown",
    "N", "A", "Daily", "Hourly", "TODO", "True", "False",
    "Same", "Direct", "ABS", "CAST", "GETDATE", "SUM", "COUNT",
    "Source", "Target", "Required", "Optional",
}

# UC layer prefix and known synapse schema prefixes
GOLD_PREFIX = re.compile(r"^[a-z_]+\.gold_sql_dp_prod_we_(?P<rest>.+?)(?:_masked)?$", re.IGNORECASE)
BRONZE_PREFIX = re.compile(r"^[a-z_]+\.bronze_etoro_(?P<rest>.+?)(?:_masked)?$", re.IGNORECASE)
# Known Synapse schemas (longest first for greedy match)
SYNAPSE_SCHEMAS_LC: list[tuple[str, str]] = [
    ("emoney_tribe", "eMoney_Tribe"),
    ("emoney_dbo", "eMoney_dbo"),
    ("dealing_dbo", "Dealing_dbo"),
    ("exw_wallet", "EXW_Wallet"),
    ("bi_db_dbo", "BI_DB_dbo"),
    ("dwh_dbo", "DWH_dbo"),
    ("exw_dbo", "EXW_dbo"),
]
# Known production schemas (etoro production DB)
PROD_SCHEMAS_LC: list[tuple[str, str]] = [
    ("backoffice", "BackOffice"),
    ("dictionary", "Dictionary"),
    ("compliance", "Compliance"),
    ("billing", "Billing"),
    ("customer", "Customer"),
    ("history", "History"),
    ("trade", "Trade"),
    ("compensations", "Compensations"),
]


def build_wiki_canonical_index() -> dict[str, str]:
    """Build a map from lowercase canonical key -> 'Schema.Object' as written in wiki filenames."""
    index: dict[str, str] = {}
    for p in WIKI_ROOT.rglob("*.md"):
        if p.name.startswith("_") or ".review-needed" in p.name or ".lineage" in p.name:
            continue
        if p.parent.name not in {"Tables", "Views", "Functions", "External Tables"}:
            continue
        # Look up the H1 first, fall back to filename stem
        try:
            text = p.read_text(encoding="utf-8", errors="replace")
        except Exception:
            text = ""
        m = re.search(r"^#\s+(.+)$", text, re.MULTILINE)
        canonical = None
        if m:
            head = m.group(1).strip().split("(")[0].strip()
            head = head.split(" ")[0].strip().strip("`").strip("[]")
            if "." in head:
                canonical = head
        if not canonical:
            # filename like Foo.Bar.md? generally is just Bar.md, with parent dir = type
            stem = p.stem
            schema = p.parent.parent.name  # e.g. DWH_dbo
            canonical = f"{schema}.{stem}"
        # add several lookup keys
        index[canonical.lower()] = canonical
        # bare-name lookup (last segment only)
        bare = canonical.split(".")[-1].lower()
        # only register bare-name if unique-ish; later collisions get warned
        if bare not in index:
            index[bare] = canonical
        else:
            # ambiguous bare name; mark unresolvable by using sentinel
            index[bare] = "__AMBIGUOUS__"
    return index


def build_uc_canonical_index() -> dict[str, str]:
    """Build a map from 'schema_lc.object_lc' -> 'Schema.Object' for UC objects we know about
    (KPI views are themselves UC objects so they should normalize)."""
    index: dict[str, str] = {}
    kpi_idx_path = SKILLS / "_kpi_views_index.json"
    if kpi_idx_path.exists():
        for v in json.loads(kpi_idx_path.read_text(encoding="utf-8")):
            self_ref = v["self_ref"]
            index[self_ref.lower()] = self_ref
    return index


def normalize_node(raw: str, wiki_idx: dict[str, str], uc_idx: dict[str, str]) -> str | None:
    """Resolve an edge endpoint to a canonical 'Schema.Object' or return None (drop)."""
    if not raw:
        return None
    s = raw.strip().strip("`").strip("[]").rstrip(":,;.")
    if not s:
        return None
    if s in NOISE_NODES:
        return None

    # If it looks like a gold UC bronze copy of a Synapse table
    m = GOLD_PREFIX.match(s)
    if m:
        rest = m.group("rest").lower()
        for prefix_lc, canonical_schema in SYNAPSE_SCHEMAS_LC:
            if rest.startswith(prefix_lc + "_"):
                obj_lc = rest[len(prefix_lc) + 1 :]
                key = f"{canonical_schema.lower()}.{obj_lc}"
                if key in wiki_idx:
                    return wiki_idx[key]
                # Try without trailing _masked / leading bi_db_ prefix duplications
                # Last-resort: synthesize
                return f"{canonical_schema}.{title_object(obj_lc)}"
        # Schema not recognized — keep original
        return s

    # Production bronze copy: <uc_schema>.bronze_etoro_<prod_schema>_<obj>(_masked)?
    m = BRONZE_PREFIX.match(s)
    if m:
        rest = m.group("rest").lower()
        for prefix_lc, canonical_schema in PROD_SCHEMAS_LC:
            if rest.startswith(prefix_lc + "_"):
                obj_lc = rest[len(prefix_lc) + 1 :]
                key = f"{canonical_schema.lower()}.{obj_lc.replace('_', '')}"
                if key in wiki_idx:
                    return wiki_idx[key]
                # Production tables often have no underscores in object names; merge
                # unless the obj_lc actually has multiple recognizable segments
                merged = obj_lc.replace("_", "")
                return f"{canonical_schema}.{title_object_compact(merged)}"
        return s

    # KPI / etoro_kpi views — keep as-is, but normalize casing via uc_idx if known
    if s.lower() in uc_idx:
        return uc_idx[s.lower()]

    # Wiki-style: 'Schema.Object'
    if "." in s:
        seg = s.split(".")
        if len(seg) >= 2:
            schema = seg[-2].strip("`").strip("[]")
            obj = seg[-1].strip("`").strip("[]")

            # Short UC name that mirrors Synapse: dwh.dim_position, bi_db.foo
            short_uc_map = {
                "dwh": "DWH_dbo",
                "bi_db": "BI_DB_dbo",
                "exw": "EXW_dbo",
                "emoney": "eMoney_dbo",
                "dealing": "Dealing_dbo",
            }
            if schema.islower() and schema in short_uc_map:
                cand_schema = short_uc_map[schema]
                key = f"{cand_schema.lower()}.{obj.lower()}"
                if key in wiki_idx:
                    return wiki_idx[key]

            cand = f"{schema}.{obj}"
            if cand.lower() in wiki_idx:
                return wiki_idx[cand.lower()]
            return cand

    # Bare name — try wiki bare-name lookup
    bare = s.lower()
    if bare in wiki_idx:
        v = wiki_idx[bare]
        if v != "__AMBIGUOUS__":
            return v
    # Drop unresolved bare names — they're noise more often than not
    return None


def title_object(s: str) -> str:
    """Best-effort titlecase for 'dim_customer' -> 'Dim_Customer'."""
    return "_".join(p.capitalize() if p.islower() else p for p in s.split("_"))


def title_object_compact(s: str) -> str:
    """Compact titlecase for 'customerstatic' -> 'CustomerStatic' (no underscore)."""
    if not s:
        return s
    return s[0].upper() + s[1:]


def main() -> int:
    print("Building canonical indexes...", flush=True)
    wiki_idx = build_wiki_canonical_index()
    uc_idx = build_uc_canonical_index()
    print(f"  wiki canonical names: {sum(1 for v in wiki_idx.values() if v != '__AMBIGUOUS__' and '.' in v)}", flush=True)
    print(f"  UC canonical names: {len(uc_idx)}", flush=True)

    # Read all sources
    raw_edges = []
    alias_map: dict[str, set[str]] = defaultdict(set)  # canonical -> set of raw aliases
    for label, path, weight in SOURCES:
        if not path.exists():
            print(f"  SKIP (no file): {path.name}", flush=True)
            continue
        with path.open("r", encoding="utf-8") as f:
            n = 0
            kept = 0
            for r in csv.DictReader(f):
                n += 1
                left_raw = r.get("left", "")
                right_raw = r.get("right", "")
                left = normalize_node(left_raw, wiki_idx, uc_idx)
                right = normalize_node(right_raw, wiki_idx, uc_idx)
                if not left or not right or left == right:
                    continue
                kept += 1
                if left != left_raw:
                    alias_map[left].add(left_raw)
                if right != right_raw:
                    alias_map[right].add(right_raw)
                raw_edges.append({
                    "left": left,
                    "right": right,
                    "edge_kind": r.get("edge_kind", label),
                    "source": label,
                    "weight": weight,
                    "join_keys": r.get("join_keys", ""),
                    "purpose": r.get("purpose", ""),
                })
            print(f"  {label}: read {n}, kept {kept}", flush=True)

    # Aggregate edges (undirected). Key = sorted (a,b).
    agg: dict[tuple[str, str], dict] = {}
    for e in raw_edges:
        a, b = sorted([e["left"], e["right"]])
        key = (a, b)
        if key not in agg:
            agg[key] = {
                "a": a,
                "b": b,
                "weight": 0.0,
                "n_edges": 0,
                "by_source": Counter(),
                "by_kind": Counter(),
                "samples": [],
            }
        slot = agg[key]
        slot["weight"] += e["weight"]
        slot["n_edges"] += 1
        slot["by_source"][e["source"]] += 1
        slot["by_kind"][e["edge_kind"]] += 1
        if len(slot["samples"]) < 2 and e["join_keys"]:
            slot["samples"].append({
                "source": e["source"],
                "edge_kind": e["edge_kind"],
                "join_keys": e["join_keys"][:120],
                "purpose": e["purpose"][:80],
            })

    # Node degree
    deg: Counter = Counter()
    deg_by_source: dict[str, Counter] = defaultdict(Counter)
    for (a, b), v in agg.items():
        deg[a] += v["weight"]
        deg[b] += v["weight"]
        for src, n in v["by_source"].items():
            deg_by_source[src][a] += n
            deg_by_source[src][b] += n

    nodes = sorted(deg.keys())
    edges = []
    for (a, b), v in agg.items():
        edges.append({
            "a": a,
            "b": b,
            "weight": round(v["weight"], 3),
            "n_edges": v["n_edges"],
            "by_source": dict(v["by_source"]),
            "by_kind": dict(v["by_kind"]),
            "samples": v["samples"],
        })

    graph = {
        "nodes": nodes,
        "edges": edges,
        "stats": {
            "n_nodes": len(nodes),
            "n_edges": len(edges),
            "edge_sources": {s: sum(e["by_source"].get(s, 0) for e in edges) for s in {"wiki","genie","kpi","kpi_prep","tableau"}},
        },
    }
    out = SKILLS / "_join_graph.json"
    out.write_text(json.dumps(graph, indent=2), encoding="utf-8")
    print(f"Wrote {out.relative_to(ROOT)}: {len(nodes)} nodes, {len(edges)} edges", flush=True)

    # alias map
    alias_out = SKILLS / "_node_alias_map.json"
    alias_out.write_text(
        json.dumps({k: sorted(v) for k, v in alias_map.items()}, indent=2), encoding="utf-8"
    )
    print(f"Wrote {alias_out.relative_to(ROOT)} ({len(alias_map)} canonicals had aliases)", flush=True)

    # Per-node summary
    summary_path = SKILLS / "_node_summary.csv"
    with summary_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["node", "total_weight"] + ["src_" + s for s in ["wiki","genie","kpi","kpi_prep","tableau"]])
        for n in sorted(nodes, key=lambda n: -deg[n]):
            row = [n, f"{deg[n]:.2f}"]
            for s in ["wiki","genie","kpi","kpi_prep","tableau"]:
                row.append(deg_by_source[s][n])
            w.writerow(row)
    print(f"Wrote {summary_path.relative_to(ROOT)}", flush=True)

    print()
    print("Top 25 nodes by total weight:")
    for n, w in deg.most_common(25):
        bd = " ".join(f"{s}={deg_by_source[s][n]}" for s in ["wiki","genie","kpi","kpi_prep","tableau"] if deg_by_source[s][n])
        print(f"  {w:7.1f}  {n:65}  [{bd}]")
    return 0


if __name__ == "__main__":
    sys.exit(main())
