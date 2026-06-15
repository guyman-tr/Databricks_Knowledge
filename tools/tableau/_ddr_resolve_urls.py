"""Take the workbook luids found by _ddr_custom_sql_sweep.py and build
clickable Tableau report URLs (one row per workbook, one URL per view).

Output: C:\\Users\\<you>\\Downloads\\ddr_report_urls.csv
        C:\\Users\\<you>\\Downloads\\ddr_report_urls.md
"""
import csv, datetime, json, os, sys, uuid, warnings, re
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


# --- workbook->tables map. Hard-coded from the sweep output to avoid re-scan;
# rebuild any time by re-running tools\tableau\_ddr_custom_sql_sweep.py.
WORKBOOK_TABLE_MAP = {
    "BI_DB_DDR_TimeRange_Aggregated_Country_Level": [
        "f318eefa-b560-4f48-bfb5-760832d21e84", "839b13d1-8f55-44c2-8efc-69b1e98bc0c6",
        "02ac4764-168a-4e05-83aa-283251a3c43b", "8da393ab-d962-4d2b-ac62-bb25c6cd091f",
        "e2b4b0ef-b117-4cc3-96ae-a75178d03b94", "7656392e-c9fc-4e51-ac1c-f5b87971808a",
        "253c9078-7616-4047-8cc5-b8033375b774", "6c2b6c97-172c-43fb-a0b8-5aef56df102d",
        "75fb2bc3-5fbd-4f63-95fe-a05d3c07da85", "8e1d6d6a-3b43-4e00-84f2-4910a43b6422",
        "83c50f54-382f-4bcd-903a-9b98dff6da81", "1ac23aa0-2ee9-4010-8227-27cdc0bf3410",
        "f8fdc211-e8bc-4d4d-b7ef-c50336a8977e", "4c5e3b03-7073-4d67-9c7d-229abecd3315",
        "c46aeee9-977d-40d9-87de-04e2874d3580", "2f64b570-3df7-44d0-b305-f145f3edec88",
        "450d4246-84ca-47ca-9dd6-999311f27d6a", "7d0fa009-d739-43ac-a77a-9447d589647d",
        "d9ed42b1-fd5f-459e-a327-329d7b1c7f9d", "981cefe9-3edc-4a21-b232-42aecc5b314e",
        "399eb4d5-b853-4e04-ad6e-8c8879f5739b", "44f6476d-7e0a-42a8-afd1-2991f89a1aa8",
        "31f8b29f-136d-401a-9c5e-0280c1f0ab41", "bd80c901-20db-423e-b64a-2f0e94521de2",
        "f9aad83c-43d0-4e0b-afe1-4420c8c1f509", "833448b0-83ca-4a8d-9c42-01b7ef642d0a",
        "0e12f293-3f47-431f-a56a-6ae3ca0a3257", "a82fd6be-125b-47bb-aea5-f257ce0ae733",
        "6b730edd-21ff-47c3-a39a-0217f74641d4", "32ce6691-3b49-46fe-919b-153d44ecbe54",
        "36e6dfdd-6d79-4824-9d09-ead1a59d82f9", "36aba8cb-6bf1-43b8-8f8b-e2a85149f0bf",
        "6c2b84df-8224-4168-9d4a-2a03fcd5dfa7",
    ],
    "BI_DB_DDR_CID_Level": [
        "c4130712-f3e0-4944-807a-8a4a35773dca", "e373bf70-508e-4e77-be92-3718384eda4c",
        "36fa4e24-96a2-4639-a7dd-2fe06140474c", "df3e4194-4243-4d7e-a203-5805bc76c613",
        "34d46e01-9e2c-41e2-ac1b-a873c6906baf", "5c2df773-6734-4466-9fe5-ea713ddac8fe",
    ],
}

SERVER = _env("TABLEAU_SERVER").rstrip("/")
SITE_NAME = os.getenv("TABLEAU_SITE_NAME", "") or ""
SITE_SEG = f"/site/{SITE_NAME}" if SITE_NAME else ""


def build_workbook_url(content_url: str) -> str:
    # contentUrl on a workbook is enough; clicking takes you to the overview.
    # Form mirrors the URL the user shared.
    return f"{SERVER}/#{SITE_SEG}/workbooks/{content_url}"


def build_view_url(workbook_content_url: str, view_content_url: str) -> str:
    # TSC view.content_url is "<workbook_slug>/sheets/<view_slug>".
    # Tableau view URL format is /#/views/<workbook_slug>/<view_slug>, so we
    # strip everything up to and including '/sheets/'.
    if "/sheets/" in view_content_url:
        view_slug = view_content_url.rsplit("/sheets/", 1)[-1]
    else:
        view_slug = view_content_url
    return f"{SERVER}/#{SITE_SEG}/views/{workbook_content_url}/{view_slug}"


srv = sign_in()
print(f"Tableau server: {SERVER}  site={'(default)' if not SITE_NAME else SITE_NAME}")

