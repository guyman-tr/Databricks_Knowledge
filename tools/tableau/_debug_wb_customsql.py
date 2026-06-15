"""Given a workbook luid, dump every custom SQL query (across embedded + published
datasources) AND the columns referenced. Used to chase the table-lineage gap
where upstreamTables is empty because the datasource is custom-SQL based."""
import datetime, json, os, sys, uuid, warnings, re
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


luid = sys.argv[1] if len(sys.argv) > 1 else "c46aeee9-977d-40d9-87de-04e2874d3580"
srv = sign_in()

# Step 1: list embedded datasource IDs (GraphQL ids, not luids) for this workbook
q1 = """
query wb($luid: String!) {
  workbooks(filter: {luid: $luid}) {
    name
    embeddedDatasources { id name }
    upstreamDatasources { luid name }
  }
}
"""
r1 = srv.metadata.query(q1, variables={"luid": luid})
if r1.get("errors"):
    print(json.dumps(r1["errors"], indent=2))
    sys.exit(1)
wb = ((r1.get("data") or {}).get("workbooks") or [{}])[0]
print(f"workbook='{wb.get('name')}'")
embedded = wb.get("embeddedDatasources") or []
published = wb.get("upstreamDatasources") or []
print(f"embeddedDatasources: {[(d.get('id'), d.get('name')) for d in embedded]}")
print(f"publishedDatasources: {[(d.get('luid'), d.get('name')) for d in published]}")

# Step 2: For each embedded datasource id, fetch its customSQLTables
q2 = """
query ds($id: ID!) {
  embeddedDatasources(filter: {id: $id}) {
    name
    upstreamTables { name fullName schema connectionType database { name } }
    upstreamDatabases { name connectionType }
    customSQLTablesConnection(first: 50) {
      totalCount
      nodes {
        id
        name
        query
        isUnsupportedCustomSql
        database { name connectionType }
        tables { name fullName schema database { name } }
        columns(first: 200) { name }
      }
    }
  }
}
"""
# Step 2: query customSQLTables filtered to ones whose downstream workbook is our luid
q2 = """
query csql($luid: String!) {
  customSQLTablesConnection(filter: {downstreamWorkbooksLuid: $luid}, first: 100) {
    totalCount
    nodes {
      id
      name
      query
      isUnsupportedCustomSql
      database { name connectionType }
      tables { name fullName schema database { name } }
      columns(first: 200) { name }
      downstreamDatasources { name }
    }
  }
}
"""
r2 = srv.metadata.query(q2, variables={"luid": luid})
if r2.get("errors"):
    print(json.dumps(r2["errors"], indent=2)[:600])
    sys.exit(1)
conn = (r2.get("data") or {}).get("customSQLTablesConnection") or {}
nodes = conn.get("nodes") or []
print(f"\ncustomSQLTables downstream from this workbook: total={conn.get('totalCount')} returned={len(nodes)}")
for c in nodes:
    sql = (c.get("query") or "").strip()
    tables = c.get("tables") or []
    db = (c.get("database") or {})
    dds = c.get("downstreamDatasources") or []
    print(f"\n  -- name='{c.get('name')}' unsupported={c.get('isUnsupportedCustomSql')} db={db.get('name')} conn={db.get('connectionType')}")
    print(f"     downstreamDatasources: {[d.get('name') for d in dds]}")
    print(f"     parsed tables ({len(tables)}):")
    for t in tables:
        print(f"        * {t.get('fullName') or t.get('name')} | schema={t.get('schema')} | db={(t.get('database') or {}).get('name')}")
    print(f"     SQL ({len(sql)} chars):")
    print("        " + sql[:2000].replace("\n", "\n        "))
    hits = sorted(set(re.findall(r"BI_DB_DDR_[A-Za-z0-9_]+", sql)))
    if hits:
        print(f"     BI_DB_DDR_* mentions: {hits}")
    cols = [col.get("name") for col in (c.get("columns") or [])]
    print(f"     columns ({len(cols)}): {cols[:20]}{'...' if len(cols) > 20 else ''}")
