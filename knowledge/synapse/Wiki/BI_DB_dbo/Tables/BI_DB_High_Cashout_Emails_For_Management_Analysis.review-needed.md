# Review Needed: BI_DB_dbo.BI_DB_High_Cashout_Emails_For_Management_Analysis

## Tier 4 Items (Best Available Knowledge)

None — all columns traced to source code or upstream wiki.

## Questions for Reviewer

1. **Snapshot_RequestorComments always NULL**: Column exists in DDL but is NOT in the SP's INSERT list. Was it intended to be populated from BI_DB_Daily_HighCashoutEmailsForManagement.RequestorComments (which is also always NULL in that table)? Should the column be removed?
2. **Column count discrepancy**: DDL has 36 columns but the batch assignment listed 34. DDL used as ground truth.
3. **Typos in column names**: `Attemp_Phone_Call` and `Attemp_Email` — missing 't'. Known or should these be renamed?
4. **AMOPCurrency column missing**: The source table BI_DB_Daily_HighCashoutEmailsForManagement does NOT appear to have this column, and it's not in the INSERT list. Is there a dashboard link mentioned in the SP header that would reveal the intended use?
5. **PII/Sensitive data**: Snapshot_AMLComment and Snapshot_RiskComment contain compliance investigation notes. Should access be restricted?
6. **Last data 2026-04-12**: Latest Snapshot_Date is April 12, while today is April 26. Has the pipeline stopped running?

## Corrections Applied

None.

## Cross-Object Consistency Notes

- **CID**: Same FK convention (Dim_Customer.RealCID) used across BI_DB_dbo.
- **WithdrawID**: Same FK convention as Fact_BillingWithdraw.WithdrawID.
- **CashoutStatusID_Withdraw**: Same name and semantics as Fact_BillingWithdraw.CashoutStatusID_Withdraw.
- **Snapshot_ columns**: Descriptions verbatim from BI_DB_Daily_HighCashoutEmailsForManagement wiki.
