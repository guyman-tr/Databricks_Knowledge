# Column Lineage: BI_DB_dbo.BI_DB_HourlyReport_Withdraws

## Summary

- **Target**: BI_DB_dbo.BI_DB_HourlyReport_Withdraws (26 columns)
- **Writer SP**: BI_DB_dbo.SP_H_Ops_HourlyReport_Withdraws
- **Primary Production Source**: etoro.Billing.Withdraw (via External_etoro_Billing_Withdraw)
- **Secondary Sources**: etoro.Billing.vWithdrawToFunding (via External_etoro_Billing_vWithdrawToFunding)
- **Load Pattern**: Hourly TRUNCATE + INSERT
- **Filters**: FundingTypeID NOT IN (27) — all non-crypto withdrawals, last 15 days, CashoutStatusID NOT IN (4=Cancelled)
- **Companion Table**: BI_DB_HourlyReport_Redeems (same structure, opposite FundingTypeID filter — crypto only)

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform | Tier |
|---------------|-------------|---------------|-----------|------|
| WithdrawID | Billing.Withdraw | WithdrawID | Passthrough | Tier 1 |
| CID | Billing.Withdraw | CID | Passthrough | Tier 1 |
| RequestAmount | Billing.Withdraw | Amount | Rename: Amount → RequestAmount. Passthrough. | Tier 1 |
| RequestDate | Billing.Withdraw | RequestDate | Passthrough | Tier 1 |
| FundingAmount | Billing.vWithdrawToFunding | Amount | SUM(Amount) per WithdrawID. Aggregate of all funding legs. | Tier 2 |
| CashoutStatusID | Billing.Withdraw | CashoutStatusID | Passthrough | Tier 1 |
| CashoutStatus | DWH_dbo.Dim_CashoutStatus | Name | Lookup: CashoutStatusID → Name | Tier 2 |
| PendingCustomerFeedback | Billing.Withdraw | Comment | CASE WHEN LEN(Comment) > 4 THEN 1 ELSE 0 | Tier 2 |
| Approved | Billing.Withdraw | Approved | Passthrough | Tier 1 |
| Foreclosed | Billing.Withdraw | CashoutReasonID | CASE WHEN CashoutReasonID IN (12=Foreclose account, 15=Affiliate Payment) THEN 1 ELSE 0 | Tier 2 |
| ReadyForPayment | — | — | SUM(CASE WHEN RequestAmount=FundingAmount AND CashoutStatusID=2 THEN 1 ELSE 0) | Tier 2 |
| COStatus1-13 | Billing.vWithdrawToFunding | Amount | PIVOT: SUM(Amount) FOR CashoutStatusID IN (1-13) | Tier 2 |
| FullyFunded | — | — | CASE WHEN RequestAmount=FundingAmount AND COStatus3 IS NULL AND COStatus4 IS NULL AND CashoutStatusID=2 THEN 1 ELSE 0 | Tier 2 |
| UpdateDate | — | — | GETDATE(). ETL metadata. | Tier 5 |

## Source Objects

| Source Object | Type | Columns Used |
|--------------|------|-------------|
| BI_DB_dbo.External_etoro_Billing_Withdraw | External Table | WithdrawID, CID, Amount, RequestDate, CashoutStatusID, FundingTypeID, Comment, Approved, CashoutReasonID |
| BI_DB_dbo.External_etoro_Billing_vWithdrawToFunding | External Table | WithdrawID, CashoutStatusID, Amount |
| DWH_dbo.Dim_CashoutStatus | Dimension | CashoutStatusID, Name |
