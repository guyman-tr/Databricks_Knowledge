import sys
sys.path.insert(0, ".")
from synapse_connect import connect, run_query

c = connect(verbose=False)
c.timeout = 900
try:
    cols, rows = run_query(
        c,
        "SELECT COUNT_BIG(*) AS cnt FROM BI_DB_dbo.BI_DB_PositionPnL",
    )
    print("COUNT_BIG:", rows)

    cols2, rows2 = run_query(
        c,
        "SELECT MIN(DateID) AS MinDateID, MAX(DateID) AS MaxDateID FROM BI_DB_dbo.BI_DB_PositionPnL",
    )
    print("MIN_MAX:", rows2)
finally:
    c.close()
