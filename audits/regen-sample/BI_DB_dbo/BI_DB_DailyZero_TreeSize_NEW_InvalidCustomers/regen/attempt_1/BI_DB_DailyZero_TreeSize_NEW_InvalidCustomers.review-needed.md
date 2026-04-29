# Review Needed — BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers

## Tier 3 Items (needs expert confirmation)

- **RiskIndex (column 5)**: DDL declares as `int NOT NULL` but SP inserts empty string `''`. Live data shows value `0`. Confirm whether this is an intentional placeholder or a deprecated column.
- **RiskGroup / DepositGroup (columns 9-10)**: Always empty string. Confirm whether these were ever populated or are reserved for future use.

## Data Quality Observations

- **Sparse 2025 data**: Only ~20K rows in 2025 (vs ~6.15M in 2021-2024). Possible ETL gap or table deprecation — confirm whether the SP is still running daily.
- **IsValidCustomer always 0**: By design (SP WHERE clause). However, column exists in DDL as nullable int — could theoretically hold other values if the filter changes.
- **IsCFD reconciliation logic**: The SP reconciles IsSettled between Dim_Position and BI_DB_PositionPnL with a complex priority CASE. When the two sources disagree, the logic may produce unexpected results. Consider validating against production expectations.

## Lineage Questions

- **No known downstream consumers identified**: Confirm whether dashboards or other SPs read this table.
- **Relationship to BI_DB_DailyZero_TreeSize_NEW**: This table appears to be the invalid-customer counterpart. Confirm whether the two tables share consumers or are always queried separately.

## Settlement Type Distribution

- SettlementType has 3 values in 2025 data: Real (70.6%), CFD (29.4%), TRS (<0.1%). CMT (SettlementTypeID=3) path exists in code but not observed in data.
