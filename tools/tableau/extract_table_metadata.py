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
        downstreamWorkbooks {
          id
          luid
          name
          projectName
          updatedAt
          owner { username name }
        }
        downstreamDatasources {
          __typename
          name
        }
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


# ---------------------------------------------------------------------------
# Server-wide custom-SQL index (built ONCE per run, reused per table)
# ---------------------------------------------------------------------------
CUSTOM_SQL_PAGE_Q = """
query allCSQL($after: String) {
  customSQLTablesConnection(first: 200, after: $after) {
    pageInfo { hasNextPage endCursor }
    totalCount
    nodes {
      id
      name
      query
      database { name connectionType }
      downstreamWorkbooks {
        id
        luid
        name
        projectName
        updatedAt
        owner { username name }
      }
    }
  }
}
"""


def build_custom_sql_index(
    server: tsc.Server,
    table_names: List[str],
) -> Dict[str, List[Dict[str, Any]]]:
    """Paginate the server's full customSQLTablesConnection and, for each
    target table, return every custom SQL node whose query body matches the
    table name as a whole word. This is the only reliable way to find table
    references that live exclusively inside hand-typed custom SQL — those
    tables never appear as DatabaseTable nodes in `databaseTablesConnection`.

    Compiled patterns guard against substring collisions (e.g.
    BI_DB_DDR_CID_Level vs BI_DB_DDR_CID_Level_Auxiliary_Metrics).

    Note: We deliberately do NOT filter by connection type here. Tableau often
    leaves `database.connectionType` empty on custom SQL nodes (the customSQL
    is opaque to the connection-type classifier), so filtering would drop
    almost all real hits.
    """
    print(f"Building server-wide custom-SQL index (one-time scan)...")
    patterns: Dict[str, re.Pattern[str]] = {}
    for t in table_names:
        patterns[t] = re.compile(rf"\b{re.escape(t)}(?![A-Za-z0-9_])", re.IGNORECASE)

    hits: Dict[str, List[Dict[str, Any]]] = {t: [] for t in table_names}
    after: Optional[str] = None
    scanned = 0
    page = 0
    while True:
        page += 1
        try:
            resp = server.metadata.query(CUSTOM_SQL_PAGE_Q, variables={"after": after})
        except Exception as exc:  # noqa: BLE001
            print(f"  custom-SQL scan ABORTED on page {page}: {exc}")
            break
        errs = resp.get("errors") or []
        for e in errs:
            print(f"  GraphQL error: {e.get('message')}")
        conn = (resp.get("data") or {}).get("customSQLTablesConnection") or {}
        nodes = conn.get("nodes") or []
        scanned += len(nodes)
        if page == 1:
            print(f"  server has {conn.get('totalCount')} custom-SQL nodes total")
        for n in nodes:
            sql = n.get("query") or ""
            if not sql:
                continue
            for t, pat in patterns.items():
                if pat.search(sql):
                    hits[t].append(n)
        pi = conn.get("pageInfo") or {}
        if not pi.get("hasNextPage"):
            break
        after = pi.get("endCursor")
    print(f"  scanned {scanned} nodes across {page} page(s).")
    for t, lst in hits.items():
        print(f"    {t}: {len(lst)} custom-SQL hit(s)")
    return hits


def merge_custom_sql_index(
    table_name: str,
    base_custom_sql: List[Dict[str, Any]],
    base_workbooks: List[Dict[str, Any]],
    csql_index_hits: List[Dict[str, Any]],
) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    """Merge the table-side (referencedByQueries) and server-side
    (customSQLTablesConnection grep) results, deduping by query id and
    workbook id. Returns (custom_sql_rows, workbook_rows) with workbook 'via'
    expanded to include 'custom_sql' for any merged-in hit."""
    sql_by_id = {q["id"]: q for q in base_custom_sql}
    wb_by_id = {w["id"]: w for w in base_workbooks}

    def upsert_wb(wb: Dict[str, Any], via: str, custom_sql_name: str = "") -> None:
        wid = str(wb.get("id") or wb.get("luid") or "")
        if not wid:
            return
        row = wb_by_id.get(wid)
        if row is None:
            owner = wb.get("owner") or {}
            row = {
                "id": wid,
                "luid": wb.get("luid") or "",
                "name": wb.get("name") or "",
                "projectName": wb.get("projectName") or "",
                "owner": owner.get("name") or owner.get("username") or "",
                "updatedAt": wb.get("updatedAt") or "",
                "via": set(),
                "custom_sql_names": set(),
            }
            wb_by_id[wid] = row
        # `via` may already be a string at this point; normalize back to set
        if isinstance(row["via"], str):
            row["via"] = set(filter(None, row["via"].split(",")))
        if isinstance(row["custom_sql_names"], str):
            existing = [x.strip() for x in row["custom_sql_names"].split("|") if x.strip()]
            row["custom_sql_names"] = set(existing)
        row["via"].add(via)
        if custom_sql_name:
            row["custom_sql_names"].add(custom_sql_name)

    for n in csql_index_hits:
        qid = str(n.get("id") or "")
        qname = n.get("name") or "<unnamed custom SQL>"
        qtext = n.get("query") or ""
        if qid and qid not in sql_by_id:
            sql_by_id[qid] = {"id": qid, "name": qname, "query": qtext}
        for wb in n.get("downstreamWorkbooks") or []:
            upsert_wb(wb, "custom_sql", qname)

    workbooks = list(wb_by_id.values())
    workbooks.sort(key=lambda r: ((r.get("projectName") or "").lower(),
                                   (r.get("name") or "").lower()))
    for r in workbooks:
        if isinstance(r["via"], set):
            r["via"] = ",".join(sorted(r["via"]))
        if isinstance(r["custom_sql_names"], set):
            r["custom_sql_names"] = " | ".join(sorted(r["custom_sql_names"]))
    return list(sql_by_id.values()), workbooks


