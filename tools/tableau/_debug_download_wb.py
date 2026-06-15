"""Download a workbook by luid and dump every table mentioned in its XML.
This bypasses Metadata API limitations (custom SQL, extracts, etc)."""
import datetime, json, os, re, sys, uuid, warnings, zipfile, io
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
needles = sys.argv[2].split(",") if len(sys.argv) > 2 else [
    "BI_DB_DDR_CID_Level",
    "BI_DB_DDR_CID_Level_Auxiliary_Metrics",
    "BI_DB_DDR_Daily_Aggregated_Auxiliary_Metrics",
    "BI_DB_DDR_TimeRange_Aggregated_Country_Level",
    "BI_DB_DDR_New_TimeRange_Aggregated_Country_Level",
]

srv = sign_in()
out_dir = Path(_env("USERPROFILE")) / "Downloads" / "tableau_workbook_dumps"
out_dir.mkdir(parents=True, exist_ok=True)
path = srv.workbooks.download(luid, filepath=str(out_dir), include_extract=False)
print(f"Downloaded to: {path}")

# Read XML. .twbx is a zip containing a .twb; .twb is raw XML.
if path.endswith(".twbx"):
    with zipfile.ZipFile(path) as z:
        twb_names = [n for n in z.namelist() if n.endswith(".twb")]
        if not twb_names:
            print("No .twb inside .twbx"); sys.exit(1)
        with z.open(twb_names[0]) as f:
            xml = f.read().decode("utf-8", errors="replace")
elif path.endswith(".twb"):
    xml = Path(path).read_text(encoding="utf-8", errors="replace")
else:
    print(f"Unexpected file type: {path}"); sys.exit(1)

print(f"\nXML length: {len(xml):,} chars\n")

# 1) Find every datasource block + summarize relations / custom SQL
ds_blocks = re.findall(r"<datasource[^>]*name=['\"]([^'\"]+)['\"][^>]*>.*?</datasource>", xml, flags=re.DOTALL)
ds_names = re.findall(r"<datasource[^>]*\s(?:formatted-name|caption|name)=['\"]([^'\"]+)['\"]", xml)
print(f"Top-level datasources (name attrs): {sorted(set(ds_names))[:20]}")

# 2) Find every relation (table reference)
relations = re.findall(r"<relation[^>]*\sname=['\"]([^'\"]+)['\"][^>]*\stype=['\"]([^'\"]+)['\"]", xml)
print(f"\nRelations ({len(relations)}):")
for n, t in relations[:30]:
    print(f"  - type={t} name={n}")

# 3) Find any <relation type='text'> custom SQL bodies
csqls = re.findall(r"<relation[^>]*\stype=['\"]text['\"][^>]*>(.*?)</relation>", xml, flags=re.DOTALL)
print(f"\nCustom-SQL relations: {len(csqls)}")
for i, sql in enumerate(csqls):
    sql_clean = re.sub(r"\s+", " ", sql).strip()
    print(f"\n  [{i+1}] {sql_clean[:600]}")
    hits = sorted(set(re.findall(r"BI_DB_DDR_[A-Za-z0-9_]+", sql_clean)))
    if hits:
        print(f"      BI_DB_DDR_* in SQL: {hits}")

# 4) Direct grep for each needle table name across full XML
print("\n=== Direct grep for needle tables in full XML ===")
for n in needles:
    n = n.strip()
    hits = []
    for m in re.finditer(re.escape(n), xml, flags=re.IGNORECASE):
        start = max(0, m.start() - 60); end = min(len(xml), m.end() + 60)
        snippet = re.sub(r"\s+", " ", xml[start:end])
        hits.append(snippet)
    print(f"\n  '{n}': {len(hits)} hits")
    for h in hits[:5]:
        print(f"     … {h} …")

# 5) Also grep for any [dbo].[BI_DB_DDR_*] or [DWH].[dbo].[BI_DB_DDR_*] patterns to enumerate
print("\n=== All BI_DB_DDR_* table names appearing in workbook XML ===")
all_ddr = sorted(set(re.findall(r"BI_DB_DDR_[A-Za-z0-9_]+", xml)))
for t in all_ddr:
    print(f"  - {t}")
