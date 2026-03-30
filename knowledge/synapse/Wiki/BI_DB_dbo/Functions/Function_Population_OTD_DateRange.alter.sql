-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Population_OTD_DateRange
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Builds, per customer, the **date range where “one-time depositor” (OTD)** status applies. **Deposit events (TP):** **`Fact_CustomerAction`** grouped by `DateID`, `RealCID` **WHERE** **`ActionTypeID = 7 OR (ActionTypeID = 44 AND IsFTD = 1)`** **AND** **`FundingTypeID <> 33`**. **Deposit events (eMoney):** **`eMoney_Fact_Transaction_Status`** **WHERE** **`TxStatusID = 2`** (settled) **AND** **`TxTypeID IN (7, 14)`**, grouped by `TxStatusModificationDateID`, `CID`. Unioned daily counts are ranked by `DateID`; customers whose **first row** already has **`CountDeposits > 1`** are **excluded**. **ToDateID** logic: if only one deposit day ever → **today’s** `DateID`; if first day had multiple deposits in branch → `MIN(DateID)`; else **second** deposit `DateID` or fallback `MIN(DateID)`.

