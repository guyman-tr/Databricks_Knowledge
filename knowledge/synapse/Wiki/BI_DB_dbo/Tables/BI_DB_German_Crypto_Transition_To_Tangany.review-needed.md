# BI_DB_dbo.BI_DB_German_Crypto_Transition_To_Tangany — Review Needed

## Tier 4 Items
None.

## Open Questions
1. **MiCA regulatory context**: Confirm whether this table is specifically for BaFin/MiCA compliance or a broader Tangany integration tracker. The TanganyStatus value "MicaCustomer" suggests MiCA, but "ConsentCustomer" (6) may represent a different regulatory path.
2. **Author unknown**: The SP has no author/date header comments. Recommend adding author attribution if known.
3. **No downstream consumers found**: This table is not referenced by any other SP in the SSDT repo. Likely consumed by BI dashboards or Compliance team reports. Confirm consumers.
4. **NULL vs 0 semantics**: The interaction flag columns (Is_TC, Is_Selfie_Popup, Is_Confirmation_Popup) are NULL when the user is not found in CustomerInteractions (LEFT JOIN). Downstream consumers should use ISNULL(..., 0) for counting. Consider whether the SP should output 0 instead of NULL for cleaner analytics.
5. **Selfie engagement low**: Only 16.5% of users encountered the selfie popup vs 82.5% for T&C. This may indicate the selfie step is conditional on prior steps or was introduced later. Confirm workflow sequencing.

## Reviewer Corrections
- None pending.

## Atlassian
- Atlassian search unavailable during this batch. Recommend manual check for Jira tickets related to "Tangany" or "German crypto transition" or "MiCA".
