---
object: EXW_dbo.EXW_ReimbursementSumTable
type: Table
generated: 2026-04-20
phase: 10B
---

# Column Lineage — EXW_dbo.EXW_ReimbursementSumTable

## ETL Chain

```
EXW_dbo.EXW_FinanceReportsBalancesNew (latest Balance + BalanceUSD at MAX BalanceDateID)
EXW_Wallet.EXW_PriceDaily (AvgPrice at MAX BalanceDateID date)
EXW_dbo.EXW_CompensationClosingCountries (FinalBalance per compensated GCID+CryptoId)
EXW_dbo.EXW_Aml_Limited_Accounts (legacy AML-limited GCIDs)
BI_DB_dbo.External_Fivetran_google_sheets_exw_aml_limited_accounts (live AML-limited GCIDs)
EXW_dbo.EXW_UserSettingsWalletAllowance (SelectedValue: 0/1=closed, 2/3=open)
EXW_dbo.EXW_DimUser (user country, regulation)
EXW_dbo.EXW_WalletClosedCountryProjects (countries closed due to compliance event)
DWH_dbo.Fact_CustomerAction (platform compensation payments, ActionTypeID=36, CompensationReasonID IN 101,102)
DWH_dbo.Dim_Customer (user CID/GCID mapping for platform side)
  |
  | SP_EXW_CompensationClosingCountries (no @d parameter — full rebuild)
  | TRUNCATE TABLE + INSERT 7 rows (one per population segment)
  | Runs after SP completes EXW_CompensationClosingCountries + EXW_ReimbursementFollowUp
  v
EXW_dbo.EXW_ReimbursementSumTable (7 rows — KPI summary)
    |
    | consumed by:
    +-- BI/reporting dashboards (no downstream SSDT SP found referencing this table)
```

## Column Lineage

| # | DWH Column | Tier | Source Table | Source Column | Transform |
|---|------------|------|-------------|---------------|-----------|
| 1 | Population | T2 | ETL-computed | — | Hardcoded string literal per UNION ALL segment (7 distinct values). Identifies the population cohort described by the row. |
| 2 | Users | T2 | ETL-computed (aggregation) | EXW_FinanceReportsBalancesNew / EXW_CompensationClosingCountries / EXW_Aml_Limited_Accounts | COUNT(DISTINCT GCID) per population segment; segment-specific logic filters which GCIDs qualify. |
| 3 | BalanceUSD | T2 | EXW_FinanceReportsBalancesNew + EXW_Wallet.EXW_PriceDaily | Balance, AvgPrice | SUM(Balance * AvgPrice) — current USD value of crypto holdings at the balance reference date (MAX BalanceDateID from EXW_FinanceReportsBalancesNew). |
| 4 | Compensated By Current USD Price | T2 | EXW_CompensationClosingCountries + EXW_Wallet.EXW_PriceDaily | FinalBalance, AvgPrice | SUM(FinalBalance * AvgPrice) per compensated GCID — value of the compensation crypto at current prices. 0 for non-compensated segments (populations 1, 2, 3 in the SP). AML and non-AML projects computed separately and combined. |
| 5 | UpdateDate | T2 | ETL-computed | — | GETDATE() at SP execution time; NOT NULL (DDL constraint). |

## Tier Summary

- **Tier 1**: 0 columns — all columns are SP-computed aggregations; no verbatim upstream column copies
- **Tier 2**: 5 columns — all derived via SP aggregation logic from EXW_FinanceReportsBalancesNew, EXW_PriceDaily, EXW_CompensationClosingCountries, EXW_Aml_Limited_Accounts, EXW_UserSettingsWalletAllowance, EXW_DimUser, EXW_WalletClosedCountryProjects, DWH_dbo fact/dim tables
- **Tier 3**: 0
- **Tier 4**: 0

## UC Target

- **Synapse**: EXW_dbo.EXW_ReimbursementSumTable
- **UC Target**: `_Not_Migrated` (no UC mapping found — regulatory reimbursement KPI summary, Synapse-only)
