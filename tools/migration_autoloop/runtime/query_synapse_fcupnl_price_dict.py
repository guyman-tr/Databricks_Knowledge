from pathlib import Path
import sys

sys.path.append(str(Path(__file__).resolve().parents[3]))

from synapse_connect import connect, run_query, print_table

q = """
SELECT 'Ext_FCUPNL_CurrencyPriceMaxDateWithSplit' AS table_name,
       COUNT_BIG(*) AS rows_cnt,
       SUM(CAST(BidSpreaded AS DECIMAL(38,10))) AS sum_bid_spreaded,
       SUM(CAST(AskSpreaded AS DECIMAL(38,10))) AS sum_ask_spreaded,
       SUM(CAST(Bid AS DECIMAL(38,10))) AS sum_bid,
       SUM(CAST(Ask AS DECIMAL(38,10))) AS sum_ask
FROM DWH_dbo.Ext_FCUPNL_CurrencyPriceMaxDateWithSplit
UNION ALL
SELECT 'Ext_FCUPNL_Dictionary_Instrument' AS table_name,
       COUNT_BIG(*) AS rows_cnt,
       SUM(CAST(InstrumentTypeID AS DECIMAL(38,10))) AS sum_bid_spreaded,
       SUM(CAST(BuyCurrencyID AS DECIMAL(38,10))) AS sum_ask_spreaded,
       SUM(CAST(SellCurrencyID AS DECIMAL(38,10))) AS sum_bid,
       NULL AS sum_ask
FROM DWH_dbo.Ext_FCUPNL_Dictionary_Instrument
"""

conn = connect()
cols, rows = run_query(conn, q)
print_table(cols, rows)
conn.close()
