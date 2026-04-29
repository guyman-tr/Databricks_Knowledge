"""
pick_sample.py

Selects 25 objects (5 schemas x 5 buckets) for the regen-harness comparison run.
Reads the latest audits/wiki_health_scan_*.csv. Stratifies across:
  - good     : Quality >= 8.5, no slop hits, not dormant
  - median   : Quality 7.5..8.0, low slop
  - slop     : T4InfHits >= 5 (LLM "(Tier 4 ... inferred ...)" boilerplate)
  - dormant  : Production Source: Unknown (dormant)
  - random   : Quality 8.0..8.5, not matching above

Falls back relaxing thresholds for schemas where a bucket is empty (e.g. eMoney
has no slop or dormant rows). Writes:
  audits/regen-sample/manifest.csv

Then copies each selected wiki + lineage + sidecar into:
  audits/regen-sample/{Schema}/{Object}/current/

Reproducible: random seed pinned to 42.
"""
from __future__ import annotations

import csv
import json
import random
import re
import shutil
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable, List, Optional

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
WIKI_ROOT = REPO_ROOT / "knowledge" / "synapse" / "Wiki"
AUDITS = REPO_ROOT / "audits"
TARGET_ROOT = AUDITS / "regen-sample"

SCHEMAS = ["BI_DB_dbo", "DWH_dbo", "Dealing_dbo", "eMoney_dbo", "EXW_dbo"]
BUCKETS = ["good", "median", "slop", "dormant", "random"]

RANDOM_SEED = 42


@dataclass
class Row:
    path: Path
    schema: str
    name: str
    mtime: str
    inf_hits: int
    t4_inf_hits: int
    dormant: bool
    has_log: bool
    q_score: Optional[float]
    selected_for: Optional[str] = None
    pick_reason: str = ""


def _to_int(s: str) -> int:
    try:
        return int((s or "0").strip() or "0")
    except ValueError:
        return 0


def _to_float(s: str) -> Optional[float]:
    s = (s or "").strip()
    if not s:
        return None
    try:
        return float(s)
    except ValueError:
        return None


def _to_bool(s: str) -> bool:
    return (s or "").strip().lower() == "true"


def find_latest_scan() -> Path:
    scans = sorted(
        AUDITS.glob("wiki_health_scan_*.csv"),
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )
    if not scans:
        sys.exit(
            "ERROR: no audits/wiki_health_scan_*.csv found. Run the scan first."
        )
    return scans[0]


def load_rows(csv_path: Path) -> List[Row]:
    rows: List[Row] = []
    with csv_path.open("r", encoding="utf-8-sig", newline="") as fh:
        rdr = csv.DictReader(fh)
        for r in rdr:
            schema = (r.get("Schema") or "").strip()
            name = (r.get("File") or "").strip()
            if schema not in SCHEMAS:
                continue
            if not name or name.startswith("_"):
                continue
            path_str = (r.get("Path") or "").strip()
            path = Path(path_str) if path_str else Path("")
            rows.append(
                Row(
                    path=path,
                    schema=schema,
                    name=name,
                    mtime=(r.get("MTime") or "").strip(),
                    inf_hits=_to_int(r.get("InfHits", "0")),
                    t4_inf_hits=_to_int(r.get("T4InfHits", "0")),
                    dormant=_to_bool(r.get("Dormant", "")),
                    has_log=_to_bool(r.get("HasLog", "")),
                    q_score=_to_float(r.get("QScore", "")),
                )
            )
    return rows


def _pick_first(
    candidates: Iterable[Row], used: set, reason: str, sort_key=None
) -> Optional[Row]:
    avail = [r for r in candidates if (r.schema, r.name) not in used]
    if not avail:
        return None
    if sort_key is not None:
        avail.sort(key=sort_key)
    chosen = avail[0]
    chosen.pick_reason = reason
    used.add((chosen.schema, chosen.name))
    return chosen


def _pick_random(
    candidates: Iterable[Row], used: set, reason: str, rng: random.Random
) -> Optional[Row]:
    avail = [r for r in candidates if (r.schema, r.name) not in used]
    if not avail:
        return None
    chosen = rng.choice(avail)
    chosen.pick_reason = reason
    used.add((chosen.schema, chosen.name))
    return chosen


