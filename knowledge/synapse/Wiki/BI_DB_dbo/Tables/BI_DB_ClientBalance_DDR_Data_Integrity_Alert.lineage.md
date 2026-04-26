# BI_DB_dbo.BI_DB_ClientBalance_DDR_Data_Integrity_Alert — Column Lineage

**Generated**: 2026-04-23 | **Phase**: 10B | **Writer SP**: SP_ClientBalance_DDR_Data_Integrity_Alert

## ETL Chain

```
DWH_dbo.Fact_CustomerAction               (ActionTypeID IN (7,44) = FCA deposits)
BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New    (CBCIDLevelDeposits)
BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New (CBAggLevelDeposits)
BI_DB_dbo.BI_DB_DDR_CID_Level             (DDRCIDLevelDeposits — BLACKLISTED)
BI_DB_dbo.BI_DB_DDR_Daily_Aggregated      (DDRDailyAggLevelDeposits — BLACKLISTED)
BI_DB_dbo.BI_DB_DDR_TimeRange_Aggregated_Country_Level (DDRAggLevelDeposits — BLACKLISTED, TimeRange='Yesterday')
    |-- SP_ClientBalance_DDR_Data_Integrity_Alert (@date, Daily SB_Daily) ---|
    |-- TRUNCATE + INSERT WHERE DataIntegrityProblem = 1 ---|
    v
BI_DB_dbo.BI_DB_ClientBalance_DDR_Data_Integrity_Alert (0 rows in healthy state)
    |-- UC: _Not_Migrated ---|
    v
  (no downstream consumers)
```

## Column Lineage

| DWH Column | Source | Source Column | Transform |
|---|---|---|---|
| DateID | ETL (@date param) | — | CAST(CONVERT(VARCHAR(8), @date, 112) AS INT) |
| FCADeposits | DWH_dbo.Fact_CustomerAction | Amount | SUM(Amount) WHERE ActionTypeID IN (7,44) |
| CBCIDLevelDeposits | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Deposits | SUM(Deposits) for @dateID |
| CBAggLevelDeposits | BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | Deposits | SUM(Deposits) for @dateID |
| DDRCIDLevelDeposits | BI_DB_dbo.BI_DB_DDR_CID_Level (BLACKLISTED) | Deposits | SUM(Deposits) for @dateID |
| DDRDailyAggLevelDeposits | BI_DB_dbo.BI_DB_DDR_Daily_Aggregated (BLACKLISTED) | Deposits | SUM(Deposits) for @dateID |
| DDRAggLevelDeposits | BI_DB_dbo.BI_DB_DDR_TimeRange_Aggregated_Country_Level (BLACKLISTED) | Deposits | SUM(Deposits) WHERE TimeRange='Yesterday' |
| DataIntegrityProblem | Computed | — | CASE WHEN any source pair mismatches THEN 1 ELSE 0 END (only rows with =1 inserted) |

## Tier Pre-Assignment

All columns are ETL-computed aggregations (SUM) or derived CASE flags — no upstream wiki column passthrough:

| DWH Column | Pre-Tier |
|---|---|
| DateID | Tier 2 (ETL-computed date int) |
| FCADeposits | Tier 2 (SUM aggregate from Fact_CustomerAction) |
| CBCIDLevelDeposits | Tier 2 (SUM aggregate from CB CID level) |
| CBAggLevelDeposits | Tier 2 (SUM aggregate from CB Aggregate level) |
| DDRCIDLevelDeposits | Tier 4 (source blacklisted, Tier 4 best available) |
| DDRDailyAggLevelDeposits | Tier 4 (source blacklisted) |
| DDRAggLevelDeposits | Tier 4 (source blacklisted) |
| DataIntegrityProblem | Tier 2 (CASE-computed reconciliation flag) |
