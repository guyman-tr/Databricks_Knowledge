"""Load everything the author agent sees about one tile, from the
extracted workbook tiles.json + Synapse/UC live schema.

Inputs:
  - workbook tiles JSON path
  - sheet name (the "tile") + dashboard name
  - asof (single date, e.g. 2026-06-08)

Output: dict that gets dropped straight into the agent prompt.
"""
from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[3]


@dataclass
class TileContext:
    workbook_name: str
    workbook_luid: str
    dashboard_name: str
    sheet_name: str
    sheet_id: str
    asof: str
    datasource_name: str
    datasource_id: str | None
    datasource_fields: list[dict]
    custom_sql_body: str | None
    custom_sql_id: str | None
    sheet_field_instances: list[dict]
    sheet_worksheet_fields: list[dict]
    upstream_synapse_tables: list[str] = field(default_factory=list)
    notes: list[str] = field(default_factory=list)

    def to_prompt_dict(self) -> dict:
        return {
            "workbook": self.workbook_name,
            "dashboard": self.dashboard_name,
            "sheet": self.sheet_name,
            "asof": self.asof,
            "datasource": self.datasource_name,
            "custom_sql_body": self.custom_sql_body,
            "datasource_calc_fields": [
                {"name": f["name"], "formula": f["formula"]}
                for f in self.datasource_fields
                if f.get("kind") == "CalculatedField" and f.get("formula")
            ],
            "tile_field_instances": [
                {
                    "name": f["name"],
                    "kind": f["kind"],
                    "aggregation": f.get("aggregation") or None,
                    "formula": f.get("formula"),
                    "upstream_columns": [
                        c["name"] for c in (f.get("upstream_columns") or [])
                    ],
                }
                for f in self.sheet_field_instances
            ],
            "tile_worksheet_calc_fields": [
                {"name": f["name"], "formula": f["formula"]}
                for f in self.sheet_worksheet_fields
                if f.get("formula")
            ],
            "upstream_synapse_tables_referenced": self.upstream_synapse_tables,
        }


def _extract_synapse_tables(sql: str | None) -> list[str]:
    if not sql:
        return []
    pat = re.compile(r"\b(?:FROM|JOIN)\s+([\[\w]+\.[\[\w]+(?:\.[\[\w]+)?)", re.IGNORECASE)
    out: set[str] = set()
    for m in pat.finditer(sql):
        ref = m.group(1).replace("[", "").replace("]", "")
        out.add(ref)
    return sorted(out)


def load_tile(tiles_json: Path, dashboard_name: str, sheet_name: str, asof: str) -> TileContext:
    data = json.loads(tiles_json.read_text(encoding="utf-8"))

    target_sheet = next(
        (s for s in data["sheets"]
         if s["name"] == sheet_name and dashboard_name in (s.get("contained_in_dashboards") or [])),
        None,
    )
    if not target_sheet:
        target_sheet = next((s for s in data["sheets"] if s["name"] == sheet_name), None)
    if not target_sheet:
        raise SystemExit(f"sheet {sheet_name!r} not found in {tiles_json}")

    ds_id = (target_sheet.get("datasource_ids") or [None])[0]
    ds_name = (target_sheet.get("datasource_names") or [None])[0]
    ds = next((d for d in data["embedded_datasources"] if d["id"] == ds_id), None)
    ds_fields = (ds or {}).get("fields") or []

    custom_sql_body = None
    custom_sql_id = None
    if ds_name and "main ddr" in ds_name.lower():
        candidate = max(
            (c for c in data["custom_sql"] if c.get("sql")),
            key=lambda c: len(c["sql"]),
            default=None,
        )
        if candidate:
            custom_sql_body = candidate["sql"]
            custom_sql_id = candidate["id"]
    elif ds_name:
        for c in data["custom_sql"]:
            if (ds_name.lower() in (c.get("name") or "").lower()) and c.get("sql"):
                custom_sql_body = c["sql"]
                custom_sql_id = c["id"]
                break

    upstream_synapse = _extract_synapse_tables(custom_sql_body)

    return TileContext(
        workbook_name=data["name"],
        workbook_luid=data["luid"],
        dashboard_name=dashboard_name,
        sheet_name=sheet_name,
        sheet_id=target_sheet["id"],
        asof=asof,
        datasource_name=ds_name or "?",
        datasource_id=ds_id,
        datasource_fields=ds_fields,
        custom_sql_body=custom_sql_body,
        custom_sql_id=custom_sql_id,
        sheet_field_instances=target_sheet.get("field_instances") or [],
        sheet_worksheet_fields=target_sheet.get("worksheet_fields") or [],
        upstream_synapse_tables=upstream_synapse,
    )
