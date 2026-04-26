# Review Needed: BI_DB_dbo.BI_DB_OPS_Fraud_Alert_Analysis

## Tier 4 Items (Low Confidence)

None — all columns traced to SP code and upstream wikis.

## Questions for Reviewer

1. **TotalCommissions discarded**: The SP computes `SUM(Revenue_Total) AS TotalCommissions` from BI_DB_CID_DailyPanel_FullData but the INSERT list does not include this column and the DDL has no TotalCommissions column. Is this intentional or a bug?
2. **ClusteredIP_RegistrationFlag always 0**: The threshold of 20 registrations within the same second (DATETIME2(0)) may be too strict. Should this be widened to same-minute grouping (currently done separately in CountryTimeClustersFlag)?
3. **3-month window alignment**: The filter is month-aligned (first of the month 3 months ago), not a rolling 90-day window. Is this the intended behavior?
4. **LanguageCountryMismatchFlag Pakistan**: LanguageID check uses `121` which may be a typo (should be `12` for Urdu?). CommunicationLanguageID check uses `12`. The mismatch in the SP code is suspicious.
5. **SP author Michail Vryoni (2025-06-25)**: No change history entries. Is this SP actively maintained?
6. **Atlassian search unavailable**: Could not search Confluence/Jira for business context on the fraud alert analysis workflow.

## Corrections Applied

- 2FA tier: Assigned Tier 2 (SP_Dim_Customer) matching Dim_Customer wiki which documents it as derived from STS_Audit_UserOperationsData.
- IsDepositor tier: Assigned Tier 2 (SP_Dim_Customer) matching Dim_Customer wiki which shows it's updated post-load.
- IsValidCustomer tier: Assigned Tier 2 (SP_Dim_Customer) matching Dim_Customer wiki which shows it's DWH-computed.
- EvMatchStatusName tier: Assigned Tier 2 (SP_Dictionaries_DL_To_Synapse) matching Dim_EvMatchStatus wiki.
