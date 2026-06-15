"""One-off deploy: push all four AppsFlyer ALTER scripts to Unity Catalog.

Mirrors tools/deploy_ddr_enrichment.py but:
  * Accepts files from any path (not just BI_DB_dbo/Tables).
  * Recognises ALTER TABLE, ALTER VIEW, COMMENT ON TABLE / VIEW / COLUMN
    as valid statement headers.
  * Writes a LAST EXECUTION footer back into each file on success.

Files (in deploy order):
  1. de_output silver fact      (87 statements: 1 table comment + 86 column comments)
  2. bi_db gold mirror suppl.   (10 statements: 1 refreshed table comment + 9 column comments)
  3. bi_db CID bridge           (12 statements: 1 table comment + 1 tags + 11 column comments) -- tags are 1 stmt
  4. bridgeclaw view            (35 statements: 1 view comment + 33 column comments + 1 tags)
"""
from __future__ import annotations
import os, re, sys, time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

ALTER_FILES = [
    ROOT / "knowledge" / "UC_generated" / "de_output" / "Tables" / "de_output_appsflyer_silver_reports.alter.sql",
    ROOT / "knowledge" / "synapse" / "Wiki" / "BI_DB_dbo" / "Tables" / "BI_DB_AppFlyer_Reports.alter.sql",
    ROOT / "knowledge" / "UC_generated" / "bi_db" / "Tables" / "bronze_marketperformance_tracking_customer.alter.sql",
    ROOT / "knowledge" / "UC_generated" / "bridgeclaw_permitted_data" / "Views" / "appflyer_reports.alter.sql",
]

STMT_STARTERS = (
    "ALTER TABLE", "ALTER VIEW",
    "COMMENT ON TABLE", "COMMENT ON VIEW", "COMMENT ON COLUMN",
)


def strip_footer(raw: str) -> str:
    return re.sub(
        r"\n*-- == LAST EXECUTION ==.*?-- ====================",
        "", raw, flags=re.DOTALL,
    ).rstrip()


def parse_statements(content: str) -> list[str]:
    content = strip_footer(content)
    stmts, current = [], []
    for line in content.splitlines():
        stripped = line.strip()
        if any(stripped.startswith(s) for s in STMT_STARTERS):
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


def label_for(stmt: str) -> str:
    s = stmt.upper()
    m = re.search(r"ALTER COLUMN (\w+)", stmt)
    if m:
        return f"col {m.group(1):24s}"
    m = re.search(r"COMMENT ON COLUMN [\w\.]+\.(\w+)", stmt)
    if m:
        return f"col {m.group(1):24s}"
    if "COMMENT ON TABLE" in s or "COMMENT ON VIEW" in s:
        return "table comment           "
    if "TBLPROPERTIES" in s:
        return "tblproperties           "
    if "SET TAGS" in s:
        return "tags                    "
    return "other                   "


def append_footer(path: Path, n_ok: int, n_total: int) -> None:
    raw = path.read_text(encoding="utf-8")
    raw = strip_footer(raw).rstrip()
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    footer = (
        "\n\n-- == LAST EXECUTION ==\n"
        f"-- Timestamp: {ts}\n"
        "-- Batch: appsflyer one-shot deploy (proposals/appsflyer_one_shot/deploy.py)\n"
        f"-- Statements: {n_ok}/{n_total} succeeded\n"
        "-- ====================\n"
    )
    path.write_text(raw + footer, encoding="utf-8")


def main() -> None:
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

    for fpath in ALTER_FILES:
        if not fpath.exists():
            print(f"[SKIP] {fpath} not found", flush=True)
            continue

        raw = fpath.read_text(encoding="utf-8")
        stmts = parse_statements(raw)
        print("=" * 70, flush=True)
        print(f"{fpath.name}  ({len(stmts)} statements)", flush=True)
        print("=" * 70, flush=True)

        ok = fail = 0
        t0 = time.time()
        for i, stmt in enumerate(stmts, 1):
            label = label_for(stmt)
            try:
                cur.execute(stmt)
                ok += 1
                print(f"  [{i:3d}/{len(stmts)}] OK   {label}", flush=True)
            except Exception as e:
                fail += 1
                msg = str(e).splitlines()[0][:200]
                print(f"  [{i:3d}/{len(stmts)}] FAIL {label} :: {msg}", flush=True)

        dt = time.time() - t0
        print(f"  -> {ok}/{len(stmts)} OK, {fail} failed in {dt:.1f}s\n", flush=True)
        append_footer(fpath, ok, len(stmts))
        grand_ok += ok
        grand_fail += fail

    print("=" * 70, flush=True)
    print(f"GRAND TOTAL: {grand_ok} OK, {grand_fail} failed", flush=True)
    print("=" * 70, flush=True)

    cur.close()
    conn.close()
    sys.exit(0 if grand_fail == 0 else 1)


if __name__ == "__main__":
    main()
