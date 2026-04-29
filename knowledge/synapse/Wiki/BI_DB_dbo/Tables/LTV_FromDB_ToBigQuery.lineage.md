# Column Lineage: BI_DB_dbo.LTV_FromDB_ToBigQuery

## Source Objects

| Source | Type | Schema | Role |
|--------|------|--------|------|
| BI_DB_dbo.BI_DB_LTV_BI_Actual | BI_DB Table | BI_DB_dbo | Sole source — canonical customer LTV store |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | CID | BI_DB_LTV_BI_Actual | CID | Passthrough | Tier 1 (via BI_DB_LTV_BI_Actual → Customer.CustomerStatic) |
| 2 | FirstDepositDate | BI_DB_LTV_BI_Actual | FirstDepositDate | Passthrough (filtered: >= @date - 90 days) | Tier 2 |
| 3 | Revenue8Y_LTV_New | BI_DB_LTV_BI_Actual | Revenue8Y_LTV_New | Passthrough (filtered: > 0) | Tier 2 |
| 4 | UpdateDate | SP_LTV_FromDB_ToBigQuery | GETDATE() | ETL-computed timestamp | Tier 5 |

## Lineage Notes

- Simple 4-column export subset of BI_DB_LTV_BI_Actual for BigQuery consumption.
- Two filters applied: FirstDepositDate >= @date-90 (rolling 90-day FTD window) AND Revenue8Y_LTV_New > 0 (only customers with positive LTV).
- UpdateDate is GETDATE() at SP execution time — not from source.
