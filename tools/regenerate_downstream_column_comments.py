#!/usr/bin/env python3
"""
Regenerate the aggregated downstream COMMENT SQL using **name-based** mapping only.

This runs discover_tree() from _deep_propagate_lib for each configured wiki root:
  - load_source_descriptions(alter_path)  -> column -> text from COMMENT literals
  - DESCRIBE downstream + match_columns -> bind by target column **name**, not ordinal
  - escape_sql_comment_value on emit -> same sanitization as .downstream.alter.sql

Merge multiple roots into one file (union of nodes; per (UC FQN, target_column) first wins,
with a warning if two roots disagree on description text).

**No** ordinal zip. **No** hand-UTF-1255 fixes in this script — that lives in _uc_comment_sanitize.

Usage (Databricks auth required for --config discover):

  python tools/regenerate_downstream_column_comments.py \\
    --config knowledge/synapse/Wiki/regenerate_downstream_sources.example.json \\
    -o knowledge/synapse/Wiki/_downstream_column_comments.sql

Merge existing lineage trees only (no DB):

  python tools/regenerate_downstream_column_comments.py \\
    --merge-trees Wiki/DWH_dbo/Tables/Dim_Customer.lineage-tree.json \\
    -o _merged.sql

See: knowledge/synapse/Wiki/README_downstream_column_comments.md
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WIKI_ROOT = ROOT / "knowledge" / "synapse" / "Wiki"
if str(WIKI_ROOT) not in sys.path:
    sys.path.insert(0, str(WIKI_ROOT))

import _deep_propagate_lib as lib  # noqa: E402


def merge_nodes_from_trees(all_nodes: list[list[dict]]) -> list[dict]:
    """
    Merge node dicts by full_name (case-insensitive). Columns keyed by target_column lower.
    First description wins; print warning on conflict.
    """
    by_fn: dict[str, dict] = {}
    for nodes in all_nodes:
        for n in nodes:
            fn = n.get("full_name") or ""
            fn_key = fn.lower()
            cols_in = n.get("columns") or []
            if fn_key not in by_fn:
                by_fn[fn_key] = {
                    "full_name": n["full_name"],
                    "object_type": n.get("object_type", "TABLE"),
                    "columns": list(cols_in),
                }
                continue
            cur = by_fn[fn_key]
            col_by = {c["target_column"].lower(): c for c in cur["columns"]}
            for c in cols_in:
                tk = c["target_column"].lower()
                if tk not in col_by:
                    col_by[tk] = c
                else:
                    d1 = col_by[tk].get("description", "")
                    d2 = c.get("description", "")
                    if d1 != d2:
                        print(
                            f"  WARN merge conflict {n['full_name']}.`{c['target_column']}`: "
                            f"keeping first description ({len(d1)} vs {len(d2)} chars)",
                            file=sys.stderr,
                        )
            cur["columns"] = list(col_by.values())
    return sorted(by_fn.values(), key=lambda x: x.get("full_name", ""))


def run_discover_and_merge(
    config: dict,
    repo_root: Path,
) -> tuple[list[dict], list[dict]]:
    """
    For each source in config['sources'], run discover_tree and merge.
    Returns (merged_nodes, sources_meta for header).
    """
    sources = config.get("sources") or []
    if not sources:
        raise SystemExit("config.sources is empty")

    include_uc = bool(config.get("include_uc_lineage", False))
    blacklist = lib.load_blacklist()
    all_node_lists: list[list[dict]] = []
    meta: list[dict] = []

    tmpdir = tempfile.mkdtemp(prefix="lineage_merge_")
    try:
        for i, src in enumerate(sources):
            alter_rel = src.get("alter_path") or src.get("alter_sql")
            if not alter_rel:
                raise SystemExit(f"sources[{i}]: missing alter_path")
            source_uc = src.get("source_uc") or src.get("source_uc_name")
            source_synapse = src.get("source_synapse") or src.get("synapse_name")
            if not source_uc or not source_synapse:
                raise SystemExit(f"sources[{i}]: need source_uc and source_synapse")

            alter_path = (repo_root / alter_rel).resolve()
            if not alter_path.is_file():
                raise SystemExit(f"Missing alter file: {alter_path}")

            descs = lib.load_source_descriptions(str(alter_path))
            if not descs:
                print(f"  SKIP (no COMMENT literals): {alter_path}", file=sys.stderr)
                continue

            tree_path = os.path.join(tmpdir, f"tree_{i}.json")
            print(f"\n=== DISCOVER [{i + 1}/{len(sources)}] {source_synapse} ===")
            try:
                lib.discover_tree(
                    source_uc,
                    source_synapse,
                    descs,
                    blacklist,
                    tree_path,
                    include_uc_lineage=include_uc,
                )
                tree = lib.LineageTree.load(tree_path)
            except Exception as e:
                print(f"  SKIP discover failed {source_synapse}: {e}", file=sys.stderr)
                continue

            all_node_lists.append(tree.nodes)
            meta.append(
                {
                    "source_synapse": source_synapse,
                    "source_uc": source_uc,
                    "alter_path": str(alter_rel),
                }
            )
    finally:
        lib.close_connection()

    if not meta:
        raise SystemExit(
            "No successful sources: every alter_path was missing or had zero COMMENT literals."
        )
    if not all_node_lists:
        raise SystemExit("Internal error: meta set but no node lists.")

    merged = merge_nodes_from_trees(all_node_lists)
    return merged, meta


def load_trees_from_files(paths: list[Path]) -> list[list[dict]]:
    out: list[list[dict]] = []
    for p in paths:
        p = p.resolve()
        if not p.is_file():
            raise SystemExit(f"Not a file: {p}")
        tree = lib.LineageTree.load(str(p))
        out.append(tree.nodes)
    return out


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--config",
        type=Path,
        help="JSON with { sources: [{ alter_path, source_uc, source_synapse }], include_uc_lineage?: bool }",
    )
    ap.add_argument(
        "--merge-trees",
        nargs="+",
        type=Path,
        metavar="PATH",
        help="Merge existing *.lineage-tree.json files (no Databricks discover)",
    )
    ap.add_argument(
        "-o",
        "--output",
        type=Path,
        required=True,
        help="Output SQL path",
    )
    ap.add_argument(
        "--repo-root",
        type=Path,
        default=ROOT,
        help="Repo root (default: parent of tools/)",
    )
    args = ap.parse_args()
    repo_root = args.repo_root.resolve()

    if bool(args.config) == bool(args.merge_trees):
        ap.error("Specify exactly one of --config or --merge-trees")

    if args.config:
        cfg = json.loads(args.config.read_text(encoding="utf-8"))
        merged, meta = run_discover_and_merge(cfg, repo_root)
    else:
        paths = [repo_root / p if not p.is_absolute() else p for p in args.merge_trees]
        all_node_lists = load_trees_from_files(paths)
        merged = merge_nodes_from_trees(all_node_lists)
        meta = [{"source_synapse": f"merge:{p.name}", "source_uc": "", "alter_path": str(p)} for p in paths]

    out_path = args.output
    if not out_path.is_absolute():
        out_path = repo_root / out_path
    out_path.parent.mkdir(parents=True, exist_ok=True)

    lib.generate_merged_downstream_alter_sql(
        merged,
        str(out_path),
        meta,
        title="MERGED multi-root deep lineage",
    )

    total_stmts = sum(len(n.get("columns") or []) for n in merged)
    print(f"\nDone: {len(merged)} UC objects, {total_stmts} COMMENT statements -> {out_path}")


if __name__ == "__main__":
    main()
