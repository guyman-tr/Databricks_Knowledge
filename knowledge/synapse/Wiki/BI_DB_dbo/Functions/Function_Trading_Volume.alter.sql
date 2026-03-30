-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Trading_Volume
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only — Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki §1, truncated):
-- Builds **two legs** from `DWH_dbo.Dim_Position` over the inclusive `YYYYMMDD` range `[@sdateInt, @edateInt]`: **opens** where `OpenDateID` is in range (uses persisted `Volume`, `InitialAmountCents`, open counters), and **closes** where `CloseDateID` is in range (uses `VolumeOnClose`, `Amount` as closed invested, close counter). The legs are `UNION ALL`’d; each row gets `TotalVolume = ISNULL(VolumeOpen,0) + ISNULL(VolumeClose,0)` and `NetInvestedAmount = InvestedAmountOpen - InvestedAmountClosed` before the final `GROUP BY` on customer and product attributes. Joins `Fact_SnapshotCustomer` + `Dim_Range` (as-of snapshot for the event `DateID`), `Dim_Instrument`, SQF and C2P flags, then left-joins copy-fund / recurring / IBAN helper tables on `PositionID` for reporting dimensions.

