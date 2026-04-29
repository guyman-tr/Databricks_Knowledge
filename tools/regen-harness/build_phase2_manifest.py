"""
build_phase2_manifest.py

Phase 2 manifest builder for the in-scope slop fix.

Reads `audits/regen-sample/_alter_scope.json` (produced by build_alter_scope.py),
filters to objects that are BOTH in-scope (mapped or downstream of mapped) AND
slop (T4InfHits >= threshold), and writes:

  audits/regen-sample/_phase2_manifest.csv

The CSV has the same column schema as the existing `manifest.csv` so the
existing harness tools (regen_one.ps1, run_all.ps1 -ManifestPath ...,
compare_one.py --manifest, summarize.py --manifest) can drive Phase 2
without modification.

Also copies each target object's current wiki + sidecars into:

  audits/regen-sample/{Schema}/{Object}/current/

(idempotent: skips when the snapshot is already present unless --force).

Inputs (read-only):
  audits/regen-sample/_alter_scope.json
  audits/wiki_health_scan_*.csv             (for q_score lookup)
  knowledge/synapse/Wiki/{Schema}/{Tables|Views|Functions}/{Object}.md  (snapshot source)

Usage:
  python build_phase2_manifest.py
  python build_phase2_manifest.py --threshold-t4 5     # stricter slop
  python build_phase2_manifest.py --force              # re-copy current/ snapshots
"""
from __future__ import annotations

import argparse
import csv
import json
import shutil
import sys
from pathlib import Path
from typing import Dict, List, Optional

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
WIKI_ROOT = REPO_ROOT / "knowledge" / "synapse" / "Wiki"
AUDITS = REPO_ROOT / "audits"
TARGET_ROOT = AUDITS / "regen-sample"
SCOPE_JSON = TARGET_ROOT / "_alter_scope.json"
PHASE2_MANIFEST = TARGET_ROOT / "_phase2_manifest.csv"


def find_latest_health_scan() -> Optional[Path]:
    candidates = sorted(AUDITS.glob("wiki_health_scan_*.csv"), key=lambda p: p.stat().st_mtime)
    return candidates[-1] if candidates else None


def load_health_scan_index(scan_path: Optional[Path]) -> Dict[str, Dict[str, str]]:
    """Map lower-cased "schema.object" -> health scan row (dict)."""
    if not scan_path or not scan_path.exists():
        return {}
    out: Dict[str, Dict[str, str]] = {}
    with scan_path.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            p = (row.get("Path") or "").replace("\\", "/").split("/")
            if "Wiki" not in p:
                continue
            i = p.index("Wiki")
            if i + 3 >= len(p):
                continue
            if p[i + 2] not in ("Tables", "Views", "Functions"):
                continue
            obj = p[i + 3]
            if obj.endswith(".md"):
                obj = obj[:-3]
            key = f"{p[i + 1]}.{obj}".lower()
            out[key] = row
    return out


def find_wiki_path(schema: str, name: str) -> Optional[Path]:
    for sub in ("Tables", "Views", "Functions"):
        cand = WIKI_ROOT / schema / sub / f"{name}.md"
        if cand.exists():
            return cand
    return None


def copy_current_snapshot(schema: str, name: str, force: bool) -> Dict:
    """Copy current wiki + sidecars into audits/regen-sample/{Schema}/{Object}/current/.
    Returns metadata dict for meta.json."""
    src = find_wiki_path(schema, name)
    if not src:
        return {"copied": 0, "skipped": True, "reason": "wiki not found in repo"}
    dest_dir = TARGET_ROOT / schema / name / "current"
    dest_wiki = dest_dir / src.name

    if dest_wiki.exists() and not force:
        return {"copied": 0, "skipped": True, "reason": "already snapshotted"}

    dest_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dest_wiki)
    copied = 1
    src_dir = src.parent
    for sibling_suffix in (".lineage.md", ".review-needed.md", ".alter.sql"):
        sibling = src_dir / f"{name}{sibling_suffix}"
        if sibling.exists():
            shutil.copy2(sibling, dest_dir / sibling.name)
            copied += 1
    return {"copied": copied, "skipped": False, "wiki_path": str(src.relative_to(REPO_ROOT)).replace("\\", "/")}


