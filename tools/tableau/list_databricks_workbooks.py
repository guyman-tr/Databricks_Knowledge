"""List Tableau workbooks whose upstream connection includes Databricks.

Walks every workbook visible to the authenticated user via the Tableau Metadata
GraphQL API, inspects each workbook's upstreamTables / upstreamDatabases for
connectionType containing "databricks", and writes a CSV of matching workbooks.

Usage (from repo root):
    python tools/tableau/list_databricks_workbooks.py \
        --out knowledge/tableau/_index/databricks_workbooks.csv

Reads creds from tools/tableau/.env (same pattern as test_connection.py).
"""
from __future__ import annotations

import argparse
import csv
import datetime
import os
import sys
import uuid
import warnings
from pathlib import Path

import jwt
import tableauserverclient as tsc
import urllib3
from dotenv import load_dotenv

HERE = Path(__file__).resolve().parent
load_dotenv(HERE / ".env")
warnings.filterwarnings("ignore")
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


def _env(name: str, default: str | None = None) -> str:
    val = os.getenv(name, default if default is not None else "")
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


def signin() -> tsc.Server:
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


WORKBOOK_PAGE_QUERY = """
query workbookPage($first: Int!, $after: String) {
  workbooksConnection(first: $first, after: $after) {
    pageInfo { hasNextPage endCursor }
    nodes {
      id
      luid
      name
      projectName
      uri
      updatedAt
      owner { name email username }
      upstreamTables {
        name
        schema
        fullName
        connectionType
        database { name }
      }
      embeddedDatasources {
        name
        upstreamTables {
          name
          schema
          fullName
          connectionType
          database { name }
        }
      }
    }
  }
}
"""


def iter_workbooks(server: tsc.Server, page_size: int = 50):
    after: str | None = None
    while True:
        resp = server.metadata.query(
            WORKBOOK_PAGE_QUERY,
            variables={"first": page_size, "after": after},
        )
        if resp.get("errors"):
            raise SystemExit(f"GraphQL errors: {resp['errors']}")
        conn = resp["data"]["workbooksConnection"]
        for node in conn["nodes"]:
            yield node
        if not conn["pageInfo"]["hasNextPage"]:
            return
        after = conn["pageInfo"]["endCursor"]


def collect_databricks_tables(workbook: dict) -> list[dict]:
    """Return the list of upstream tables on this workbook whose connectionType
    indicates Databricks. Aggregates across direct upstreamTables and
    embeddedDatasources[*].upstreamTables.
    """
    out: list[dict] = []
    for tbl in workbook.get("upstreamTables") or []:
        if _is_databricks(tbl.get("connectionType")):
            out.append(tbl)
    for ds in workbook.get("embeddedDatasources") or []:
        for tbl in ds.get("upstreamTables") or []:
            if _is_databricks(tbl.get("connectionType")):
                out.append(tbl)
    return out


def _is_databricks(connection_type: str | None) -> bool:
    if not connection_type:
        return False
    ct = connection_type.lower()
    return "databricks" in ct or ct == "spark-sql" or ct == "spark"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--out",
        default=str(Path("knowledge/tableau/_index/databricks_workbooks.csv")),
        help="Output CSV path",
    )
    parser.add_argument("--page-size", type=int, default=50)
    parser.add_argument(
        "--include-non-databricks-summary",
        action="store_true",
        help="Also print breakdown of all connection types seen",
    )
    args = parser.parse_args()

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    print("Signing in to Tableau ...", flush=True)
    server = signin()
    print(f"  site_id = {server.site_id}", flush=True)

    rows: list[dict] = []
    conn_type_counts: dict[str, int] = {}
    n_workbooks = 0

    try:
        for wb in iter_workbooks(server, page_size=args.page_size):
            n_workbooks += 1
            if n_workbooks % 200 == 0:
                print(f"  scanned {n_workbooks} workbooks ... matched={len(rows)}", flush=True)

            all_tables = list(wb.get("upstreamTables") or [])
            for ds in wb.get("embeddedDatasources") or []:
                all_tables.extend(ds.get("upstreamTables") or [])
            for t in all_tables:
                ct = (t.get("connectionType") or "").lower() or "(empty)"
                conn_type_counts[ct] = conn_type_counts.get(ct, 0) + 1

            dbx_tables = collect_databricks_tables(wb)
            if not dbx_tables:
                continue

            owner = wb.get("owner") or {}
            unique_tables = sorted({
                _table_full(t) for t in dbx_tables
            })
            unique_dbs = sorted({
                (t.get("database") or {}).get("name") or ""
                for t in dbx_tables
                if (t.get("database") or {}).get("name")
            })
            unique_conn_types = sorted({
                (t.get("connectionType") or "").lower()
                for t in dbx_tables
            })

            rows.append({
                "workbook_luid": wb.get("luid") or "",
                "workbook_name": wb.get("name") or "",
                "project": wb.get("projectName") or "",
                "owner_name": owner.get("name") or "",
                "owner_email": owner.get("email") or "",
                "updated_at": wb.get("updatedAt") or "",
                "url": wb.get("uri") or "",
                "n_databricks_tables": len(dbx_tables),
                "databricks_connection_types": ",".join(unique_conn_types),
                "databricks_databases": ",".join(unique_dbs),
                "databricks_tables_sample": ",".join(unique_tables[:8]),
                "databricks_tables_truncated": "yes" if len(unique_tables) > 8 else "no",
            })
    finally:
        try:
            server.auth.sign_out()
        except Exception:  # noqa: BLE001
            pass

    print(f"\nScanned {n_workbooks} workbooks; {len(rows)} have at least one Databricks upstream.")

    fieldnames = [
        "workbook_luid",
        "workbook_name",
        "project",
        "owner_name",
        "owner_email",
        "updated_at",
        "url",
        "n_databricks_tables",
        "databricks_connection_types",
        "databricks_databases",
        "databricks_tables_sample",
        "databricks_tables_truncated",
    ]
    rows.sort(key=lambda r: (r["project"].lower(), r["workbook_name"].lower()))
    with out_path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    print(f"Wrote {out_path}")

    if args.include_non_databricks_summary:
        print("\nConnection-type frequency across all upstream tables seen:")
        for ct, n in sorted(conn_type_counts.items(), key=lambda x: -x[1]):
            print(f"  {ct:30}  {n}")

    return 0


def _table_full(t: dict) -> str:
    full = t.get("fullName")
    if full:
        return full
    db = (t.get("database") or {}).get("name") or ""
    schema = t.get("schema") or ""
    name = t.get("name") or ""
    parts = [p for p in (db, schema, name) if p]
    return ".".join(parts) if parts else (name or "?")


if __name__ == "__main__":
    sys.exit(main())
