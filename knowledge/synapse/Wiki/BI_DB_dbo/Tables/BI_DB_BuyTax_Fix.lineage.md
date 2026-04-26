# Column Lineage — BI_DB_dbo.BI_DB_BuyTax_Fix

Generated: 2026-04-23 | Writer SP: None (orphaned table) | ETL Frequency: Unknown / ad-hoc

## Production Source

| Property | Value |
|----------|-------|
| **Primary Source** | Unknown — no writer SP populates this table |
| **Source Layer** | Orphaned — SP_BuyTax_Fix exists but reruns other SPs rather than writing here |
| **UC Target** | `_Not_Migrated` |
| **Upstream Wiki** | None |

## ETL Pipeline

```
BI_DB_dbo.BI_DB_BuyTax_Fix
  |-- No writer SP identified --|
  |-- SP_BuyTax_Fix exists but: reads BI_DB_IndexDividends_Alert for dates, --|
  |-- reruns SP_DailyDividendsByPosition + SP_Index_Divident_TaxReport + --|
  |-- SP_Index_Divident_TaxReport_CID_Level, DOES NOT write to this table --|
  v
0 rows (table is empty; vestigial or populated manually ad-hoc)
```

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Tier |
|---|------------|---------------|---------------|-----------|------|
| 1 | Date | Unknown | Unknown | Unknown — no active writer SP; table contains 0 rows | Tier 4 |

## Tier Summary

| Tier | Count | Notes |
|------|-------|-------|
| Tier 4 | 1 | No writer SP identified; table is orphaned/vestigial |
