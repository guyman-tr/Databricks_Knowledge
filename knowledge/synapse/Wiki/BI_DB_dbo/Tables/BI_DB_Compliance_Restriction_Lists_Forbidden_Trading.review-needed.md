# Review Notes — BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_Forbidden_Trading

**Batch**: 18 | **Generated**: 2026-04-21 | **Reviewer**: TBD

## Tier 4 Items

None. All 4 columns are Tier 2 (SP code / Fivetran Google Sheets passthrough via SP_CID_Compliance_CID_And_Country_Risk_Lists).

## Data Quality Issues Flagged

1. **nvarchar → int implicit cast (CountryID)** — Source Google Sheet `country_id` column is nvarchar in the External Table. Invalid non-integer values in the sheet would cause the SP INSERT to fail silently or error. No explicit CAST/TRY_CAST in SP.

2. **No date-range columns** — Unlike BI_DB_Compliance_Restriction_Lists_Countries, this table has no FromDate/ToDate. There is no way to determine when a restriction was added or removed. Historical restriction changes are permanently lost on each TRUNCATE+INSERT cycle.

3. **Fivetran artifact `[_]` column** — The External Table source (External_Fivetran_google_sheets_forbiddentrading) includes a `[_]` column (Fivetran row-index artifact). The SP SELECT omits it. Confirm this column should remain excluded.

## Open Questions

1. **SP_Compliance_Forbidden_Trades consumer** — The SP is the known consumer of this table. Are there additional consumers (reports, dashboards, other SPs) that should be documented under Referenced By?

2. **`Rank 1/2 countries` vs `Rank 1 countries`** — Two separate lists exist (136 rows and 16 rows respectively). What is the business distinction? Are "Rank 1 countries" a strict subset of "Rank 1/2 countries" or an independent category?

3. **`Country VBT` and `Regulation VBD`** — These have very few rows (3 and 1 respectively). Are these operationally meaningful restriction types or legacy/test entries that should be excluded from compliance logic?

4. **No date-range tracking** — Is the absence of FromDate/ToDate intentional for this table vs. the Countries table, or was date-range tracking planned but never implemented?
