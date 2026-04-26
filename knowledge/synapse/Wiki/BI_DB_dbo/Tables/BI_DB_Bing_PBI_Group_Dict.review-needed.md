# Review Needed: BI_DB_dbo.BI_DB_Bing_PBI_Group_Dict

## Items Requiring Human Review

### Tier 4 / Low-Confidence Items

None — all 11 columns are Tier 2 with clear SP code traceability.

### Questions for Reviewers

1. **SP "--need to fix" comment**: SP_Bing_PBI has a comment on the Group_Dict source table reference (`--need to fix`). What is the known issue? Is this technical debt from an incorrect source table being used, or a naming issue?

2. **id type conversion (bigint→varchar)**: The `id` column is stored as varchar(max) despite containing bigint values. Is this intentional? JOINs from Daily_Perf/Goals_Funnels (where ad_group_id is bigint) require explicit CAST, which may impact query performance at scale. Should the DDL be corrected to bigint?

3. **Non-unique id**: The history source produces 110,185 rows for 83,503 distinct ad groups. Power BI reports that JOIN on ad_group_id without dedup will multiply rows. Are existing reports aware of this? Is there a Power BI-level deduplication step?

4. **cpc_bid truncation**: Float→numeric(18,0) truncation loses decimal precision. For eToro's Bing campaigns, are there fractional CPC bids being silently rounded down to 0? This could affect any bid analysis done from this table.

5. **Feed status divergence**: Dictionary tables (Group_Dict, Campaign_Dict) are still being refreshed (2026-04-13) while performance tables (Daily_Perf, Goals_Funnels) stopped in 2025-10-16. Should the dictionary tables be frozen alongside the performance tables once Bing Ads reporting is officially decommissioned?

### Potential Issues

- The TRUNCATE+INSERT pattern means this table has no history visibility within the DWH — only the most recent Fivetran snapshot is preserved. Historical ad group configurations are only available from the source lake directly.

### Corrections from Prior Reviews

None.
