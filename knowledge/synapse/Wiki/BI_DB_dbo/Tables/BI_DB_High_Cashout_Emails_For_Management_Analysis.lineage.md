# Column Lineage: BI_DB_dbo.BI_DB_High_Cashout_Emails_For_Management_Analysis

## Summary

- **Target**: BI_DB_dbo.BI_DB_High_Cashout_Emails_For_Management_Analysis (36 columns)
- **Writer SP**: BI_DB_dbo.SP_BI_DB_High_Cashout_Emails_For_Management_Analysis
- **Primary Source**: BI_DB_dbo.BI_DB_Daily_HighCashoutEmailsForManagement (daily snapshot INSERT)
- **Enrichment Sources**: DWH_dbo.Fact_BillingWithdraw, DWH_dbo.Dim_CashoutStatus, BI_DB_dbo.BI_DB_UsageTracking_SF
- **Load Pattern**: Daily DELETE (yesterday) + INSERT from daily email table, then UPDATE with enrichment data
- **Production Ancestry**: etoro.Billing.Withdraw → Fact_BillingWithdraw → this table

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform | Tier |
|---------------|-------------|---------------|-----------|------|
| Snapshot_Date | BI_DB_Daily_HighCashoutEmailsForManagement | Date | Rename: Date → Snapshot_Date. Passthrough. | Tier 2 |
| CID | BI_DB_Daily_HighCashoutEmailsForManagement | CID | Passthrough | Tier 2 |
| WithdrawID | BI_DB_Daily_HighCashoutEmailsForManagement | WithdrawID | Passthrough | Tier 2 |
| Snapshot_CO Amount | BI_DB_Daily_HighCashoutEmailsForManagement | CO Amount | Rename. Passthrough. | Tier 2 |
| Snapshot_ClientWithdrawReason | BI_DB_Daily_HighCashoutEmailsForManagement | ClientWithdrawReason | Rename. Passthrough. | Tier 2 |
| Snapshot_RequestorComments | — | — | In DDL but NOT in INSERT — always NULL. Never populated. | Tier 2 |
| Snapshot_Category | BI_DB_Daily_HighCashoutEmailsForManagement | Category | Rename. Passthrough. | Tier 2 |
| Snapshot_Country | BI_DB_Daily_HighCashoutEmailsForManagement | Country | Rename. Passthrough. | Tier 2 |
| Snapshot_Age | BI_DB_Daily_HighCashoutEmailsForManagement | Age | Rename. Passthrough. | Tier 2 |
| Snapshot_Regulation | BI_DB_Daily_HighCashoutEmailsForManagement | Regulation | Rename. Passthrough. | Tier 2 |
| Snapshot_AMLComment | BI_DB_Daily_HighCashoutEmailsForManagement | AMLComment | Rename. Passthrough. | Tier 2 |
| Snapshot_RiskComment | BI_DB_Daily_HighCashoutEmailsForManagement | RiskComment | Rename. Passthrough. | Tier 2 |
| Snapshot_ProvidedSelfie | BI_DB_Daily_HighCashoutEmailsForManagement | ProvidedSelfie | Rename. Passthrough. | Tier 2 |
| Snapshot_WasContactedLast12Months | BI_DB_Daily_HighCashoutEmailsForManagement | WasContactedLast12Months | Rename. Passthrough. | Tier 2 |
| Snapshot_Account Manager | BI_DB_Daily_HighCashoutEmailsForManagement | Account Manager | Rename. Passthrough. | Tier 2 |
| Snapshot_NWA | BI_DB_Daily_HighCashoutEmailsForManagement | NWA | Rename. Passthrough. | Tier 2 |
| Snapshot_Revenues | BI_DB_Daily_HighCashoutEmailsForManagement | Revenues | Rename. Passthrough. | Tier 2 |
| Snapshot_CustomerStatus | BI_DB_Daily_HighCashoutEmailsForManagement | CustomerStatus | Rename. Passthrough. | Tier 2 |
| Snapshot_Verification | BI_DB_Daily_HighCashoutEmailsForManagement | Verification | Rename. Passthrough. | Tier 2 |
| Snapshot_ExpiredPOI | BI_DB_Daily_HighCashoutEmailsForManagement | ExpiredPOI | Rename. Passthrough. | Tier 2 |
| Snapshot_CompensationAmount | BI_DB_Daily_HighCashoutEmailsForManagement | CompensationAmount | Rename. Passthrough. | Tier 2 |
| Snapshot_Amount_Withdraw | BI_DB_Daily_HighCashoutEmailsForManagement | Amount_Withdraw | Rename. Passthrough. | Tier 2 |
| Snapshot_Equity | BI_DB_Daily_HighCashoutEmailsForManagement | Equity | Rename. Passthrough. | Tier 2 |
| Snapshot_Balance | BI_DB_Daily_HighCashoutEmailsForManagement | Balance | Rename. Passthrough. | Tier 2 |
| Snapshot_FundingType | BI_DB_Daily_HighCashoutEmailsForManagement | FundingType | Rename. Passthrough. | Tier 2 |
| Snapshot_CashoutReason | BI_DB_Daily_HighCashoutEmailsForManagement | CashoutReason | Rename. Passthrough. | Tier 2 |
| RequestDate | Fact_BillingWithdraw | RequestDate | Passthrough via JOIN on WithdrawID. | Tier 1 |
| ModificationDate | Fact_BillingWithdraw | ModificationDate | Passthrough via JOIN on WithdrawID. | Tier 1 |
| Max_UpdateDate_BillingWithdraw | Fact_BillingWithdraw | UpdateDate | MAX(UpdateDate) — global scalar variable, same for all rows. | Tier 2 |
| CashoutStatus | Dim_CashoutStatus | Name | Lookup: Fact_BillingWithdraw.CashoutStatusID_Withdraw → Dim_CashoutStatus.Name. | Tier 2 |
| CashoutStatusID_Withdraw | Fact_BillingWithdraw | CashoutStatusID_Withdraw | Passthrough via JOIN on WithdrawID. | Tier 1 |
| Phone_Calls | BI_DB_UsageTracking_SF | ActionName='Phone_Call_Succeed__c' | SUM(CASE) count of successful phone calls between RequestDate and resolution date. | Tier 2 |
| UpdateDate | — | — | GETDATE(). ETL metadata. | Tier 5 |
| Completed_Email | BI_DB_UsageTracking_SF | ActionName='Completed_Contact_Email__c' | SUM(CASE) count of completed contact emails between RequestDate and resolution date. | Tier 2 |
| Attemp_Phone_Call | BI_DB_UsageTracking_SF | ActionName='Contacted__c' | SUM(CASE) count of phone call attempts between RequestDate and resolution date. | Tier 2 |
| Attemp_Email | BI_DB_UsageTracking_SF | ActionName='Outbound_Email__c' | SUM(CASE) count of outbound email attempts between RequestDate and resolution date. | Tier 2 |

## Source Objects

| Source Object | Type | Columns Used |
|--------------|------|-------------|
| BI_DB_dbo.BI_DB_Daily_HighCashoutEmailsForManagement | BI_DB Table | All 25 Snapshot_ columns (daily email data) |
| DWH_dbo.Fact_BillingWithdraw | DWH Fact | WithdrawID, RequestDate, ModificationDate, CashoutStatusID_Withdraw, UpdateDate |
| DWH_dbo.Dim_CashoutStatus | DWH Dimension | CashoutStatusID, Name |
| BI_DB_dbo.BI_DB_UsageTracking_SF | BI_DB Table | CID, ActionName, CreatedDate_SF |
