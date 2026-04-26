# Lineage: BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Agg

## Object
- **Schema**: BI_DB_dbo
- **Object**: BI_DB_AML_Affiliate_Abuse_Agg
- **Type**: Table
- **Writer SP**: SP_AML_Affiliate_Abuse (DISABLED 2024-12-31)
- **UC Target**: Not_Migrated

## ETL Pipeline
```
BI_DB_dbo.BI_DB_MarketingMonthlyRawData + DWH_dbo.Dim_Affiliate (SubChannelID filter)
  |-- SP_AML_Affiliate_Abuse Step 01: #Aff_acivated (activated affiliates since 2023) ---|
  v
DWH_dbo.Dim_Customer + DWH_dbo.Fact_BillingWithdraw
  |-- SP Step 07: CO monthly aggregation ---|
  v
DWH_dbo.Fact_BillingDeposit
  |-- SP Step 07: Deposit monthly aggregation ---|
  v
DWH_dbo.Dim_Customer + DWH_dbo.Dim_Position
  |-- SP Step 07: Position monthly aggregation ---|
  v
#final_agg_data (HASH AffiliateID)
  |-- TRUNCATE + INSERT (SP disabled 2024-12-31) ---|
  v
BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Agg (20,627 rows, frozen 2024-12-31)
```

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|----------------|-------------|---------------|-----------|
| AffiliateID | BI_DB_MarketingMonthlyRawData → Dim_Affiliate | AffiliateID | passthrough |
| Channel | BI_DB_MarketingMonthlyRawData → Dim_Affiliate | Channel | passthrough |
| Year | Fact_BillingWithdraw / Fact_BillingDeposit / Dim_Position | RequestDate / ModificationDate / OpenOccurred | YEAR() extract |
| Month | same | same | MONTH() extract |
| Approved_CO | Fact_BillingWithdraw | WithdrawID | COUNT DISTINCT WHERE CashoutStatusID_Funding=3 |
| Unapproved_CO | Fact_BillingWithdraw | WithdrawID | COUNT DISTINCT WHERE CashoutStatusID_Funding≠3 |
| Approved_Deposits | Fact_BillingDeposit | DepositID | COUNT DISTINCT WHERE PaymentStatusID=2 |
| Unapproved_Deposits | Fact_BillingDeposit | DepositID | COUNT DISTINCT WHERE PaymentStatusID≠2 |
| Has_Open_Trade | Dim_Position | PositionID | COUNT DISTINCT WHERE OpenOccurred≥2023 |
| UpdateDate | ETL metadata | — | GETDATE() |

## Source Objects
- `BI_DB_dbo.BI_DB_MarketingMonthlyRawData` — affiliate performance metrics (activated since 2023)
- `DWH_dbo.Dim_Affiliate` — SubChannelID filter (20,31,39,40,41,42,44)
- `DWH_dbo.Dim_Customer` — customer-affiliate join
- `DWH_dbo.Fact_BillingWithdraw` — monthly CO counts (approved/unapproved)
- `DWH_dbo.Fact_BillingDeposit` — monthly deposit counts (approved/unapproved)
- `DWH_dbo.Dim_Position` — monthly unique customers with open trades
