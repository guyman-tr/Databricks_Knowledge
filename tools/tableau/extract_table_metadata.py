"""Extract Tableau usage (custom SQL + downstream calc fields + workbooks)
for one or more database tables, and write a per-table markdown knowledge file
plus CSV indices.

Usage examples
--------------
Single table:
    python tools/tableau/extract_table_metadata.py \
        --tables BI_DB_DDR_Customer_Daily_Status

Multiple tables (comma-separated):
    python tools/tableau/extract_table_metadata.py \
        --tables BI_DB_Airdrop_Data,Fact_Deposit_State

From a file (one table name per line, blank lines / # comments allowed):
    python tools/tableau/extract_table_metadata.py \
        --tables-file pilots.txt

Output
------
- knowledge/tableau/<DB>_<schema>/<TableName>.md     per-table markdown
- knowledge/tableau/_index/custom_sql.csv            one row per (table, query)
- knowledge/tableau/_index/calc_fields.csv           one row per (table, calc field)
- knowledge/tableau/_index/workbooks.csv             one row per (table, workbook)
- knowledge/tableau/_index/run_log.jsonl             per-run summary line per table
"""
from __future__ import annotations

import argparse
import csv
import datetime
import json
import os
import re
import sys
import uuid
import warnings
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Set, Tuple

import urllib3
import jwt
import tableauserverclient as tsc
from dotenv import load_dotenv

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
HERE = Path(__file__).resolve().parent
load_dotenv(HERE / ".env")

warnings.filterwarnings("ignore")
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

KNOWLEDGE_ROOT = REPO_ROOT / "knowledge" / "tableau"
INDEX_DIR = KNOWLEDGE_ROOT / "_index"

DEFAULT_ALLOWED_CONNECTIONS = {
    "azure_sql_dw",
    "azure_sql_database",
    "databricks",
    "databricks_v2",
    "sqlserver",
}

GRAPHQL_QUERY = """
query tables($tableName: String!) {
  databaseTablesConnection(filter: {name: $tableName}) {
    totalCount
    nodes {
      __typename
      id
      name
      fullName
      schema
      connectionType
      database { name connectionType }
      referencedByQueries {
        __typename
        id
        name
        query
      }
      downstreamWorkbooks {
        __typename
        id
        luid
        name
        projectName
        updatedAt
        owner { username name }
        embeddedDatasources {
          id
          name
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
  }
}
"""


# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------
def _env(name: str) -> str:
    val = os.getenv(name, "")
    if not val:
        raise SystemExit(f"Missing env var: {name}")
    return val


def make_jwt(client_id: str, secret_id: str, secret_value: str, username: str) -> str:
    now = datetime.datetime.now(datetime.timezone.utc)
    payload = {
        "iss": client_id,
        "exp": now + datetime.timedelta(minutes=10),
        "jti": str(uuid.uuid4()),
        "aud": "tableau",
        "sub": username,
        "scp": ["tableau:content:*"],
    }
    headers = {"kid": secret_id, "iss": client_id}
    return jwt.encode(payload, secret_value, algorithm="HS256", headers=headers)


def sign_in() -> tsc.Server:
    server_url = _env("TABLEAU_SERVER").rstrip("/")
    client_id = _env("TABLEAU_CLIENT_ID")
    secret_id = _env("TABLEAU_SECRET_ID")
    secret_value = _env("TABLEAU_SECRET_VALUE")
    username = _env("TABLEAU_USERNAME")
    site = os.getenv("TABLEAU_SITE_NAME", "")

    token = make_jwt(client_id, secret_id, secret_value, username)
    server = tsc.Server(server_url, use_server_version=True, http_options={"verify": False})
    server.auth.sign_in(tsc.JWTAuth(token, site_id=site))
    return server


# ---------------------------------------------------------------------------
# Extraction
# ---------------------------------------------------------------------------
def fetch_table_nodes(server: tsc.Server, table_name: str) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    resp = server.metadata.query(GRAPHQL_QUERY, variables={"tableName": table_name})
    errors = resp.get("errors") or []
    nodes = (resp.get("data") or {}).get("databaseTablesConnection", {}).get("nodes") or []
    return nodes, errors


def filter_nodes(
    nodes: List[Dict[str, Any]],
    table_name: str,
    allowed_connections: Optional[Set[str]],
) -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    for node in nodes:
        if str(node.get("name") or "") != table_name:
            continue
        ct = str(node.get("connectionType") or "").lower()
        if allowed_connections is not None and ct not in allowed_connections:
            continue
        out.append(node)
    return out


