from pathlib import Path
import sys

sys.path.append(str(Path(__file__).resolve().parents[3]))

from synapse_connect import connect, run_query, print_table

q = """
SELECT 'Ext_FCUPNL_Trade_Position' AS table_name,
       COUNT_BIG(*) AS rows_cnt,
       SUM(CAST(AmountInUnitsDecimal AS DECIMAL(38,10))) AS sum_amount_units,
       SUM(CAST(InitForexRate AS DECIMAL(38,10))) AS sum_init_forex,
       SUM(CAST(CommissionByUnits AS DECIMAL(38,10))) AS sum_commission_by_units,
       SUM(CAST(FullCommissionByUnits AS DECIMAL(38,10))) AS sum_full_commission_by_units,
       SUM(CAST(PnLInDollars AS DECIMAL(38,10))) AS sum_pnl_dollars
FROM DWH_dbo.Ext_FCUPNL_Trade_Position
UNION ALL
SELECT 'Ext_FCUPNL_History_Position' AS table_name,
       COUNT_BIG(*) AS rows_cnt,
       SUM(CAST(AmountInUnitsDecimal AS DECIMAL(38,10))) AS sum_amount_units,
       SUM(CAST(InitForexRate AS DECIMAL(38,10))) AS sum_init_forex,
       SUM(CAST(CommissionByUnits AS DECIMAL(38,10))) AS sum_commission_by_units,
       SUM(CAST(FullCommissionByUnits AS DECIMAL(38,10))) AS sum_full_commission_by_units,
       SUM(CAST(EndOfDayPnLInDollars AS DECIMAL(38,10))) AS sum_pnl_dollars
FROM DWH_dbo.Ext_FCUPNL_History_Position
UNION ALL
SELECT 'Fact_SnapshotEquity@20260619' AS table_name,
       COUNT_BIG(*) AS rows_cnt,
       SUM(CAST(TotalPositionsAmount+TotalCash+TotalStockOrders+InProcessCashouts AS DECIMAL(38,10))) AS sum_amount_units,
       SUM(CAST(Credit AS DECIMAL(38,10))) AS sum_init_forex,
       NULL AS sum_commission_by_units,
       NULL AS sum_full_commission_by_units,
       NULL AS sum_pnl_dollars
FROM DWH_dbo.Fact_SnapshotEquity a
JOIN DWH_dbo.V_M2M_Date_DateRange b
  ON a.DateRangeID = b.DateRangeID
WHERE b.DateKey = 20260619
"""

conn = connect()
cols, rows = run_query(conn, q)
print_table(cols, rows)
conn.close()
