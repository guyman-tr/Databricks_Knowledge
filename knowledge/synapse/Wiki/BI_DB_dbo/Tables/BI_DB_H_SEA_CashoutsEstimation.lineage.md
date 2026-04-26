# Column Lineage: BI_DB_dbo.BI_DB_H_SEA_CashoutsEstimation

## Summary

- **Target**: BI_DB_dbo.BI_DB_H_SEA_CashoutsEstimation (12 columns)
- **Writer SP**: BI_DB_dbo.SP_H_SEA_CashoutsEstimation
- **Primary Production Source**: etoro.Billing.Withdraw (via External_etoro_Billing_Withdraw)
- **Secondary Sources**: etoro.Billing.vWithdrawToFunding (via External_etoro_Billing_vWithdrawToFunding), etoro.Billing.Funding (via External_etoro_Billing_Funding_Datafactory)
- **Load Pattern**: Hourly TRUNCATE + INSERT
- **Generic Pipeline**: etoro.Billing.Withdraw → Bronze/etoro/Billing/Withdraw/ (Override, 60 min, delta) → External_etoro_Billing_Withdraw

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform | Tier |
|---------------|-------------|---------------|-----------|------|
| WID | Billing.Withdraw | WithdrawID | Rename: WithdrawID → WID. Passthrough. | Tier 1 |
| CID | Billing.Withdraw | CID | Passthrough | Tier 1 |
| Net. Cashout Amount | Billing.Withdraw / Billing.WithdrawToFunding | Amount | SUM(CAST(Amount AS decimal(16,2))). Aggregated per WithdrawID. | Tier 2 |
| Status | DWH_dbo.Dim_CashoutStatus | Name | JOIN on CashoutStatusID → Name. Lookup resolution. | Tier 2 |
| Funding Method | DWH_dbo.Dim_FundingType | Name | JOIN on FundingTypeID → Name. Lookup resolution. | Tier 2 |
| Request Time | Billing.Withdraw | RequestDate | Rename: RequestDate → Request Time. Passthrough. | Tier 1 |
| FundingID | Billing.Withdraw / Billing.WithdrawToFunding | FundingID | Passthrough. From Withdraw for Pending/InProcess; from WithdrawToFunding for PendingReview. | Tier 1 |
| AMOPCurrency | DWH_dbo.Dim_Currency | Abbreviation | JOIN on AccountCurrencyID/ProcessCurrencyID → Abbreviation. Lookup resolution. | Tier 2 |
| Approved | Billing.Withdraw | Approved | CASE WHEN Approved=1 THEN 'YES' ELSE 'NO'. Bit-to-string transform. | Tier 2 |
| SCREEN | — | — | Hardcoded: 'PaymentsToSend' (PendingReview path) or 'WD Requests Screen' (Pending/InProcess path). ETL-computed. | Tier 2 |
| Regulation | DWH_dbo.Dim_Regulation | Name | JOIN chain: Dim_Customer.RealCID → RegulationID → Dim_Regulation.Name. Lookup resolution. | Tier 2 |
| UpdateDate | — | — | GETDATE(). ETL metadata timestamp. | Tier 5 |

## Source Objects

| Source Object | Type | Columns Used |
|--------------|------|-------------|
| BI_DB_dbo.External_etoro_Billing_Withdraw | External Table | WithdrawID, CID, Amount, CashoutStatusID, FundingTypeID, RequestDate, FundingID, AccountCurrencyID, Approved |
| BI_DB_dbo.External_etoro_Billing_vWithdrawToFunding | External Table | WithdrawID, FundingID, Amount, CashoutStatusID, ProcessCurrencyID |
| BI_DB_dbo.External_etoro_Billing_Funding_Datafactory | External Table | FundingID, FundingTypeID |
| DWH_dbo.Dim_FundingType | Dimension | FundingTypeID, Name |
| DWH_dbo.Dim_Currency | Dimension | CurrencyID, Abbreviation |
| DWH_dbo.Dim_CashoutStatus | Dimension | CashoutStatusID, Name |
| DWH_dbo.Dim_Customer | Dimension | RealCID, RegulationID |
| DWH_dbo.Dim_Regulation | Dimension | ID, Name |
