"""
build_phase4_manifest.py

Phase 4 manifest builder for the in-scope newbuild backlog.

Reads `audits/regen-sample/_alter_scope.json` (produced by build_alter_scope.py),
filters to objects that are in-scope AND not yet documented, and writes:

  audits/regen-sample/_phase4_manifest.csv

The CSV uses the same column schema as `_phase2_manifest.csv` so the harness
runner (run_all.ps1 -ManifestPath ..., compare_one.py --manifest, summarize.py
--manifest) can drive a controlled Phase 4 batch run.

UNLIKE Phase 2, Phase 4 objects have NO existing wiki to snapshot. There is
nothing to copy into `current/`. We only ensure the per-object output dir
exists so `regen_one.ps1` can write into it.

Layering / sort order (highest leverage first):
  1. hops_from_seed asc      (seeds = bronze tables, highest leverage)
  2. kind asc                 (mapped seeds before pure-downstream)
  3. schema asc, name asc     (deterministic tie-break)

Schema filter:
  Only schemas that the wiki batch loop knows how to drive end up as targets
  by default — i.e. schemas with an SSDT folder under
  DataPlatform/SynapseSQLPool1/sql_dp_prod_we/. Pass --schema NAME to scope
  to one schema, or --include-all to keep every in-scope schema (including
  GCP_DataSet_*, EXE, EXW_Wallet, etc. that have no SSDT mirror).

Inputs (read-only):
  audits/regen-sample/_alter_scope.json
  ../../DataPlatform/SynapseSQLPool1/sql_dp_prod_we/{Schema}/Tables (existence check)

Usage:
  python build_phase4_manifest.py
  python build_phase4_manifest.py --schema BI_DB_dbo
  python build_phase4_manifest.py --max-hops 1
  python build_phase4_manifest.py --include-all --no-create-dirs
"""
from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path
from typing import Dict, List, Optional

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
WIKI_ROOT = REPO_ROOT / "knowledge" / "synapse" / "Wiki"
AUDITS = REPO_ROOT / "audits"
TARGET_ROOT = AUDITS / "regen-sample"
SCOPE_JSON = TARGET_ROOT / "_alter_scope.json"
PHASE4_MANIFEST = TARGET_ROOT / "_phase4_manifest.csv"

DATAPLATFORM_ROOT = REPO_ROOT.parent / "DataPlatform"
SSDT_ROOT = DATAPLATFORM_ROOT / "SynapseSQLPool1" / "sql_dp_prod_we"

LOOP_SCHEMAS = {
    "BI_DB_dbo", "DWH_dbo", "Dealing_dbo", "eMoney_dbo", "EXW_dbo",
}


def has_ssdt_mirror(schema: str) -> bool:
    """True if the schema has an SSDT Tables folder we could pick from."""
    return (SSDT_ROOT / schema / "Tables").exists()


def main() -> int:
    p = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    p.add_argument("--schema", default=None,
                   help="restrict to a single schema (e.g. BI_DB_dbo)")
    p.add_argument("--max-hops", type=int, default=2,
                   help="upper bound on hops_from_seed to include (default: 2 -- matches build_alter_scope.py)")
    p.add_argument("--include-all", action="store_true",
                   help="include schemas without an SSDT mirror (e.g. GCP_DataSet_*, EXE, EXW_Wallet). Off by default because the wiki loop cannot pick them.")
    p.add_argument("--no-create-dirs", action="store_true",
                   help="do not create per-object output dirs under audits/regen-sample/{Schema}/{Object}/")
    p.add_argument("--output", default=str(PHASE4_MANIFEST),
                   help="output manifest CSV path (default: audits/regen-sample/_phase4_manifest.csv)")
    p.add_argument("--quiet", action="store_true")
    args = p.parse_args()

    if not SCOPE_JSON.exists():
        sys.exit(f"ERROR: {SCOPE_JSON} not found. Run build_alter_scope.py first.")

    scope_data = json.loads(SCOPE_JSON.read_text(encoding="utf-8"))
    in_scope: List[Dict] = scope_data.get("in_scope") or []

    targets = [r for r in in_scope
               if not r.get("currently_documented")
               and r.get("hops_from_seed", 99) <= args.max_hops]

    if args.schema:
        before = len(targets)
        targets = [r for r in targets if r["schema"] == args.schema]
        if not args.quiet:
            print(f"Schema filter '{args.schema}': {before} -> {len(targets)}")

    if not args.include_all:
        before = len(targets)
        targets = [r for r in targets
                   if r["schema"] in LOOP_SCHEMAS or has_ssdt_mirror(r["schema"])]
        if not args.quiet and before != len(targets):
            print(f"SSDT-mirror filter (loop-buildable schemas): {before} -> {len(targets)}")
            dropped_schemas = sorted({
                r["schema"] for r in in_scope
                if not r.get("currently_documented")
                and r.get("hops_from_seed", 99) <= args.max_hops
                and r["schema"] not in LOOP_SCHEMAS
                and not has_ssdt_mirror(r["schema"])
            })
            if dropped_schemas:
                print(f"  Schemas without SSDT mirror (use --include-all to keep): {', '.join(dropped_schemas)}")

    targets.sort(key=lambda r: (
        int(r.get("hops_from_seed", 99)),
        str(r.get("kind", "")),
        r["schema"].lower(),
        r["name"].lower(),
    ))

    schema_counts: Dict[str, int] = {}
    hop_counts: Dict[int, int] = {}
    kind_counts: Dict[str, int] = {}
    for r in targets:
        schema_counts[r["schema"]] = schema_counts.get(r["schema"], 0) + 1
        hop = int(r.get("hops_from_seed", 99))
        hop_counts[hop] = hop_counts.get(hop, 0) + 1
        kind = str(r.get("kind", ""))
        kind_counts[kind] = kind_counts.get(kind, 0) + 1

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8", newline="") as fh:
        wr = csv.writer(fh)
        wr.writerow([
            "Schema", "Object", "Bucket", "PickReason",
            "CurrentQuality", "InfHits", "T4InfHits",
            "Dormant", "HasUpstreamLog", "MTime", "CurrentPath",
        ])
        created_dirs = 0
        for r in targets:
            wr.writerow([
                r["schema"], r["name"], "newbuild",
                f"in-scope newbuild (kind={r['kind']}, hops={r['hops_from_seed']}, mapped_uc={'Y' if r.get('mapped_uc') else 'N'})",
                "", "", "0", "False", "False", "", "",
            ])
            if not args.no_create_dirs:
                obj_dir = TARGET_ROOT / r["schema"] / r["name"]
                if not obj_dir.exists():
                    obj_dir.mkdir(parents=True, exist_ok=True)
                    created_dirs += 1

    if not args.quiet:
        print()
        print(f"Wrote manifest: {out_path.relative_to(REPO_ROOT)}  ({len(targets)} rows)")
        if not args.no_create_dirs:
            print(f"Created {created_dirs} new per-object dirs under audits/regen-sample/")
        print()
        print("Per-schema:")
        for s in sorted(schema_counts.keys()):
            print(f"  {s:25} {schema_counts[s]:5}")
        print()
        print("Per-hop-distance:")
        for h in sorted(hop_counts.keys()):
            print(f"  hops={h}  {hop_counts[h]:5}")
        print()
        print("Per-kind:")
        for k in sorted(kind_counts.keys()):
            print(f"  {k:30} {kind_counts[k]:5}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
