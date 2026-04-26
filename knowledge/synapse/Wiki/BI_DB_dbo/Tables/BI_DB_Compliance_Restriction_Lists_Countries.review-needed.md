# Review Notes — BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_Countries

**Batch**: 18 | **Generated**: 2026-04-21 | **Reviewer**: TBD

## Tier 4 Items

None. All 8 columns are Tier 2 (SP/ETL code — Fivetran/Google Sheets passthrough via SP_CID_Compliance_CID_And_Country_Risk_Lists).

## Data Quality Issues Flagged

1. **UsedIn and Source always NULL** — Both columns exist in DDL and in the External Table source (fields: `used_in`, `source`), but the SP INSERT explicitly lists target columns and omits them. They are never populated. The wiki documents this, but AML team should confirm whether these fields were intentionally abandoned or need to be wired in.

2. **nvarchar → int implicit cast (CountryID)** — Source Google Sheet `country_id` column is nvarchar in the External Table. Invalid non-integer values in the sheet would cause the SP INSERT to fail. No explicit CAST/TRY_CAST in the SP.

3. **NULL List rows (2 rows)** — 2 rows in the physical table have NULL List value. This is a data quality gap originating from the source Google Sheet. AML team should review.

4. **CountryID NULL for unmapped countries** — Countries like Jersey, Palestine, French Southern and Antarctic Territories have no DWH CountryID mapping. Any JOIN on CountryID silently drops these rows.

## Open Questions

1. **Test___ prefix lists** — Two lists start with `Test___` (`Test___Trading_Alert_HighLeverage` with 179 rows, `Test___Trading_Alert_CFD` with 30 rows). These account for ~27% of all rows. Are these still operationally used, or are they legacy/test categories that should be excluded from compliance queries? Verify with AML team.

2. **UsedIn / Source wiring** — Were these columns intentionally excluded from the ETL pipeline (i.e., the Google Sheet fields were informational only and never formally part of the data model)? Or is this an incomplete implementation that should be filled in?

3. **Full rebuild semantics** — The daily TRUNCATE+INSERT means there is no historical record if a country is removed from a list. Is there a separate audit/history table for compliance list changes?
