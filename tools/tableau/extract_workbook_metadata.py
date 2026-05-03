"""Extract custom SQL + embedded datasources + calculated fields for one or more
Tableau workbooks (workbook-first; complement to extract_table_metadata.py).

Usage
-----
By workbook luid:
    python tools/tableau/extract_workbook_metadata.py --luids 9d8e103d-c4c7-41ac-9c6f-8b72a81c4e25

By exact name (will match all workbooks with that name across projects):
    python tools/tableau/extract_workbook_metadata.py --name "eToro's Daily Data Report (DDR)"

By project name (extract every workbook in the project):
    python tools/tableau/extract_workbook_metadata.py --project "DDR's"

Output
------
Per workbook -> knowledge/tableau/_workbooks/<project_slug>/<workbook_slug>.md
Index lines appended to knowledge/tableau/_workbooks/_index/run_log.jsonl.
"""
from __future__ import annotations

import argparse
import datetime
import json
import os
import re
import sys
import uuid
import warnings
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import urllib3
import jwt
import tableauserverclient as tsc
from dotenv import load_dotenv

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
HERE = Path(__file__).resolve().parent
load_dotenv(HERE / ".env")
warnings.filterwarnings("ignore")
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

OUT_ROOT = REPO_ROOT / "knowledge" / "tableau" / "_workbooks"


# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------
def _env(name: str) -> str:
    val = os.getenv(name, "")
    if not val:
        raise SystemExit(f"Missing env var: {name}")
    return val


def make_jwt() -> str:
    now = datetime.datetime.now(datetime.timezone.utc)
    return jwt.encode(
        {
            "iss": _env("TABLEAU_CLIENT_ID"),
            "exp": now + datetime.timedelta(minutes=10),
            "jti": str(uuid.uuid4()),
            "aud": "tableau",
            "sub": _env("TABLEAU_USERNAME"),
            "scp": ["tableau:content:*"],
        },
        _env("TABLEAU_SECRET_VALUE"),
        algorithm="HS256",
        headers={"kid": _env("TABLEAU_SECRET_ID"), "iss": _env("TABLEAU_CLIENT_ID")},
    )


def sign_in() -> tsc.Server:
    server = tsc.Server(_env("TABLEAU_SERVER").rstrip("/"), use_server_version=True, http_options={"verify": False})
    server.auth.sign_in(tsc.JWTAuth(make_jwt(), site_id=os.getenv("TABLEAU_SITE_NAME", "")))
    return server


# ---------------------------------------------------------------------------
# Discovery (resolve target luids)
# ---------------------------------------------------------------------------
def list_workbooks(server: tsc.Server, *, project: Optional[str], name: Optional[str]) -> List[Dict[str, Any]]:
    if project:
        q = """
        query wbs($p: String!) {
          workbooksConnection(filter: {projectName: $p}, first: 200) {
            nodes { luid name projectName updatedAt owner { name username } }
          }
        }
        """
        resp = server.metadata.query(q, variables={"p": project})
    elif name:
        q = """
        query wbs($n: String!) {
          workbooksConnection(filter: {name: $n}, first: 50) {
            nodes { luid name projectName updatedAt owner { name username } }
          }
        }
        """
        resp = server.metadata.query(q, variables={"n": name})
    else:
        return []
    return ((resp.get("data") or {}).get("workbooksConnection") or {}).get("nodes") or []


# ---------------------------------------------------------------------------
# Workbook detail query
# ---------------------------------------------------------------------------
WORKBOOK_DETAIL = """
query wb($luid: String!) {
  workbooks(filter: {luid: $luid}) {
    luid
    name
    projectName
    updatedAt
    owner { name username }
    upstreamTables {
      __typename
      name
      fullName
      schema
      connectionType
      database { name }
    }
    embeddedDatasources {
      id
      name
      hasExtracts
      upstreamTables {
        name
        fullName
        schema
        connectionType
        database { name }
      }
      upstreamDatabases { name connectionType }
      fields {
        __typename
        id
        name
        ... on CalculatedField {
          formula
        }
      }
    }
  }
}
"""

CUSTOM_SQL_FOR_WORKBOOK = """
query csqls($luid: String!) {
  customSQLTablesConnection(filter: {downstreamWorkbooksLuidWithin: [$luid]}, first: 200) {
    totalCount
    nodes {
      id
      name
      query
      isUnsupportedCustomSql
      database { name connectionType }
      tables { name fullName schema }
      downstreamWorkbooks(filter: {luid: $luid}) { luid name }
    }
  }
}
"""

# Some Tableau Server versions don't have downstreamWorkbooksLuidWithin - fall back filter
CUSTOM_SQL_FALLBACK = """
query csqls {
  customSQLTablesConnection(first: 1000) {
    nodes {
      id
      name
      query
      isUnsupportedCustomSql
      database { name connectionType }
      tables { name fullName schema }
      downstreamWorkbooks { luid name projectName }
    }
  }
}
"""


