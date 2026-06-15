"""Quick: find workbooks by partial name and dump their upstream tables AND
published datasources (which the standard extractor misses)."""
import datetime, json, os, sys, uuid, warnings
from pathlib import Path
import urllib3, jwt, tableauserverclient as tsc
from dotenv import load_dotenv

HERE = Path(__file__).resolve().parent
load_dotenv(HERE / ".env")
warnings.filterwarnings("ignore")
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


def _env(name): return os.getenv(name, "") or sys.exit(f"missing {name}")


def sign_in():
    now = datetime.datetime.now(datetime.timezone.utc)
    token = jwt.encode(
        {"iss": _env("TABLEAU_CLIENT_ID"), "exp": now + datetime.timedelta(minutes=10),
         "jti": str(uuid.uuid4()), "aud": "tableau", "sub": _env("TABLEAU_USERNAME"),
         "scp": ["tableau:content:*"]},
        _env("TABLEAU_SECRET_VALUE"), algorithm="HS256",
        headers={"kid": _env("TABLEAU_SECRET_ID"), "iss": _env("TABLEAU_CLIENT_ID")})
    srv = tsc.Server(_env("TABLEAU_SERVER").rstrip("/"), use_server_version=True, http_options={"verify": False})
    srv.auth.sign_in(tsc.JWTAuth(token, site_id=os.getenv("TABLEAU_SITE_NAME", "")))
    return srv


needle = sys.argv[1] if len(sys.argv) > 1 else "Country Level"
srv = sign_in()
print(f"Searching workbooks with name containing: '{needle}'")
q = """
query wbs($n: String!) {
  workbooksConnection(filter: {nameWithin: [$n]}, first: 50) {
    totalCount
    nodes { luid name projectName updatedAt owner { name } }
  }
}
"""
# `nameWithin` doesn't exist — try filter args supported by Tableau metadata API
# Use contains-style filter instead:
q = """
query wbs($n: String!) {
  workbooksConnection(filter: {nameContains: $n}, first: 50) {
    totalCount
    nodes { luid name projectName updatedAt owner { name } }
  }
}
"""
resp = srv.metadata.query(q, variables={"n": needle})
if resp.get("errors"):
    print("ERR with nameContains, trying without filter (paginated full list)...")
    # fallback: list all and filter client-side
    matches = []
    q2 = """
    query wbs($after: String) {
      workbooksConnection(first: 1000, after: $after) {
        pageInfo { hasNextPage endCursor }
        nodes { luid name projectName updatedAt owner { name } }
      }
    }
    """
    after = None
    total_scanned = 0
    while True:
        r = srv.metadata.query(q2, variables={"after": after})
        if r.get("errors"):
            print("errors:", r["errors"])
            break
        conn = (r.get("data") or {}).get("workbooksConnection") or {}
        nodes = conn.get("nodes") or []
        total_scanned += len(nodes)
        for n in nodes:
            if needle.lower() in (n.get("name") or "").lower():
                matches.append(n)
        page = conn.get("pageInfo") or {}
        if not page.get("hasNextPage"):
            break
        after = page.get("endCursor")
    print(f"Scanned {total_scanned} workbooks, found {len(matches)} matching '{needle}'")
    nodes = matches
else:
    conn = (resp.get("data") or {}).get("workbooksConnection") or {}
    nodes = conn.get("nodes") or []
    print(f"totalCount={conn.get('totalCount')} returned={len(nodes)}")

for n in nodes:
    print(f"  - {n.get('name')}   project={n.get('projectName')}   owner={(n.get('owner') or {}).get('name')}   updated={n.get('updatedAt')}   luid={n.get('luid')}")
