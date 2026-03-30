---

## schema: Dealing_dbo
database: Synapse DWH
total_deployable: 29
generated: 0
deployed: 20
failed: 9
last_generate_batch: 0
last_deploy_batch: 1
last_updated: "2026-03-30"

## Schema ALTER + Deployment Progress

| Metric                             | Value      |
| ---------------------------------- | ---------- |
| **Schema**                         | Dealing_dbo |
| **Total deployable**               | 29        |
| **Pending (no .alter.sql)**        | 0        |
| **Generated (awaiting UC deploy)** | 0        |
| **Deployed (UC)**                  | 20         |
| **Stub-only (no UC)**              | 0          |
| **Failed**                         | 9         |
| **Stale**                          | 0          |
| **Last generate batch**            | 0          |
| **Last deploy batch**              | 1          |
| **Last updated**                   | 2026-03-30 |

> **Rows**: `Pending` = no local `.alter.sql`. `Generated` = `.alter.sql` present, UC not deployed in this index pass. `Deployed` = UC ALTERs executed.

## Tables (29)

| Object                                                                                                                       | Deploy status                                                                                                                                      |
| ---------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Dealing_dbo.Dealing_ApexRecon_Holdings](Tables/Dealing_ApexRecon_Holdings.md)                                               | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_ApexRecon_TradeActivity](Tables/Dealing_ApexRecon_TradeActivity.md)                                     | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_BNY_VIRTU_ReconEODHolding](Tables/Dealing_BNY_VIRTU_ReconEODHolding.md)                                 | Failed (deploy Batch 1) — [INVALID_IDENTIFIER] The unquoted identifier BNY-eToro_Rate is invalid and must be back quoted as: `BNY-eToro_Rate`. Unq|
| [Dealing_dbo.Dealing_Boundary_Cost](Tables/Dealing_Boundary_Cost.md)                                                         | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_Clicks_OpenClose_Breakdown](Tables/Dealing_Clicks_OpenClose_Breakdown.md)                               | Failed (deploy Batch 1) — [PARSE_SYNTAX_ERROR] Syntax error at or near 'of'. SQLSTATE: 42601 (line 1, pos 110) == SQL == ALTER TABLE main.dealing.|
| [Dealing_dbo.Dealing_CommoditiesIntraHour_Clients](Tables/Dealing_CommoditiesIntraHour_Clients.md)                           | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_CommoditiesIntraHour_Etoro](Tables/Dealing_CommoditiesIntraHour_Etoro.md)                               | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_dbo.Dealing_IndiciesIntraHour_Clients](Tables/Dealing_dbo.Dealing_IndiciesIntraHour_Clients.md)         | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_dbo.Dealing_IndiciesIntraHour_Etoro](Tables/Dealing_dbo.Dealing_IndiciesIntraHour_Etoro.md)             | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_dbo.Dealing_NumberofPositionsOpened_Agg](Tables/Dealing_dbo.Dealing_NumberofPositionsOpened_Agg.md)     | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_DealingDashboard_Clients](Tables/Dealing_DealingDashboard_Clients.md)                                   | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_Duco_ActivityRecon](Tables/Dealing_Duco_ActivityRecon.md)                                               | Failed (deploy Batch 1) — [PARSE_SYNTAX_ERROR] Syntax error at or near '/'. SQLSTATE: 42601 (line 1, pos 100) == SQL == ALTER TABLE main.dealing.g|
| [Dealing_dbo.Dealing_Duco_EODRecon](Tables/Dealing_Duco_EODRecon.md)                                                         | Failed (deploy Batch 1) — [PARSE_SYNTAX_ERROR] Syntax error at or near '/'. SQLSTATE: 42601 (line 1, pos 93) == SQL == ALTER TABLE main.bi_db.gold|
| [Dealing_dbo.Dealing_Employees_Report](Tables/Dealing_Employees_Report.md)                                                   | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_ESMANetLoss](Tables/Dealing_ESMANetLoss.md)                                                             | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee](Tables/Dealing_Islamic_Daily_Administrative_Fee.md)                   | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_Islamic_Daily_Spot_Price_Adjustment](Tables/Dealing_Islamic_Daily_Spot_Price_Adjustment.md)             | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_ManipulationReport_RealStocks](Tables/Dealing_ManipulationReport_RealStocks.md)                         | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_ManipulationReport_RealStocks_CID](Tables/Dealing_ManipulationReport_RealStocks_CID.md)                 | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_Marex_Recon_EODHoldings_Futures](Tables/Dealing_Marex_Recon_EODHoldings_Futures.md)                     | Failed (deploy Batch 1) — [INVALID_IDENTIFIER] The unquoted identifier Marex-Clients_Price is invalid and must be back quoted as: `Marex-Clients_P|
| [Dealing_dbo.Dealing_NOP_Report](Tables/Dealing_NOP_Report.md)                                                               | Failed (deploy Batch 1) — [COLUMN_NOT_FOUND_IN_TABLE] Column 'NOP_USD' not found in table 'main'.'bi_db'.'gold_sql_dp_prod_we_dealing_dbo_dealing_|
| [Dealing_dbo.Dealing_RiskMatrix_V2](Tables/Dealing_RiskMatrix_V2.md)                                                         | Failed (deploy Batch 1) — [PARSE_SYNTAX_ERROR] Syntax error at or near '1'. SQLSTATE: 42601 (line 1, pos 101) == SQL == ALTER TABLE main.dealing.g|
| [Dealing_dbo.Dealing_Rollover_Assurance](Tables/Dealing_Rollover_Assurance.md)                                               | Failed (deploy Batch 1) — DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`dwh`.`gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_ass|
| [Dealing_dbo.Dealing_SAXORecon_EODHoldings](Tables/Dealing_SAXORecon_EODHoldings.md)                                         | Failed (deploy Batch 1) — [PARSE_SYNTAX_ERROR] Syntax error at or near '/'. SQLSTATE: 42601 (line 1, pos 108) == SQL == ALTER TABLE main.dealing.g|
| [Dealing_dbo.Dealing_Staking_DailyPool](Tables/Dealing_Staking_DailyPool.md)                                                 | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_Staking_OptedOut](Tables/Dealing_Staking_OptedOut.md)                                                   | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_Staking_Parameters](Tables/Dealing_Staking_Parameters.md)                                               | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_Staking_Results](Tables/Dealing_Staking_Results.md)                                                     | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_Staking_Summary](Tables/Dealing_Staking_Summary.md)                                                     | Deployed (Batch 1) — 2026-03-30|
