"""Find every Tableau workbook that references the 4 DDR tables via *custom SQL*.

Why: the standard extractor (databaseTablesConnection -> downstreamWorkbooks)
only sees workbooks that attached the physical table. When a datasource pastes
hand-written SQL, the table is hidden inside a CustomSQLTable node and the
table-side traversal returns 0 workbooks even though the SQL clearly hits it.

This script paginates through every CustomSQLTable on the server, greps the
SQL body for each needle table, and prints the parent workbooks. Combine with
the table-graph result for the full picture."""
import datetime, json, os, sys, uuid, warnings, re
from pathlib import Path
import urllib3, jwt, tableauserverclient as tsc
from dotenv import load_dotenv

HERE = Path(__file__).resolve().parent
load_dotenv(HERE / ".env")
warnings.filterwarnings("ignore")
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

NEEDLES = [
    "BI_DB_DDR_CID_Level_Auxiliary_Metrics",
    "BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics",
    "BI_DB_DDR_TimeRange_Aggregated_Country_Level",
    "BI_DB_DDR_CID_Level",
]


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


srv = sign_in()

# Q: page through every CustomSQLTable. Pull the query body, parent datasources,
# and downstream workbooks. We must paginate using the standard relay cursor.
Q = """
query allCSQL($after: String) {
  customSQLTablesConnection(first: 200, after: $after) {
    pageInfo { hasNextPage endCursor }
    totalCount
    nodes {
      id
      name
      query
      database { name connectionType }
      downstreamDatasources {
        __typename
        name
      }
      downstreamWorkbooks {
        luid
        name
        projectName
        owner { name username }
      }
    }
  }
}
"""

hits = {n: [] for n in NEEDLES}
after = None
total = 0
page = 0
while True:
    page += 1
    r = srv.metadata.query(Q, variables={"after": after})
    if r.get("errors"):
        print("errors:")
        print(json.dumps(r["errors"], indent=2)[:1200])
        break
    conn = (r.get("data") or {}).get("customSQLTablesConnection") or {}
    nodes = conn.get("nodes") or []
    total += len(nodes)
    if page == 1:
        print(f"server total customSQLTables = {conn.get('totalCount')}")
    for c in nodes:
        sql = c.get("query") or ""
        for needle in NEEDLES:
            if re.search(rf"\b{re.escape(needle)}\b", sql, flags=re.IGNORECASE):
                hits[needle].append(c)
    pi = conn.get("pageInfo") or {}
    if not pi.get("hasNextPage"):
        break
    after = pi.get("endCursor")
    if page % 5 == 0:
        print(f"  scanned {total} custom-SQL nodes so far...")

print(f"\nscanned {total} custom-SQL nodes across {page} pages")

# Resolve workbook hits per needle (dedupe by workbook luid). Note BI_DB_DDR_CID_Level
# is a substring of BI_DB_DDR_CID_Level_Auxiliary_Metrics, so we collapse:
# attribute a hit to BI_DB_DDR_CID_Level ONLY if the SQL also contains the bare table
# (not just the _Auxiliary_Metrics variant).
def is_real_cid_level_hit(sql: str) -> bool:
    # match BI_DB_DDR_CID_Level not followed by _Auxiliary
    return bool(re.search(r"BI_DB_DDR_CID_Level(?!_Auxiliary)\b", sql, flags=re.IGNORECASE))


def collect_workbooks(csql_node):
    out = []
    ds_names = ", ".join(sorted({(d.get("name") or "?") + f"({d.get('__typename')})"
                                  for d in (csql_node.get("downstreamDatasources") or [])}))
    for wb in (csql_node.get("downstreamWorkbooks") or []):
        out.append({**wb, "via": ds_names or "(unknown)"})
    return out


for needle in NEEDLES:
    nodes = hits[needle]
    if needle == "BI_DB_DDR_CID_Level":
        nodes = [n for n in nodes if is_real_cid_level_hit(n.get("query") or "")]
    print(f"\n=== {needle}: {len(nodes)} custom-SQL nodes contain this table ===")
    workbook_map = {}
    for c in nodes:
        wbs = collect_workbooks(c)
        sql_excerpt = re.sub(r"\s+", " ", c.get("query") or "")[:150]
        for wb in wbs:
            key = wb.get("luid")
            workbook_map.setdefault(key, {"name": wb.get("name"),
                                          "project": wb.get("projectName"),
                                          "owner": (wb.get("owner") or {}).get("name"),
                                          "vias": set(),
                                          "csql_examples": []})
            workbook_map[key]["vias"].add(wb.get("via", ""))
            if len(workbook_map[key]["csql_examples"]) < 2:
                workbook_map[key]["csql_examples"].append(sql_excerpt)
    if not workbook_map:
        print("  (no downstream workbooks resolved)")
    for luid, w in sorted(workbook_map.items(), key=lambda kv: (kv[1]["project"] or "", kv[1]["name"] or "")):
        print(f"  - {w['name']!r}  | project={w['project']}  | owner={w['owner']}  | luid={luid}")
        for v in sorted(w["vias"]):
            print(f"      via: {v}")
