# BI_DB_dbo.BI_DB_IndexDividends_Alert — Column Lineage

## Source Systems

| Source | Type | Description |
|--------|------|-------------|
| BI_DB_dbo.BI_DB_DailyDividendsByPosition | BI_DB Table | Position-level daily dividends |
| BI_DB_dbo.BI_DB_Index_Dividend_TaxReport | BI_DB Table | Index dividend tax report |
| BI_DB_dbo.BI_DB_Index_Dividend_TaxReport_CID_Level | BI_DB Table | CID-level index dividend tax |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|----------------|-------------|---------------|-----------|
| Date | All 3 source tables | DateID | CAST from YYYYMMDD int to DATE |
| TableName | — | — | Hardcoded string literal identifying which source table had NULL BuyTax |
| BuyTax_Null_Ind | All 3 source tables | BuyTax | MAX(CASE WHEN BuyTax IS NULL THEN 1 ELSE 0 END), only rows where =1 |
| UpdateDate | — | — | @Date parameter (SP execution date) |

## Pipeline

```
BI_DB_dbo.BI_DB_DailyDividendsByPosition (BuyTax NULLs, last 30 days)
  + BI_DB_dbo.BI_DB_Index_Dividend_TaxReport (BuyTax NULLs, last 30 days)
  + BI_DB_dbo.BI_DB_Index_Dividend_TaxReport_CID_Level (BuyTax NULLs, last 30 days)
    |-- SP_IndexDividend_Alert @Date (daily TRUNCATE + INSERT) --|
    |   UNION ALL of dates with NULL BuyTax from each table      |
    v
BI_DB_dbo.BI_DB_IndexDividends_Alert (0 rows when healthy)
```
