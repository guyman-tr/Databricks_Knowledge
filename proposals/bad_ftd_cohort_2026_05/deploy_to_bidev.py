"""
Deploy + smoke-test the bad-FTD cohort exclusion to Synapse STG (bidev).
Uses autocommit=True to satisfy Synapse Dedicated Pool's "DDL not in transaction" rule.

Target objects:
    BI_DB_dbo.Function_Population_First_Time_Funded
    BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms

Environment defaults: stg-synapse-dataplatform-we.sql.azuresynapse.net
(see synapse_connect.py for overrides)
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from synapse_connect import connect, run_query, print_table  # noqa: E402


HERE = Path(__file__).parent

FILES = [
    ("Function_Population_First_Time_Funded", HERE / "Function_Population_First_Time_Funded.synapse.sql"),
    ("Function_MIMO_First_Deposit_All_Platforms", HERE / "Function_MIMO_First_Deposit_All_Platforms.synapse.sql"),
]


def extract_alter(text: str) -> str:
    """Strip the leading comment block, trailing GO, and return the function body.

    Synapse Dedicated SQL Pool does NOT support ALTER FUNCTION - it only allows
    CREATE / DROP. This helper returns the CREATE FUNCTION statement (rewriting
    the ALTER keyword from the proposal file).
    """
    start = text.find("ALTER FUNCTION [")
    if start < 0:
        start = text.find("CREATE FUNCTION [")
        if start < 0:
            raise ValueError("ALTER/CREATE FUNCTION [ not found in script")
    body = text[start:]
    body = body.rstrip()
    if body.endswith("GO"):
        body = body[:-2].rstrip()
    if body.endswith(";"):
        body = body[:-1].rstrip()
    body = body.replace("ALTER FUNCTION", "CREATE FUNCTION", 1)
    return body


FUNC_FULL_NAMES = {
    "Function_Population_First_Time_Funded":      "[BI_DB_dbo].[Function_Population_First_Time_Funded]",
    "Function_MIMO_First_Deposit_All_Platforms":  "[BI_DB_dbo].[Function_MIMO_First_Deposit_All_Platforms]",
}


def main():
    print("=" * 70, flush=True)
    print("Deploying bad-FTD exclusion to Synapse bidev (STG)", flush=True)
    print("=" * 70, flush=True)

    conn = connect()
    conn.autocommit = True   # CRITICAL - Synapse Dedicated Pool forbids DDL in tx
    cursor = conn.cursor()

    # 0. Pre-flight: confirm both targets exist
    cursor.execute("""
        SELECT s.name + '.' + o.name AS qname, o.modify_date
        FROM sys.objects o
        JOIN sys.schemas s ON o.schema_id = s.schema_id
        WHERE o.name IN ('Function_Population_First_Time_Funded','Function_MIMO_First_Deposit_All_Platforms')
        ORDER BY o.name
    """)
    rows = cursor.fetchall()
    print("\nPre-flight target check:", flush=True)
    for r in rows:
        print(f"  {r[0]}  (modified: {r[1]})", flush=True)
    if len(rows) != 2:
        print("ABORT: expected 2 functions, found", len(rows), flush=True)
        return 1

    # 1. Baseline row count from each function (pre-deploy)
    print("\nBaseline: FTF row count from current function", flush=True)
    cursor.execute("SELECT COUNT(*) FROM BI_DB_dbo.Function_Population_First_Time_Funded()")
    baseline_ftf = cursor.fetchone()[0]
    print(f"  Function_Population_First_Time_Funded -> {baseline_ftf:,} rows", flush=True)

    cursor.execute("SELECT COUNT(*) FROM BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms(0)")
    baseline_mimo = cursor.fetchone()[0]
    print(f"  Function_MIMO_First_Deposit_All_Platforms(0) -> {baseline_mimo:,} rows", flush=True)

    # 2. Bad-cohort sizes in this environment
    print("\nBidev cohort presence:", flush=True)
    cursor.execute("""
        SELECT
          SUM(CASE WHEN CAST(FirstDepositDate AS DATE) IN ('20250818','20250819','20250820') THEN 1 ELSE 0 END) AS aug2025,
          SUM(CASE WHEN CAST(FirstDepositDate AS DATE) IN ('20260522','20260523','20260525') THEN 1 ELSE 0 END) AS may2026
        FROM DWH_dbo.Dim_Customer
        WHERE FirstDepositAmount = 1
    """)
    aug, may = cursor.fetchone()
    print(f"  Aug-2025 cohort ($1 FTDs): {aug:,}", flush=True)
    print(f"  May-2026 cohort ($1 FTDs): {may:,}", flush=True)

    # 3. Apply each change (DROP + CREATE since Dedicated Pool has no ALTER FUNCTION)
    for name, path in FILES:
        print(f"\nDeploying {name} (DROP + CREATE) ...", flush=True)
        sql = path.read_text(encoding="utf-8")
        create_stmt = extract_alter(sql)
        full_name = FUNC_FULL_NAMES[name]
        try:
            cursor.execute(f"IF OBJECT_ID(N'{full_name}') IS NOT NULL DROP FUNCTION {full_name}")
            print(f"  Dropped {full_name}", flush=True)
            cursor.execute(create_stmt)
            print(f"  Created {full_name}", flush=True)
        except Exception as e:
            print(f"  FAILED: {e}", flush=True)
            print(f"  WARNING: function may have been dropped without successful recreate -- inspect manually.", flush=True)
            raise

    # 4. Post-deploy validation: compile + row count
    print("\nPost-deploy validation:", flush=True)
    cursor.execute("SELECT COUNT(*) FROM BI_DB_dbo.Function_Population_First_Time_Funded()")
    after_ftf = cursor.fetchone()[0]
    print(f"  Function_Population_First_Time_Funded -> {after_ftf:,} rows (delta {after_ftf - baseline_ftf:+,})", flush=True)

    cursor.execute("SELECT COUNT(*) FROM BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms(0)")
    after_mimo = cursor.fetchone()[0]
    print(f"  Function_MIMO_First_Deposit_All_Platforms(0) -> {after_mimo:,} rows (delta {after_mimo - baseline_mimo:+,})", flush=True)

    # 5. Show that the Aug 2025 cohort is excluded by the function (positive control - bidev has this data)
    print("\nFunctional check (Aug-2025 cohort - bidev has this data):", flush=True)
    cursor.execute("""
        SELECT
            (SELECT COUNT(*) FROM DWH_dbo.Dim_Customer
              WHERE CAST(FirstDepositDate AS DATE) IN ('20250818','20250819','20250820')
                AND FirstDepositAmount = 1) AS in_dim_customer,
            (SELECT COUNT(*) FROM BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms(0)
              WHERE CAST(FirstDepositDate AS DATE) IN ('20250818','20250819','20250820')
                AND FirstDepositAmount = 1) AS after_mimo,
            (SELECT COUNT(*) FROM BI_DB_dbo.Function_Population_First_Time_Funded()
              WHERE FTDDateID IN (20250818,20250819,20250820)) AS after_ftf
    """)
    cohort = cursor.fetchone()
    print(f"  In Dim_Customer (raw):                    {cohort[0]:,}", flush=True)
    print(f"  Surviving in MIMO function after deploy:  {cohort[1]:,}", flush=True)
    print(f"  Surviving in FTF function after deploy:   {cohort[2]:,}", flush=True)
    print("  (cohort[1] and cohort[2] should equal the repeat-depositor count, not the raw cohort)", flush=True)

    # 6. Inspect the change history line to confirm version
    print("\nVersion stamp (last 3 history lines):", flush=True)
    cursor.execute("""
        SELECT TOP 1 modify_date FROM sys.objects WHERE name = 'Function_Population_First_Time_Funded'
    """)
    print(f"  Function_Population_First_Time_Funded modify_date: {cursor.fetchone()[0]}", flush=True)

    cursor.close()
    conn.close()
    print("\nDone.\n", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
