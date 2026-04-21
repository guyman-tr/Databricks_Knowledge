-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.RemovePrefix
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Extracts the **rightmost segment** of a delimited string by finding the last occurrence of `@Delimiter` and returning everything to its right. Effectively "removes the prefix" — strips all leading segments and the final delimiter, returning only the trailing part. **Primary use case**: Parsing EXW_Settings `ResourceName` paths to extract the final component. For example, given a ResourceName like `''cryptos/2/allowstakingmode''` with delimiter `''/''`, returns `''allowstakingmode''`. **Contrast with RemoveSuffix**: RemoveSuffix returns everything before the *first* delimiter; RemovePrefix returns everything after the *last* delimiter.

