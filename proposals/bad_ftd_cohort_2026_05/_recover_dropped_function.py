"""
URGENT RECOVERY: restore BI_DB_dbo.Function_Population_First_Time_Funded
which was dropped by the failed ALTER deploy.

Uses the captured PROD definition (which is what bidev had as of 2025-12-01,
since Nir S deployed the same code to both at that time).
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from synapse_connect import connect  # noqa: E402


# Step 1: Minimal test CREATE FUNCTION
TEST_FN = """CREATE FUNCTION [BI_DB_dbo].[fn_test_ftd_recovery_minimal] ()
RETURNS TABLE
AS RETURN (SELECT CAST(1 AS INT) AS x)"""

CLEAN_TEST = "IF OBJECT_ID(N'[BI_DB_dbo].[fn_test_ftd_recovery_minimal]') IS NOT NULL DROP FUNCTION [BI_DB_dbo].[fn_test_ftd_recovery_minimal]"


def main():
    conn = connect()
    conn.autocommit = True
    cur = conn.cursor()

    print("\n=== Step 1: probe whether CREATE FUNCTION works at all ===", flush=True)
    cur.execute(CLEAN_TEST)
    try:
        cur.execute(TEST_FN)
        print("OK -- minimal CREATE FUNCTION works on bidev.", flush=True)
    except Exception as e:
        print(f"FAILED on minimal CREATE: {e}", flush=True)
        print("This means Synapse Dedicated Pool here has a different limitation.", flush=True)
        cur.close(); conn.close()
        return 1
    cur.execute(CLEAN_TEST)
    print("Cleaned up minimal test function.", flush=True)

    # Step 2: probe whether SET SCHEMA COMPENSATION matters
    print("\n=== Step 2: restore Function_Population_First_Time_Funded ===", flush=True)
    print("Will run the captured prod definition.", flush=True)
    print("Reading the prod definition from proposals file...", flush=True)

    sql_path = Path(__file__).parent / "Function_Population_First_Time_Funded.synapse.sql"
    text = sql_path.read_text(encoding="utf-8")
    start = text.find("ALTER FUNCTION [")
    body = text[start:].rstrip()
    if body.endswith("GO"):
        body = body[:-2].rstrip()
    if body.endswith(";"):
        body = body[:-1].rstrip()
    create_stmt = body.replace("ALTER FUNCTION", "CREATE FUNCTION", 1)

    # Print the first 200 chars to inspect
    print(f"First 200 chars of CREATE statement:\n  {create_stmt[:200]!r}\n", flush=True)

    try:
        cur.execute(create_stmt)
        print("OK -- Function_Population_First_Time_Funded restored.", flush=True)
    except Exception as e:
        print(f"FAILED: {e}", flush=True)
        cur.close(); conn.close()
        return 2

    cur.close(); conn.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
