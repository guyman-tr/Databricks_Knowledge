-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_FactPayments
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- EXW_FactPayments records the lifecycle of every Simplex fiat-to-crypto payment request on the eToro Wallet platform. Simplex was a third-party payment provider enabling users to purchase cryptocurrency using credit/debit cards in EUR or GBP. Each payment passed through up to 11 status stages, and EXW_FactPayments stores one row per payment per status transition — making it an event-log/accumulating snapshot rather than a simple payment fact table. The table contains 553,884 rows representing 99,410 distinct payment requests spanning 2020-01-29 to 2022-09-20. The payment success rate is approximately 22% (21,747 "Completed" events out of 99,410 payments). Most payments either fail at the provider initiation stage or are stuck in DocumentCompleted/InitiateCompleted intermediate states. **Architectural note**: Each PaymentID appears approximately 5–6 times — once for each status it passes t

