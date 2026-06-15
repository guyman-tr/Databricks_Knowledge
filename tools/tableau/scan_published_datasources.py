"""Enumerate every PublishedDatasource on the server and dump its upstream
tables + downstream workbooks. Used to plug a coverage gap in the bulk
table-by-table sweep: a workbook that consumes a published datasource that
references a table via DIRECT (not custom-SQL) connection might be invisible
to the table-side sweep.

Output: knowledge/tableau/_index/published_datasources.csv
        columns: pds_luid, pds_name, project, owner,
                 upstream_table_full_name, upstream_table_bare,
                 downstream_workbook_count
"""

from __future__ import annotations

import csv
import datetime
import os
import sys
import uuid
import warnings
from pathlib import Path

import urllib3
import jwt
import tableauserverclient as tsc
from dotenv import load_dotenv

REPO_ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
load_dotenv(HERE / ".env")
warnings.filterwarnings("ignore")
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

OUT_CSV   = REPO_ROOT / "knowledge" / "tableau" / "_index" / "published_datasources.csv"
OUT_CSV2  = REPO_ROOT / "knowledge" / "tableau" / "_index" / "published_datasources_csql.csv"

QUERY = """
query allPDS($after: String) {
  publishedDatasourcesConnection(first: 50, after: $after) {
    pageInfo { hasNextPage endCursor }
    totalCount
    nodes {
      luid
      name
      projectName
      owner { username name }
      upstreamTables {
        __typename
        name
        fullName
        schema
        database { name connectionType }
      }
      downstreamWorkbooks {
        id
        luid
        name
      }
    }
  }
}
"""

# Custom-SQL queries underneath a published datasource — important for the
# "we already covered custom SQL" claim verification.
QUERY_CSQL = """
query allPDSCSQL($after: String) {
  publishedDatasourcesConnection(first: 50, after: $after) {
    pageInfo { hasNextPage endCursor }
    nodes {
      luid
      name
      upstreamDatasources {
        __typename
        name
      }
    }
  }
}
"""


def _env(name):
    v = os.getenv(name, "")
    if not v:
        raise SystemExit(f"Missing env: {name}")
    return v


def make_jwt():
    now = datetime.datetime.now(datetime.timezone.utc)
    return jwt.encode(
        {
            "iss": _env("TABLEAU_CLIENT_ID"),
            "exp": now + datetime.timedelta(minutes=10),
            "jti": str(uuid.uuid4()), "aud": "tableau",
            "sub": _env("TABLEAU_USERNAME"),
            "scp": ["tableau:content:*"],
        },
        _env("TABLEAU_SECRET_VALUE"), algorithm="HS256",
        headers={"kid": _env("TABLEAU_SECRET_ID"), "iss": _env("TABLEAU_CLIENT_ID")},
    )


def main() -> int:
    server_url = _env("TABLEAU_SERVER").rstrip("/")
    server = tsc.Server(server_url, use_server_version=True, http_options={"verify": False})
    server.auth.sign_in(tsc.JWTAuth(make_jwt(), site_id=os.getenv("TABLEAU_SITE_NAME", "")))

    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    rows = []
    after = None
    page = 0
    total = 0
    while True:
        page += 1
        resp = server.metadata.query(QUERY, variables={"after": after})
        conn = (resp.get("data") or {}).get("publishedDatasourcesConnection") or {}
        nodes = conn.get("nodes") or []
        if page == 1:
            total = conn.get("totalCount", 0)
            print(f"published datasources total: {total}")

        for n in nodes:
            luid = n.get("luid", "")
            name = n.get("name", "")
            project = n.get("projectName", "")
            owner = (n.get("owner") or {}).get("name", "") or (n.get("owner") or {}).get("username", "")
            up_tables = n.get("upstreamTables") or []
            wb_count = len(n.get("downstreamWorkbooks") or [])
            if not up_tables:
                rows.append([luid, name, project, owner, "", "", wb_count])
                continue
            for t in up_tables:
                full = t.get("fullName") or ""
                bare = t.get("name") or ""
                rows.append([luid, name, project, owner, full, bare, wb_count])

        pi = conn.get("pageInfo") or {}
        if not pi.get("hasNextPage"):
            break
        after = pi.get("endCursor")
        print(f"  page {page} done; next cursor set", flush=True)

    with OUT_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["pds_luid", "pds_name", "project", "owner",
                    "upstream_table_full_name", "upstream_table_bare",
                    "downstream_workbook_count"])
        w.writerows(rows)
    print(f"\nwrote {len(rows)} (pds, table) rows -> {OUT_CSV}")
    print(f"unique PDS: {len({r[0] for r in rows})}")
    print(f"unique tables touched by PDS: {len({r[5] for r in rows if r[5]})}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
