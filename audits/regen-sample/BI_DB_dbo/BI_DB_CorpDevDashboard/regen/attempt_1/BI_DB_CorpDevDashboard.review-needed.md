# Review Needed: BI_DB_dbo.BI_DB_CorpDevDashboard

## 1. Dormancy / Retirement Status

- **Last refresh**: 2023-10-08 (UpdateDate). No data beyond Active_Month=202310.
- **Action needed**: Confirm whether SP_CorpDevDashboard is still scheduled in OpsDB or has been retired. If retired, the table and wiki should be marked as deprecated.
- **Impact**: If dormant, downstream consumers (if any) are reading stale data.

## 2. HASH Distribution Key Anomaly

- The table is distributed on `HASH(CIDs)`, but `CIDs` is a metric column (bigint count), not an identifier.
- This means distribution is effectively random (by count value). For a 7,461-row table this is harmless, but it's architecturally unusual and worth flagging if the table is ever scaled.

## 3. Soc Indicator Duplication Risk

- The `Indicator='Soc'` UNION branch produces one row per MonthlyPanel row (per funded customer per month), LEFT JOINed to the social temp tables by Region. Since social metrics are already aggregated to the Region level in the temp tables, this produces many duplicate rows with the same Liked/Shared/WereCopied/CopiedOther values per region.
- **Action needed**: Verify whether downstream consumers GROUP BY or deduplicate these rows correctly. The current design appears to produce ~5.87M rows for Soc per month in theory, though the live table shows only 21 Soc rows total — suggesting the SP may have a hidden dedup or the table was only loaded for a few months with the Soc logic.

## 4. Revenue Formula Version

- The table uses `Revenue_Total` (legacy formula, excludes function fees) rather than `Revenue_Total_New` (post-2025 formula including all fee components).
- If the dashboard is revived, the revenue columns should be reviewed for alignment with current reporting standards.

## 5. Tier 1 Coverage

- Only 1 of 34 columns qualified for Tier 1 (EOM_Club — passthrough dimension).
- This is expected for an aggregation table where all other columns are SUM/COUNT computations. No Tier 1 coverage issue.

## 6. Missing Upstream Wikis

- `BI_DB_Social_Activity` — no wiki found in the bundle or local Synapse wiki.
- `BI_DB_Guru_Copiers` — no wiki found in the bundle or local Synapse wiki.
- These sources are used for the social engagement metrics (Liked, Shared, WereCopied, CopiedOther). When wikis are generated for these objects, consider re-evaluating tier assignments.
