-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_DimUser_Enriched
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- EXW_DimUser_Enriched is the "wide view" of a Wallet user, designed for AML analysts and compliance teams who need a single-row-per-user profile combining identity, regulation, compliance risk scores, KYC investment capacity limits, current balance, and account lifecycle status. It is not a slowly-changing dimension — it is rebuilt fresh daily by a full TRUNCATE+INSERT, so it always reflects the current state. The table starts from the 699,692 Wallet users in EXW_DimUser (scoped by CustomerWalletsView) and enriches them with: 1. **Compliance scores** from DWH_dbo.Dim_Customer: PEPStatusID (screening status), WorldCheckID (sanctions), EvMatchStatus (e-ID verification vendors: Onfido, Au10tix), DocumentStatusID. 2. **KYC investment-capacity limits**: UpperLimit derived from KYC Question 14 (declared net worth bracket — 8 USD thresholds from $1K to $1M); RealizedEquity from DWH_dbo.V_Liabili

