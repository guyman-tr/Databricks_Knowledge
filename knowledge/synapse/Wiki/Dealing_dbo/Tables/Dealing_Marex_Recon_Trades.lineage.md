# Column Lineage — Dealing_dbo.Dealing_Marex_Recon_Trades

**Writer**: `Dealing_dbo.SP_Marex_Recon`
**Pattern**: DELETE-INSERT by Date
**ETL Type**: LP Reconciliation — Marex vs eToro daily trade activity

## Source Tables

| Source | Type | Role |
|---|---|---|
| CopyFromLake.etoro_Hedge_ExecutionLog | LP Feed (Tier 2) | Marex execution log (eToro-side execution records for Marex-routed trades) |
| Dealing_dbo.Dealing_Duco_ActivityRecon | Internal (Tier 2) | eToro trade activity (Marex HS filter via Fivetran LP='Marex') |
| Dealing_staging.External_Bronze_Fivetran_google_sheets_marex_mapping_table | Reference (Tier 2) | Marex contract → eToro InstrumentID mapping |
| Dealing_staging.External_Fivetran_dealing_active_hs_mappings | Reference | Marex HS → LiquidityAccountID mapping |

## Column → Source Mapping

| Column | Source | Transform |
|---|---|---|
| Date | SP parameter | DateToDateID() UDF; DELETE-INSERT by Date |
| InstrumentID | External_Bronze_Fivetran_google_sheets_marex_mapping_table | Contract → InstrumentID; NULL if unmapped |
| InstrumentDisplayName | ISNULL(Duco, Marex ContractName) | Prefer eToro naming |
| Symbol | Dim_Instrument | eToro ticker |
| ISINCode | Dim_Instrument | Resolved from InstrumentID |
| CUSIP | Dim_Instrument | Resolved from InstrumentID |
| Currency | CopyFromLake.etoro_Hedge_ExecutionLog | Instrument local currency |
| Exchange | Dealing_Duco_ActivityRecon | eToro side |
| LiquidityAccountID | External_Fivetran_dealing_active_hs_mappings | LP='Marex' filter |
| HedgeServerID | Dealing_Duco_ActivityRecon | From LiquidityAccountID mapping; NULL for Marex-only |
| Account | CopyFromLake.etoro_Hedge_ExecutionLog | Marex account code |
| Contract | CopyFromLake.etoro_Hedge_ExecutionLog | Marex contract code |
| ContractName | CopyFromLake.etoro_Hedge_ExecutionLog | Contract description |
| eToro_Units | Dealing_Duco_ActivityRecon.eToro_Units | SUM for Marex HS; ISNULL(,0) |
| eToroLocalAmount | Dealing_Duco_ActivityRecon.eToroLocalAmount | SUM; ISNULL(,0) |
| eToroUSDAmount | Dealing_Duco_ActivityRecon.eToroUSDAmount | Passthrough; ISNULL(,0) |
| eToroRate | Dealing_Duco_ActivityRecon.eToro_Rate | AVG |
| eToro_FX | Dealing_Duco_ActivityRecon.FXratetoUSD | Passthrough |
| Marex_Units | CopyFromLake.etoro_Hedge_ExecutionLog | SUM by Contract+Account; ISNULL(,0) |
| Marex_LocalAmount | CopyFromLake.etoro_Hedge_ExecutionLog | Notional local; ISNULL(,0) |
| Marex_AmountUSD | CopyFromLake.etoro_Hedge_ExecutionLog | Notional USD; ISNULL(,0) |
| Marex_FX | CopyFromLake.etoro_Hedge_ExecutionLog | FX rate |
| ClientUnits | Dealing_Duco_ActivityRecon.ClientUnits | SUM; ISNULL(,0) |
| ClientsLocalAmount | Dealing_Duco_ActivityRecon | Local currency client flow; ISNULL(,0) |
| ClientsUSDAmount | Dealing_Duco_ActivityRecon.ClientAmount | Passthrough; ISNULL(,0) |
| Marex-eToro_Units | Computed | ISNULL(Marex_Units,0) − ISNULL(eToro_Units,0) |
| Marex-Clients_Units | Computed | ISNULL(Marex_Units,0) − ISNULL(ClientUnits,0) |
| Marex-eToro_LocalAmount | Computed | ISNULL(Marex_LocalAmount,0) − ISNULL(eToroLocalAmount,0) |
| Marex-eToro_USDAmount | Computed | ISNULL(Marex_AmountUSD,0) − ISNULL(eToroUSDAmount,0) |
| Marex-Clients_USDAmount | Computed | ISNULL(Marex_AmountUSD,0) − ISNULL(ClientsUSDAmount,0) |
| UpdateDate | ETL | GETDATE() on INSERT |
