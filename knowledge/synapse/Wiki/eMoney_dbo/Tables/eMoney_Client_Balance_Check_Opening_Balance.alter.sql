-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- `eMoney_Client_Balance_Check_Opening_Balance` is a data quality monitoring table for the eToro Money (eTM) opening balance reconciliation process. Each row represents a **date on which an opening balance discrepancy was detected** — meaning the DWH-computed opening balance (derived from the currency balance system, `OpeningBalanceByCB`) differed from the back-office recorded opening balance (`OpeningBalance`). The reconciliation gap is defined as: ``` OpeningBalanceGAP = CASE WHEN oc.AccountId IS NULL THEN 0 ELSE (oc.OpeningBalanceByCB - b.OpeningBalance) END ``` When `SUM(OpeningBalanceGAP)` for any `BalanceDateID` is non-zero, a row is inserted recording the date and the aggregate gap. A completely empty table (current state) means opening balance integrity checks are passing. The SP is a companion to `eMoney_Client_Balance_Check_Exceptions_Gap` (both called from `SP_eMoney_ClientBalan

