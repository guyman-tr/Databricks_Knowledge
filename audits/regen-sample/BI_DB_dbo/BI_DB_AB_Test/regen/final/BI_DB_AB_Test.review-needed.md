# BI_DB_dbo.BI_DB_AB_Test — Review Needed

## 1. Dormant Table — Production Source Unknown

- **Issue**: No stored procedure writes to or reads from this table. No Generic Pipeline mapping found. Table was created via Jira DS-1703 and appears to have been manually loaded.
- **Data evidence**: Last UpdateDate is 2023-04-29. No data has been added in over 3 years.
- **Action needed**: Confirm whether this table is still in use or should be deprecated. Identify the original data loading process (manual SQL inserts? external script? SSIS package?).

## 2. Tier 3 Columns — No Upstream Wiki

- **Columns**: DateID, Date, IsControl, BI_Owner, Business_Owner, Name, UpdateDate (7 of 8 columns)
- **Reason**: No upstream wiki exists. No SP code exists to trace column origins. Descriptions are grounded in DDL structure and live data evidence only.
- **Action needed**: If the original data loading script or process is located, review column descriptions for accuracy against the source.

## 3. BI_Owner Column — Single Value

- **Issue**: BI_Owner contains only "Tom Boksenbojm" across all 314,240 rows. This may indicate the column was intended to vary per test but was populated with a default value.
- **Action needed**: Confirm whether BI_Owner was intended to track per-test ownership or is simply a metadata artifact.

## 4. Companion Table Relationship

- **Related object**: BI_DB_dbo.BI_DB_AB_Test_Data has additional columns (TestName, IsControlPortfolioEnabled, ServiceLevelAnchored, IsPortfolioAnchored, FromDateID, ToDateID) that provide richer test configuration.
- **Action needed**: Confirm the intended join between BI_DB_AB_Test and BI_DB_AB_Test_Data (likely RealCID + Name/TestName).

## 5. UC Migration Status

- **Current**: Not migrated to Unity Catalog.
- **Action needed**: Determine if this dormant table warrants UC migration or should be archived.
