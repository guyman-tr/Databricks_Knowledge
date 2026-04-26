# BI_DB_dbo.BI_DB_German_Open_Real_Crypto_Positions_Daily — Review Needed

## Tier 4 Items
None.

## Open Questions
1. **Registration cutoff 2023-07-13**: The SP filters Dim_Customer.RegisteredReal < '2023-07-13'. This likely corresponds to a regulatory change (BaFin crypto custody transition or MiCA-related policy). Confirm the business rationale for this cutoff date.
2. **Author unknown**: The SP has no author/date header comments. Recommend adding author attribution if known.
3. **Relationship to Tangany transition**: This table and BI_DB_German_Crypto_Transition_To_Tangany both focus on German crypto customers. Confirm if they serve the same regulatory reporting use case or different stakeholders.
4. **No downstream consumers found**: Not referenced by any other SP in the SSDT repo. Likely consumed by regulatory dashboards or compliance reports.
5. **BuyCurrency count mismatch**: 180 distinct BuyCurrency values vs 189 distinct InstrumentDisplayName values — some instruments share the same currency ticker (e.g., multiple tokens on the same blockchain). This is expected but may confuse analysts who assume 1:1 mapping.

## Reviewer Corrections
- None pending.

## Atlassian
- Atlassian search unavailable during this batch. Recommend manual check for Jira tickets related to "German crypto positions" or "BaFin daily report".
