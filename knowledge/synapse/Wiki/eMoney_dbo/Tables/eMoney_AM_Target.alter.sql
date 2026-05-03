-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_AM_Target
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- `eMoney_AM_Target` is the eToro Money account-manager performance tracking table. Each row represents one **eligible eToro Money customer on a specific reporting date**, paired with their assigned account manager and a set of MIMO (Money-In/Money-Out) action metrics. The table was designed for the eToro Money Account Manager (AM) team to track: 1. **Which customers** their AMs are responsible for each day (based on `DWH_dbo.Dim_Customer.AccountManagerID`) 2. **How much MIMO activity** those customers generated - split by eToro Money (FundingTypeID=33) vs. other funding types 3. **Progress toward quarterly targets** using fixed target-period windows The table holds **385,394,399 rows** across **1,016 days** from 2023-07-01 to 2026-04-11. The daily eligible population is approximately **520,000 customers**. Rows are partitioned by `Report_Date_ID`; the `DELETE+INSERT` pattern ensures each 

