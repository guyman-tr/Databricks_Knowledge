# BI_DB_dbo.BI_DB_Money_Out_New_Management_Dashboard — Column Lineage

## Lineage Metadata

| Property | Value |
|----------|-------|
| **Writer SP** | BI_DB_dbo.SP_Money_Out_New_Management_Dashboard |
| **Load Pattern** | Daily DELETE+INSERT by WithdrawID+CID+FundingID, plus DELETE older than 7 months |
| **Refresh** | Daily (SB_Daily, Priority 0) |
| **UC Target** | _Not_Migrated |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|--------------|-----------|------|
| 1 | CID | DWH_dbo.Fact_BillingWithdraw | CID | Direct | T2 |
| 2 | Country | DWH_dbo.Dim_Country | Name | Via Fact_SnapshotCustomer.CountryID | T2 |
| 3 | Region | DWH_dbo.Dim_Country | MarketingRegionManualName | Via Fact_SnapshotCustomer.CountryID | T2 |
| 4 | Regulation | DWH_dbo.Dim_Regulation | Name | Via Dim_Country.RegulationID | T2 |
| 5 | WithdrawID | DWH_dbo.Fact_BillingWithdraw | WithdrawID | Direct | T2 |
| 6 | FundingID | DWH_dbo.Fact_BillingWithdraw | FundingID | Direct | T2 |
| 7 | FundingTypeID | DWH_dbo.Fact_BillingWithdraw | FundingTypeID | Direct (from withdraw record) | T2 |
| 8 | WithdrawPaymentID | DWH_dbo.Fact_BillingWithdraw | WithdrawPaymentID | ISNULL(WithdrawPaymentID, 0) | T2 |
| 9 | CashoutStatusID_Withdraw | DWH_dbo.Fact_BillingWithdraw | CashoutStatusID_Withdraw | Direct | T2 |
| 10 | CashoutStatusID_Funding | DWH_dbo.Fact_BillingWithdraw | CashoutStatusID_Funding / CashoutStatusID_Withdraw | ISNULL(CashoutStatusID_Funding, CashoutStatusID_Withdraw) — falls back to withdraw status | T2 |
| 11 | PaymentStatus | DWH_dbo.Dim_CashoutStatus | Name | Via CashoutStatusID_Funding (primary) or CashoutStatusID_Withdraw (fallback) | T2 |
| 12 | RequestDate | DWH_dbo.Fact_BillingWithdraw | RequestDate | Direct | T2 |
| 13 | Amount$Withdraw | DWH_dbo.Fact_BillingWithdraw | Amount_WithdrawToFunding / Amount_Withdraw | ISNULL(Amount_WithdrawToFunding, Amount_Withdraw) — prefers funding leg amount | T2 |
| 14 | Fee | DWH_dbo.Fact_BillingWithdraw | Fee | Direct | T2 |
| 15 | ModificationDate | DWH_dbo.Fact_BillingWithdraw | ModificationDate | Direct | T2 |
| 16 | AutoApproval | DWH_dbo.Fact_BillingWithdraw | Comment | CASE: Comment LIKE '%Auto Approval%' → 'AutoApproval', else 'Manual' | T2 |
| 17 | FundingType | DWH_dbo.Dim_FundingType | Name | Via FundingTypeID_Withdraw | T2 |
| 18 | RedeemInd | DWH_dbo.Fact_BillingWithdraw | FundingTypeID_Funding | CASE: FundingTypeID_Funding=27 → 1 (crypto wallet redeem), else 0 | T2 |
| 19 | SLAHours | DWH_dbo.Fact_BillingWithdraw | RequestDate, ModificationDate | DATEDIFF(HOUR, RequestDate, ModificationDate) | T2 |
| 20 | Preparation | DWH_dbo.Dim_CashoutMode | CashoutModeName | ISNULL(CashoutModeName, 'Canceled') via CashoutModeID | T2 |
| 21 | ExecutionApproval | DWH_dbo.Dim_FundingType | Name | CASE: Name IN ('OnlineBanking','MoneyBookers','UnionPay','Bank Details','WireTransfer') → 'Manual', else 'AutoExecuted' | T2 |
| 22 | UpdateDate | ETL | GETDATE() | Set on INSERT | T5 |
