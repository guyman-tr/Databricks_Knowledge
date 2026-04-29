# Review Needed: BI_DB_dbo.BI_DB_ActiveAffiliatesPlanned

## Critical: Table is Empty

1. **0 rows**: No plan/budget data has been loaded. All planned columns in BI_DB_ActiveAffiliatesPlanned_Actual will be NULL.
2. **Manual input required**: This table has no automated writer SP — data must be loaded manually.

## Questions for Reviewer

- Is the plan/budget upload process still active? If not, should this table and BI_DB_ActiveAffiliatesPlanned_Actual be decommissioned?
- What team is responsible for populating plan targets? (Affiliate team, Finance, Growth?)
- Is there an alternative planning mechanism (e.g., Google Sheets, Salesforce) that replaced this table?
- The DDL has 7 columns but the batch assignment says 8 — confirm the actual column count.
