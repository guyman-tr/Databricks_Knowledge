-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_WalletElligibleCountries
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- EXW_WalletElligibleCountries is the per-country wallet eligibility reference table. It answers the question: "Can users from Country X, operating under Regulation Y, open or use an eToro Wallet?" The table has one row per country × regulation combination (4,228 rows = 250 countries × ~17 rows average, including US state-level breakdown). The core data comes from EXW_Settings resource 5903 (''AllowedUsingWalletStatus''), which stores operator-configured rules at various granularities (by country, by country+regulation, by country+region, etc.). The SP resolves the winning rule per country × regulation × US state by selecting the highest-priority setting (max RestrictionWeight) from the applicable rule matches. Current distribution: Closed (0) = 2,183 combinations (52%), Open (2) = 1,947 (46%), OpenForExistingOnly (3) = 98 (2%). No ReadOnly (1) entries exist in the current data — this valu

