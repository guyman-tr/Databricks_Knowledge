"""Search the metadata API for any tables whose name *contains* a substring."""
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


def main() -> int:
    needle = sys.argv[1] if len(sys.argv) > 1 else "Fact_Deposit"

    now = datetime.datetime.now(datetime.timezone.utc)
    token = jwt.encode(
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
        headers={"kid": os.environ["TABLEAU_SECRET_ID"], "iss": os.environ["TABLEAU_CLIENT_ID"]},
    )

    server = tsc.Server(
        os.environ["TABLEAU_SERVER"].rstrip("/"),
        use_server_version=True,
        http_options={"verify": False},
    )
    server.auth.sign_in(tsc.JWTAuth(token, site_id=os.getenv("TABLEAU_SITE_NAME", "")))

    try:
        introspect = """
        {
          __type(name: "DatabaseTable_Filter") {
            name
            inputFields { name type { name kind ofType { name kind } } }
          }
        }
        """
        ir = server.metadata.query(introspect)
        print("--- DatabaseTable_Filter input fields ---")
        for f in (((ir.get("data") or {}).get("__type") or {}).get("inputFields") or []):
            tn = ((f.get("type") or {}).get("name")) or ((f.get("type") or {}).get("ofType") or {}).get("name")
            print(f"  {f['name']:30} {tn}")
        print()

        query = """
        query findTables($needle: String!) {
          databaseTablesConnection(filter: {text: $needle}, first: 50) {
            totalCount
            nodes {
              id
              name
              fullName
              schema
              connectionType
              database { name }
            }
          }
        }
        """
        resp = server.metadata.query(query, variables={"needle": needle})
        errors = resp.get("errors") or []
        for e in errors:
            print("WARN:", e.get("message"))
        nodes = (resp.get("data") or {}).get("databaseTablesConnection", {}).get("nodes") or []
        total = (resp.get("data") or {}).get("databaseTablesConnection", {}).get("totalCount")
        print(f"needle='{needle}'  totalCount={total}  returned={len(nodes)}")
        for n in nodes:
            print(
                f"  {n.get('connectionType','?'):20}  "
                f"{(n.get('database') or {}).get('name','?'):24}  "
                f"{n.get('schema','?'):20}  {n.get('name','?')}"
            )
    finally:
        server.auth.sign_out()
    return 0


if __name__ == "__main__":
    sys.exit(main())
