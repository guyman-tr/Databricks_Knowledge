-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_Staking_Allowed_Country
-- UC Target: _Not_Migrated
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- EXW_Staking_Allowed_Country stores the resolved staking eligibility for each country/crypto combination. Staking eligibility is controlled through the EXW_Settings configuration system: a setting with ResourceName pattern `cryptos/{N}/allowstakingmode` determines whether a specific crypto can be staked in a specific country. **Current state**: All StakingAllowed values are 0. ETH staking was part of the eToro Wallet offering but has been discontinued. The table structure is preserved for future reactivation capability. The EXW_Settings priority resolution works through weighted tag matching — a country can be matched by CountryAndRegion (country+state), Country name, or GeoRegistrationDate (country group tag). The highest-weight matching tag wins and its SelectedValue (''true''/''false'') determines eligibility.