def fetch_workbook(server: tsc.Server, luid: str) -> Optional[Dict[str, Any]]:
    resp = server.metadata.query(WORKBOOK_DETAIL, variables={"luid": luid})
    for e in resp.get("errors") or []:
        code = (e.get("extensions") or {}).get("code")
        if code != "PERMISSIONS_MODE_SWITCHED":
            print(f"  GraphQL: [{code}] {e.get('message')}")
    wbs = (resp.get("data") or {}).get("workbooks") or []
    return wbs[0] if wbs else None


def fetch_custom_sql_for_workbook(server: tsc.Server, luid: str) -> Tuple[List[Dict[str, Any]], str]:
    """Returns (rows, mode) where mode is 'native_filter' or 'fallback_scan'."""
    try:
        resp = server.metadata.query(CUSTOM_SQL_FOR_WORKBOOK, variables={"luid": luid})
        errs = resp.get("errors") or []
        # If the server rejects the filter shape, fall through to fallback
        validation_err = any(
            "Validation error" in (e.get("message") or "") or "WrongType" in (e.get("message") or "")
            for e in errs
        )
        if not validation_err:
            for e in errs:
                code = (e.get("extensions") or {}).get("code")
                if code != "PERMISSIONS_MODE_SWITCHED":
                    print(f"  CustomSQL GraphQL: [{code}] {e.get('message')}")
            nodes = (((resp.get("data") or {}).get("customSQLTablesConnection") or {}).get("nodes")) or []
            return nodes, "native_filter"
    except Exception as exc:  # noqa: BLE001
        print(f"  Native filter failed: {type(exc).__name__}: {exc}")

    # Fallback: scan ALL custom SQL tables and filter client-side by downstream workbook luid
    print("  Falling back to full scan of customSQLTablesConnection...")
    resp = server.metadata.query(CUSTOM_SQL_FALLBACK)
    nodes_all = (((resp.get("data") or {}).get("customSQLTablesConnection") or {}).get("nodes")) or []
    out: List[Dict[str, Any]] = []
    for n in nodes_all:
        for wb in n.get("downstreamWorkbooks") or []:
            if (wb or {}).get("luid") == luid:
                out.append(n)
                break
    return out, "fallback_scan"


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
def slug(value: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9._-]+", "_", value)
    return cleaned.strip("_") or "unknown"


