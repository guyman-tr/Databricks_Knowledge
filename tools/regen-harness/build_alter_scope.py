"""
build_alter_scope.py

Read-only computation of the ALTER scope set:

    SCOPE = mapped (objects with a non-null uc_table in the pipeline mapping)
            ∪ upstream(mapped) via FORWARD-BFS on _dependency_order.json

An object is in scope iff (a) it is itself mapped to a Unity Catalog table,
OR (b) some downstream object that depends on it is mapped. In either case
the wiki contributes to documenting data that ends up in the lake.

Pure SINK consumers (regulatory reports, marketing dashboards, AML monitors,
etc.) that read from mapped Facts/Dims but produce no further mapped output
are explicitly EXCLUDED — wiki'ing them costs tokens but doesn't trace any
column into the lake.

Direction note (read carefully):
  forward[A] = A.depends_on  (things A reads from = A's upstream producers)
  reverse[A] = A.dependents  (things that read from A = A's downstream consumers)
We walk FORWARD from mapped sinks to collect their upstream lineage.

Inputs (all read-only):
  knowledge/synapse/Wiki/_dependency_order.json
  knowledge/synapse/Wiki/_generic_pipeline_mapping.json
  audits/wiki_health_scan_*.csv  (latest by mtime)
  knowledge/synapse/Wiki/{Schema}/{Tables|Views|Functions}/{Object}.md
                                      (presence check only)

Outputs:
  audits/regen-sample/_alter_scope.json          (full record per in-scope object)
  audits/regen-sample/_alter_scope.csv           (flat tabular form, easy to grep/sort)
  audits/regen-sample/_alter_scope.summary.md    (per-schema breakdown, same shape as
                                                  planning step output)

Usage:
  python build_alter_scope.py
  python build_alter_scope.py --hops 1
  python build_alter_scope.py --threshold-t4 5
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import sys
from collections import Counter, defaultdict
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
WIKI_ROOT = REPO_ROOT / "knowledge" / "synapse" / "Wiki"
AUDITS = REPO_ROOT / "audits"
TARGET_ROOT = AUDITS / "regen-sample"

DEP_ORDER = WIKI_ROOT / "_dependency_order.json"
MAPPING = WIKI_ROOT / "_generic_pipeline_mapping.json"

# Synapse schemas that can host an External_* table. Order matters only for
# disambiguation when multiple schemas have the same External_ name; first hit wins.
EXTERNAL_HOST_SCHEMAS = (
    "BI_DB_dbo",
    "DWH_dbo",
    "Dealing_dbo",
    "eMoney_dbo",
    "EXW_dbo",
    "Schemas",
    "DE_dbo",
    "CryptoDB_dbo",
)

# Wiki sidecar filename suffixes that should NOT count as a primary wiki .md.
SIDECAR_SUFFIXES = (".lineage.md", ".review-needed.md", ".propagation-scope.md")


# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------


@dataclass
class ScopeRow:
    object: str                # full lower-cased "schema.name"
    schema: str                # schema part, original case from dep graph
    name: str                  # object name, original case
    kind: str                  # "seed_external" | "seed_dwh_internal" | "lineage_upstream"
    hops_from_seed: int        # 0 for mapped seeds, 1+ for upstreams of mapped seeds
    mapped_uc: Optional[str]   # uc_table from mapping (set for ANY mapped node, regardless of hop)
    currently_documented: bool
    wiki_path: Optional[str]   # repo-relative if documented, else None
    slop_t4_hits: int          # T4InfHits from latest health scan, 0 if no row


@dataclass
class MappedNoMirror:
    """Mapping row that has uc_table but no Synapse External_ counterpart in the dep graph.

    These get UC ALTERs through the direct-bronze pathway and don't need a
    Synapse wiki. Tracked for visibility only.
    """
    database_name: str
    schema_name: str
    table_name: str
    uc_table: str


# ---------------------------------------------------------------------------
# Loaders
# ---------------------------------------------------------------------------


def load_dep_graph() -> Tuple[Dict[str, Set[str]], Dict[str, Set[str]], Dict[str, str]]:
    """Return (forward, reverse, original_case_lookup).

    forward[node_lower] = set of dependency node_lower
    reverse[node_lower] = set of dependent node_lower
    original_case_lookup[node_lower] = original-case "Schema.Name"
    """
    if not DEP_ORDER.exists():
        sys.exit(f"ERROR: {DEP_ORDER} not found")
    data = json.loads(DEP_ORDER.read_text(encoding="utf-8"))
    forward: Dict[str, Set[str]] = {}
    reverse: Dict[str, Set[str]] = defaultdict(set)
    original: Dict[str, str] = {}
    for entry in data:
        tbl = entry["table"]
        tbl_lc = tbl.lower()
        original.setdefault(tbl_lc, tbl)
        deps = entry.get("depends_on") or []
        forward[tbl_lc] = {d.lower() for d in deps}
        for d in deps:
            d_lc = d.lower()
            reverse[d_lc].add(tbl_lc)
            original.setdefault(d_lc, d)
    return forward, dict(reverse), original


def load_mapping() -> List[Dict]:
    if not MAPPING.exists():
        sys.exit(f"ERROR: {MAPPING} not found")
    return json.loads(MAPPING.read_text(encoding="utf-8")).get("mappings", [])


def find_latest_health_scan() -> Optional[Path]:
    candidates = sorted(AUDITS.glob("wiki_health_scan_*.csv"), key=lambda p: p.stat().st_mtime)
    return candidates[-1] if candidates else None


def load_slop_map(scan_path: Optional[Path]) -> Dict[str, int]:
    """Map lower-cased "schema.object" -> T4InfHits."""
    if not scan_path or not scan_path.exists():
        return {}
    out: Dict[str, int] = {}
    with scan_path.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                t4 = int(row.get("T4InfHits") or 0)
            except ValueError:
                t4 = 0
            n = path_to_synapse_name(row.get("Path") or "")
            if n:
                out[n] = t4
    return out


def path_to_synapse_name(p: str) -> Optional[str]:
    """Extract lower-cased "schema.object" from a wiki .md path."""
    parts = p.replace("\\", "/").split("/")
    if "Wiki" not in parts:
        return None
    i = parts.index("Wiki")
    if i + 3 >= len(parts):
        return None
    if parts[i + 2] not in ("Tables", "Views", "Functions"):
        return None
    obj = parts[i + 3]
    if obj.endswith(".md"):
        obj = obj[:-3]
    return f"{parts[i + 1]}.{obj}".lower()


def collect_documented_wikis() -> Dict[str, Path]:
    """Return lower-cased "schema.object" -> repo-relative wiki path."""
    out: Dict[str, Path] = {}
    if not WIKI_ROOT.exists():
        return out
    for sch_dir in WIKI_ROOT.iterdir():
        if not sch_dir.is_dir():
            continue
        for sub in ("Tables", "Views", "Functions"):
            sub_dir = sch_dir / sub
            if not sub_dir.is_dir():
                continue
            for md in sub_dir.glob("*.md"):
                name = md.name
                if any(name.endswith(s) for s in SIDECAR_SUFFIXES):
                    continue
                obj = name[:-3]  # strip .md
                key = f"{sch_dir.name}.{obj}".lower()
                out[key] = md.relative_to(REPO_ROOT)
    return out


# ---------------------------------------------------------------------------
# Seed assembly + BFS
# ---------------------------------------------------------------------------


def build_seeds(
    nodes: Set[str],
    mapping: List[Dict],
) -> Tuple[Dict[str, str], Dict[str, str], List[MappedNoMirror]]:
    """Return (external_seeds, dwh_internal_seeds, mapped_no_mirror).

    external_seeds[node_lower]   = uc_table (best-effort match from mapping name)
    dwh_internal_seeds[node_lower] = uc_table
    mapped_no_mirror             = mapping rows whose External_* counterpart is
                                   not present in the dep graph
    """
    external_seeds: Dict[str, str] = {}
    dwh_internal_seeds: Dict[str, str] = {}
    no_mirror: List[MappedNoMirror] = []

    # Index every External_* node in the graph by its underscore-suffix tail so
    # we can match mapping rows to nodes regardless of host schema.
    # NOTE (2026-04-30): unmapped External_* are NO LONGER auto-seeded. Under
    # forward-BFS from mapped seeds, an unmapped External_* still gets pulled
    # into scope iff some mapped object depends on it. If nothing mapped reads
    # from it, it has no business being a wiki target.
    ext_index: Dict[str, str] = {}  # tail_lower -> full_node_lower
    for n in nodes:
        if ".external_" not in n:
            continue
        try:
            schema_part, name_part = n.split(".", 1)
        except ValueError:
            continue
        if not name_part.startswith("external_"):
            continue
        tail = name_part[len("external_"):]
        ext_index.setdefault(tail, n)

    for r in mapping:
        if not r.get("uc_table"):
            continue
        db = r["database_name"]
        sch = r["schema_name"]
        tbl = r["table_name"]
        uc = r["uc_table"]
        if db == "sql_dp_prod_we":
            cand = f"{sch}.{tbl}".lower()
            if cand in nodes:
                dwh_internal_seeds[cand] = uc
            else:
                # Mapping says this Synapse table has a UC counterpart but it's not in
                # _dependency_order.json — extremely rare; flag as no-mirror for visibility.
                no_mirror.append(MappedNoMirror(db, sch, tbl, uc))
            continue
        # External-source mapping: tail = db_schema_table (lowercased)
        tail = f"{db}_{sch}_{tbl}".lower()
        node = ext_index.get(tail)
        if node:
            external_seeds[node] = uc
        else:
            no_mirror.append(MappedNoMirror(db, sch, tbl, uc))

    return external_seeds, dwh_internal_seeds, no_mirror


def bfs_with_hops(
    seeds: Set[str],
    graph: Dict[str, Set[str]],
    max_hops: int,
) -> Dict[str, int]:
    """Return node_lower -> hops_from_seed (0 for seed, 1+ for transitive).

    Direction is determined by the graph passed in:
      - pass `forward` (depends_on)  => walk UPSTREAM producers
      - pass `reverse` (dependents)  => walk DOWNSTREAM consumers
    Only the SHORTEST path hop count is recorded. BFS terminates naturally
    when the frontier is empty even before max_hops is reached.
    """
    visited: Dict[str, int] = {s: 0 for s in seeds}
    frontier = set(seeds)
    for hop in range(1, max_hops + 1):
        new_frontier: Set[str] = set()
        for n in frontier:
            for x in graph.get(n, ()):
                if x not in visited:
                    visited[x] = hop
                    new_frontier.add(x)
        frontier = new_frontier
        if not frontier:
            break
    return visited


# ---------------------------------------------------------------------------
# Output writers
# ---------------------------------------------------------------------------


def write_outputs(
    rows: List[ScopeRow],
    no_mirror: List[MappedNoMirror],
    args: argparse.Namespace,
    health_scan_path: Optional[Path],
    dep_order_mtime: datetime,
) -> Dict[str, Path]:
    TARGET_ROOT.mkdir(parents=True, exist_ok=True)

    json_path = TARGET_ROOT / "_alter_scope.json"
    csv_path = TARGET_ROOT / "_alter_scope.csv"
    summary_path = TARGET_ROOT / "_alter_scope.summary.md"

    metadata = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "dep_order_mtime_utc": dep_order_mtime.isoformat(),
        "health_scan": str(health_scan_path.relative_to(REPO_ROOT)) if health_scan_path else None,
        "hops": args.hops,
        "slop_threshold_t4": args.threshold_t4,
        "in_scope_count": len(rows),
        "mapped_no_synapse_mirror_count": len(no_mirror),
    }

    json_path.write_text(
        json.dumps(
            {
                "metadata": metadata,
                "in_scope": [asdict(r) for r in rows],
                "mapped_no_synapse_mirror": [asdict(m) for m in no_mirror],
            },
            indent=2,
        ),
        encoding="utf-8",
    )

    with csv_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow([
            "object", "schema", "name", "kind", "hops_from_seed",
            "mapped_uc", "currently_documented", "wiki_path", "slop_t4_hits",
        ])
        for r in rows:
            w.writerow([
                r.object, r.schema, r.name, r.kind, r.hops_from_seed,
                r.mapped_uc or "", "true" if r.currently_documented else "false",
                r.wiki_path or "", r.slop_t4_hits,
            ])

    summary_path.write_text(_render_summary(rows, no_mirror, metadata), encoding="utf-8")

    return {"json": json_path, "csv": csv_path, "summary": summary_path}


def _render_summary(
    rows: List[ScopeRow],
    no_mirror: List[MappedNoMirror],
    metadata: Dict,
) -> str:
    in_scope_doc = sum(1 for r in rows if r.currently_documented)
    in_scope_todo = len(rows) - in_scope_doc
    seeds = sum(1 for r in rows if r.kind != "lineage_upstream")
    upstream = sum(1 for r in rows if r.kind == "lineage_upstream")
    in_scope_slop = sum(1 for r in rows if r.slop_t4_hits >= metadata["slop_threshold_t4"])

    per_sch_doc: Counter = Counter()
    per_sch_todo: Counter = Counter()
    per_sch_slop: Counter = Counter()
    for r in rows:
        if r.currently_documented:
            per_sch_doc[r.schema] += 1
        else:
            per_sch_todo[r.schema] += 1
        if r.slop_t4_hits >= metadata["slop_threshold_t4"]:
            per_sch_slop[r.schema] += 1

    lines: List[str] = []
    lines.append("# ALTER Scope Summary")
    lines.append("")
    lines.append(f"_Generated {metadata['generated_at_utc']}_")
    lines.append("")
    lines.append("## Inputs")
    lines.append("")
    lines.append(f"- Dependency graph mtime: `{metadata['dep_order_mtime_utc']}`")
    lines.append(f"- Health scan: `{metadata['health_scan'] or '(none found)'}`")
    lines.append(f"- BFS hops: `{metadata['hops']}`")
    lines.append(f"- Slop threshold: `T4InfHits >= {metadata['slop_threshold_t4']}`")
    lines.append("")
    lines.append("## Headline")
    lines.append("")
    lines.append(f"- **Total in-scope objects**: {len(rows)}  ({seeds} mapped seeds + {upstream} lineage upstreams)")
    lines.append(f"- **In-scope already documented**: {in_scope_doc}")
    lines.append(f"- **In-scope NOT yet documented**: {in_scope_todo}")
    lines.append(f"- **In-scope slop (T4InfHits >= {metadata['slop_threshold_t4']})**: {in_scope_slop}")
    lines.append(f"- **Mapped rows with no Synapse mirror** (direct-bronze ALTER pathway, not in this scope): {len(no_mirror)}")
    lines.append("")
    lines.append("## Per-schema breakdown")
    lines.append("")
    lines.append("| Schema | In-scope documented | In-scope NOT documented | In-scope slop |")
    lines.append("|---|---:|---:|---:|")
    for sch in sorted(set(list(per_sch_doc) + list(per_sch_todo))):
        d = per_sch_doc[sch]
        t = per_sch_todo[sch]
        s = per_sch_slop[sch]
        if d + t == 0:
            continue
        lines.append(f"| `{sch}` | {d} | {t} | {s} |")
    lines.append("")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--hops", type=int, default=20,
                   help="upstream BFS hop limit (default: 20 — generous; BFS terminates earlier when frontier empties)")
    p.add_argument("--threshold-t4", type=int, default=1,
                   help="minimum T4InfHits for a wiki to count as 'slop' in the summary (default: 1)")
    p.add_argument("--quiet", action="store_true")
    args = p.parse_args()

    forward, reverse, original = load_dep_graph()
    nodes = set(forward.keys())
    for s in reverse:
        nodes.add(s)
    if not args.quiet:
        print(f"Loaded dep graph: {len(nodes)} nodes ({len(forward)} keys, {sum(len(v) for v in reverse.values())} reverse edges)")

    mapping = load_mapping()
    if not args.quiet:
        print(f"Loaded mapping: {len(mapping)} rows")

    health_scan_path = find_latest_health_scan()
    if not args.quiet:
        print(f"Latest health scan: {health_scan_path.name if health_scan_path else '(none)'}")
    slop_map = load_slop_map(health_scan_path)

    documented = collect_documented_wikis()
    if not args.quiet:
        print(f"Documented wikis on disk: {len(documented)}")

    external_seeds, dwh_seeds, no_mirror = build_seeds(nodes, mapping)
    # Only MAPPED objects are seeds (have a non-empty uc_table). Drop unmapped
    # External_* — they only stay in scope if forward-BFS finds them as an
    # upstream of something mapped.
    external_seeds_mapped = {k: v for k, v in external_seeds.items() if v}
    seed_keys = set(external_seeds_mapped) | set(dwh_seeds)
    if not args.quiet:
        dropped_ext = len(external_seeds) - len(external_seeds_mapped)
        print(f"Mapped seeds: {len(external_seeds_mapped)} external + {len(dwh_seeds)} dwh-internal = {len(seed_keys)} total")
        print(f"Dropped {dropped_ext} unmapped External_* (will only be in scope if upstream of a mapped seed)")
        print(f"Mapping rows with no Synapse mirror (direct-bronze pathway): {len(no_mirror)}")

    # FORWARD-BFS: walk depends_on chain to collect upstream lineage of mapped seeds.
    hops_map = bfs_with_hops(seed_keys, forward, args.hops)
    if not args.quiet:
        print(f"Forward BFS @ max_hops={args.hops}: {len(hops_map)} in-scope nodes")

    # Build a lookup of mapped_uc keyed by node so upstreams that ARE themselves
    # mapped (e.g. DWH_dbo.Fact_X feeding BI_DB_dbo.Fact_Y) get tagged correctly.
    mapped_uc_lookup: Dict[str, str] = {}
    for k, v in external_seeds_mapped.items():
        mapped_uc_lookup[k] = v
    for k, v in dwh_seeds.items():
        mapped_uc_lookup[k] = v

    rows: List[ScopeRow] = []
    for node_lower, hop in hops_map.items():
        # Reconstruct schema/name. Original case if available, else split lowercase.
        orig = original.get(node_lower, node_lower)
        if "." in orig:
            schema_orig, name_orig = orig.split(".", 1)
        else:
            schema_orig, name_orig = "", orig
        uc = mapped_uc_lookup.get(node_lower)
        if hop == 0:
            kind = "seed_external" if node_lower in external_seeds_mapped else "seed_dwh_internal"
        elif uc:
            # Upstream of a mapped seed AND itself mapped — tag by its own seed type
            kind = "seed_external" if node_lower in external_seeds_mapped else "seed_dwh_internal"
        else:
            kind = "lineage_upstream"
        wiki = documented.get(node_lower)
        rows.append(ScopeRow(
            object=node_lower,
            schema=schema_orig,
            name=name_orig,
            kind=kind,
            hops_from_seed=hop,
            mapped_uc=uc,
            currently_documented=wiki is not None,
            wiki_path=str(wiki).replace("\\", "/") if wiki else None,
            slop_t4_hits=slop_map.get(node_lower, 0),
        ))

    rows.sort(key=lambda r: (r.hops_from_seed, r.schema.lower(), r.name.lower()))

    dep_mtime = datetime.fromtimestamp(DEP_ORDER.stat().st_mtime, tz=timezone.utc)
    paths = write_outputs(rows, no_mirror, args, health_scan_path, dep_mtime)

    if not args.quiet:
        print()
        print("Wrote:")
        for k, v in paths.items():
            print(f"  {k:8} -> {v.relative_to(REPO_ROOT)}")
        print()
        slop_count = sum(1 for r in rows if r.slop_t4_hits >= args.threshold_t4)
        print(f"In-scope slop (T4InfHits >= {args.threshold_t4}): {slop_count}")
        oos_slop = sum(1 for n, t in slop_map.items() if t >= args.threshold_t4 and n not in hops_map)
        print(f"Out-of-scope slop (T4InfHits >= {args.threshold_t4}): {oos_slop}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
