# BI_DB_dbo.BI_DB_ClusteringLog — Review Needed

## 1. Tier 3 Coverage

All 5 columns are Tier 3. No upstream wiki exists (`_no_upstream_found.txt` present). Descriptions are grounded in DDL structure, live sample data, and downstream SP_CID_DailyCluster code analysis.

## 2. Open Questions

- **Python/ML pipeline ownership**: Which team owns the clustering pipeline that writes to `BI_DB_python.BI_DB_ClusteringLog`? Likely BI-Customer team based on Confluence search results. Confirm with data engineering.
- **Clustering algorithm**: What ML model/algorithm assigns the 6 cluster labels? The pipeline is external to Synapse — source code not available in the DataPlatform SSDT repo.
- **Promotion mechanism**: How is data promoted from `BI_DB_python.BI_DB_ClusteringLog` to `BI_DB_dbo.BI_DB_ClusteringLog`? No SP was found for this step — may be a CTAS, RENAME, or external orchestration.
- **Duplicate CID+DateID rows**: Sample data did not show duplicates, but there is no uniqueness constraint. SP_CID_DailyCluster uses GROUP BY when reading, suggesting duplicates may exist or have existed historically.

## 3. Data Quality Observations

- **UpdateDate lag**: Sample data shows UpdateDate is typically 1-2 days after Date, suggesting the pipeline runs with a short delay after the assignment date.
- **NULL columns**: All columns are nullable per DDL, but sample data shows no NULLs in any column. Confirm whether NULLs are expected.
- **HEAP storage**: The BI_DB_dbo copy uses HEAP (no clustered index), while the BI_DB_python staging copy has a CLUSTERED INDEX on DateID. Consider adding an index for query performance on this 202.9M-row table.

## 4. UC Migration Status

Table is marked `_Not_Migrated`. No Unity Catalog target has been defined. Assess whether this table should be migrated as part of the BI_DB clustering pipeline migration to Databricks.