def collect_custom_sql(nodes: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    seen: Set[Tuple[str, str]] = set()
    for node in nodes:
        for q in node.get("referencedByQueries") or []:
            qid = str(q.get("id") or "")
            qtext = str(q.get("query") or "")
            key = (qid, qtext)
            if key in seen:
                continue
            seen.add(key)
            rows.append(
                {
                    "id": qid,
                    "name": q.get("name") or "",
                    "query": qtext,
                }
            )
    return rows


def collect_workbooks(nodes: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    seen: Set[str] = set()
    for node in nodes:
        for wb in node.get("downstreamWorkbooks") or []:
            wid = str(wb.get("id") or "")
            if wid in seen:
                continue
            seen.add(wid)
            owner = wb.get("owner") or {}
            rows.append(
                {
                    "id": wid,
                    "luid": wb.get("luid") or "",
                    "name": wb.get("name") or "",
                    "projectName": wb.get("projectName") or "",
                    "owner": owner.get("name") or owner.get("username") or "",
                    "updatedAt": wb.get("updatedAt") or "",
                }
            )
    rows.sort(key=lambda r: (r["projectName"].lower(), r["name"].lower()))
    return rows


def collect_calc_fields(nodes: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    seen: Set[Tuple[str, str, str]] = set()
    for node in nodes:
        for wb in node.get("downstreamWorkbooks") or []:
            wb_name = wb.get("name") or ""
            for ds in wb.get("embeddedDatasources") or []:
                ds_name = ds.get("name") or ""
                for f in ds.get("fields") or []:
                    if f.get("__typename") != "CalculatedField":
                        continue
                    name = f.get("name") or ""
                    formula = f.get("formula") or ""
                    key = (wb_name, ds_name, name + "::" + formula)
                    if key in seen:
                        continue
                    seen.add(key)
                    rows.append(
                        {
                            "id": f.get("id") or "",
                            "name": name,
                            "formula": formula,
                            "workbookName": wb_name,
                            "datasourceName": ds_name,
                        }
                    )
    rows.sort(key=lambda r: (r["workbookName"].lower(), r["datasourceName"].lower(), r["name"].lower()))
    return rows


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
def slug(value: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9._-]+", "_", value)
    return cleaned.strip("_") or "unknown"


def write_table_markdown(
    out_path: Path,
    table_name: str,
    primary_node: Dict[str, Any],
    custom_sql: List[Dict[str, Any]],
    workbooks: List[Dict[str, Any]],
    calc_fields: List[Dict[str, Any]],
    other_nodes: List[Dict[str, Any]],
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)

    db = (primary_node.get("database") or {}).get("name") or ""
    db_ct = (primary_node.get("database") or {}).get("connectionType") or ""
    schema = primary_node.get("schema") or ""
    full_name = primary_node.get("fullName") or ""
    table_id = primary_node.get("id") or ""
    ct = primary_node.get("connectionType") or ""

    lines: List[str] = []
    lines.append(f"# Tableau Usage — {table_name}")
    lines.append("")
    lines.append("> Generated by `tools/tableau/extract_table_metadata.py`. Do not edit by hand.")
    lines.append("")
    lines.append("## Identity")
    lines.append("")
    lines.append(f"- Full name: `{full_name}`")
    lines.append(f"- Database: `{db}` ({db_ct})")
    lines.append(f"- Schema: `{schema}`")
    lines.append(f"- Connection type: `{ct}`")
    lines.append(f"- Tableau metadata id: `{table_id}`")
    if other_nodes:
        lines.append(f"- Other matching nodes (different connections): {len(other_nodes)}")
    lines.append("")
    lines.append("## Summary")
    lines.append("")
    lines.append(f"- Custom SQL queries: **{len(custom_sql)}**")
    lines.append(f"- Downstream workbooks: **{len(workbooks)}**")
    lines.append(f"- Downstream calculated fields: **{len(calc_fields)}**")
    lines.append("")

    lines.append("## Custom SQL queries referencing this table")
    lines.append("")
    if not custom_sql:
        lines.append("_None._")
    else:
        for i, q in enumerate(custom_sql, start=1):
            lines.append(f"### {i}. {q['name'] or '<unnamed query>'}")
            lines.append("")
            lines.append(f"- Tableau id: `{q['id']}`")
            lines.append("")
            lines.append("```sql")
            lines.append((q["query"] or "-- empty query").rstrip())
            lines.append("```")
            lines.append("")

    lines.append("## Downstream workbooks")
    lines.append("")
    if not workbooks:
        lines.append("_None._")
    else:
        lines.append("| # | Workbook | Project | Owner | Last updated | Tableau id |")
        lines.append("|---|---|---|---|---|---|")
        for i, wb in enumerate(workbooks, start=1):
            lines.append(
                f"| {i} | {wb['name']} | {wb['projectName']} | {wb['owner']} | "
                f"{wb['updatedAt']} | `{wb['id']}` |"
            )
    lines.append("")

    lines.append("## Downstream calculated fields (in embedded datasources)")
    lines.append("")
    if not calc_fields:
        lines.append("_None._")
    else:
        last_wb: Optional[str] = None
        last_ds: Optional[str] = None
        for f in calc_fields:
            wb = f["workbookName"]
            ds = f["datasourceName"]
            if wb != last_wb:
                lines.append(f"### Workbook: {wb}")
                lines.append("")
                last_wb = wb
                last_ds = None
            if ds != last_ds:
                lines.append(f"#### Datasource: {ds}")
                lines.append("")
                last_ds = ds
            lines.append(f"- **{f['name'] or '<unnamed>'}**")
            lines.append("")
            lines.append("  ```")
            lines.append("  " + (f["formula"] or "<empty formula>").replace("\n", "\n  "))
            lines.append("  ```")
            lines.append("")

    out_path.write_text("\n".join(lines), encoding="utf-8")


# ---------------------------------------------------------------------------
# Index writers (append-only, dedup by composite key)
# ---------------------------------------------------------------------------
class IndexWriters:
    def __init__(self, root: Path) -> None:
        root.mkdir(parents=True, exist_ok=True)
        self.custom_sql_path = root / "custom_sql.csv"
        self.calc_fields_path = root / "calc_fields.csv"
        self.workbooks_path = root / "workbooks.csv"
        self.run_log_path = root / "run_log.jsonl"

        self._init_csv(
            self.custom_sql_path,
            ["table", "table_full_name", "query_id", "query_name", "query_chars"],
        )
        self._init_csv(
            self.calc_fields_path,
            ["table", "table_full_name", "workbook", "datasource", "field_name", "formula_chars"],
        )
        self._init_csv(
            self.workbooks_path,
            ["table", "table_full_name", "workbook_id", "workbook_name", "project", "owner", "updated_at"],
        )

    @staticmethod
    def _init_csv(path: Path, headers: List[str]) -> None:
        if not path.exists():
            with path.open("w", encoding="utf-8", newline="") as fh:
                csv.writer(fh).writerow(headers)

    def write(
        self,
        table: str,
        table_full_name: str,
        custom_sql: List[Dict[str, Any]],
        workbooks: List[Dict[str, Any]],
        calc_fields: List[Dict[str, Any]],
    ) -> None:
        with self.custom_sql_path.open("a", encoding="utf-8", newline="") as fh:
            w = csv.writer(fh)
            for q in custom_sql:
                w.writerow([table, table_full_name, q["id"], q["name"], len(q["query"] or "")])
        with self.workbooks_path.open("a", encoding="utf-8", newline="") as fh:
            w = csv.writer(fh)
            for wb in workbooks:
                w.writerow(
                    [
                        table,
                        table_full_name,
                        wb["id"],
                        wb["name"],
                        wb["projectName"],
                        wb["owner"],
                        wb["updatedAt"],
                    ]
                )
        with self.calc_fields_path.open("a", encoding="utf-8", newline="") as fh:
            w = csv.writer(fh)
            for f in calc_fields:
                w.writerow(
                    [
                        table,
                        table_full_name,
                        f["workbookName"],
                        f["datasourceName"],
                        f["name"],
                        len(f["formula"] or ""),
                    ]
                )

    def log_run(self, payload: Dict[str, Any]) -> None:
        with self.run_log_path.open("a", encoding="utf-8") as fh:
            fh.write(json.dumps(payload, ensure_ascii=False) + "\n")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def parse_tables_arg(args: argparse.Namespace) -> List[str]:
    tables: List[str] = []
    if args.tables:
        for t in args.tables.split(","):
            t = t.strip()
            if t and t not in tables:
                tables.append(t)
    if args.tables_file:
        path = Path(args.tables_file)
        if not path.is_absolute():
            path = REPO_ROOT / path
        for raw in path.read_text(encoding="utf-8").splitlines():
            t = raw.strip()
            if not t or t.startswith("#"):
                continue
            if t not in tables:
                tables.append(t)
    if not tables:
        raise SystemExit("Provide --tables or --tables-file with at least one table name.")
    return tables


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract Tableau metadata for database tables")
    parser.add_argument("--tables", type=str, default="", help="Comma-separated list of table names")
    parser.add_argument("--tables-file", type=str, default="", help="Path to file with one table name per line")
    parser.add_argument(
        "--all-connections",
        action="store_true",
        help="Skip the connection-type filter (return matches for any connection type)",
    )
    parser.add_argument(
        "--connections",
        type=str,
        default=",".join(sorted(DEFAULT_ALLOWED_CONNECTIONS)),
        help="Comma-separated lowercase connectionType allowlist",
    )
    parser.add_argument(
        "--out-root",
        type=str,
        default=str(KNOWLEDGE_ROOT),
        help="Output root directory for markdown + indices",
    )
    args = parser.parse_args()

    tables = parse_tables_arg(args)
    out_root = Path(args.out_root).resolve()
    if args.all_connections:
        allowed: Optional[Set[str]] = None
    else:
        allowed = {c.strip().lower() for c in args.connections.split(",") if c.strip()}

    print(f"Signing in to Tableau...")
    server = sign_in()
    print(f"Signed in. Processing {len(tables)} table(s).")
    print()

    writers = IndexWriters(out_root / "_index")

    overall_ok = 0
    overall_skipped = 0
    overall_errors = 0
    started_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
    try:
        for idx, table in enumerate(tables, start=1):
            print(f"[{idx}/{len(tables)}] {table}")
            try:
                nodes, errors = fetch_table_nodes(server, table)
            except Exception as exc:  # noqa: BLE001
                print(f"  ERROR fetching: {type(exc).__name__}: {exc}")
                overall_errors += 1
                writers.log_run(
                    {
                        "started_at": started_at,
                        "table": table,
                        "status": "error",
                        "error": f"{type(exc).__name__}: {exc}",
                    }
                )
                continue
            for e in errors:
                code = (e.get("extensions") or {}).get("code")
                msg = e.get("message")
                if code == "PERMISSIONS_MODE_SWITCHED":
                    continue  # informational only
                print(f"  GraphQL error: [{code}] {msg}")
            if not nodes:
                print(f"  No nodes returned. Skipping.")
                overall_skipped += 1
                writers.log_run(
                    {"started_at": started_at, "table": table, "status": "no_nodes"}
                )
                continue

            matching = filter_nodes(nodes, table, allowed)
            if not matching:
                cts = sorted({(n.get("connectionType") or "?") for n in nodes if n.get("name") == table})
                print(f"  No matching connection type. Returned: {cts}. Skipping.")
                overall_skipped += 1
                writers.log_run(
                    {
                        "started_at": started_at,
                        "table": table,
                        "status": "filtered_out",
                        "returned_connection_types": list(cts),
                    }
                )
                continue

            primary = matching[0]
            other = matching[1:]
            custom_sql = collect_custom_sql(matching)
            workbooks = collect_workbooks(matching)
            calc_fields = collect_calc_fields(matching)

            db = (primary.get("database") or {}).get("name") or "unknown_db"
            schema = primary.get("schema") or "unknown_schema"
            sub = f"{slug(db)}__{slug(schema)}"
            md_path = out_root / sub / f"{slug(table)}.md"
            write_table_markdown(
                out_path=md_path,
                table_name=table,
                primary_node=primary,
                custom_sql=custom_sql,
                workbooks=workbooks,
                calc_fields=calc_fields,
                other_nodes=other,
            )
            writers.write(
                table=table,
                table_full_name=primary.get("fullName") or "",
                custom_sql=custom_sql,
                workbooks=workbooks,
                calc_fields=calc_fields,
            )
            writers.log_run(
                {
                    "started_at": started_at,
                    "table": table,
                    "status": "ok",
                    "matching_nodes": len(matching),
                    "custom_sql": len(custom_sql),
                    "workbooks": len(workbooks),
                    "calc_fields": len(calc_fields),
                    "markdown": str(md_path.relative_to(REPO_ROOT)),
                }
            )
            overall_ok += 1
            print(
                f"  OK  custom_sql={len(custom_sql)} "
                f"workbooks={len(workbooks)} calc_fields={len(calc_fields)}  "
                f"-> {md_path.relative_to(REPO_ROOT)}"
            )
    finally:
        try:
            server.auth.sign_out()
        except Exception:  # noqa: BLE001
            pass

    print()
    print(f"Done. ok={overall_ok} skipped={overall_skipped} errors={overall_errors}")
    return 0 if overall_errors == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
