"""Resolve a Tableau workbook by its contentUrl (the URL slug), then dump its
upstream tables AND published datasources (which the workbook-detail extractor misses)."""
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


content_url = sys.argv[1] if len(sys.argv) > 1 else "DDRNewCountryLevelAllHistoricalData"
srv = sign_in()

print(f"=== Step 1: REST lookup by contentUrl={content_url!r} ===")
req = tsc.RequestOptions()
req.filter.add(tsc.Filter(tsc.RequestOptions.Field.ContentUrl, tsc.RequestOptions.Operator.Equals, content_url))
wbs, _ = srv.workbooks.get(req_options=req)
print(f"Found {len(wbs)} workbook(s)")
for w in wbs:
    print(f"  - name='{w.name}'  project='{w.project_name}'  owner_id={w.owner_id}  luid={w.id}  contentUrl={w.content_url}")

if not wbs:
    print("\nNo match via REST. Try wildcard search next.")
    sys.exit(0)

for w in wbs:
    luid = w.id
    print(f"\n=== Step 2: Metadata API detail for luid={luid} ===")
    q = """
    query wb($luid: String!) {
      workbooks(filter: {luid: $luid}) {
        luid
        name
        projectName
        upstreamTables {
          name
          fullName
          schema
          connectionType
          database { name }
        }
        embeddedDatasources {
          name
          upstreamTables { name fullName schema connectionType database { name } }
        }
        upstreamDatasources {
          __typename
          luid
          name
          isCertified
          hasExtracts
          upstreamTables { name fullName schema connectionType database { name } }
        }
      }
    }
    """
    resp = srv.metadata.query(q, variables={"luid": luid})
    if resp.get("errors"):
        print("METADATA ERRORS:")
        for e in resp["errors"]:
            print(" ", e.get("message", e))
    data = (resp.get("data") or {}).get("workbooks") or []
    if not data:
        print("  No workbook detail returned by metadata API.")
        continue
    wb = data[0]
    print(f"  name='{wb.get('name')}'  project='{wb.get('projectName')}'")

    print(f"\n  upstreamTables ({len(wb.get('upstreamTables') or [])}):")
    for t in wb.get("upstreamTables") or []:
        print(f"    - {t.get('name')} | fullName={t.get('fullName')} | conn={t.get('connectionType')} | db={(t.get('database') or {}).get('name')}")

    eds = wb.get("embeddedDatasources") or []
    print(f"\n  embeddedDatasources ({len(eds)}):")
    for d in eds:
        ut = d.get("upstreamTables") or []
        print(f"    - '{d.get('name')}'  upstreamTables={len(ut)}")
        for t in ut:
            print(f"        * {t.get('name')} | conn={t.get('connectionType')}")

    pds = wb.get("upstreamDatasources") or []
    print(f"\n  upstreamDatasources / publishedDatasources ({len(pds)}):")
    for d in pds:
        ut = d.get("upstreamTables") or []
        print(f"    - '{d.get('name')}'  luid={d.get('luid')}  certified={d.get('isCertified')}  upstreamTables={len(ut)}")
        for t in ut:
            print(f"        * {t.get('name')} | fullName={t.get('fullName')} | conn={t.get('connectionType')}")
