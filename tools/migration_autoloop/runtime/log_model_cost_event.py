#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[3]))

from tools.migration_autoloop.model_cost_ledger import append_model_cost_event


def main() -> int:
    ap = argparse.ArgumentParser(description="Append a model-cost ledger event.")
    ap.add_argument("--flow-id", required=True)
    ap.add_argument("--pipeline-name", default="DWH_Daily_Process_-_Entry_Point")
    ap.add_argument("--status", default="in_progress")
    ap.add_argument("--run-id", default="")
    ap.add_argument("--low", type=float, required=True)
    ap.add_argument("--mid", type=float, required=True)
    ap.add_argument("--high", type=float, required=True)
    ap.add_argument("--notes", default="")
    ap.add_argument("--evidence-path", default="")
    args = ap.parse_args()

    if not (args.low <= args.mid <= args.high):
        raise SystemExit("expected low <= mid <= high")

    ledger = Path("tools/migration_autoloop/runtime/model_cost_ledger.csv")
    append_model_cost_event(
        ledger,
        event_ts=dt.datetime.now(dt.timezone.utc).isoformat(),
        flow_id=args.flow_id.strip(),
        pipeline_name=args.pipeline_name.strip(),
        status=args.status.strip(),
        run_id=args.run_id.strip(),
        model_cost_usd_low=args.low,
        model_cost_usd_mid=args.mid,
        model_cost_usd_high=args.high,
        notes=args.notes,
        evidence_path=args.evidence_path,
    )
    print(str(ledger))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
