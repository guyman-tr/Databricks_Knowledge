# Review: BI_DB_dbo.BI_DB_AM_Contacted

*Sidecar for wiki review. Does NOT contain wiki content — see BI_DB_AM_Contacted.md.*
*Generated: 2026-04-21 | Batch 14 #2*

## Tier 3 Items — Reviewer Confirmation Requested

| Column | Current Tier | Question |
|--------|-------------|---------|
| Desk | Tier 3 | Inherited from Dim_Country wiki (Tier 3 — Ext_Dim_Country_Region_Desk). Is this still the authoritative tier? Any plan to promote Desk to a dimension-level Tier 1 column? |

## Business Logic Questions

1. **Hardcoded ManagerIDs (1151–1154)**: SP_AM_Contacted filters `WHERE dm.ManagerID NOT IN (1151, 1152, 1153, 1154)` — these appear to be test/internal AMs excluded from contact tracking. Confirm these IDs are stable and intentional. Are they documented anywhere in Dim_Manager?

2. **DDM masking on phone columns**: `Last30DaysPhoneContacted`, `Last60DaysPhoneContacted`, `Last30DaysPhoneContactedAttempt` are masked with `MASKED WITH (FUNCTION = 'default()')`. Unauthorized users will see `0` — identical to "not phone-contacted." Is there any downstream query that checks for phone contact rates using a role that lacks UNMASK permission? This could produce silent data quality issues.

3. **Contact rate discrepancy check**: As of 2026-04-13, 0.7% of 2.5M CIDs were contacted in the last 30 days (~17,500 customers). Does this align with business expectations for the AM team's outreach volume?

4. **120-day rolling window boundary**: The rolling delete pattern (`DELETE WHERE UpdateDate < DATEADD(DAY,-120,GETDATE())`) means coverage starts exactly 120 days before the ETL run date. Queries spanning more than 120 days of history will silently miss older data — no error, just incomplete results. Is there a warning in downstream BI reports?

5. **V_Liabilities join to yesterday**: Equity and RealizedEquity are joined on `DateID = CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY,-1,GETDATE()),112))`. If the daily ETL runs before Liabilities data is loaded for yesterday, these columns will be NULL for all rows. Is there a dependency gate between SP_AM_Contacted and the Liabilities load job?

## UC Target Uncertainty

Table not found in generic pipeline mapping. Assumed `_Not_Migrated`. Reviewer should confirm:
- Is there a Databricks/UC equivalent for account manager contact tracking?
- If migrated, update wiki UC Target field and generate ALTER script.

## No Issues Found

- Element count: 15/15 — matches DDL ✓
- DDM masking on 3 phone columns documented ✓
- Rolling 120-day delete pattern documented ✓
- Hardcoded ManagerID exclusions documented ✓
- Club values (7 distinct) confirmed via distribution ✓
- Temp table split (#SF1 30d, #SF2 60d, #SF3 30d+attempts) traced to SP code ✓
