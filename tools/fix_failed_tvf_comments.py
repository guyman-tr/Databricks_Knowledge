"""
Apply COMMENT ON COLUMN to the 2 TVF views that failed CREATE OR REPLACE VIEW.

v_population_funded  — column count mismatch blocked DDL rebuild
v_pnl_single_day     — dependency on missing bi_output_stg view blocked DDL rebuild

COMMENT ON COLUMN never touches the DDL, so it works on any live view.
"""

import os, re, sys

REPO_ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))
FUNC_DIR  = os.path.join(REPO_ROOT, "knowledge", "synapse", "Wiki", "BI_DB_dbo", "Functions")

DBX_HOST      = "adb-5142916747090026.6.azuredatabricks.net"
DBX_HTTP_PATH = "/sql/1.0/warehouses/208214768b0e0308"

TARGETS = [
    ("Function_Population_Funded",  "main.etoro_kpi_prep.v_population_funded"),
    ("Function_PnL_Single_Day",     "main.etoro_kpi_prep.v_pnl_single_day"),
]

MAX_COMMENT = 500

# ---------------------------------------------------------------------------
# Wiki parser (identical to recreate_views_with_col_comments.py)
# ---------------------------------------------------------------------------

def clean_md(text):
    text = re.sub(r'\*\*(.+?)\*\*', r'\1', text)
    text = re.sub(r'\*(.+?)\*',     r'\1', text)
    text = re.sub(r'`([^`]+)`',     r'\1', text)
    text = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', text)
    return re.sub(r'\s+', ' ', text).strip()

def esc(text):
    return text.replace("'", "''")

def truncate(text, limit):
    return text if len(text) <= limit else text[:limit - 3] + "..."

def parse_wiki_cols(tvf_name):
    path = os.path.join(FUNC_DIR, tvf_name + ".md")
    with open(path, encoding="utf-8") as f:
        content = f.read()

    m4 = re.search(r'## 4\. Output Columns\s*\n(.*?)(?=\n## |\Z)', content, re.DOTALL)
    cols = {}
    if not m4:
        return cols

    for line in m4.group(1).splitlines():
        line = line.strip()
        if not line.startswith('|') or line.startswith('|---') or '# |' in line:
            continue
        parts = [p.strip() for p in line.split('|')]
        if len(parts) < 6:
            continue
        col_raw   = parts[2].strip().strip('*').strip('`')
        source    = clean_md(parts[3].strip())
        transform = clean_md(parts[4].strip())
        tier      = parts[5].strip()
        if not col_raw or col_raw.lower() == 'column':
            continue
        if transform.lower() in ("direct", "direct pass-through",
                                  "direct from union branches", "direct from union row"):
            comment = f"Direct pass-through from {source}. ({tier} — {tvf_name})"
        else:
            comment = f"{transform}. Source: {source}. ({tier} — {tvf_name})"
        cols[col_raw.lower()] = truncate(comment, MAX_COMMENT)

    return cols

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    from databricks import sql
    print(f"Connecting to {DBX_HOST}...")
    conn = sql.connect(
        server_hostname=DBX_HOST,
        http_path=DBX_HTTP_PATH,
        auth_type="databricks-oauth",
    )
    cursor = conn.cursor()
    print("Connected.\n")

    total_ok = total_fail = 0

    for tvf_name, uc_name in TARGETS:
        print(f"{'='*60}")
        print(f"  {tvf_name}  ->  {uc_name}")

        wiki_cols = parse_wiki_cols(tvf_name)
        print(f"  Wiki: {len(wiki_cols)} columns from §4")

        # Get actual columns from UC
        try:
            cursor.execute(f"DESCRIBE TABLE {uc_name}")
            uc_cols = [row[0] for row in cursor.fetchall()
                       if row[0] and not row[0].startswith("#")]
        except Exception as e:
            print(f"  SKIP — DESCRIBE failed: {e}")
            continue

        ok = fail = 0
        for col in uc_cols:
            desc = wiki_cols.get(col.lower())
            if not desc:
                continue
            stmt = f"COMMENT ON COLUMN {uc_name}.`{col}` IS '{esc(desc)}'"
            try:
                cursor.execute(stmt)
                ok += 1
            except Exception as e:
                fail += 1
                print(f"  WARN {col}: {e}")

        print(f"  {ok} comments applied, {fail} failed, "
              f"{len(uc_cols) - ok - fail} columns had no wiki description")
        total_ok += ok
        total_fail += fail

    cursor.close()
    conn.close()
    print(f"\nDone. Total: {total_ok} applied, {total_fail} failed.")

if __name__ == "__main__":
    main()
