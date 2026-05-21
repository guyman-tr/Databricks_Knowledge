#!/usr/bin/env python3
"""Build a topologically-ordered audit queue across ALL Synapse schemas.

Output: `audits/_audit_queue_<timestamp>.csv` with one row per in-scope wiki:

    wiki_path,uc_full_name,synapse_schema,topological_layer,tier1_claim_count,
    has_alter_sql,wiki_kind

Rows are sorted by `topological_layer ASC, tier1_claim_count DESC, wiki_path ASC`
so the consumer (`audit_dag_walk.py`) processes upstream layers first -- the
Phase D contract from the cleanup plan.

The queue intentionally INCLUDES wikis that the current run already corrected
(layer 0 / DWH_dbo will reappear). The walk can no-op those by reading the
existing `_tier1_truth_corrections.csv` for that wiki path.
"""
from __future__ import annotations

import argparse
import csv
import sys
from datetime import datetime, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "tools"))

from cleanup_tier1 import dag

QUEUE_FIELDS = [
    "wiki_path",
    "uc_full_name",
    "synapse_schema",
    "topological_layer",
    "tier1_claim_count",
    "has_alter_sql",
    "wiki_kind",
]


def build_queue() -> list[dict]:
    dag.load_dag()
    rows: list[dict] = []
    for wp, fn, layer, n_claims in dag.all_in_scope_wikis_with_tier1_tags():
        path = REPO / wp
        alt = path.with_name(path.stem + ".alter.sql")
        # Pull synapse_schema + wiki_kind from the upstream index where available
        info = dag._wiki_by_full.get(fn, {})  # noqa: SLF001 -- intentional
        rows.append({
            "wiki_path": wp,
            "uc_full_name": fn,
            "synapse_schema": info.get("synapse_schema") or dag.synapse_schema_of(wp) or "",
            "topological_layer": layer,
            "tier1_claim_count": n_claims,
            "has_alter_sql": "YES" if alt.exists() else "NO",
            "wiki_kind": info.get("wiki_kind", ""),
        })
    return rows


def write_queue(rows: list[dict], out_dir: Path) -> Path:
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H-%M-%SZ")
    out = out_dir / f"_audit_queue_{ts}.csv"
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=QUEUE_FIELDS)
        w.writeheader()
        for r in rows:
            w.writerow(r)
    return out


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out-dir", default=str(REPO / "audits"))
    ap.add_argument("--summary", action="store_true",
                    help="Print per-layer summary to stdout.")
    args = ap.parse_args()

    rows = build_queue()
    out = write_queue(rows, Path(args.out_dir))

    by_layer: dict[int, list[dict]] = {}
    for r in rows:
        by_layer.setdefault(r["topological_layer"], []).append(r)
    total_claims = sum(r["tier1_claim_count"] for r in rows)
    print(f"Wrote {len(rows)} queue rows across {len(by_layer)} topological "
          f"layers, totaling {total_claims} Tier-1 claims -> {out}")

    if args.summary:
        print()
        print(f"{'layer':>5} {'wikis':>6} {'claims':>7} {'w/alter':>8}  example_schemas")
        for layer in sorted(by_layer):
            wikis = by_layer[layer]
            claims = sum(w["tier1_claim_count"] for w in wikis)
            alters = sum(1 for w in wikis if w["has_alter_sql"] == "YES")
            schemas = sorted({w["synapse_schema"] for w in wikis if w["synapse_schema"]})
            schema_label = ", ".join(schemas[:4])
            if len(schemas) > 4:
                schema_label += f", +{len(schemas) - 4}"
            print(f"{layer:>5} {len(wikis):>6} {claims:>7} {alters:>8}  {schema_label}")


if __name__ == "__main__":
    main()
