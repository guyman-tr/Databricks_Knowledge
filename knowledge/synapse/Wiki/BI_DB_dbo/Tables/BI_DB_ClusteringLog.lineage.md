# BI_DB_dbo.BI_DB_ClusteringLog — Column Lineage

## Source Objects

| # | Source Object | Source Type | Relationship | Schema |
|---|---|---|---|---|
| 1 | BI_DB_python.BI_DB_ClusteringLog | Table (staging) | Direct copy — Python ML pipeline output staged here before promotion to BI_DB_dbo | BI_DB_python |
| 2 | SP_CID_DailyCluster | Stored Procedure | Reader — consumes this table to build BI_DB_CID_DailyCluster | BI_DB_dbo |
| 3 | BI_DB_ClusteringDailyPrepData | Table | Sibling — joined by SP_CID_DailyCluster on CID for ratio enrichment | BI_DB_dbo |

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | CID | BI_DB_python.BI_DB_ClusteringLog | CID | Passthrough from Python ML pipeline staging table | Tier 3 |
| 2 | ClusterDesc | BI_DB_python.BI_DB_ClusteringLog | ClusterDesc | Passthrough — ML-assigned cluster label | Tier 3 |
| 3 | Date | BI_DB_python.BI_DB_ClusteringLog | Date | Passthrough — clustering assignment date | Tier 3 |
| 4 | DateID | BI_DB_python.BI_DB_ClusteringLog | DateID | Passthrough — integer key YYYYMMDD | Tier 3 |
| 5 | UpdateDate | BI_DB_python.BI_DB_ClusteringLog | UpdateDate | Passthrough — timestamp of last clustering run | Tier 3 |

## Notes

- No production database upstream exists. Data originates from a Python/ML clustering pipeline that writes to `BI_DB_python.BI_DB_ClusteringLog` (staging schema), then promoted to `BI_DB_dbo.BI_DB_ClusteringLog`.
- No Synapse SP writes to this table; all inserts come from the external Python pipeline.
- `_no_upstream_found.txt` marker is present — no upstream wiki is resolvable.
