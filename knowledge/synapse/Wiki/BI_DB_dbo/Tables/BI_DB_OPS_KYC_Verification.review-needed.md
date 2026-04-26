# Review Needed: BI_DB_dbo.BI_DB_OPS_KYC_Verification

## Tier 4 Items (Low Confidence)

None — all columns traced to SP code and upstream wikis.

## Questions for Reviewer

1. **Effective date waterfall complexity**: The EffectiveAddDate calculation has 5 branches in a CASE expression. Confirm the business intent — is EVMatchStatusDate always the preferred SLA start for EV-verified customers?
2. **FirstTouch SLA logic**: The FirstTouch calculation has 5 CASE branches with different DATEDIFF sources depending on the relationship between FirstReviewed, FirstDepositDate, EffectiveAddDate, DateAdded, and EVMatchStatusDate. This is fragile — a misunderstanding in one branch could misreport SLA.
3. **Occurred sentinel '3000-01-01'**: Documents without review have Occurred set to 3000-01-01. This sentinel will produce very large FirstTouch values if not filtered. Confirm downstream consumers filter this correctly.
4. **Document type IDs**: SuggestedDocumentTypeID IN (1,2,13,15,6,18,23) — what are types 6, 13, 15, 18, 23? Only 1=POA and 2=POI are commented in the SP.
5. **@6month is actually 1 year**: Despite the variable name `@6month`, it's set to `DATEADD(YEAR, -1, DATEFROMPARTS(YEAR(GETDATE()), 1, 1))` — Jan 1 of the prior year. Misleading variable name.
6. **WITH (NOLOCK) usage**: The SP uses NOLOCK hints which are unnecessary in Synapse snapshot isolation. Not a data quality issue but code smell.
7. **Atlassian search unavailable**: Could not verify business context for KYC verification SLA reporting.

## Corrections Applied

- Region tier: Assigned Tier 2 (SP_Dictionaries_Country_DL_To_Synapse) matching Dim_Country wiki.
- IsDepositor: Assigned Tier 2 (SP_OPS_KYC_Verification) because it's re-computed differently from Dim_Customer.IsDepositor.