def write_meta(schema: str, name: str, scope_row: Dict, scan_row: Optional[Dict]) -> None:
    dest_dir = TARGET_ROOT / schema / name / "current"
    dest_dir.mkdir(parents=True, exist_ok=True)
    q_score = None
    if scan_row:
        q_raw = (scan_row.get("QScore") or "").strip()
        if q_raw:
            try:
                q_score = float(q_raw)
            except ValueError:
                q_score = None
    meta = {
        "schema": schema,
        "object": name,
        "bucket": "slop",
        "phase": "phase2_in_scope_slop",
        "kind": scope_row["kind"],
        "hops_from_seed": scope_row["hops_from_seed"],
        "mapped_uc": scope_row.get("mapped_uc"),
        "slop_t4_hits": scope_row["slop_t4_hits"],
        "current_quality": q_score,
        "current_path": scope_row.get("wiki_path"),
    }
    (dest_dir / "meta.json").write_text(
        json.dumps(meta, indent=2), encoding="utf-8"
    )


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--threshold-t4", type=int, default=1,
                   help="minimum T4InfHits to count as slop (default: 1)")
    p.add_argument("--force", action="store_true",
                   help="re-copy current/ snapshots even if they already exist")
    p.add_argument("--quiet", action="store_true")
    args = p.parse_args()

    if not SCOPE_JSON.exists():
        sys.exit(f"ERROR: {SCOPE_JSON} not found. Run build_alter_scope.py first.")

    scope_data = json.loads(SCOPE_JSON.read_text(encoding="utf-8"))
    in_scope: List[Dict] = scope_data.get("in_scope") or []

    targets = [r for r in in_scope if r.get("slop_t4_hits", 0) >= args.threshold_t4 and r.get("currently_documented")]
    if not args.quiet:
        print(f"Loaded scope: {len(in_scope)} in-scope objects")
        print(f"Phase 2 targets (in-scope, T4InfHits >= {args.threshold_t4}, documented): {len(targets)}")

    scan_path = find_latest_health_scan()
    scan_index = load_health_scan_index(scan_path)
    if not args.quiet:
        print(f"Health scan: {scan_path.name if scan_path else '(none)'}  ({len(scan_index)} rows indexed)")

    targets.sort(key=lambda r: (r["schema"].lower(), r["name"].lower()))

    PHASE2_MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    with PHASE2_MANIFEST.open("w", encoding="utf-8", newline="") as fh:
        wr = csv.writer(fh)
        wr.writerow([
            "Schema", "Object", "Bucket", "PickReason",
            "CurrentQuality", "InfHits", "T4InfHits",
            "Dormant", "HasUpstreamLog", "MTime", "CurrentPath",
        ])
        copied_total = 0
        skipped_total = 0
        for r in targets:
            scan_row = scan_index.get(r["object"])
            q = (scan_row.get("QScore") or "") if scan_row else ""
            inf = (scan_row.get("InfHits") or "0") if scan_row else "0"
            t4 = str(r.get("slop_t4_hits", 0))
            dormant = (scan_row.get("Dormant") or "False") if scan_row else "False"
            haslog = (scan_row.get("HasLog") or "False") if scan_row else "False"
            mtime = (scan_row.get("MTime") or "") if scan_row else ""
            current_path = r.get("wiki_path") or ""
            wr.writerow([
                r["schema"], r["name"], "slop",
                f"in-scope slop (T4InfHits>={args.threshold_t4}, kind={r['kind']}, hops={r['hops_from_seed']})",
                q, inf, t4, dormant, haslog, mtime, current_path,
            ])
            res = copy_current_snapshot(r["schema"], r["name"], args.force)
            if res["skipped"]:
                skipped_total += 1
                if not args.quiet:
                    print(f"  - {r['schema']:18} {r['name']:50}  (skip: {res['reason']})")
            else:
                copied_total += res["copied"]
                if not args.quiet:
                    print(f"  + {r['schema']:18} {r['name']:50}  (copied {res['copied']} files)")
            write_meta(r["schema"], r["name"], r, scan_row)

    if not args.quiet:
        print()
        print(f"Wrote manifest: {PHASE2_MANIFEST.relative_to(REPO_ROOT)}  ({len(targets)} rows)")
        print(f"Snapshots: copied {copied_total} files across new dirs, skipped {skipped_total} already-present dirs")

    return 0


if __name__ == "__main__":
    sys.exit(main())
