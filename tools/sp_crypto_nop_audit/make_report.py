"""Diff the 04:00 vs 09:00 source-fingerprint snapshots for a given target_date
and produce a markdown report highlighting WHICH upstream sources actually
changed between the two polls.

If both snapshots aren't present yet, exit cleanly (so the 04:00 task can
call this without complaint — the report fires on the 09:00 run).

Outputs:
  tools/sp_crypto_nop_audit/reports/<YYYY-MM-DD>.md
  C:\\Users\\<you>\\Downloads\\sp_crypto_nop_source_audit_<YYYY-MM-DD>.md  (copy)
"""
from __future__ import annotations

import argparse
import csv
import datetime
import json
import os
import shutil
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

HERE = Path(__file__).resolve().parent
SNAP_DIR = HERE / "snapshots"
REPORT_DIR = HERE / "reports"
REPORT_DIR.mkdir(parents=True, exist_ok=True)


def load_snapshot(path: Path) -> Dict[str, Dict[str, Any]]:
    out: Dict[str, Dict[str, Any]] = {}
    with path.open("r", encoding="utf-8", newline="") as fh:
        r = csv.DictReader(fh)
        for row in r:
            try:
                fp = json.loads(row.get("fingerprint_json") or "{}")
            except Exception:
                fp = {"_parse_error": True, "raw": row.get("fingerprint_json")}
            row["_fp"] = fp
            out[row["source_id"]] = row
    return out


def discover_snapshots(target_date: datetime.date) -> List[Path]:
    pattern = f"{target_date.isoformat()}_*.csv"
    return list(SNAP_DIR.glob(pattern))


def _poll_at(path: Path) -> str:
    """Return the poll_at_utc from the first row of the CSV (falls back to mtime)."""
    try:
        with path.open("r", encoding="utf-8", newline="") as fh:
            r = csv.DictReader(fh)
            for row in r:
                ts = (row.get("poll_at_utc") or "").strip()
                if ts:
                    return ts
                break
    except Exception:
        pass
    return datetime.datetime.fromtimestamp(path.stat().st_mtime).isoformat()


def pick_pair(paths: List[Path]) -> Optional[Tuple[Path, Path]]:
    """Sort snapshots by their actual poll_at_utc (not file mtime), then pick
    the earliest and latest. Manual reruns interleaved with scheduled runs
    still produce the right widest-window diff."""
    if len(paths) < 2:
        return None
    ordered = sorted(paths, key=_poll_at)
    return ordered[0], ordered[-1]


def fmt_val(v: Any) -> str:
    if v is None:
        return "—"
    if isinstance(v, float):
        if v != v:  # NaN
            return "NaN"
        if abs(v - round(v)) < 1e-9 and abs(v) < 1e15:
            return f"{int(round(v)):,}"
        return f"{v:,.4f}".rstrip("0").rstrip(".") or "0"
    if isinstance(v, int):
        return f"{v:,}"
    return str(v)


