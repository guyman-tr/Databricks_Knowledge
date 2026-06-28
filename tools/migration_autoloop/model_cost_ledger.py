#!/usr/bin/env python3
"""Model-only cost ledger helpers for migration flows."""
from __future__ import annotations

import csv
from pathlib import Path
from typing import Any

MODEL_COST_FIELDS = [
    "event_ts",
    "flow_id",
    "pipeline_name",
    "status",
    "run_id",
    "model_cost_usd_low",
    "model_cost_usd_mid",
    "model_cost_usd_high",
    "notes",
    "evidence_path",
]


def append_model_cost_event(
    ledger_csv: Path,
    *,
    event_ts: str,
    flow_id: str,
    pipeline_name: str,
    status: str,
    run_id: str,
    model_cost_usd_low: float,
    model_cost_usd_mid: float,
    model_cost_usd_high: float,
    notes: str,
    evidence_path: str,
) -> None:
    row: dict[str, Any] = {
        "event_ts": event_ts,
        "flow_id": flow_id,
        "pipeline_name": pipeline_name,
        "status": status,
        "run_id": run_id,
        "model_cost_usd_low": f"{model_cost_usd_low:.2f}",
        "model_cost_usd_mid": f"{model_cost_usd_mid:.2f}",
        "model_cost_usd_high": f"{model_cost_usd_high:.2f}",
        "notes": notes.strip(),
        "evidence_path": evidence_path.strip(),
    }
    ledger_csv.parent.mkdir(parents=True, exist_ok=True)
    write_header = not ledger_csv.exists()
    with ledger_csv.open("a", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=MODEL_COST_FIELDS)
        if write_header:
            writer.writeheader()
        writer.writerow(row)