def collect_workbooks(nodes: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Merge two attribution paths:
      1. Direct: table dragged onto canvas
         (DatabaseTable.downstreamWorkbooks)
      2. Custom-SQL: table mentioned inside a CustomSQLTable.query
         (DatabaseTable.referencedByQueries[*].downstreamWorkbooks)
    Tableau's metadata index normally only surfaces #1 from the table side; #2
    is invisible to a `databaseTablesConnection -> downstreamWorkbooks` walk,
    which used to undercount workbooks for any table referenced only via custom
    SQL (a very common pattern for DDR-style facts).
    """
    by_id: Dict[str, Dict[str, Any]] = {}

    def upsert(wb: Dict[str, Any], via: str, custom_sql_name: str = "") -> None:
        wid = str(wb.get("id") or wb.get("luid") or "")
        if not wid:
            return
        row = by_id.get(wid)
        if row is None:
            owner = wb.get("owner") or {}
            row = {
                "id": wid,
                "luid": wb.get("luid") or "",
                "name": wb.get("name") or "",
                "projectName": wb.get("projectName") or "",
                "owner": owner.get("name") or owner.get("username") or "",
                "updatedAt": wb.get("updatedAt") or "",
                "via": set(),
                "custom_sql_names": set(),
            }
            by_id[wid] = row
        row["via"].add(via)
        if custom_sql_name:
            row["custom_sql_names"].add(custom_sql_name)

    for node in nodes:
        for wb in node.get("downstreamWorkbooks") or []:
            upsert(wb, "direct")
        for q in node.get("referencedByQueries") or []:
            qname = q.get("name") or "<unnamed custom SQL>"
            for wb in q.get("downstreamWorkbooks") or []:
                upsert(wb, "custom_sql", qname)

    rows = list(by_id.values())
    # Stable-sort: project, then name
    rows.sort(key=lambda r: (r["projectName"].lower(), r["name"].lower()))
    # Materialize the sets into deterministic strings for downstream serializers
    for r in rows:
        r["via"] = ",".join(sorted(r["via"]))
        r["custom_sql_names"] = " | ".join(sorted(r["custom_sql_names"]))
    return rows


# ---------------------------------------------------------------------------
# URL resolution (REST + Metadata API to build clickable Tableau URLs)
# ---------------------------------------------------------------------------
def resolve_workbook_urls(server: tsc.Server, workbooks: List[Dict[str, Any]]) -> None:
    """Mutates `workbooks` in place, adding 'workbook_url' and 'view_urls'
    (list of {name, url}) for each entry that has a luid. Failures are logged
    but do not abort the run."""
    if not workbooks:
        return
    server_url = _env("TABLEAU_SERVER").rstrip("/")
    site_name = os.getenv("TABLEAU_SITE_NAME", "") or ""
    site_seg = f"/site/{site_name}" if site_name else ""

    for wb in workbooks:
        wb["workbook_url"] = ""
        wb["view_urls"] = []
        luid = wb.get("luid") or ""
        if not luid:
            continue
        try:
            wb_obj = server.workbooks.get_by_id(luid)
            server.workbooks.populate_views(wb_obj)
        except Exception as exc:  # noqa: BLE001
            wb["url_error"] = f"{type(exc).__name__}: {exc}"
            continue
        content_url = wb_obj.content_url or ""
        if content_url:
            wb["workbook_url"] = f"{server_url}/#{site_seg}/workbooks/{content_url}"
        for v in (wb_obj.views or []):
            view_slug = (v.content_url or "").rsplit("/sheets/", 1)[-1]
            if not view_slug or not content_url:
                continue
            wb["view_urls"].append(
                {
                    "name": v.name or view_slug,
                    "url": f"{server_url}/#{site_seg}/views/{content_url}/{view_slug}",
                }
            )


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
        n_direct = sum(1 for w in workbooks if "direct" in (w.get("via") or ""))
        n_csql = sum(1 for w in workbooks if "custom_sql" in (w.get("via") or ""))
        lines.append(
            f"_Attribution: {n_direct} via direct table-drag, {n_csql} via custom SQL "
            f"(workbooks can use both paths)._"
        )
        lines.append("")
        lines.append("| # | Workbook | Project | Owner | Via | Last updated | URL |")
        lines.append("|---|---|---|---|---|---|---|")
        for i, wb in enumerate(workbooks, start=1):
            name_cell = wb["name"].replace("|", "\\|")
            via = wb.get("via") or ""
            url = wb.get("workbook_url") or ""
            url_cell = f"[open]({url})" if url else "_url unavailable_"
            lines.append(
                f"| {i} | {name_cell} | {wb['projectName']} | {wb['owner']} | "
                f"{via} | {wb['updatedAt']} | {url_cell} |"
            )
        # Per-workbook view URL list — handy for sharing specific report tabs
        any_views = any(wb.get("view_urls") for wb in workbooks)
        if any_views:
            lines.append("")
            lines.append("### View URLs (per workbook)")
            lines.append("")
            for wb in workbooks:
                views = wb.get("view_urls") or []
                if not views:
                    continue
                lines.append(f"- **{wb['name']}** ({wb['projectName']})")
                for v in views:
                    lines.append(f"  - [{v['name']}]({v['url']})")
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
            ["table", "table_full_name", "workbook_id", "workbook_luid", "workbook_name",
             "project", "owner", "via", "updated_at", "workbook_url", "view_urls",
             "custom_sql_names"],
        )

    @staticmethod
    def _init_csv(path: Path, headers: List[str]) -> None:
        if path.exists():
            try:
                with path.open("r", encoding="utf-8", newline="") as fh:
                    existing = next(csv.reader(fh), [])
            except Exception:
                existing = []
            if existing != headers:
                rotated = path.with_suffix(path.suffix + ".old")
                path.replace(rotated)
                print(f"  (header changed: archived old CSV -> {rotated.name})")
            else:
                return
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
                view_urls = "\n".join(v["url"] for v in (wb.get("view_urls") or []))
                w.writerow(
                    [
                        table,
                        table_full_name,
                        wb["id"],
                        wb.get("luid") or "",
                        wb["name"],
                        wb["projectName"],
                        wb["owner"],
                        wb.get("via") or "",
                        wb["updatedAt"],
                        wb.get("workbook_url") or "",
                        view_urls,
                        wb.get("custom_sql_names") or "",
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
    parser.add_argument(
        "--no-urls",
        action="store_true",
        help="Skip per-workbook REST lookups for clickable URLs (faster).",
    )
    parser.add_argument(
        "--no-custom-sql-sweep",
        action="store_true",
        help="Skip the server-wide custom-SQL scan. Without this, tables only "
             "referenced via hand-typed custom SQL will appear as unused.",
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

    csql_index: Dict[str, List[Dict[str, Any]]] = {}
    if not args.no_custom_sql_sweep:
        csql_index = build_custom_sql_index(server, tables)
        print()

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
            csql_hits = csql_index.get(table, [])

            if not nodes and not csql_hits:
                print(f"  No nodes returned and no custom-SQL hits. Skipping.")
                overall_skipped += 1
                writers.log_run(
                    {"started_at": started_at, "table": table, "status": "no_nodes"}
                )
                continue

            matching = filter_nodes(nodes, table, allowed)
            if not matching and not csql_hits:
                cts = sorted({(n.get("connectionType") or "?") for n in nodes if n.get("name") == table})
                print(f"  No matching connection type and no custom-SQL hits. "
                      f"Returned cts: {cts}. Skipping.")
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

            # If no DatabaseTable node passed the filter but custom SQL hits
            # exist, synthesize a primary node so downstream writers have
            # somewhere to anchor identity. Use the first custom-SQL hit's
            # database for connection metadata.
            if matching:
                primary = matching[0]
                other = matching[1:]
            else:
                first_csql_db = (csql_hits[0].get("database") or {}) if csql_hits else {}
                primary = {
                    "id": "",
                    "name": table,
                    "fullName": "",
                    "schema": "",
                    "connectionType": first_csql_db.get("connectionType") or "",
                    "database": first_csql_db,
                }
                other = []

            custom_sql = collect_custom_sql(matching)
            workbooks = collect_workbooks(matching)
            calc_fields = collect_calc_fields(matching)
            if csql_hits:
                custom_sql, workbooks = merge_custom_sql_index(
                    table_name=table,
                    base_custom_sql=custom_sql,
                    base_workbooks=workbooks,
                    csql_index_hits=csql_hits,
                )
            if workbooks and not args.no_urls:
                resolve_workbook_urls(server, workbooks)

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
