# DWH_dbo.Dim_Manager -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None -- all columns traced to SP code (Tier 2) or live data (Tier 3).

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| UserGroup / ParentUserGroup | Both columns are hardcoded to 'Not Available' in SP_Dictionaries_DL_To_Synapse. Were these originally intended to represent manager team hierarchy (e.g., APAC Customer Success / Global CS)? Is there a plan to populate them, or should they be considered permanently deprecated? |
| CalendlyID | Inactive managers all show CalendlyID='etoro-club'. Is 'etoro-club' a real Calendly handle for a shared/company account, or is it a default placeholder set when a manager's Calendly account is deactivated? Should it be NULL'd out for inactive managers? |
| IsTeamLeader | Only 1 active team leader in the current data (IsActive=True, IsTeamLeader=True = 1 row). This seems very low for 1,367 active managers. Is IsTeamLeader being populated correctly, or has it become stale? |

## Structural Questions

| Question |
|----------|
| Dim_Manager uses an incremental UPDATE+INSERT pattern (never truncated). This is unusual for DWH dimension tables. Was this intentional to preserve InsertDate as the manager's true first-appearance date? If a manager is re-hired with the same ManagerID, what happens? |
| PK_ManagerID is NOT ENFORCED -- Synapse syntax, but no DB-level uniqueness guarantee. Has any duplicate ManagerID been observed in practice? |
| SFManagerID is set only for managers present in SalesForceToBOManagerMapping. How many of the 1,367 active managers have SFManagerID populated vs NULL? Should all active managers have a Salesforce mapping? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On | New Tier 1-3 | Change Summary |
|--------|-------------------|--------------|--------------|----------------|
