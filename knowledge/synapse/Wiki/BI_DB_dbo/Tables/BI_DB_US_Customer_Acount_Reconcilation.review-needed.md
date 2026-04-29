# BI_DB_dbo.BI_DB_US_Customer_Acount_Reconcilation — Review Needed

## Tier 4 Items

None.

## Questions for Reviewer

1. **Table/column name typos**: "Acount" (not Account) and "Reconcilation" (not Reconciliation) in table name; "EtoroAcountStatus" has same typo. Are there downstream consumers relying on these names?
2. **'Check' status never persisted**: The SP logic includes a 'Check' CASE branch for both-side matches, but the WHERE clause filters them out. Is this intentional — was 'Check' ever persisted historically?
3. **347M rows with no indexing**: HEAP with ROUND_ROBIN on 347M rows — should Date be indexed or should the table be partitioned by Date?
4. **ApexApprovedDate nullability**: NULL for auto-approved accounts — is there a way to distinguish "auto-approved" from "approval date not yet captured"?
