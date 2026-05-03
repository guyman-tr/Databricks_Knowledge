# Review Needed: BI_DB_dbo.Rev_Cluster_Dict

## 1. Tier 3 Coverage

All 8 columns are Tier 3 — this is expected for a manually maintained static dictionary with no writer SP and no upstream production wiki (`_no_upstream_found.txt` confirmed).

Column descriptions are grounded in:
- DDL column names and types
- Consumer SP logic (SP_KYC_Score_CID_Level CASE expressions define the bracket semantics)
- Live data sampling (all 36 rows inspected; distinct values confirmed)

## 2. Items for Human Review

- **Cluster assignment logic**: The mapping from 3-dimension combinations to cluster numbers (1–10) appears to be a business-defined decision. No documentation was found explaining _why_ specific combinations map to specific clusters. A subject matter expert (Tal Buhnik or Yarden) should confirm the cluster numbering rationale.
- **Completeness**: The table has 36 rows covering 3×3×4 = 36 combinations. The "Not_Answered" (index=99) category from the SP is intentionally excluded from this dictionary — customers with any unanswered dimension get "No Cluster" via the LEFT JOIN NULL path. Confirm this is intended.
- **Staleness**: Last update was 2023-11-14 (over 2 years ago). Confirm whether the cluster definitions are still current or if an update is planned.
- **No OpsDB entry**: This table is not tracked in OpsDB. If it should be monitored, it needs to be added.

## 3. Production Source

Production source is unknown/dormant. The table is manually maintained with no ETL pipeline. No upstream wiki exists.