def fmt_delta(a: Any, b: Any) -> Tuple[str, bool]:
    """Return (delta_string, changed_flag)."""
    if a is None and b is None:
        return ("—", False)
    if a is None or b is None:
        return (f"{fmt_val(a)} → {fmt_val(b)}", True)
    # Try numeric subtraction
    try:
        fa = float(a)
        fb = float(b)
        if fa == fb:
            return ("0", False)
        d = fb - fa
        # Format absolute and relative
        sign = "+" if d > 0 else ""
        pct = (d / fa * 100) if fa != 0 else float("inf")
        pct_s = f"{pct:+.2f}%" if abs(pct) < 1e9 else "Δ"
        # Integer-ish?
        if isinstance(a, (int, float)) and isinstance(b, (int, float)) and \
           abs(d - round(d)) < 1e-9 and abs(fa) < 1e15:
            return (f"{sign}{int(round(d)):,}  ({pct_s})", True)
        return (f"{sign}{d:,.4f}  ({pct_s})".replace(",.0000", ""), True)
    except (TypeError, ValueError):
        if a == b:
            return ("—", False)
        return (f"{fmt_val(a)} → {fmt_val(b)}", True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--target-date",
        type=str,
        default="",
        help="YYYY-MM-DD; defaults to yesterday (matching the default of poll_sources.py)",
    )
    parser.add_argument(
        "--copy-to-downloads",
        action="store_true",
        default=True,
        help="Also copy the report into the user's Downloads folder (default true).",
    )
    parser.add_argument(
        "--require-two",
        action="store_true",
        default=False,
        help="Exit 1 if fewer than 2 snapshots exist (default: exit 0 silently).",
    )
    args = parser.parse_args()

    target_date = (
        datetime.date.fromisoformat(args.target_date)
        if args.target_date
        else datetime.date.today() - datetime.timedelta(days=1)
    )
    paths = discover_snapshots(target_date)
    if not paths:
        print(f"No snapshots found for {target_date.isoformat()} in {SNAP_DIR}", flush=True)
        return 1 if args.require_two else 0

    pair = pick_pair(paths)
    if pair is None:
        print(f"Only one snapshot for {target_date.isoformat()} so far — skipping diff.\n"
              f"  found: {[p.name for p in paths]}", flush=True)
        return 1 if args.require_two else 0

    early_path, late_path = pair
    early = load_snapshot(early_path)
    late = load_snapshot(late_path)

    print(f"Comparing:\n  EARLY = {early_path.name}\n  LATE  = {late_path.name}\n", flush=True)

    # Build report
    rep: List[str] = []
    rep.append(f"# SP_Crypto_NOP source audit — `@Date = {target_date.isoformat()}`")
    rep.append("")
    rep.append(f"_Generated {datetime.datetime.utcnow().isoformat(timespec='seconds')}Z "
               f"by tools/sp_crypto_nop_audit/make_report.py_")
    rep.append("")
    rep.append(f"- **Early snapshot**: `{early_path.name}` "
               f"(poll_at_utc = {next(iter(early.values()))['poll_at_utc']})")
    rep.append(f"- **Late  snapshot**: `{late_path.name}` "
               f"(poll_at_utc = {next(iter(late.values()))['poll_at_utc']})")
    rep.append("")
    rep.append("Verdict legend: ✅ unchanged · ⚠️ row-count changed · 🔥 row-count AND signal sums changed · 📝 fingerprint changed but not row count")
    rep.append("")

    rep.append("## Summary")
    rep.append("")
    summary_rows: List[Tuple[str, str, str, str]] = []
    detail_rows: List[Tuple[str, Dict[str, Tuple[Any, Any]]]] = []
    n_changed = 0
    n_rows_changed = 0

    all_ids = sorted(set(early.keys()) | set(late.keys()))
    for sid in all_ids:
        e = early.get(sid)
        l = late.get(sid)
        if e is None or l is None:
            verdict = "❓ missing in one snapshot"
            summary_rows.append((sid, verdict,
                                  e["row_count"] if e else "—",
                                  l["row_count"] if l else "—"))
            continue

        e_fp = e.get("_fp", {})
        l_fp = l.get("_fp", {})

        # Detect changes per fingerprint key
        diffs: Dict[str, Tuple[Any, Any]] = {}
        for k in sorted(set(e_fp.keys()) | set(l_fp.keys())):
            va, vb = e_fp.get(k), l_fp.get(k)
            if va != vb:
                diffs[k] = (va, vb)

        row_count_changed = "row_count" in diffs
        signal_changed = any(
            k.startswith(("sum_", "max_")) for k in diffs.keys() if k != "row_count"
        )

        if not diffs:
            verdict = "✅ unchanged"
        elif row_count_changed and signal_changed:
            verdict = "🔥 row count AND signal changed"
            n_changed += 1
            n_rows_changed += 1
        elif row_count_changed:
            verdict = "⚠️ row count changed"
            n_changed += 1
            n_rows_changed += 1
        elif signal_changed:
            verdict = "🔥 signal changed (row count same)"
            n_changed += 1
        else:
            verdict = "📝 metadata changed"
            n_changed += 1

        summary_rows.append((sid, verdict,
                              str(e["row_count"]), str(l["row_count"])))
        if diffs:
            detail_rows.append((sid, diffs))

    rep.append(f"**{len(summary_rows)} sources polled · "
               f"{n_changed} changed between early and late · "
               f"{n_rows_changed} had row-count drift.**")
    rep.append("")
    rep.append("| Source | Verdict | rows@early | rows@late |")
    rep.append("|---|---|---:|---:|")
    for sid, verdict, ea, la in summary_rows:
        rep.append(f"| `{sid}` | {verdict} | {ea} | {la} |")
    rep.append("")

    # Detail per changed source
    if detail_rows:
        rep.append("## Detailed changes (only sources that drifted)")
        rep.append("")
        for sid, diffs in detail_rows:
            e = early.get(sid, {})
            l = late.get(sid, {})
            rep.append(f"### `{sid}` — {e.get('source_label', '')}")
            rep.append("")
            rep.append(f"- scope: _{e.get('scope', '')}_")
            rep.append(f"- elapsed: early={e.get('elapsed_ms','?')}ms · late={l.get('elapsed_ms','?')}ms")
            rep.append("")
            rep.append("| field | early | late | delta |")
            rep.append("|---|---|---|---|")
            for k, (va, vb) in diffs.items():
                delta_s, _ = fmt_delta(va, vb)
                rep.append(f"| `{k}` | {fmt_val(va)} | {fmt_val(vb)} | {delta_s} |")
            rep.append("")
    else:
        rep.append("## Detailed changes")
        rep.append("")
        rep.append("_No sources drifted between the two polls. Every upstream returned identical fingerprints._")
        rep.append("")

    rep.append("---")
    rep.append("")
    rep.append("## How to interpret")
    rep.append("")
    rep.append("- If ALL non-target sources show ✅ between early and late, then the SP is reading "
               "a frozen set of date-partition snapshots and re-running it on the same `@Date` "
               "is *expected* to produce identical results.")
    rep.append("- If a source flips from ✅ to ⚠️/🔥, that source's `@DateID` partition is still being "
               "loaded after the early poll — re-running SP_Crypto_NOP after the upstream completes "
               "should produce different output.")
    rep.append("- The two `TARGET_*` rows are the SP's INSERT targets — they should match whichever "
               "SP_Crypto_NOP run wrote them last (see `SP_Crypto_NOP_run_history`).")
    rep.append("")

    rep_path = REPORT_DIR / f"{target_date.isoformat()}.md"
    rep_path.write_text("\n".join(rep), encoding="utf-8")
    print(f"Wrote {rep_path}", flush=True)

    # Append a one-line verdict to a rolling status log so you can grep
    # the whole watch period in a single file.
    status_path = HERE / "daily_status.log"
    poll_ts_early = next(iter(early.values()))["poll_at_utc"]
    poll_ts_late  = next(iter(late.values()))["poll_at_utc"]
    verdict_str   = "DRIFT" if n_changed > 0 else "OK"
    status_line = (
        f"{target_date.isoformat()}  verdict={verdict_str:<5}  "
        f"changed={n_changed:>2}/{len(summary_rows):<2}  "
        f"early={poll_ts_early}  late={poll_ts_late}  "
        f"report={rep_path.name}\n"
    )
    with status_path.open("a", encoding="utf-8") as fh:
        fh.write(status_line)
    print(f"Status: {status_line.rstrip()}", flush=True)

    # Copy to Downloads ONLY when drift is detected. Quiet days stay quiet so
    # the Downloads folder becomes a "needs attention" inbox.
    if args.copy_to_downloads and n_changed > 0:
        downloads = Path(os.environ.get("USERPROFILE", str(Path.home()))) / "Downloads"
        if downloads.exists():
            dest = downloads / f"ALERT_sp_crypto_nop_drift_{target_date.isoformat()}.md"
            shutil.copy2(rep_path, dest)
            print(f"DRIFT DETECTED — copied to {dest}", flush=True)
    elif args.copy_to_downloads:
        print(f"No drift — skipping Downloads copy (in-repo report still at {rep_path}).", flush=True)

    return 0


if __name__ == "__main__":
    sys.exit(main())
