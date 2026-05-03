"""Discovery: find Tableau workbooks related to the eToro Daily Data Report.

Strategy: combine three signals
  1. Workbooks in the 'DDR' / 'DDR's' / 'Daily Data Report' projects.
  2. Workbooks whose own name contains 'DDR' or 'Daily Data Report' (case-insensitive).
  3. As a fallback, any workbook surfaced as downstream from the BI_DB_DDR_* tables
     (we already have BI_DB_DDR_Customer_Daily_Status and BI_DB_DDR_Fact_MIMO_AllPlatforms
      processed; the union covers most of the family).

Read-only: queries the metadata API and prints to stdout. No files are written.
"""
from __future__ import annotations

import datetime
import json
import os
import sys
import uuid
import warnings
from pathlib import Path

import urllib3
import jwt
import tableauserverclient as tsc
from dotenv import load_dotenv

HERE = Path(__file__).resolve().parent
load_dotenv(HERE / ".env")
warnings.filterwarnings("ignore")
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


def make_jwt() -> str:
    now = datetime.datetime.now(datetime.timezone.utc)
    return jwt.encode(
        {
            "iss": os.environ["TABLEAU_CLIENT_ID"],
            "exp": now + datetime.timedelta(minutes=10),
            "jti": str(uuid.uuid4()),
            "aud": "tableau",
            "sub": os.environ["TABLEAU_USERNAME"],
            "scp": ["tableau:content:*"],
        },
        os.environ["TABLEAU_SECRET_VALUE"],
        algorithm="HS256",
        headers={
            "kid": os.environ["TABLEAU_SECRET_ID"],
            "iss": os.environ["TABLEAU_CLIENT_ID"],
        },
    )


def main() -> int:
    server = tsc.Server(
        os.environ["TABLEAU_SERVER"].rstrip("/"),
        use_server_version=True,
        http_options={"verify": False},
    )
    server.auth.sign_in(tsc.JWTAuth(make_jwt(), site_id=os.getenv("TABLEAU_SITE_NAME", "")))

    try:
        # Introspect the Workbook_Filter type to learn the filter contract.
        filter_introspect = """
        {
          __type(name: "Workbook_Filter") {
            inputFields { name type { name kind ofType { name kind } } }
          }
        }
        """
        ir = server.metadata.query(filter_introspect)
        print("--- Workbook_Filter input fields ---")
        for f in ((((ir.get("data") or {}).get("__type") or {}).get("inputFields")) or []):
            tn = ((f.get("type") or {}).get("name")) or ((f.get("type") or {}).get("ofType") or {}).get("name")
            print(f"  {f['name']:30} {tn}")
        print()

        # 1. Project-name search: the project we know exists is "DDR's"
        for project in ["DDR's", "DDR", "Daily Data Report"]:
            print(f"--- workbooks in projectName='{project}' ---")
            q = """
            query wbs($p: String!) {
              workbooksConnection(filter: {projectName: $p}, first: 100) {
                totalCount
                nodes { name luid projectName updatedAt owner { name username } }
              }
            }
            """
            try:
                resp = server.metadata.query(q, variables={"p": project})
                for e in resp.get("errors") or []:
                    code = (e.get("extensions") or {}).get("code")
                    if code != "PERMISSIONS_MODE_SWITCHED":
                        print(f"  WARN: [{code}] {e.get('message')}")
                conn = (resp.get("data") or {}).get("workbooksConnection") or {}
                print(f"  totalCount={conn.get('totalCount')}")
                for n in conn.get("nodes") or []:
                    owner = (n.get("owner") or {}).get("name") or (n.get("owner") or {}).get("username") or "?"
                    print(f"  - '{n['name']}' (project='{n['projectName']}', owner='{owner}', updated={n.get('updatedAt')}) luid={n.get('luid')}")
            except Exception as exc:  # noqa: BLE001
                print(f"  ERR: {type(exc).__name__}: {exc}")
            print()

        # 2. Name-contains search via the 'name' field (no contains in this server,
        #    so we fall back to project iteration plus an exact-name probe).
        for needle in ["Daily Data Report", "DDR Dashboard", "DDR Report", "DDR"]:
            print(f"--- workbooks with name='{needle}' (exact) ---")
            q = """
            query wbsByName($n: String!) {
              workbooksConnection(filter: {name: $n}, first: 50) {
                totalCount
                nodes { name luid projectName updatedAt owner { name username } }
              }
            }
            """
            try:
                resp = server.metadata.query(q, variables={"n": needle})
                conn = (resp.get("data") or {}).get("workbooksConnection") or {}
                print(f"  totalCount={conn.get('totalCount')}")
                for n in conn.get("nodes") or []:
                    print(f"  - '{n['name']}' (project='{n['projectName']}') luid={n.get('luid')}")
            except Exception as exc:  # noqa: BLE001
                print(f"  ERR: {type(exc).__name__}: {exc}")
            print()
    finally:
        try:
            server.auth.sign_out()
        except Exception:  # noqa: BLE001
            pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
