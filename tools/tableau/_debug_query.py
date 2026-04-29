"""Inspect the raw metadata response for one table to learn the schema."""
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
    table = sys.argv[1] if len(sys.argv) > 1 else "BI_DB_DDR_Customer_Daily_Status"

    now = datetime.datetime.now(datetime.timezone.utc)
    token = jwt.encode(
        {
            "iss": os.environ["TABLEAU_CLIENT_ID"],
            "exp": now + datetime.timedelta(minutes=5),
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
        query = """
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
              referencedByQueries { __typename id name }
              downstreamWorkbooks { __typename id name }
            }
          }
        }
        """
        resp = server.metadata.query(query, variables={"tableName": table})
        print(json.dumps(resp, indent=2)[:6000])
    finally:
        server.auth.sign_out()
    return 0


if __name__ == "__main__":
    sys.exit(main())