def pick_for_schema(
    schema_rows: List[Row], rng: random.Random
) -> List[Row]:
    used: set = set()
    out: List[Row] = []

    # ---- good: Q>=8.5, no slop, not dormant. Fallback: Q>=8.0; then highest Q.
    good = [
        r
        for r in schema_rows
        if r.q_score is not None
        and r.q_score >= 8.5
        and r.t4_inf_hits == 0
        and not r.dormant
    ]
    pick = _pick_first(
        good,
        used,
        "good: Q>=8.5, no slop, not dormant",
        sort_key=lambda r: (-(r.q_score or 0), r.name),
    )
    if pick is None:
        good_relaxed = [
            r
            for r in schema_rows
            if r.q_score is not None and r.q_score >= 8.0 and not r.dormant
        ]
        pick = _pick_first(
            good_relaxed,
            used,
            "good (relaxed): Q>=8.0, not dormant",
            sort_key=lambda r: (-(r.q_score or 0), r.name),
        )
    if pick is None:
        ranked = [r for r in schema_rows if r.q_score is not None]
        pick = _pick_first(
            ranked,
            used,
            "good (last resort): highest available Q",
            sort_key=lambda r: (-(r.q_score or 0), r.name),
        )
    if pick is not None:
        pick.selected_for = "good"
        out.append(pick)

    # ---- median: Q in [7.5, 8.0), low slop. Fallback: [7.0, 8.0); then lowest.
    median = [
        r
        for r in schema_rows
        if r.q_score is not None
        and 7.5 <= r.q_score < 8.0
        and r.t4_inf_hits <= 2
    ]
    pick = _pick_first(
        median,
        used,
        "median: Q in [7.5,8.0), low slop",
        sort_key=lambda r: (r.q_score or 0, r.name),
    )
    if pick is None:
        median_relaxed = [
            r
            for r in schema_rows
            if r.q_score is not None and 7.0 <= r.q_score < 8.0
        ]
        pick = _pick_first(
            median_relaxed,
            used,
            "median (relaxed): Q in [7.0,8.0)",
            sort_key=lambda r: (r.q_score or 0, r.name),
        )
    if pick is None:
        median_lr = [
            r
            for r in schema_rows
            if r.q_score is not None and r.q_score < 8.5
        ]
        pick = _pick_first(
            median_lr,
            used,
            "median (last resort): lowest non-top Q",
            sort_key=lambda r: (r.q_score or 0, r.name),
        )
    if pick is None:
        # Final fallback: schemas with homogeneous Q (e.g. eMoney all Q>=8.5
        # or Q=None) need *something* to label as median for stratification.
        pick = _pick_first(
            schema_rows,
            used,
            "median (final fallback): any remaining row",
            sort_key=lambda r: (r.q_score or 99, r.name),
        )
    if pick is not None:
        pick.selected_for = "median"
        out.append(pick)

    # ---- slop: T4InfHits>=5. Fallback: T4InfHits>=1; then InfHits>=1.
    slop = [r for r in schema_rows if r.t4_inf_hits >= 5]
    pick = _pick_first(
        slop,
        used,
        "slop: T4InfHits>=5",
        sort_key=lambda r: (-r.t4_inf_hits, -(r.inf_hits or 0)),
    )
    if pick is None:
        slop_relaxed = [r for r in schema_rows if r.t4_inf_hits >= 1]
        pick = _pick_first(
            slop_relaxed,
            used,
            "slop (relaxed): T4InfHits>=1",
            sort_key=lambda r: (-r.t4_inf_hits, -(r.inf_hits or 0)),
        )
    if pick is None:
        slop_inf = [r for r in schema_rows if r.inf_hits >= 1]
        pick = _pick_first(
            slop_inf,
            used,
            "slop (last resort): any inferred-from-name occurrence",
            sort_key=lambda r: -(r.inf_hits or 0),
        )
    if pick is None:
        worst = [r for r in schema_rows if r.q_score is not None]
        pick = _pick_first(
            worst,
            used,
            "slop (no slop in schema): worst-quality available as proxy",
            sort_key=lambda r: (r.q_score or 0, r.name),
        )
    if pick is not None:
        pick.selected_for = "slop"
        out.append(pick)

    # ---- dormant: Production Source unknown. Fallback: lowest Q remaining.
    dormant = [r for r in schema_rows if r.dormant]
    pick = _pick_first(
        dormant,
        used,
        "dormant: Production Source: Unknown (dormant)",
        sort_key=lambda r: (r.q_score or 0, r.name),
    )
    if pick is None:
        weak = [
            r
            for r in schema_rows
            if r.q_score is not None and r.q_score <= 7.5
        ]
        pick = _pick_first(
            weak,
            used,
            "dormant (no dormant in schema): low-Q proxy",
            sort_key=lambda r: (r.q_score or 0, r.name),
        )
    if pick is None:
        any_left = [r for r in schema_rows]
        pick = _pick_first(
            any_left,
            used,
            "dormant (last resort): any remaining",
            sort_key=lambda r: (r.q_score or 0, r.name),
        )
    if pick is not None:
        pick.selected_for = "dormant"
        out.append(pick)

    # ---- random: Q in [8.0, 8.5). Fallback: any not yet picked.
    rand_pool = [
        r
        for r in schema_rows
        if r.q_score is not None
        and 8.0 <= r.q_score < 8.5
        and r.t4_inf_hits == 0
    ]
    pick = _pick_random(
        rand_pool, used, "random: Q in [8.0,8.5), no slop", rng
    )
    if pick is None:
        pick = _pick_random(
            schema_rows, used, "random (relaxed): any remaining", rng
        )
    if pick is not None:
        pick.selected_for = "random"
        out.append(pick)

    return out


