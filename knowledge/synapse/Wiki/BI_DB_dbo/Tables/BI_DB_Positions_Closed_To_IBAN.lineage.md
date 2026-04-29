# BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN — Column Lineage

## Source Objects

| Source Object | Schema | Role |
|---------------|--------|------|
| External_bi_output_finance_bi_db_positions_closed_to_iban_parquet | BI_DB_dbo | Primary source — external table with PositionID-to-WithdrawPaymentID mappings from the finance BI output |
| Dim_Position | DWH_dbo | JOIN — provides CID for deduplication verification |
| Fact_BillingWithdraw | DWH_dbo | JOIN — CID+WithdrawPaymentID deduplication (R&D design flaw workaround) |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| PositionID | External_...closed_to_iban_parquet | PositionID | Passthrough (after dedup JOIN) |
| WithdrawPaymentID | External_...closed_to_iban_parquet | WithdrawPaymentID | Passthrough (after dedup JOIN) |
| UpdateDate | — | — | GETDATE() at insert time |

## ETL Pipeline

```
BI_DB_dbo.External_bi_output_finance_bi_db_positions_closed_to_iban_parquet
  |-- JOIN DWH_dbo.Dim_Position (get CID for dedup)
  v
#closedToIban (PositionID, WithdrawPaymentID, CID)
  |-- JOIN DWH_dbo.Fact_BillingWithdraw (CID + WithdrawPaymentID dedup)
  |-- TRUNCATE + INSERT, UpdateDate = GETDATE()
  v
BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN (3.16M rows)
  |-- Generic Pipeline (Override, delta, daily)
  v
general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban
```
