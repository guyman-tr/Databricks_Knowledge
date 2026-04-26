# Review Needed: BI_DB_dbo.BI_DB_ActiveAffActualMonthly_Region_GroupAffName

Generated: 2026-04-21 | Batch 13 #1

## Tier 4 Items (Low Confidence — Needs Verification)

_No Tier 4 items. All columns resolved to Tier 1, Tier 2, or Tier 5._

## Open Questions for Reviewers

1. **"New affiliate" year filter**: The SP uses `HAVING YEAR(MIN(date)) >= YEAR(@StartDate)` to identify new affiliates. This filter means for January runs, affiliates who started in prior years are not counted as "new" — but for mid-year runs, affiliates who started in January of the same year would be included. Is this the intended behavior? Should this be an exact month filter?

2. **YearMonth ≠ Date edge case**: The `YearMonth` column is derived from the actual event date (registration/FTD date), while `Date` is the first day of the target month parameter. In theory, if an affiliate brings a registration on March 31 and the SP is run for April, could that registration appear in the April row? Clarify if this is a known edge case.

3. **Desk = 'Unknown' (89 rows)**: 89 rows have Desk = 'Unknown'. These are affiliate registrations where BI_DB_CIDFirstDates.Region had no corresponding match in DWH_dbo.Dim_Country.Region. Is this expected? Is there a cleanup process?

4. **Cross-object Desk consistency**: Existing BI_DB wikis (KYC_Weekly_Export, Professional_OptUp) describe `Desk` with Tier 2 (SP-derived). This wiki uses Tier 1 (DWH_dbo.Dim_Country) per the upstream inheritance rule. Reviewer should confirm whether the two prior wiki files should be updated to Tier 1 for their Desk column (since they also source from Dim_Country).

5. **Amount_FTDs currency**: Assumed USD based on BI_DB_CIDFirstDates.FirstDepositAmount. Please confirm all affiliate desks report in USD or if currency conversion is applied.

6. **Frequency vs process**: OpsDB records this as `ProcessName=SB_Daily` but `FrequencySP=Monthly`. Confirm whether this is run daily (as part of SB_Daily) but only processes the current month, or truly monthly.

## Correction Notes

- Column names `NewAffWithRegistretActual`, `TotalActiveAffRegistretActual`, `TotalRegistretActual` contain "Registret" (should be "Registered"). This is a legacy typo embedded in the DDL — not a documentation error.
- The SP excludes test affiliates (`AffiliatesGroupsName NOT LIKE '%test%'`) only in the "new affiliate" subqueries (#FirstFTDsRaw, #FirstRegRaw), not in the total active counts. This means test affiliates may appear in TotalActive* metrics but not in New* metrics.