def write_manifest(picks: List[Row], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as fh:
        wr = csv.writer(fh)
        wr.writerow(
            [
                "Schema",
                "Object",
                "Bucket",
                "PickReason",
                "CurrentQuality",
                "InfHits",
                "T4InfHits",
                "Dormant",
                "HasUpstreamLog",
                "MTime",
                "CurrentPath",
            ]
        )
        for r in picks:
            wr.writerow(
                [
                    r.schema,
                    r.name,
                    r.selected_for or "",
                    r.pick_reason,
                    "" if r.q_score is None else f"{r.q_score:.2f}",
                    r.inf_hits,
                    r.t4_inf_hits,
                    "True" if r.dormant else "False",
                    "True" if r.has_log else "False",
                    r.mtime,
                    str(r.path),
                ]
            )


def copy_current(picks: List[Row], target_root: Path) -> None:
    """Snapshot the current wiki + lineage + sidecar into target_root."""
    for r in picks:
        if not r.path or not r.path.exists():
            print(f"  WARN: source missing for {r.schema}/{r.name}: {r.path}")
            continue
        dest_dir = target_root / r.schema / r.name / "current"
        dest_dir.mkdir(parents=True, exist_ok=True)
        # Always copy the wiki itself
        shutil.copy2(r.path, dest_dir / r.path.name)
        # Sibling files: .lineage.md, .review-needed.md, .alter.sql (if present)
        wiki_dir = r.path.parent
        for sibling_suffix in (".lineage.md", ".review-needed.md", ".alter.sql"):
            sibling = wiki_dir / f"{r.name}{sibling_suffix}"
            if sibling.exists():
                shutil.copy2(sibling, dest_dir / sibling.name)
        # meta.json
        meta = {
            "schema": r.schema,
            "object": r.name,
            "bucket": r.selected_for,
            "pick_reason": r.pick_reason,
            "current_quality": r.q_score,
            "inf_hits": r.inf_hits,
            "t4_inf_hits": r.t4_inf_hits,
            "dormant": r.dormant,
            "has_upstream_log": r.has_log,
            "mtime": r.mtime,
            "current_path": str(r.path),
        }
        (dest_dir / "meta.json").write_text(
            json.dumps(meta, indent=2, default=str), encoding="utf-8"
        )


def main() -> int:
    rng = random.Random(RANDOM_SEED)
    csv_path = find_latest_scan()
    print(f"Health scan: {csv_path}")
    rows = load_rows(csv_path)
    print(f"Loaded {len(rows)} rows across {len(SCHEMAS)} schemas")
    print()

    all_picks: List[Row] = []
    for schema in SCHEMAS:
        sch_rows = [r for r in rows if r.schema == schema]
        if not sch_rows:
            print(f"  {schema}: NO rows in scan, skipping")
            continue
        picks = pick_for_schema(sch_rows, rng)
        print(f"  {schema}: picked {len(picks)} / 5")
        for r in picks:
            qs = f"{r.q_score:.1f}" if r.q_score is not None else "?"
            print(
                f"    {r.selected_for:<8}  Q={qs:<4}  T4Inf={r.t4_inf_hits:<3}  "
                f"dormant={str(r.dormant):<5}  {r.name}"
            )
        all_picks.extend(picks)
        print()

    if not all_picks:
        print("No picks selected. Exiting.")
        return 1

    manifest = TARGET_ROOT / "manifest.csv"
    write_manifest(all_picks, manifest)
    print(f"Wrote manifest: {manifest}  ({len(all_picks)} rows)")

    print()
    print("Copying current wikis to side folder...")
    copy_current(all_picks, TARGET_ROOT)
    print(f"Done. Side folder: {TARGET_ROOT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
