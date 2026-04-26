# Review Notes — BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_CIDs

**Batch**: 18 | **Generated**: 2026-04-21 | **Reviewer**: TBD

## Tier 4 Items

None. All 5 columns are Tier 2 (Fivetran/Google Sheets passthrough).

## Data Quality Issues Flagged

1. **'Gaming/eGamling' typo** — List value misspelled in source Google Sheet. 'eGamling' instead of 'eGambling'. The typo is preserved in the physical table — queries must use the misspelled string exactly.

2. **nvarchar → int implicit cast** — Source Google Sheet CID column is nvarchar(4000). Invalid non-integer values in the sheet would cause the SP to fail silently or error at INSERT. No explicit CAST/TRY_CAST in SP.

3. **nvarchar → date implicit cast** — from_date and to_date in the External Table are nvarchar(4000). Invalid date strings would cause INSERT failure.

## Open Questions

1. **Google Sheet URL** — The SP header references https://bit.ly/3ccznBr. Is this still the active Google Sheet? If Fivetran is pulling from SharePoint/compliance_help_cids, the bit.ly link may be outdated documentation.

2. **No date-range overlap validation** — A CID can appear multiple times on the same List with overlapping date ranges. Is this expected or a data quality issue?

3. **ToDate NULL semantics** — Some rows have ToDate = NULL. Does NULL mean "forever active" or "open-ended, to be filled"? Clarify with AML team.
