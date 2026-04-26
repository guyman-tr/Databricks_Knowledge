# Review Needed: BI_DB_dbo.BI_DB_OPS_MastersAndSubAccounts_AlignmentMonitoringReport

## Tier 4 Items (Low Confidence)

None -- all columns traced to SP code and upstream wikis.

## Questions for Reviewer

1. **AccountType CASE logic**: The Master SELECT uses `CASE WHEN bc.MasterAccountCID = bc.MasterAccountCID` which is always true (self-comparison). This means all rows from the first UNION branch are 'Master'. Intentional since that branch only pulls MasterAccountCID as CID, but the CASE is misleading.
2. **Q32 from two sources**: Q32_PEP_MM_Question comes from BI_DB_KYC_Panel while Q32_AnswerText comes from V_CustomerAnswers (latest per GCID). These may diverge if the customer re-answered Q32. Which is authoritative?
3. **PendingWithdraws Monday logic**: On Mondays, the pending window extends 3 days back (to cover Friday+weekend). This means Monday snapshots include more pending items than other days -- SLA comparisons across weekdays may be misleading.
4. **No UC migration**: This table has no generic pipeline mapping entry and is not migrated to Unity Catalog.
5. **Atlassian search unavailable**: Could not verify business context for master-sub alignment monitoring.
6. **Employee account exclusion**: Change history (2025-11-10) mentions removing employee accounts, but the SP code uses PlayerLevelID<>4 for both master and sub -- PlayerLevelID=4 is "Internal" per Dim_PlayerLevel wiki, not necessarily employees. Confirm this captures the intent.
7. **TotalCompensation uses Amount>0**: Unlike Object 2 (HighCompensationsVsDeposits) which uses Amount<0, this SP filters Amount>0 -- tracking credit compensations given TO the customer.

## Corrections Applied

- Dim_RiskClassification, Dim_AccountType, Dim_RiskStatus, Dim_ScreeningStatus, Dim_PendingClosureStatus: Assigned Tier 2 (DWH dim lookups -- no production upstream wiki documents these as Tier 1).
