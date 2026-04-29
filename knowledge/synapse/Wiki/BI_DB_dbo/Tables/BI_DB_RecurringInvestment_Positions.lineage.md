# Column Lineage: BI_DB_dbo.BI_DB_RecurringInvestment_Positions

## Source Objects

| Source Object | Schema | Role | Join Condition |
|--------------|--------|------|----------------|
| BI_DB_dbo.External_bi_db_recurringinvestment_positions_parquet | BI_DB_dbo | Source — external parquet table | Direct SELECT (no joins) |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|--------------|-------------|---------------|-----------|
| PositionID | External_bi_db_recurringinvestment_positions_parquet | PositionID | passthrough |
| DepositID | External_bi_db_recurringinvestment_positions_parquet | DepositID | passthrough |
| UpdateDate | (computed) | — | GETDATE() at SP execution |

## Writer SP

- **SP**: `BI_DB_dbo.SP_RecurringInvestment_Positions` (Guy Manova, 2025-03-19)
- **Pattern**: TRUNCATE + INSERT (full refresh)
- **Source**: External parquet table from data lake (recurring investment service)
