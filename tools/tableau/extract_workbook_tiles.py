"""Deep workbook extractor: sheets + dashboards + sheet-field placement.

Companion to `extract_workbook_metadata.py` — that one produces the
human-readable workbook.md (custom SQL bodies + calc-field formulas);
this one produces a structured JSON the loop-authoring agent consumes
to compose ground-truth SQL per tile.

Output: knowledge/tableau/_workbooks/<project>/<workbook>.tiles.json

Schema (one file per workbook):
{
  "luid": "...", "name": "...", "project": "...",
  "embedded_datasources": [
    {"id", "name", "has_extracts", "contains_unsupported_custom_sql",
     "upstream_database_tables": [{"id","name","fullName"}],
     "fields": [
        {"id","name","kind":"ColumnField"|"CalculatedField"|"DatasourceField"|...,
         "formula": str | null,
         "remote_field_name": str | null,
         "upstream_columns": [{"name","table_full_name"}]
        }, ...]
    }, ...
  ],
  "custom_sql": [
    {"id","name","is_unsupported","sql","downstream_workbooks":[...]}
  ],
  "dashboards": [
    {"id","name","sheet_ids":[...]}
  ],
  "sheets": [
    {"id","name","contained_in_dashboards":[name],
     "datasource_ids":[...],
     "field_instances":[
        {"id","name","kind","aggregation","formula",
         "upstream_columns":[{"name","table_full_name"}],
         "upstream_fields":[{"kind","name","formula"}]
        }, ...],
     "worksheet_fields":[{"id","name","kind","formula"}, ...]
    }, ...
  ]
}

Usage:
    python tools/tableau/extract_workbook_tiles.py --luid 9d8e103d-c4c7-41ac-9c6f-8b72a81c4e25
    python tools/tableau/extract_workbook_tiles.py --name "eToro's Daily Data Report (DDR)"
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))
from _lib import signin, gql  # noqa: E402

OUT_ROOT = REPO_ROOT / "knowledge" / "tableau" / "_workbooks"


# ---------- queries ----------------------------------------------------------

WB_QUERY = """
query w($luid: String!) {
  workbooks(filter: {luid: $luid}) {
    id luid name projectName updatedAt
    embeddedDatasources {
      id name hasExtracts containsUnsupportedCustomSql
      upstreamTables {
        __typename id name
        ... on DatabaseTable { fullName schema database { name } }
      }
      fields {
        __typename id name fullyQualifiedName isHidden
        ... on CalculatedField { formula }
        ... on ColumnField {
          aggregation
          columns { name table { __typename id name ... on DatabaseTable { fullName } } }
        }
        ... on DatasourceField {
          remoteField {
            __typename
            ... on ColumnField { name aggregation }
            ... on CalculatedField { name formula }
          }
        }
      }
    }
    dashboards {
      id name
      sheets { id name }
    }
    sheets {
      id name
      parentEmbeddedDatasources { id name }
      containedInDashboards { id name }
      worksheetFields { __typename id name formula }
      sheetFieldInstances {
        __typename id name fullyQualifiedName
        ... on CalculatedField { formula }
        ... on ColumnField {
          aggregation
          columns { name table { __typename id name ... on DatabaseTable { fullName } } }
        }
        ... on DatasourceField {
          remoteField {
            __typename
            ... on ColumnField {
              name aggregation
              columns { name table { __typename id name ... on DatabaseTable { fullName } } }
            }
            ... on CalculatedField { name formula }
          }
        }
        upstreamColumns { name table { __typename id name ... on DatabaseTable { fullName } } }
        upstreamFields {
          __typename
          ... on CalculatedField { name formula }
          ... on ColumnField { name aggregation }
        }
      }
    }
  }
}
"""

CUSTOM_SQL_FALLBACK = """
query csqls($first: Int!, $after: String) {
  customSQLTablesConnection(first: $first, after: $after) {
    pageInfo { hasNextPage endCursor }
    nodes {
      id name query isUnsupportedCustomSql
      database { name connectionType }
      tables { name fullName schema }
      downstreamWorkbooks { luid name }
    }
  }
}
"""

WORKBOOK_LOOKUP = """
query find($n: String) {
  workbooksConnection(filter: {name: $n}, first: 50) {
    nodes { luid name projectName }
  }
}
"""


# ---------- helpers ----------------------------------------------------------

def slug(value: str) -> str:
    s = re.sub(r"[^A-Za-z0-9._-]+", "_", value)
    return s.strip("_") or "unknown"


def first(coll, default=None):
    return (coll or [default])[0] if coll else default


def _flatten_field(f: dict) -> dict:
    """Project the GraphQL Field union to a flat dict."""
    kind = f.get("__typename")
    out = {
        "id": f.get("id"),
        "name": f.get("name"),
        "kind": kind,
        "fully_qualified_name": f.get("fullyQualifiedName"),
        "is_hidden": f.get("isHidden"),
        "aggregation": f.get("aggregation"),
        "formula": f.get("formula"),
        "columns": [],
        "upstream_columns": [],
        "upstream_fields": [],
        "remote_field": None,
    }
    for c in f.get("columns") or []:
        tbl = c.get("table") or {}
        out["columns"].append({
            "name": c.get("name"),
            "table_full_name": tbl.get("fullName"),
            "table_name": tbl.get("name"),
            "table_kind": tbl.get("__typename"),
        })
    for c in f.get("upstreamColumns") or []:
        tbl = c.get("table") or {}
        out["upstream_columns"].append({
            "name": c.get("name"),
            "table_full_name": tbl.get("fullName"),
            "table_name": tbl.get("name"),
            "table_kind": tbl.get("__typename"),
        })
    for uf in f.get("upstreamFields") or []:
        out["upstream_fields"].append({
            "kind": uf.get("__typename"),
            "name": uf.get("name"),
            "formula": uf.get("formula"),
            "aggregation": uf.get("aggregation"),
        })
    rf = f.get("remoteField") or {}
    if rf:
        out["remote_field"] = {
            "kind": rf.get("__typename"),
            "name": rf.get("name"),
            "aggregation": rf.get("aggregation"),
            "formula": rf.get("formula"),
        }
    return out


def _resolve_luid_by_name(server, name: str) -> str | None:
    data = gql(server, WORKBOOK_LOOKUP, {"n": name})
    nodes = ((data.get("workbooksConnection") or {}).get("nodes") or [])
    if not nodes:
        return None
    if len(nodes) > 1:
        print(f"WARN: {len(nodes)} workbooks named {name!r}; using the first")
    return nodes[0].get("luid")


def fetch_custom_sql_for_workbook(server, target_luid: str) -> list[dict]:
    """Fallback scan: customSQLTablesConnection isn't filterable in this server.
    Pull all (paginated), filter client-side."""
    out = []
    after = None
    while True:
        d = gql(server, CUSTOM_SQL_FALLBACK, {"first": 100, "after": after})
        conn = d.get("customSQLTablesConnection") or {}
        for n in conn.get("nodes") or []:
            for wb in n.get("downstreamWorkbooks") or []:
                if (wb or {}).get("luid") == target_luid:
                    out.append(n)
                    break
        page = conn.get("pageInfo") or {}
        if not page.get("hasNextPage"):
            break
        after = page.get("endCursor")
    return out


# ---------- main extraction --------------------------------------------------

def extract(server, luid: str) -> dict:
    print(f"querying workbook luid={luid} ...")
    data = gql(server, WB_QUERY, {"luid": luid})
    wbs = data.get("workbooks") or []
    if not wbs:
        raise SystemExit(f"workbook luid={luid} not found")
    wb = wbs[0]

    print(f"workbook: {wb.get('name')} ({len(wb.get('sheets') or [])} sheets, "
          f"{len(wb.get('dashboards') or [])} dashboards, "
          f"{len(wb.get('embeddedDatasources') or [])} datasources)")

    print("fetching custom-SQL bodies ...")
    csqls = fetch_custom_sql_for_workbook(server, luid)
    print(f"  found {len(csqls)} custom-SQL queries")

    out: dict = {
        "luid": luid,
        "name": wb.get("name"),
        "project": wb.get("projectName"),
        "updated_at": wb.get("updatedAt"),
        "embedded_datasources": [],
        "custom_sql": [],
        "dashboards": [],
        "sheets": [],
    }

    for ds in wb.get("embeddedDatasources") or []:
        out["embedded_datasources"].append({
            "id": ds.get("id"),
            "name": ds.get("name"),
            "has_extracts": ds.get("hasExtracts"),
            "contains_unsupported_custom_sql": ds.get("containsUnsupportedCustomSql"),
            "upstream_database_tables": [
                {"id": t.get("id"), "name": t.get("name"),
                 "full_name": t.get("fullName"), "schema": t.get("schema"),
                 "database": (t.get("database") or {}).get("name")}
                for t in (ds.get("upstreamTables") or [])
                if t.get("__typename") == "DatabaseTable"
            ],
            "fields": [_flatten_field(f) for f in (ds.get("fields") or [])],
        })

    for c in csqls:
        out["custom_sql"].append({
            "id": c.get("id"),
            "name": c.get("name"),
            "is_unsupported": c.get("isUnsupportedCustomSql"),
            "database_name": (c.get("database") or {}).get("name"),
            "connection_type": (c.get("database") or {}).get("connectionType"),
            "upstream_tables": [
                {"name": t.get("name"), "full_name": t.get("fullName"), "schema": t.get("schema")}
                for t in (c.get("tables") or [])
            ],
            "sql": c.get("query"),
        })

    for d in wb.get("dashboards") or []:
        out["dashboards"].append({
            "id": d.get("id"),
            "name": d.get("name"),
            "sheet_ids": [s.get("id") for s in (d.get("sheets") or [])],
            "sheet_names": [s.get("name") for s in (d.get("sheets") or [])],
        })

    for sh in wb.get("sheets") or []:
        out["sheets"].append({
            "id": sh.get("id"),
            "name": sh.get("name"),
            "datasource_ids": [d.get("id") for d in (sh.get("parentEmbeddedDatasources") or [])],
            "datasource_names": [d.get("name") for d in (sh.get("parentEmbeddedDatasources") or [])],
            "contained_in_dashboards": [d.get("name") for d in (sh.get("containedInDashboards") or [])],
            "field_instances": [_flatten_field(f) for f in (sh.get("sheetFieldInstances") or [])],
            "worksheet_fields": [_flatten_field(f) for f in (sh.get("worksheetFields") or [])],
        })

    return out


def write(out: dict) -> Path:
    project = out.get("project") or "_unknown"
    name = out.get("name") or "unknown"
    target = OUT_ROOT / slug(project) / f"{slug(name)}.tiles.json"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(out, indent=2, default=str), encoding="utf-8")
    return target


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--luid", help="workbook luid")
    ap.add_argument("--name", help="exact workbook name")
    args = ap.parse_args()
    if not args.luid and not args.name:
        sys.exit("Pass --luid or --name")

    server = signin()
    luid = args.luid
    if not luid:
        luid = _resolve_luid_by_name(server, args.name)
        if not luid:
            sys.exit(f"workbook named {args.name!r} not found")
        print(f"resolved {args.name!r} -> {luid}")

    out = extract(server, luid)
    target = write(out)
    print(f"\nwrote {target.relative_to(REPO_ROOT)}")
    n_sheets = len(out["sheets"])
    n_dashes = len(out["dashboards"])
    n_field_inst = sum(len(s["field_instances"]) for s in out["sheets"])
    n_csql = len(out["custom_sql"])
    print(f"  {n_dashes} dashboards, {n_sheets} sheets, "
          f"{n_field_inst} field instances, {n_csql} custom-SQL bodies")


if __name__ == "__main__":
    main()
