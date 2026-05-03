# BI_DB_dbo.BI_DB_CountryDCM — Review Needed

## 1. Tier 3 Coverage

All 4 columns are Tier 3 (no upstream wiki, no writer SP). This is expected for a manually loaded reference table with no automated ETL.

## 2. Open Questions

- **Who maintains this table?** No writer SP exists. The single UpdateDate (2021-10-13) suggests a one-time bulk load. If ongoing maintenance is needed, the owner/process is undocumented.
- **Sync with Dim_Country**: Both this table and `DWH_dbo.Dim_Country` have a `MarketingRegionManualName` column. It is unclear whether these are kept in sync or can diverge. SP_DCM_Dashboard uses `Dim_Country.MarketingRegionManualName` in some code paths and this table's value in others.
- **Completeness**: Are all 231 countries still current? DCM may have added new countries or territories since October 2021.

## 3. Suggested Actions

- [ ] Identify the table owner and document the update process
- [ ] Verify whether `MarketingRegionManualName` values here match `DWH_dbo.Dim_Country.MarketingRegionManualName` for the same countries
- [ ] Confirm whether any new countries have been added to DCM campaigns since 2021-10-13 that are missing from this mapping
