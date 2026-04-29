# BI_DB_dbo.BI_DB_W8_Users_Status — Review Needed

## Tier 4 Items

None.

## Questions for Reviewer

1. **W8_Group_Status_ID year-end logic**: The expiry classification compares ExpiryDate against the current calendar year-end. Confirm the exact boundary: is status 2 ("expiring this year") defined as ExpiryDate = Dec 31 of current year, or ExpiryDate falls within the current calendar year? Edge cases at year boundaries could shift millions of rows between statuses.
2. **Group classification activity threshold**: Group B vs A is distinguished by "activity" for Bronze/Silver/Gold customers. What defines "activity" — is it last_Log_IN recency, open positions, deposits, or a combination? The exact cutoff criteria should be documented.
3. **RN_W8SignDate always 1**: This column is a ROW_NUMBER residual from the deduplication logic. Since it is always 1 in the output, consider whether it should be dropped in a future cleanup.
4. **ComplianceStateDB source stability**: The GAP requirement columns depend on External_ComplianceStateDB_Compliance_CustomerRequirmentsHistoryViewForW8ben. Confirm this external view is stable and whether RequirementIDs 14/16/17 are fixed or could change.
5. **Previous player status join**: The Previous_PlayerStatus columns come from BI_DB_AML_PlayerStatus_Changes. Confirm the join key and whether this captures the most recent status change or a specific historical point.
6. **VerificationLevelID upstream tier**: Assigned Tier 2 (SP via Dim_Customer) rather than Tier 1. If BackOffice.Customer wiki documents this field, it could be promoted to Tier 1.
