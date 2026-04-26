# BI_DB_dbo.BI_DB_DCM_Dashboard — Review Needed

## Tier 2 Items (All Columns)

All 39 non-ETL columns are Tier 2 (SP code analysis). No upstream wiki for DCM Fivetran data.

## Open Questions

1. What currency is MediaCost in? The DDL type is int, not money/decimal — is this in cents, dollars, or a different unit?
2. FTDs vs FTDs1 and Regs vs Regs1 — are they always identical at "High Level"? The comment says "calculation changed" in Nov 2021 but both still exist. Can FTDs1/Regs1 be removed?
3. The RIGHT JOIN in the "First Action" UNION with Dim_Affiliate produces rows for all affiliates even if no first action data exists — is this intentional? It creates sparse rows.
4. BI_DB_CountryDCM is used to map DCM country names to Affwiz country names — where is this mapping maintained?
5. The 90-day rolling window is significantly larger than most BI_DB tables (typically 10 days). Is this due to DCM view-through attribution windows?

## Data Quality Observations

- First Action LOD is very sparse (<1% of rows) — most product breakdown columns will be 0
- Campaign/CampaignId/Placement/PlacementId are NULL for ~27% of rows (High Level LOD)
- MediaCost is int type, which truncates decimal values — potential precision loss

## Cross-Object Consistency

- Country values from Dim_Country.Name — consistent with other BI_DB tables ✓
- AffiliateID from Dim_Affiliate — consistent ✓
