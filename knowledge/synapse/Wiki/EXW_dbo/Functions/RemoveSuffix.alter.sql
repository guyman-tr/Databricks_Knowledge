-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.RemoveSuffix
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Extracts the **leftmost segment** of a delimited string by finding the first occurrence of `@Delimiter` and returning everything to its left. Effectively "removes the suffix" — strips the delimiter and all trailing segments, returning only the leading part. **Primary use case**: Parsing EXW_Settings `ResourceName` paths to extract the leading component. For example, given a ResourceName like `''cryptos/2/allowstakingmode''` with delimiter `''/''`, returns `''cryptos''`. **Contrast with RemovePrefix**: RemovePrefix returns everything after the *last* delimiter; RemoveSuffix returns everything before the *first* delimiter.

