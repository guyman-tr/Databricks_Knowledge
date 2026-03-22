# Review Sidecar — Dealing_dbo.External_Fivetran_dealing_overnight_fees

## Unverified Claims

| # | Claim | Source | Needs |
|---|-------|--------|-------|
| 1 | Schema alias: Dealing_staging vs Dealing_dbo contains the same data | SP code references `Dealing_staging` schema | Verify whether Dealing_dbo copy is a synonym or separate table |
| 2 | Front/Next assignment relies on alphabetical ticker sort | SP code `ROW_NUMBER() OVER (PARTITION BY future_short_cut ORDER BY ticker)` | Confirm Bloomberg ticker naming always sorts front-month first |
| 3 | Only 7 specific InstrumentIDs are used (17, 22, 339-341, 343, 344) | SP WHERE clause | Verify if additional instruments have been added since SP was written |
| 4 | Data source is Bloomberg | Inferred from ticker naming conventions | Confirm the actual data provider |

## Reviewer Corrections

*(none yet)*
