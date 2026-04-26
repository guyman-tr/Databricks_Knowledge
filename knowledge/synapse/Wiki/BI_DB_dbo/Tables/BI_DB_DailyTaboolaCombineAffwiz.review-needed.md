# BI_DB_dbo.BI_DB_DailyTaboolaCombineAffwiz — Review Needed

## Tier 2 Items (All Columns)

All 20 non-ETL columns are Tier 2 (SP code analysis). No upstream production wiki exists for the Taboola API data source or the marketing attribution logic.

## Open Questions

1. What currency is Cost denominated in? The Taboola API reports in campaign currency — is this always USD, or does it vary by market (EUR for EU campaigns)?
2. The campaign name parsing logic is extremely complex (deeply nested CHARINDEX/LEFT/REVERSE). Has this been validated for edge cases? What happens when a campaign name doesn't follow the expected format?
3. BI_DB_python.BI_DB_TaboolaCampaignsByCountry is loaded by a Python process — what is the refresh cadence? Is it always populated before SP_Taboola runs?
4. The Ver2 (Verification Level 2) source uses SubAffiliateID while Reg/FTD use SubSerialID — why the different source fields?
5. VisibleImpressions — is this the IAB/MRC viewability standard? Confirm with the marketing analytics team.

## Data Quality Observations

- Platform NULL for ~15% of recent rows — campaign naming convention is not always followed
- AffiliateID is always 45729 — column is functionally constant
- AW_* columns are NULL for many rows (Taboola-only campaigns with no Affwiz match)

## Cross-Object Consistency

- Country values from Dim_Country.Name — consistent with other BI_DB tables ✓
- AffiliateID matches Dim_Affiliate — but hardcoded rather than dynamic ✓
