"""Probe the Tableau Metadata API to confirm coverage gaps:
1. Are there published datasources that reference our tables but were missed?
2. Does the API expose Initial SQL? If so, can we grep it?

Outputs counts only — diagnostic, not a final scan.
"""

from __future__ import annotations

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


def make_jwt(client_id, secret_id, secret_value, username):
    now = datetime.datetime.now(datetime.timezone.utc)
    return jwt.encode(
        {
            "iss": client_id, "exp": now + datetime.timedelta(minutes=10),
            "jti": str(uuid.uuid4()), "aud": "tableau", "sub": username,
            "scp": ["tableau:content:*"],
        },
        secret_value, algorithm="HS256",
        headers={"kid": secret_id, "iss": client_id},
    )


def main() -> int:
    server_url = os.getenv("TABLEAU_SERVER", "").rstrip("/")
    token = make_jwt(os.environ["TABLEAU_CLIENT_ID"], os.environ["TABLEAU_SECRET_ID"],
                     os.environ["TABLEAU_SECRET_VALUE"], os.environ["TABLEAU_USERNAME"])
    server = tsc.Server(server_url, use_server_version=True, http_options={"verify": False})
    server.auth.sign_in(tsc.JWTAuth(token, site_id=os.getenv("TABLEAU_SITE_NAME", "")))

    # 1. Total published datasources on the server
    q = """
    query { publishedDatasourcesConnection(first: 1) { totalCount } }
    """
    resp = server.metadata.query(q)
    pds_total = (resp.get("data") or {}).get("publishedDatasourcesConnection", {}).get("totalCount", 0)
    print(f"published datasources total: {pds_total}")

    # 2. For one of our keep tables that came back as "no consumer", check
    #    whether any published datasource references it via upstreamTables.
    test_tables = [
        "BI_DB_AML_PI_Abuse",
        "BI_DB_AML_PI_Abuse_DeviceID_AS_PI",
        "BI_DB_AML_FCA_Crypto_Threshold",
        "BI_DB_Diversification",
    ]
    q2 = """
    query pdsForTable($tableName: String!) {
      databaseTablesConnection(filter: {name: $tableName}) {
        nodes {
          name
          fullName
          schema
          downstreamDatasources { __typename name luid hasExtracts }
          downstreamWorkbooks { id name }
        }
      }
    }
    """
    print("\nProbing tables that came back as B_NO_TABLEAU_CONSUMER:")
    for t in test_tables:
        r = server.metadata.query(q2, variables={"tableName": t})
        nodes = ((r.get("data") or {}).get("databaseTablesConnection") or {}).get("nodes") or []
        if not nodes:
            print(f"  {t}: no DatabaseTable node found")
            continue
        for n in nodes:
            ds = n.get("downstreamDatasources") or []
            wb = n.get("downstreamWorkbooks") or []
            print(f"  {n['name']} (fullName={n.get('fullName')}, schema={n.get('schema')}) "
                  f"-> downstreamDatasources={len(ds)} downstreamWorkbooks={len(wb)}")
            for d in ds[:5]:
                print(f"      DS: {d.get('__typename')} name={d.get('name')!r}")

    # 3. Check whether the Database node itself has initialSql
    q3 = """
    query { databases(filter: {connectionType: "azure_sql_dw"}) {
      __typename name connectionType
    } }
    """
    try:
        r = server.metadata.query(q3)
        dbs = (r.get("data") or {}).get("databases") or []
        print(f"\nazure_sql_dw databases visible: {len(dbs)}")
        for d in dbs[:5]:
            print(f"  {d.get('name')}")
    except Exception as e:  # noqa: BLE001
        print(f"databases query failed: {e}")

    # 4. Check whether DatabaseServer has initialSql / DatabaseConnection has initialSql
    q4 = """
    query introspect {
      __type(name: "DatabaseServer") {
        name
        fields { name type { name kind } }
      }
    }
    """
    try:
        r = server.metadata.query(q4)
        fields = (((r.get("data") or {}).get("__type") or {}).get("fields") or [])
        names = [f["name"] for f in fields]
        print(f"\nDatabaseServer fields ({len(names)}):")
        print("  " + ", ".join(names))
        if any("initial" in n.lower() or "sql" in n.lower() for n in names):
            print("  -> has SQL-related field(s)")
    except Exception as e:  # noqa: BLE001
        print(f"introspection failed: {e}")

    # 5. Check the EmbeddedDatasource type for initialSql
    q5 = """
    query introspect {
      __type(name: "EmbeddedDatasource") {
        name
        fields { name type { name kind } }
      }
    }
    """
    try:
        r = server.metadata.query(q5)
        fields = (((r.get("data") or {}).get("__type") or {}).get("fields") or [])
        names = [f["name"] for f in fields]
        print(f"\nEmbeddedDatasource fields ({len(names)}):")
        print("  " + ", ".join(names))
    except Exception as e:  # noqa: BLE001
        print(f"introspection failed: {e}")

    # 6. Same for PublishedDatasource
    q6 = """
    query introspect {
      __type(name: "PublishedDatasource") {
        name
        fields { name type { name kind } }
      }
    }
    """
    try:
        r = server.metadata.query(q6)
        fields = (((r.get("data") or {}).get("__type") or {}).get("fields") or [])
        names = [f["name"] for f in fields]
        print(f"\nPublishedDatasource fields ({len(names)}):")
        print("  " + ", ".join(names))
    except Exception as e:  # noqa: BLE001
        print(f"introspection failed: {e}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
