-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- `eMoney_Client_Balance_Check_Exceptions_Gap` is a data quality monitoring table for the eToro Money (eTM) balance reconciliation process. Each row represents a **date on which a closing-balance exception was detected** - meaning the DWH-calculated closing balance did not reconcile with the back-office (BO) closing balance. The reconciliation check is defined as: ``` CheckCalc = ClosingPositiveBalanceCalc + ClosingNegativeBalanceBO - ClosingBalanceBO ``` When `SUM(CheckCalc)` for any `BalanceDateID` is non-zero, a row is inserted into this table recording the date and the aggregate exception gap. A completely empty table (current state) means all balance checks have passed - the DWH and BO balances are in agreement. The table is populated as a sub-step of `SP_eMoney_ClientBalance` (the main daily eTM balance SP). It is not part of the `SP_eMoney_Execute_Group_One` pipeline and does not us

