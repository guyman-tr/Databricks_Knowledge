# Column Lineage: BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Dep

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Dep` |
| **UC Target** | Not_Migrated |
| **Primary Source** | `DWH_dbo.Fact_BillingDeposit` (FundingID-level aggregation) |
| **ETL SP** | `SP_AML_Multiple_Accounts` (@Date parameter, on-demand / not in OpsDB standard schedule) |
| **Secondary Sources** | `External_etoro_Billing_Funding` (IsBlocked), `DWH_dbo.Dim_Customer` (filters only) |
| **Generated** | 2026-04-23 |

## Lineage Chain

```
DWH_dbo.Fact_BillingDeposit
    │  FundingID groups WHERE:
    │    - FundingID NOT IN (1,2,3,4,5,6,7)    [exclude internal/test funding IDs]
    │    - IsValidCustomer = 1
    │    - IsDepositor = 1
    │    - VerificationLevelID >= 2             [partial KYC or better]
    │    HAVING COUNT(DISTINCT CID) >= 2        [multiple people sharing same deposit entity]
    │
    ├── LEFT JOIN External_etoro_Billing_Funding bf
    │     ON fbd.FundingID = bf.FundingID
    │     → IsBlocked flag (is this funding entity currently blocked in Billing?)
    │
    └─ SP_AML_Multiple_Accounts (Step 11)
        ├─ TRUNCATE TABLE target
        └─ INSERT → BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Dep
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **rename** | Same value, different column name in DWH. |
| **join-enriched** | Joined from a secondary source table during ETL. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| FundingID | DWH_dbo.Fact_BillingDeposit | FundingID | passthrough | GROUP BY FundingID | The shared deposit funding entity — maps to etoro.Billing.Funding |
| IsBlocked | External_etoro_Billing_Funding | IsBlocked | join-enriched | `bf.IsBlocked` via FundingID join | 0/1: whether this entity is currently blocked in the Billing system |
| Total_Users | DWH_dbo.Fact_BillingDeposit | CID | ETL-computed | `COUNT(DISTINCT CID)` per FundingID group | Number of unique verified depositors sharing this funding entity |
| Group_Type | — | — | ETL-computed | `CASE WHEN Total_Users BETWEEN 5 AND 20 THEN '5 to 20' WHEN … BETWEEN 21 AND 50 THEN '21 to 50' WHEN … BETWEEN 51 AND 500 THEN '51 to 500' ELSE 'above 500' END` | Size classification of the sharing group |
| Last_Deposit_Date | DWH_dbo.Fact_BillingDeposit | DepositDate | ETL-computed | `MAX(DepositDate)` per FundingID group | Most recent deposit using this funding entity |
| Total_Approved_Deposit | DWH_dbo.Fact_BillingDeposit | Amount | ETL-computed | `SUM(Amount)` for approved deposits per FundingID | Total approved deposit value (USD) |
| Num_Approved_Deposit | DWH_dbo.Fact_BillingDeposit | — | ETL-computed | `COUNT(*)` for approved deposits per FundingID | Count of approved deposit transactions |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL execution timestamp |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 1 |
| **Rename** | 0 |
| **Join-enriched** | 1 |
| **ETL-computed** | 6 |
| **Total** | 8 |
