# Column Lineage: BI_DB_dbo.BI_DB_HourlyReport_Redeems

## Summary

- **Target**: BI_DB_dbo.BI_DB_HourlyReport_Redeems (26 columns)
- **Writer SP**: BI_DB_dbo.SP_H_HourlyReport_Redeems
- **Primary Production Source**: etoro.Billing.Withdraw (via External_etoro_Billing_Withdraw)
- **Secondary Sources**: etoro.Billing.vWithdrawToFunding (via External_etoro_Billing_vWithdrawToFunding + External_etoro_Billimg_vWithdrawToFunding_FUll)
- **Load Pattern**: Hourly TRUNCATE + INSERT
- **Filters**: FundingTypeID=27 (eToroCryptoWallet), last 30 days, CashoutStatusID NOT IN (4=Cancelled)

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
| PendingCustomerFeedback | Billing.Withdraw | Comment | CASE WHEN LEN(Comment) > 4 THEN 1 ELSE 0. Indicates customer provided feedback. | Tier 2 |
| Approved | Billing.Withdraw | Approved | Passthrough (int, not bit-to-string like Object 1) | Tier 1 |
| Foreclosed | Billing.Withdraw | CashoutReasonID | CASE WHEN CashoutReasonID IN (12=Foreclose account, 15=Affiliate Payment) THEN 1 ELSE 0 | Tier 2 |
| ReadyForPayment | — | — | SUM(CASE WHEN RequestAmount=FundingAmount AND CashoutStatusID=2 THEN 1 ELSE 0). Fully funded + InProcess status. | Tier 2 |
| COStatus1 | Billing.vWithdrawToFunding | Amount | PIVOT: SUM(Amount) WHERE CashoutStatusID=1 (Pending) | Tier 2 |
| COStatus2 | Billing.vWithdrawToFunding | Amount | PIVOT: SUM(Amount) WHERE CashoutStatusID=2 (InProcess) | Tier 2 |
| COStatus3 | Billing.vWithdrawToFunding | Amount | PIVOT: SUM(Amount) WHERE CashoutStatusID=3 (Processed) | Tier 2 |
| COStatus4 | Billing.vWithdrawToFunding | Amount | PIVOT: SUM(Amount) WHERE CashoutStatusID=4 (Cancelled) | Tier 2 |
| COStatus5 | Billing.vWithdrawToFunding | Amount | PIVOT: SUM(Amount) WHERE CashoutStatusID=5 | Tier 2 |
| COStatus6 | Billing.vWithdrawToFunding | Amount | PIVOT: SUM(Amount) WHERE CashoutStatusID=6 | Tier 2 |
| COStatus7 | Billing.vWithdrawToFunding | Amount | PIVOT: SUM(Amount) WHERE CashoutStatusID=7 | Tier 2 |
| COStatus8 | Billing.vWithdrawToFunding | Amount | PIVOT: SUM(Amount) WHERE CashoutStatusID=8 | Tier 2 |
| COStatus9 | Billing.vWithdrawToFunding | Amount | PIVOT: SUM(Amount) WHERE CashoutStatusID=9 | Tier 2 |
| COStatus10 | Billing.vWithdrawToFunding | Amount | PIVOT: SUM(Amount) WHERE CashoutStatusID=10 | Tier 2 |
| COStatus11 | Billing.vWithdrawToFunding | Amount | PIVOT: SUM(Amount) WHERE CashoutStatusID=11 | Tier 2 |
| COStatus12 | Billing.vWithdrawToFunding | Amount | PIVOT: SUM(Amount) WHERE CashoutStatusID=12 | Tier 2 |
| COStatus13 | Billing.vWithdrawToFunding | Amount | PIVOT: SUM(Amount) WHERE CashoutStatusID=13 | Tier 2 |
| FullyFunded | — | — | CASE WHEN RequestAmount=FundingAmount AND COStatus3 IS NULL AND COStatus4 IS NULL AND CashoutStatusID=2 THEN 1 ELSE 0. Fully funded with no processed/cancelled legs. | Tier 2 |
| UpdateDate | — | — | GETDATE(). ETL metadata. | Tier 5 |

## Source Objects

| Source Object | Type | Columns Used |
|--------------|------|-------------|
| BI_DB_dbo.External_etoro_Billing_Withdraw | External Table | WithdrawID, CID, Amount, RequestDate, CashoutStatusID, FundingTypeID, Comment, Approved, CashoutReasonID |
| BI_DB_dbo.External_etoro_Billimg_vWithdrawToFunding_FUll | External Table | WithdrawID, Amount (for FundingAmount aggregation) |
| BI_DB_dbo.External_etoro_Billing_vWithdrawToFunding | External Table | WithdrawID, CashoutStatusID, Amount (for PIVOT) |
| DWH_dbo.Dim_CashoutStatus | Dimension | CashoutStatusID, Name |
