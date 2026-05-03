-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_Conversion_Allowed_Country
-- UC Target: _Not_Migrated
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- EXW_Conversion_Allowed_Country stores resolved crypto-to-crypto conversion eligibility for each country/crypto combination. Conversions have a directional component: a crypto can be a "From" source (selling) or a "To" target (buying) in a conversion pair. Each direction is independently controlled via EXW_Settings. The full eligibility for a conversion requires: 1. User-level eligibility (AllowedUser*) - is the user in a country allowed to convert at all? 2. From-direction eligibility (From*) - is this specific crypto allowed as a conversion source? 3. To-direction eligibility (To*) - is this specific crypto allowed as a conversion target? **Current state**: All FromConversionAllowed and ToConversionAllowed values are 0. Crypto-to-crypto conversions were discontinued; no country/crypto combination currently meets eligibility conditions. The table is preserved for audit and future reactiv

