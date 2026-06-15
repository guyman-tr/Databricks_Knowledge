"""Walk fields -> upstreamColumns -> table to recover lineage when
EmbeddedDatasource.upstreamTables is empty (custom SQL case)."""
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

# Try: workbooks -> embeddedDatasources -> fields -> upstreamColumns -> table.name
q = """
query wb($luid: String!) {
  workbooks(filter: {luid: $luid}) {
    name
    embeddedDatasources {
      id
      name
      hasExtracts
      fields {
        __typename
        name
        upstreamColumns {
          name
          table {
            __typename
            name
            ... on DatabaseTable { fullName schema connectionType database { name } }
            ... on CustomSQLTable { query database { name connectionType } }
          }
        }
        ... on CalculatedField {
          formula
        }
      }
    }
  }
}
"""
r = srv.metadata.query(q, variables={"luid": luid})
if r.get("errors"):
    print(json.dumps(r["errors"], indent=2)[:1200])
    sys.exit(1)

wbs = (r.get("data") or {}).get("workbooks") or []
for wb in wbs:
    print(f"workbook='{wb.get('name')}'")
    for ds in wb.get("embeddedDatasources") or []:
        print(f"\n  === embeddedDatasource '{ds.get('name')}'  hasExtracts={ds.get('hasExtracts')} ===")
        tables_seen = {}        # fullName -> set of fields
        csql_seen = {}          # snippet -> set of fields
        custom_sql_full = {}
        fields = ds.get("fields") or []
        for f in fields:
            fname = f.get("name")
            for col in (f.get("upstreamColumns") or []):
                t = col.get("table") or {}
                tt = t.get("__typename")
                if tt == "DatabaseTable":
                    key = t.get("fullName") or t.get("name")
                    tables_seen.setdefault(key, {"conn": t.get("connectionType"),
                                                  "db": (t.get("database") or {}).get("name"),
                                                  "schema": t.get("schema"),
                                                  "fields": set()})
                    tables_seen[key]["fields"].add(fname)
                elif tt == "CustomSQLTable":
                    sql = (t.get("query") or "").strip()
                    name = t.get("name")
                    custom_sql_full[name] = sql
                    csql_seen.setdefault(name, {"db": (t.get("database") or {}).get("name"),
                                                 "conn": (t.get("database") or {}).get("connectionType"),
                                                 "fields": set()})
                    csql_seen[name]["fields"].add(fname)
        print(f"  total fields scanned: {len(fields)}")
        print(f"  DatabaseTable references ({len(tables_seen)}):")
        for k, v in sorted(tables_seen.items()):
            print(f"    * {k}  | conn={v['conn']} | db={v['db']} | schema={v['schema']} | used_by_fields={len(v['fields'])}")
        print(f"  CustomSQLTable references ({len(csql_seen)}):")
        for k, v in sorted(csql_seen.items()):
            print(f"    * {k}  | conn={v['conn']} | db={v['db']} | used_by_fields={len(v['fields'])}")
            sql = custom_sql_full.get(k, "")
            hits = sorted(set(re.findall(r"BI_DB_DDR_[A-Za-z0-9_]+", sql)))
            other_tables = sorted(set(re.findall(r"(?:DWH_dbo|dbo)\.\[?([A-Za-z0-9_]+)\]?", sql)))
            print(f"      SQL length: {len(sql)} chars")
            print(f"      BI_DB_DDR_* mentions: {hits}")
            if other_tables:
                print(f"      other DWH_dbo.* tables: {other_tables[:20]}")
            print("      SQL first 1500 chars:")
            print("        " + sql[:1500].replace("\n", "\n        "))
