"""
Deploy Cat3a fixed view alter.sql files to Unity Catalog.
Skips comment-only lines. Runs all statements in a single session.
"""
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))

from databricks import sql

ALTER_FILES = [
    r"C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer.alter.sql",
    r"C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.alter.sql",
    r"C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotEquity_FromDateID.alter.sql",
]


def load_statements(path):
    """Split SQL file into statements, accumulating lines until any line ends with ';'.
    Skips comment-only lines and blank lines."""
    with open(path, encoding="utf-8") as f:
        raw = f.read()

    statements = []
    current = []
    for line in raw.splitlines():
        stripped = line.strip()
        if stripped.startswith("--") or stripped == "":
            continue
        current.append(line)
        if stripped.endswith(";"):
            stmt = "\n".join(current).strip()
            if stmt:
                statements.append(stmt)
            current = []
    if current:
        stmt = "\n".join(current).strip()
        if stmt:
            statements.append(stmt)
    return statements


def main():
    conn = sql.connect(
        server_hostname="adb-5142916747090026.6.azuredatabricks.net",
        http_path="/sql/1.0/warehouses/208214768b0e0308",
        auth_type="databricks-oauth",
    )
    cursor = conn.cursor()

    total_ok = 0
    total_fail = 0

    for path in ALTER_FILES:
        stmts = load_statements(path)
        label = os.path.basename(path)
        print(f"\n=== {label} ({len(stmts)} statements) ===")
        ok = fail = 0
        for stmt in stmts:
            try:
                cursor.execute(stmt)
                ok += 1
                print(f"  OK: {stmt[:80].replace(chr(10), ' ')}")
            except Exception as e:
                fail += 1
                print(f"  FAIL: {e}")
                print(f"    SQL: {stmt[:120].replace(chr(10), ' ')}")
        print(f"  Result: {ok}/{ok+fail} succeeded")
        total_ok += ok
        total_fail += fail

    cursor.close()
    conn.close()
    print(f"\n=== TOTAL: {total_ok}/{total_ok+total_fail} succeeded ===")


if __name__ == "__main__":
    main()