def write_workbook_markdown(wb: Dict[str, Any], custom_sql: List[Dict[str, Any]], mode: str) -> Path:
    project = wb.get("projectName") or "_unknown_project"
    out_path = OUT_ROOT / slug(project) / f"{slug(wb['name'])}.md"
    out_path.parent.mkdir(parents=True, exist_ok=True)

    owner = (wb.get("owner") or {}).get("name") or (wb.get("owner") or {}).get("username") or "?"
    upstream_tables = wb.get("upstreamTables") or []
    embedded = wb.get("embeddedDatasources") or []

    lines: List[str] = []
    lines.append(f"# Tableau Workbook — {wb['name']}")
    lines.append("")
    lines.append("> Generated by `tools/tableau/extract_workbook_metadata.py`. Do not edit by hand.")
    lines.append("")
    lines.append("## Identity")
    lines.append("")
    lines.append(f"- Workbook luid: `{wb.get('luid')}`")
    lines.append(f"- Project: `{project}`")
    lines.append(f"- Owner: {owner}")
    lines.append(f"- Last updated: {wb.get('updatedAt')}")
    lines.append(f"- Custom-SQL retrieval mode: `{mode}`")
    lines.append("")

    lines.append("## Summary")
    lines.append("")
    lines.append(f"- Custom SQL tables: **{len(custom_sql)}**")
    lines.append(f"- Embedded datasources: **{len(embedded)}**")
    lines.append(f"- Distinct upstream tables: **{len({(t.get('fullName') or t.get('name')) for t in upstream_tables})}**")
    lines.append("")

    lines.append("## Upstream tables (from workbook.upstreamTables)")
    lines.append("")
    if not upstream_tables:
        lines.append("_None._")
    else:
        lines.append("| # | Full Name | Schema | Database | Connection |")
        lines.append("|---|---|---|---|---|")
        for i, t in enumerate(upstream_tables, start=1):
            db = (t.get("database") or {}).get("name") or ""
            lines.append(
                f"| {i} | `{t.get('fullName') or t.get('name') or ''}` | "
                f"{t.get('schema') or ''} | {db} | {t.get('connectionType') or ''} |"
            )
    lines.append("")

    lines.append("## Custom SQL queries used by this workbook")
    lines.append("")
    if not custom_sql:
        lines.append("_No custom SQL tables found for this workbook._")
    else:
        for i, q in enumerate(custom_sql, start=1):
            db_name = (q.get("database") or {}).get("name") or ""
            db_ct = (q.get("database") or {}).get("connectionType") or ""
            tables_used = ", ".join(
                sorted({(t.get("fullName") or t.get("name") or "") for t in (q.get("tables") or [])})
            )
            lines.append(f"### {i}. {q.get('name') or '<unnamed query>'}")
            lines.append("")
            lines.append(f"- Tableau id: `{q.get('id')}`")
            lines.append(f"- Database: `{db_name}` ({db_ct})")
            lines.append(f"- Tables referenced: {tables_used or '<none>'}")
            if q.get("isUnsupportedCustomSql"):
                lines.append(f"- **NOTE**: marked `isUnsupportedCustomSql=True` by Tableau")
            lines.append("")
            lines.append("```sql")
            lines.append((q.get("query") or "-- empty query").rstrip())
            lines.append("```")
            lines.append("")

    lines.append("## Embedded datasources (with calculated fields)")
    lines.append("")
    if not embedded:
        lines.append("_None._")
    else:
        for ds in embedded:
            lines.append(f"### Datasource: {ds.get('name') or '<unnamed>'}")
            lines.append("")
            lines.append(f"- Datasource id: `{ds.get('id')}`")
            lines.append(f"- Has extracts: {ds.get('hasExtracts')}")
            ups = ds.get("upstreamTables") or []
            if ups:
                lines.append("- Upstream tables in this datasource:")
                for t in ups:
                    db = (t.get("database") or {}).get("name") or ""
                    lines.append(f"  - `{t.get('fullName') or t.get('name')}` ({db}, {t.get('connectionType') or ''})")
            lines.append("")
            calc = [f for f in (ds.get("fields") or []) if f.get("__typename") == "CalculatedField"]
            if calc:
                lines.append(f"#### Calculated fields ({len(calc)})")
                lines.append("")
                for f in sorted(calc, key=lambda x: (x.get("name") or "").lower()):
                    lines.append(f"- **{f.get('name') or '<unnamed>'}**")
                    lines.append("")
                    lines.append("  ```")
                    formula = (f.get("formula") or "<empty formula>")
                    lines.append("  " + formula.replace("\n", "\n  "))
                    lines.append("  ```")
                    lines.append("")
            else:
                lines.append("_(no calculated fields)_")
                lines.append("")

    out_path.write_text("\n".join(lines), encoding="utf-8")
    return out_path


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def main() -> int:
    p = argparse.ArgumentParser(description="Extract Tableau workbook metadata (custom SQL + calc fields)")
    p.add_argument("--luids", type=str, default="", help="Comma-separated workbook luids")
    p.add_argument("--name", type=str, default="", help="Workbook name (exact match)")
    p.add_argument("--project", type=str, default="", help="Project name (extract all workbooks in project)")
    args = p.parse_args()

    server = sign_in()
    print("Signed in to Tableau.")

    targets: List[Dict[str, Any]] = []
    try:
        if args.luids:
            for l in args.luids.split(","):
                l = l.strip()
                if l:
                    targets.append({"luid": l, "name": "(by luid)", "projectName": "?"})
        if args.name or args.project:
            found = list_workbooks(server, project=args.project or None, name=args.name or None)
            for wb in found:
                if wb["luid"] not in {t["luid"] for t in targets}:
                    targets.append(wb)

        if not targets:
            print("No targets. Provide --luids, --name, or --project.")
            return 2

        OUT_ROOT.mkdir(parents=True, exist_ok=True)
        log_path = OUT_ROOT / "_index" / "run_log.jsonl"
        log_path.parent.mkdir(parents=True, exist_ok=True)
        started_at = datetime.datetime.now(datetime.timezone.utc).isoformat()

        for i, t in enumerate(targets, start=1):
            luid = t["luid"]
            print(f"\n[{i}/{len(targets)}] luid={luid} ({t.get('name')})")
            wb = fetch_workbook(server, luid)
            if not wb:
                print("  No workbook returned.")
                with log_path.open("a", encoding="utf-8") as fh:
                    fh.write(json.dumps({"started_at": started_at, "luid": luid, "status": "not_found"}) + "\n")
                continue
            csql, mode = fetch_custom_sql_for_workbook(server, luid)
            out = write_workbook_markdown(wb, csql, mode)
            with log_path.open("a", encoding="utf-8") as fh:
                fh.write(
                    json.dumps(
                        {
                            "started_at": started_at,
                            "luid": luid,
                            "name": wb.get("name"),
                            "project": wb.get("projectName"),
                            "custom_sql_count": len(csql),
                            "datasources": len(wb.get("embeddedDatasources") or []),
                            "upstream_tables": len(wb.get("upstreamTables") or []),
                            "mode": mode,
                            "output": str(out.relative_to(REPO_ROOT)),
                        }
                    )
                    + "\n"
                )
            print(
                f"  OK  custom_sql={len(csql)}  datasources={len(wb.get('embeddedDatasources') or [])}  "
                f"upstream={len(wb.get('upstreamTables') or [])}  -> {out.relative_to(REPO_ROOT)}"
            )
    finally:
        try:
            server.auth.sign_out()
        except Exception:  # noqa: BLE001
            pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
