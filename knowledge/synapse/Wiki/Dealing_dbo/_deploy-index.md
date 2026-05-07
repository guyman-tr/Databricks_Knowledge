---

## schema: Dealing_dbo
database: Synapse DWH
total_deployable: 33
generated: 0
deployed: 29
failed: 4
last_generate_batch: 0
last_deploy_batch: 11
last_updated: "2026-05-07"

## Schema ALTER + Deployment Progress

| Metric                             | Value      |
| ---------------------------------- | ---------- |
| **Schema**                         | Dealing_dbo |
| **Total deployable**               | 29        |
| **Pending (no .alter.sql)**        | 0        |
| **Generated (awaiting UC deploy)** | 0        |
| **Deployed (UC)**                  | 29         |
| **Stub-only (no UC)**              | 0          |
| **Failed**                         | 4         |
| **Stale**                          | 0          |
| **Last generate batch**            | 0          |
| **Last deploy batch**              | 11          |
| **Last updated**                   | 2026-03-30 |

> **Rows**: `Pending` = no local `.alter.sql`. `Generated` = `.alter.sql` present, UC not deployed in this index pass. `Deployed` = UC ALTERs executed.

## Tables (32)

| Object                                                                                                                       | Deploy status                                                                                                                                      |
| ---------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Dealing_dbo.Dealing_ApexRecon_Holdings](Tables/Dealing_ApexRecon_Holdings.md)                                               | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_ApexRecon_TradeActivity](Tables/Dealing_ApexRecon_TradeActivity.md)                                     | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_BNY_VIRTU_ReconEODHolding](Tables/Dealing_BNY_VIRTU_ReconEODHolding.md)                                 | Deployed (Batch 2) — 2026-05-03|
| [Dealing_dbo.Dealing_Boundary_Cost](Tables/Dealing_Boundary_Cost.md)                                                         | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_Clicks_OpenClose_Breakdown](Tables/Dealing_Clicks_OpenClose_Breakdown.md)                               | Failed (deploy Batch 2) — [RequestId=09c3b145-93d9-4e27-86d2-8d18ed07fdb6 ErrorClass=RESOURCE_DOES_NOT_EXIST] Column `Size of Tickets` does not ex|
| [Dealing_dbo.Dealing_CommoditiesIntraHour_Clients](Tables/Dealing_CommoditiesIntraHour_Clients.md)                           | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_CommoditiesIntraHour_Etoro](Tables/Dealing_CommoditiesIntraHour_Etoro.md)                               | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_dbo.Dealing_IndiciesIntraHour_Clients](Tables/Dealing_dbo.Dealing_IndiciesIntraHour_Clients.md)         | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_dbo.Dealing_IndiciesIntraHour_Etoro](Tables/Dealing_dbo.Dealing_IndiciesIntraHour_Etoro.md)             | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_dbo.Dealing_NumberofPositionsOpened_Agg](Tables/Dealing_dbo.Dealing_NumberofPositionsOpened_Agg.md)     | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_DealingDashboard_Clients](Tables/Dealing_DealingDashboard_Clients.md)                                   | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_Duco_ActivityRecon](Tables/Dealing_Duco_ActivityRecon.md)                                               | Deployed (Batch 2) — 2026-05-03|
| [Dealing_dbo.Dealing_Duco_EODRecon](Tables/Dealing_Duco_EODRecon.md)                                                         | Deployed (Batch 2) — 2026-05-03|
| [Dealing_dbo.Dealing_Employees_Report](Tables/Dealing_Employees_Report.md)                                                   | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_ESMANetLoss](Tables/Dealing_ESMANetLoss.md)                                                             | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee](Tables/Dealing_Islamic_Daily_Administrative_Fee.md)                   | Deployed (Batch 10) — 2026-05-05|
| [Dealing_dbo.Dealing_Islamic_Daily_Spot_Price_Adjustment](Tables/Dealing_Islamic_Daily_Spot_Price_Adjustment.md)             | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_ManipulationReport_RealStocks](Tables/Dealing_ManipulationReport_RealStocks.md)                         | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_ManipulationReport_RealStocks_CID](Tables/Dealing_ManipulationReport_RealStocks_CID.md)                 | Deployed (Batch 1) — 2026-03-30|
| [Dealing_dbo.Dealing_Marex_Recon_EODHoldings_Futures](Tables/Dealing_Marex_Recon_EODHoldings_Futures.md)                     | Deployed (Batch 2) — 2026-05-03|
| [Dealing_dbo.Dealing_NOP_Report](Tables/Dealing_NOP_Report.md)                                                               | Failed (deploy Batch 2) — [COLUMN_NOT_FOUND_IN_TABLE] Column 'NOP_USD' not found in table 'main'.'bi_db'.'gold_sql_dp_prod_we_dealing_dbo_dealing_|
| [Dealing_dbo.Dealing_RiskMatrix_V2](Tables/Dealing_RiskMatrix_V2.md)                                                         | Failed (deploy Batch 2) — [PARSE_SYNTAX_ERROR] Syntax error at or near '…'. SQLSTATE: 42601 (line 1, pos 106) == SQL == ALTER TABLE main.dealing.g|
| [Dealing_dbo.Dealing_Rollover_Assurance](Tables/Dealing_Rollover_Assurance.md)                                               | Failed (deploy Batch 2) — DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`dwh`.`gold_sql_dp_prod_we_dealing_dbo_dealing_rollover_ass|
| [Dealing_dbo.Dealing_SAXORecon_EODHoldings](Tables/Dealing_SAXORecon_EODHoldings.md)                                         | Deployed (Batch 2) — 2026-05-03|
| [Dealing_dbo.Dealing_Staking_DailyPool](Tables/Dealing_Staking_DailyPool.md)                                                 | Deployed (Batch 10) — 2026-05-05|
| [Dealing_dbo.Dealing_Staking_OptedOut](Tables/Dealing_Staking_OptedOut.md)                                                   | Deployed (Batch 10) — 2026-05-05|
| [Dealing_dbo.Dealing_Staking_Parameters](Tables/Dealing_Staking_Parameters.md)                                               | Deployed (Batch 10) — 2026-05-05|
| [Dealing_dbo.Dealing_Staking_Results](Tables/Dealing_Staking_Results.md)                                                     | Deployed (Batch 10) — 2026-05-05|
| [Dealing_dbo.Dealing_Staking_Summary](Tables/Dealing_Staking_Summary.md)                                                     | Deployed (Batch 1) — 2026-03-30|

## Tables (3)

| Object | Deploy status |
|--------|---------------|
| [Dealing_dbo.Dealing_IndiciesIntraHour_Clients](Tables/Dealing_IndiciesIntraHour_Clients.md) | Deployed (Batch 9) — 2026-05-03|
| [Dealing_dbo.Dealing_IndiciesIntraHour_Etoro](Tables/Dealing_IndiciesIntraHour_Etoro.md) | Deployed (Batch 9) — 2026-05-03|
| [Dealing_dbo.Dealing_NumberofPositionsOpened_Agg](Tables/Dealing_NumberofPositionsOpened_Agg.md) | Deployed (Batch 9) — 2026-05-03|

## Views (1)

| Object | Deploy status |
|--------|---------------|
| [Dealing_dbo.V_Dealing_Duco_EODRecon](Views/V_Dealing_Duco_EODRecon.md) | Deployed (Batch 11) — 2026-05-07|
