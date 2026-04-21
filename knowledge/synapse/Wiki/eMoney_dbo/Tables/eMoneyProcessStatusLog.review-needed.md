# Review Needed — eMoney_dbo.eMoneyProcessStatusLog

Generated: 2026-04-21 | Reviewer: Data Engineering / eTM Platform Team

## Tier 4 Items (Requires Verification)

None — all 5 columns are Tier 2 sourced directly from SP_eMoneyProcessStatusLog code.

## Open Questions

1. **Why were SPs commented out in 2023-10-30?** SP_eMoney_Execute_Group_One header attributes the change to Katy F ("Disable SPs execs"). Was this a permanent architectural change (individual SP scheduling) or a temporary disable? If permanent, the log is now a historical archive only.

2. **Are individual SPs now logged elsewhere?** Since the eTM SPs still run (eMoney_Dim_Account UpdateDate = 2026-04-13), they must be scheduled independently. Do they log execution status elsewhere (ADF pipeline logs, Synapse monitoring, Databricks job logs)?

3. **Should this table be de-listed?** Since it receives no new data and the orchestration pattern changed, consider whether this table should be marked as "Archived" rather than "Active" in the schema index.

4. **NULL ProcessName entries (9 rows)**: These predate the SP naming convention finalization. If historical accuracy matters, these can be traced by joining on ProcessStatusTime to the SP_eMoney_Execute_Group_One orchestration timeline.

5. **CATCH block still active**: SP_eMoney_Execute_Group_One CATCH block (lines 153-154) still calls SP_eMoneyProcessStatusLog. If this orchestrator SP is ever called directly (e.g., debugging), Fail entries would be added. Is this intentional?

## Reviewer Corrections

*[To be filled by reviewer]*

## Flagged Risks

- Table is FROZEN since 2023-10-30 — querying for recent operational status will return stale data.
- The 60 Start entries without matching Complete/Fail (8,377 − 8,317 − 32 = 28) suggest some edge cases where the log was written to Start but the SP crashed before the Complete/Fail was written. These represent unlogged failures.
