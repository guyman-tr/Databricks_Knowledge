SELECT '2026-06-15' AS day, count(*) AS rows
FROM parquet.`abfss://internal-sources@dldataplatformprodwe.dfs.core.windows.net/Bronze/DailySnapshot/etr_y=2026/etr_ym=2026-06/etr_ymd=2026-06-15/etoro/Billing/Withdraw`