# Build a global owner_id -> name map via Metadata API (paginated; tableau caps page at 1000).
OWNER_Q = """
query owners($after: String) {
  workbooksConnection(first: 1000, after: $after) {
    pageInfo { hasNextPage endCursor }
    nodes { luid owner { name username } }
  }
}
"""
_owner_by_luid: dict[str, str] = {}
_after = None
while True:
    _r = srv.metadata.query(OWNER_Q, variables={"after": _after})
    _conn = (_r.get("data") or {}).get("workbooksConnection") or {}
    for n in _conn.get("nodes") or []:
        o = n.get("owner") or {}
        _owner_by_luid[n.get("luid") or ""] = o.get("name") or o.get("username") or ""
    _pi = _conn.get("pageInfo") or {}
    if not _pi.get("hasNextPage"):
        break
    _after = _pi.get("endCursor")
print(f"loaded owner map for {len(_owner_by_luid)} workbooks via metadata API")

# Build reverse map: luid -> [tables]
luid_to_tables: dict[str, list[str]] = {}
for table, luids in WORKBOOK_TABLE_MAP.items():
    for luid in luids:
        luid_to_tables.setdefault(luid, []).append(table)
all_luids = list(luid_to_tables.keys())
print(f"resolving URLs for {len(all_luids)} distinct workbook luids...")

# Get contentUrl + name + project + owner via REST (single batched filter by id list isn't
# supported by TSC, but luid lookup is one call per workbook; cheap with N<50).
rows: list[dict] = []
for i, luid in enumerate(all_luids, 1):
    try:
        wb = srv.workbooks.get_by_id(luid)
    except Exception as e:
        print(f"  [{i}/{len(all_luids)}] {luid}: REST get_by_id FAILED ({e})")
        rows.append({"luid": luid, "name": "(unavailable)", "project_name": "", "owner_name": "",
                      "content_url": "", "workbook_url": "", "view_urls": "",
                      "tables": ";".join(luid_to_tables[luid])})
        continue
    # Populate views (separate call)
    srv.workbooks.populate_views(wb)
    view_urls = []
    for v in (wb.views or []):
        if v.content_url:
            view_urls.append(build_view_url(wb.content_url, v.content_url))
    workbook_url = build_workbook_url(wb.content_url) if wb.content_url else ""
    owner_name = _owner_by_luid.get(luid, "") or "(unknown)"
    rows.append({
        "luid": luid,
        "name": wb.name,
        "project_name": wb.project_name,
        "owner_name": owner_name,
        "content_url": wb.content_url,
        "workbook_url": workbook_url,
        "view_urls": "\n".join(view_urls),
        "tables": ";".join(luid_to_tables[luid]),
    })
    if i % 10 == 0:
        print(f"  resolved {i}/{len(all_luids)}")

# Sort: by primary table (most-mentioned), then project, then name
def sort_key(r):
    tbls = r["tables"].split(";")
    primary = tbls[0] if tbls else ""
    return (primary, (r.get("project_name") or ""), (r.get("name") or ""))


rows.sort(key=sort_key)

downloads = Path(_env("USERPROFILE")) / "Downloads"
csv_path = downloads / "ddr_report_urls.csv"
md_path = downloads / "ddr_report_urls.md"

with csv_path.open("w", encoding="utf-8", newline="") as f:
    w = csv.writer(f)
    w.writerow(["table", "workbook", "project", "owner", "workbook_url", "view_url", "luid"])
    for r in rows:
        view_list = r["view_urls"].split("\n") if r["view_urls"] else [""]
        for v in view_list:
            for tbl in r["tables"].split(";"):
                w.writerow([tbl, r["name"], r["project_name"], r["owner_name"],
                            r["workbook_url"], v, r["luid"]])
print(f"\nWrote {csv_path}")

# Markdown by table
md = ["# DDR table -> Tableau report URLs",
      f"_Generated {datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M UTC')} • "
      f"source: tools/tableau/_ddr_custom_sql_sweep.py + _ddr_resolve_urls.py_\n",
      "Workbook URL opens the report's overview; view URLs deep-link to each tab.\n"]
by_table: dict[str, list[dict]] = {}
for r in rows:
    for tbl in r["tables"].split(";"):
        by_table.setdefault(tbl, []).append(r)

for tbl in ["BI_DB_DDR_CID_Level",
            "BI_DB_DDR_CID_Level_Auxiliary_Metrics",
            "BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics",
            "BI_DB_DDR_TimeRange_Aggregated_Country_Level"]:
    items = by_table.get(tbl, [])
    md.append(f"\n## `{tbl}` — {len(items)} workbook(s)\n")
    if not items:
        md.append("_no workbooks reference this table (neither via direct upstream nor via custom SQL)_\n")
        continue
    items.sort(key=lambda r: ((r.get("project_name") or ""), (r.get("name") or "")))
    for r in items:
        md.append(f"### [{r['name']}]({r['workbook_url']})")
        md.append(f"- project: `{r['project_name']}`")
        md.append(f"- owner: {r['owner_name']}")
        md.append(f"- workbook URL: {r['workbook_url']}")
        views = [v for v in r["view_urls"].split("\n") if v]
        if views:
            md.append(f"- views ({len(views)}):")
            for v in views:
                # show last URL path segment as friendly label
                label = v.rsplit("/", 1)[-1]
                md.append(f"  - [{label}]({v})")
        md.append("")

md_path.write_text("\n".join(md), encoding="utf-8")
print(f"Wrote {md_path}")
print(f"\nDone. {len(rows)} workbooks, {sum(1 for r in rows if r['view_urls'])} with at least one view URL.")
