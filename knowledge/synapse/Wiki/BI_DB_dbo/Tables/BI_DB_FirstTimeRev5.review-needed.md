# BI_DB_dbo.BI_DB_FirstTimeRev5 — Review Needed

## Tier 4 Items
None.

## Open Questions
1. **Business context**: What downstream process consumes this table? No consumers found in the BI_DB_dbo codebase. Likely used by BI dashboards or external reporting outside the SSDT repo.
2. **$5 threshold**: Is $5 a configurable business rule or hardcoded? Currently hardcoded in the SP (`WHERE AggregatedCommission > 5`). Confirm if this threshold has changed or is planned to change.
3. **Minor row-CID discrepancy**: 994,439 rows vs 994,412 distinct CIDs (27 extra rows). Likely from same-day reprocessing edge cases. Confirm if this is expected.

## Reviewer Corrections
- None pending.

## Atlassian
- Atlassian search unavailable during this batch. Recommend manual check for Jira tickets related to "FirstTimeRev5" or "$5 commission milestone".
