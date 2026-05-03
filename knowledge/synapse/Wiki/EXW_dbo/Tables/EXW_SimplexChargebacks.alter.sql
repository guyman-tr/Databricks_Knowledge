-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_SimplexChargebacks
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- EXW_SimplexChargebacks is a micro reference table holding 5 historical chargeback disputes processed through the Simplex payment provider for eToro Wallet crypto purchases. Each row represents a single card chargeback filed against a Simplex-facilitated transaction, tracking the chargeback type, card network reason code, acquirer reference (ARN), Simplex''s liability determination, and the fund settlement narrative. All 5 records are from 2019 (February to May), were loaded in a single bulk operation on 2020-03-15, and have not been updated since. All disputes are classified as card fraud (CNP fraud), all are processor ECP Bank, and Simplex bore full liability in all cases. The `CB Funds Status` field contains free-text notes from Simplex describing the settlement timeline (e.g., "Funds and fees returned by Simplex on 2019-09"). This table serves as a historical audit trail of chargeback

