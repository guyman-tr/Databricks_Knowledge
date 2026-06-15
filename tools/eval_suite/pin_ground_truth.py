"""One-shot pinning pass: run each case's ground_truth_sql at its asof,
cache the result back into the YAML's `expected_value`.

Cases with `expected_value.type == "PENDING"` are pinned; existing pinned
values are skipped unless `--repin` is passed.

Auth: same path as `tools/dbx_query.py` and the Cursor MCP — WorkspaceClient
with profile DEFAULT (azure-cli auth, already cached). No popups.

Usage:
    python tools/eval_suite/pin_ground_truth.py
    python tools/eval_suite/pin_ground_truth.py --only ddr
    python tools/eval_suite/pin_ground_truth.py --repin
    python tools/eval_suite/pin_ground_truth.py --case-id ddr__ddr_revenue_v__total_revenue_total
"""
from __future__ import annotations

import argparse
import sys
import time
from decimal import Decimal
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
CASES_DIR = HERE / "cases"

sys.path.insert(0, str(HERE))
from dbx import make_client, run_sql  # noqa: E402


def _coerce_value(v):
    if isinstance(v, Decimal):
        return float(v)
    if hasattr(v, "isoformat"):
        return v.isoformat()
    if isinstance(v, str):
        # Statement Execution API returns numbers as strings sometimes
        try:
            if "." in v or "e" in v.lower():
                return float(v)
            return int(v)
        except (ValueError, TypeError):
            return v
    return v


def _summarize_rows(rows, columns) -> dict:
    if not rows:
        return {"type": "numeric", "value": None, "tolerance_pct": 0.5,
                "_meta": "empty result"}
    if len(rows) == 1 and len(rows[0]) == 1:
        return {"type": "numeric", "value": _coerce_value(rows[0][0]), "tolerance_pct": 0.5}
    if len(columns) == 2 and all(len(r) == 2 for r in rows):
        series = [[_coerce_value(r[0]), _coerce_value(r[1])] for r in rows]
        return {"type": "numeric_series", "value": series, "tolerance_pct": 0.5}
    return {
        "type": "tabular",
        "value": [[_coerce_value(c) for c in r] for r in rows],
        "columns": list(columns),
        "tolerance_pct": 0.5,
    }


def _select_cases(only: str | None, case_id: str | None, repin: bool) -> list[Path]:
    files = sorted(CASES_DIR.glob("*.yaml"))
    out: list[Path] = []
    for f in files:
        if case_id and f.stem != case_id:
            continue
        try:
            doc = yaml.safe_load(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        if only and not str(doc.get("source", "")).startswith(only):
            continue
        ev_type = (doc.get("expected_value") or {}).get("type")
        if ev_type and ev_type != "PENDING" and not repin:
            continue
        out.append(f)
    return out


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", help="restrict to source prefix (ddr | tableau | genie | known_failure)")
    parser.add_argument("--case-id", help="pin a single case by id")
    parser.add_argument("--repin", action="store_true", help="re-run even if expected_value already set")
    parser.add_argument("--profile", default=None)
    parser.add_argument("--warehouse-id", default=None)
    parser.add_argument("--max-rows", type=int, default=10000)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    cases = _select_cases(args.only, args.case_id, args.repin)
    if not cases:
        print("[pin] no cases to pin (everything already has expected_value, or filter excluded all)")
        return 0
    print(f"[pin] {len(cases)} cases to pin")

    if args.dry_run:
        for c in cases:
            print(f"[pin] DRY {c.name}")
        return 0

    print(f"[pin] connecting via WorkspaceClient (profile={args.profile or 'DEFAULT'})")
    w = make_client(profile=args.profile)
    pinned = failed = skipped = 0
    for path in cases:
        doc = yaml.safe_load(path.read_text(encoding="utf-8"))
        sql = (doc.get("ground_truth_sql") or "").strip()
        if not sql:
            print(f"[pin] {path.name}: empty SQL, skipping")
            skipped += 1
            continue
        t0 = time.time()
        try:
            qr = run_sql(w, sql, warehouse_id=args.warehouse_id)
        except Exception as e:
            msg = str(e).splitlines()[0][:160]
            print(f"[pin] {path.name}: FAIL ({time.time()-t0:.1f}s) {msg}")
            doc.setdefault("notes", "")
            doc["notes"] = (doc["notes"] + "\n[pin error] " + msg).strip()
            path.write_text(yaml.safe_dump(doc, sort_keys=False, allow_unicode=True), encoding="utf-8")
            failed += 1
            continue
        rows = qr.rows[: args.max_rows]
        ev = _summarize_rows(rows, qr.columns)
        old_tol = (doc.get("expected_value") or {}).get("tolerance_pct")
        if old_tol is not None:
            ev["tolerance_pct"] = old_tol
        doc["expected_value"] = ev
        path.write_text(yaml.safe_dump(doc, sort_keys=False, allow_unicode=True), encoding="utf-8")
        preview = str(ev.get("value"))[:80]
        print(f"[pin] {path.name}: OK ({time.time()-t0:.1f}s) -> {ev['type']}={preview}")
        pinned += 1

    print(f"\n[pin] pinned={pinned} failed={failed} skipped={skipped}")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
