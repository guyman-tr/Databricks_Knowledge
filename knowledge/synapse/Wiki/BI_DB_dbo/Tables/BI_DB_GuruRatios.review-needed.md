# Review Needed: BI_DB_dbo.BI_DB_GuruRatios

## 1. Staleness / Disabled SP

- Both `SP_GuruRatio` and `SP_Guru_Ratio_Populate` contain `-- Disabled for investigation`
- All 50 rows have `UpdateDate = 2024-06-06` — the table has not been refreshed in ~2 years
- **Action needed**: Confirm whether this table is still in use or should be deprecated. If deprecated, consider adding to the blacklist.

## 2. Legacy SP Copy (SP_GuruRatio_20240305)

- `SP_GuruRatio_20240305` is a near-identical copy of `SP_GuruRatio`, likely a pre-change backup from 2024-03-05
- The only difference is the newer SP uses explicit `CREATE TABLE ... WITH (DISTRIBUTION, HEAP)` syntax instead of `SELECT INTO`
- **Action needed**: Confirm if the backup SP can be dropped.

## 3. Unresolved External Source

- `general.etoroGeneral_History_GuruCopiers` is an external/staging table with no wiki documentation
- The `Cash` and `Investment` columns from this table feed the ratio numerator but have no documented definition
- **Action needed**: Locate documentation for this external table or document its columns.

## 4. No Downstream Consumers

- No views, SPs, or other objects in the SSDT codebase reference `BI_DB_GuruRatios` as a source
- Combined with the disabled SP, this suggests the table may be orphaned
- **Action needed**: Verify if any external tools (dashboards, reports, ad-hoc queries) consume this table.

## 5. UC Migration Status

- Table is not in `_generic_pipeline_mapping.json` — not migrated to Unity Catalog
- **Action needed**: Determine if migration is planned or if the table will be retired.
