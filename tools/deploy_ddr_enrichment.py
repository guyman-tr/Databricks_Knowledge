"""Deploy enriched DDR column comments to Unity Catalog.
Uses databricks.sql connector (same as deploy_alter_batch.py) for fast execution.
"""
import os, re, sys, time
from pathlib import Path
from datetime import datetime, timezone

WIKI_ROOT = Path(__file__).resolve().parents[1] / "knowledge" / "synapse" / "Wiki" / "BI_DB_dbo" / "Tables"

ALTER_FILES = [
    "BI_DB_DDR_Customer_Daily_Status.alter.sql",
    "BI_DB_DDR_Fact_MIMO_AllPlatforms.alter.sql",
    "BI_DB_DDR_Fact_Trading_Volumes_And_Amounts.alter.sql",
    "BI_DB_DDR_Customer_Periodic_Status.alter.sql",
    "BI_DB_DDR_Fact_Revenue_Generating_Actions.alter.sql",
    "BI_DB_CIDFirstDates.alter.sql",
]

def strip_footer(raw: str) -> str:
    return re.sub(
        r"\n*-- == LAST EXECUTION ==.*?-- ====================",
        "", raw, flags=re.DOTALL,
    ).rstrip()

def parse_statements(content: str) -> list[str]:
    content = strip_footer(content)
    stmts, current = [], []
    for line in content.splitlines():
        if line.strip().startswith("ALTER TABLE") or line.strip().startswith("ALTER VIEW"):
            if current:
                stmts.append("\n".join(current).strip())
            current = [line]
        elif current:
            current.append(line)
            if line.rstrip().endswith(";"):
                stmts.append("\n".join(current).strip())
                current = []
    if current:
        stmts.append("\n".join(current).strip())
    return [s for s in stmts if s]

def main():
    from databricks import sql

    host = os.environ.get("DATABRICKS_SERVER_HOSTNAME", "adb-5142916747090026.6.azuredatabricks.net")
    http_path = os.environ.get("DATABRICKS_HTTP_PATH", "/sql/1.0/warehouses/208214768b0e0308")
    token = (os.environ.get("DATABRICKS_TOKEN") or "").strip()

    print("Connecting to Databricks...", flush=True)
    if token:
        print("Auth: PAT", flush=True)
        conn = sql.connect(server_hostname=host, http_path=http_path, access_token=token)
    else:
        print("Auth: databricks-oauth", flush=True)
        conn = sql.connect(server_hostname=host, http_path=http_path, auth_type="databricks-oauth")
    cur = conn.cursor()
    print("Connected.\n", flush=True)

    grand_ok = grand_fail = 0

    for fname in ALTER_FILES:
        fpath = WIKI_ROOT / fname
        if not fpath.exists():
            print(f"[SKIP] {fname} not found", flush=True)
            continue

        raw = fpath.read_text(encoding="utf-8")
        stmts = parse_statements(raw)
        print(f"{'='*60}", flush=True)
        print(f"{fname}  ({len(stmts)} statements)", flush=True)
        print(f"{'='*60}", flush=True)

        ok = fail = 0
        t0 = time.time()
        for i, stmt in enumerate(stmts, 1):
            col_match = re.search(r"ALTER COLUMN (\w+)", stmt)
            col_name = col_match.group(1) if col_match else "tbl"
            action = ("COMMENT" if "COMMENT" in stmt.upper() else
                      "TAGS" if "TAGS" in stmt.upper() else
                      "TBLPROPS" if "TBLPROPERTIES" in stmt.upper() else "OTHER")
            try:
                cur.execute(stmt)
                ok += 1
                if i % 20 == 0 or i == len(stmts):
                    print(f"  [{i:3d}/{len(stmts)}] OK   last: {action:8s} {col_name}", flush=True)
            except Exception as e:
                fail += 1
                print(f"  [{i:3d}/{len(stmts)}] FAIL {action:8s} {col_name}  => {str(e)[:150]}", flush=True)

        elapsed = time.time() - t0
        print(f"  => {ok} OK, {fail} FAIL in {elapsed:.0f}s\n", flush=True)

        ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
        footer = f"\n-- == LAST EXECUTION ==\n-- Timestamp: {ts}\n-- TVF DDR enrichment deploy\n-- Statements: {ok}/{ok+fail} succeeded\n-- ====================\n"
        fpath.write_text(strip_footer(raw) + footer, encoding="utf-8")

        grand_ok += ok
        grand_fail += fail

    cur.close()
    conn.close()

    print(f"{'='*60}", flush=True)
    print(f"GRAND TOTAL: {grand_ok} OK, {grand_fail} FAIL", flush=True)
    print(f"{'='*60}", flush=True)

if __name__ == "__main__":
    main()
