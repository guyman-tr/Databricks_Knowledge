-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_Payment_Allowed_Country
-- UC Target: _Not_Migrated
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- EXW_Payment_Allowed_Country stores the resolved crypto payment (Simplex) eligibility for each country/crypto combination. Payment eligibility requires **both** conditions to be true: (1) the user''s country must be eligible at the user level, and (2) the specific crypto must be eligible at the crypto level. Both conditions are resolved independently from EXW_Settings and stored as separate column groups (AllowedUser* and Cryptos*). **Current state**: All PaymentAllowed values are 0. Simplex-based crypto purchases were part of the eToro Wallet offering but have been discontinued. The table structure and settings column groups are preserved for audit and potential future reactivation. The dual-condition design (AllowedUser AND Cryptos) means that even if a country is generally payment-eligible, specific cryptos can be disabled, and vice versa.

