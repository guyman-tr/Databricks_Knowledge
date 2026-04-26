# Lineage: BI_DB_dbo.BI_DB_Finance_Net_MIMO

Generated: 2026-04-22 | Phase 10B

## ETL Pipeline

```
DWH_dbo.Fact_BillingDeposit (PaymentStatusID=2, approved deposits → #deposit_agg)
  + DWH_dbo.Fact_BillingWithdraw (CashoutStatusID_Withdraw=3, approved withdrawals → #withdraw_agg)
  + DWH_dbo.Fact_SnapshotCustomer (IsValidCustomer=1, IsCreditReportValidCB, RegulationID, PlayerLevelID)
  + DWH_dbo.Dim_Range (SCD2 bridge: FromDateID ≤ ModificationDateID ≤ ToDateID)
  + DWH_dbo.Dim_FundingType (funding method name — deposits use FundingTypeID, withdrawals use FundingTypeID_Funding)
  + DWH_dbo.Dim_Currency (currency abbreviation — deposits use CurrencyID, withdrawals use ProcessCurrencyID)
  + DWH_dbo.Dim_Regulation (regulation name from Fact_SnapshotCustomer.RegulationID)
  + DWH_dbo.Dim_PlayerLevel (club/tier name from Fact_SnapshotCustomer.PlayerLevelID)
    |-- SP_Finance_Net_MIMO @Date (Daily) ---|
    |   #deposit_agg: SUM(AmountUSD) as positive inflows, COUNT DISTINCT DepositID   |
    |   #withdraw_agg: SUM(Amount_WithdrawToFunding * -1) as outflows (sign-flipped)  |
    |   UNION ALL → #unionall → GROUP BY dims → #netmimo (Net_MIMO_AmountUSD)         |
    |   DELETE WHERE ModificationDateID = @DateID                                      |
    |   INSERT 14 columns                                                               |
    v
BI_DB_dbo.BI_DB_Finance_Net_MIMO
  (699,055 rows, Jan 2021 – Apr 2026, daily aggregated by funding/currency/regulation/club)
  UC Target: Not Migrated
```

## Column Lineage

| # | Column | Source | Transform | Tier |
|---|--------|--------|-----------|------|
| 1 | ModificationDate | DWH_dbo.Fact_BillingDeposit / Fact_BillingWithdraw | CAST(ModificationDate AS DATE) — event date | Tier 2 |
| 2 | ModificationDateID | SP_Finance_Net_MIMO | CAST(CONVERT(CHAR(8), ModificationDate, 112) AS INT) — YYYYMMDD; clustered index + DELETE key | Tier 2 |
| 3 | FundingTypeID | DWH_dbo.Fact_BillingDeposit / Fact_BillingWithdraw | fbd.FundingTypeID (deposits); fbw.FundingTypeID_Funding (withdrawals) | Tier 2 |
| 4 | FundingType | DWH_dbo.Dim_FundingType | dft.Name — funding method name (e.g., 'eToroMoney', 'CreditCard', 'WireTransfer') | Tier 2 |
| 5 | CurrencyID | DWH_dbo.Fact_BillingDeposit / Fact_BillingWithdraw | fbd.CurrencyID (deposits); fbw.ProcessCurrencyID (withdrawals) | Tier 2 |
| 6 | Currency | DWH_dbo.Dim_Currency | cur.Abbreviation — currency code (e.g., 'EUR', 'GBP', 'USD') | Tier 2 |
| 7 | RegulationID | DWH_dbo.Fact_SnapshotCustomer | snp.RegulationID — customer regulatory jurisdiction ID at event date | Tier 2 |
| 8 | Regulation | DWH_dbo.Dim_Regulation | reg.Name via snp.RegulationID (DWHRegulationID join) | Tier 2 |
| 9 | IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | snp.IsCreditReportValidCB — GROUP BY dimension | Tier 1 |
| 10 | Club | DWH_dbo.Dim_PlayerLevel | dpl.Name via snp.PlayerLevelID | Tier 2 |
| 11 | Total_Transaction_Count | DWH_dbo.Fact_BillingDeposit / Fact_BillingWithdraw | SUM(Transaction_Count): deposits = COUNT DISTINCT DepositID; withdrawals = COUNT DISTINCT WithdrawID | Tier 2 |
| 12 | Total_SubTransaction_Count | DWH_dbo.Fact_BillingDeposit / Fact_BillingWithdraw | SUM(SubTransaction_Count): deposits = COUNT DepositID; withdrawals = COUNT WithdrawPaymentID | Tier 2 |
| 13 | Net_MIMO_AmountUSD | DWH_dbo.Fact_BillingDeposit / Fact_BillingWithdraw | SUM(AmountUSD for deposits + Amount_WithdrawToFunding×−1 for withdrawals) = net USD flow | Tier 2 |
| 14 | UpdateDate | SP_Finance_Net_MIMO | GETDATE() at INSERT | Tier 2 |

## Tier Summary

- **Tier 1**: 1 column (IsCreditReportValidCB — from DWH_dbo.Fact_SnapshotCustomer)
- **Tier 2**: 13 columns (SP-computed aggregations, dimension names, date transforms)
- **UC Target**: Not Migrated

## Notes

- Withdrawals use `Amount_WithdrawToFunding * -1` so their contribution to Net_MIMO_AmountUSD is negative — Net_MIMO_AmountUSD > 0 means net money inflow, < 0 means net outflow.
- Only approved events are included: PaymentStatusID=2 (deposits), CashoutStatusID_Withdraw=3 (withdrawals).
- Only valid customers: Fact_SnapshotCustomer WHERE IsValidCustomer=1 (demo accounts excluded).
- Transaction_Count vs SubTransaction_Count differ for withdrawals: one WithdrawID can have multiple WithdrawPaymentIDs (different payment methods per withdrawal request). For deposits the counts are equal.
- FundingTypeID for withdrawals comes from FundingTypeID_Funding (processor side), not FundingTypeID_Withdraw (customer side).
- CurrencyID for withdrawals comes from ProcessCurrencyID (processing currency), not the customer withdrawal currency.
