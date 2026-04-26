# Review Needed: BI_DB_dbo.BI_DB_ActiveAffiliatesPlanned_Actual

Generated: 2026-04-21 | Batch 13 #2

## Tier 4 Items (Low Confidence — Needs Verification)

_No Tier 4 items. All columns resolved to Tier 1, Tier 2, or Tier 5._

## Open Questions for Reviewers

1. **"New affiliate" year filter**: The SP uses `HAVING YEAR(MIN(date)) >= YEAR(@StartDate)` to identify new affiliates. This means an affiliate who made their first registration in January of the target year is counted as "new" even for a December run of the same year. Conversely, affiliates from prior years are never "new." Is this the intended annual-cohort behavior, or should the filter use an exact month comparison?

2. **NULL Indicator rows (507)**: These are historical rows predating the July 2021 UNION/Indicator restructuring. Are they functionally equivalent to 'Desk' rows (same aggregation logic, just no Indicator stamp)? Can queries safely combine them with `WHERE Indicator = 'Desk' OR Indicator IS NULL`? Should they be backfilled with 'Desk' via a one-time UPDATE?

3. **NewMarketingRegion planned targets**: Branch 2 ('NewMarketingRegion') hardcodes all planned columns to NULL. Is there a plan to add NMR-level planned targets in BI_DB_ActiveAffiliatesPlanned, or is NMR intentionally actuals-only?

4. **ChurnPlaaned as FLOAT**: All other planned columns (NewAffWithFTDPlaaned, TotalActiveAffPlaaned, TotalFTDsPlaaned) are INT. ChurnPlaaned is FLOAT — confirm this represents a rate/ratio (e.g., 0.15 = 15% churn) rather than a count.

5. **Cross-object Desk tier consistency**: This wiki assigns Desk as Tier 1 (DWH_dbo.Dim_Country) per the upstream inheritance rule. Earlier Batch 12 wikis (KYC_Weekly_Export, Professional_OptUp) assigned Desk as Tier 2 (SP-derived). Since all three tables source Desk from Dim_Country via the same Region join, reviewer should confirm whether the prior Batch 12 wikis should be updated to Tier 1 for their Desk column.

6. **Desk='Unknown' rows**: This table uses the same Region→Desk join pattern as BI_DB_ActiveAffActualMonthly_Region_GroupAffName, which has 89 rows with Desk='Unknown' (Region not matched in Dim_Country). Confirm whether this table has a similar 'Unknown' Desk population and whether a cleanup process exists.

## Correction Notes

- Column names `NewAffWithRegistretActual`, `TotalActiveAffRegistretActual`, `TotalRegistretActual` contain "Registret" (should be "Registered"). This is a legacy typo embedded in the DDL — not a documentation error.
- Planned column names `NewAffWithFTDPlaaned`, `TotalActiveAffPlaaned`, `ChurnPlaaned`, `TotalFTDsPlaaned` contain "Plaaned" (should be "Planned"). This is a legacy typo embedded in the DDL — not a documentation error.
- The SP excludes test affiliates (`AffiliatesGroupsName NOT LIKE '%test%'`) only in the "new affiliate" subqueries, not in the total active counts. This means test affiliates may appear in TotalActive* metrics but not in New* metrics.
