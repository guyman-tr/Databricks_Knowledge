# Column Lineage — Dealing_dbo.Dealing_Marex_Recon_EODHoldings

**Writer**: `Dealing_dbo.SP_Marex_Recon`
**Pattern**: DELETE-INSERT by Date
**ETL Type**: LP Reconciliation — Marex vs eToro EOD holdings

## Source Tables

| Source | Type | Role |
|---|---|---|
| Dealing_staging.LP_EdnF_CorePosition | LP Feed (Tier 2) | Marex EOD net position file |
| Dealing_staging.LP_EdnF_CoreBalance | LP Feed (Tier 2) | Marex EOD balance/value file |
| Dealing_staging.External_Bronze_Fivetran_google_sheets_marex_mapping_table | Reference (Tier 2) | Marex contract → eToro InstrumentID mapping (Google Sheets via Fivetran) |
| etoro_Hedge_Netting | Internal (Tier 2) | eToro hedge position (current netting config) |
| History_Netting_History | Internal (Tier 2) | eToro hedge position (historical netting config, temporal) |
| Dealing_dbo.Dealing_Duco_EODRecon | Internal (Tier 2) | Client NOP (Marex HS filter via Fivetran LP='Marex') |
| Dealing_staging.External_Fivetran_dealing_active_hs_mappings | Reference | Marex HS → LiquidityAccountID mapping |

## Column → Source Mapping

| Column | Source | Transform |
|---|---|---|
| Date | SP parameter | DateToDateID() UDF; DELETE-INSERT by Date |
| InstrumentID | External_Bronze_Fivetran_google_sheets_marex_mapping_table | Contract → InstrumentID lookup; NULL if unmapped |
| InstrumentDisplayName | Dim_Instrument or Marex ContractName | ISNULL(eToro, Marex) |
| Symbol | Dim_Instrument | eToro ticker |
| ISINCode | Dim_Instrument | Resolved from InstrumentID |
| CUSIP | Dim_Instrument | Resolved from InstrumentID |
| Currency | LP_EdnF_CorePosition | Instrument local currency |
| Exchange | Dealing_Duco_EODRecon | eToro side |
| LiquidityAccountID | External_Fivetran_dealing_active_hs_mappings | LP='Marex' filter |
| HedgeServerID | etoro_Hedge_Netting | Mapped via LiquidityAccountID; NULL for Marex-only |
| Account | LP_EdnF_CorePosition | Marex account code |
| Contract | LP_EdnF_CorePosition | Marex contract code (join key to mapping table) |
| ContractName | LP_EdnF_CorePosition | Marex contract description |
| eToro_Units | etoro_Hedge_Netting / History_Netting_History | Temporal join: ValidFrom ≤ Date < ValidTo; ISNULL(,0) |
| eToroLocalAmount | etoro_Hedge_Netting | Local currency value; ISNULL(,0) |
| eToroUSDAmount | etoro_Hedge_Netting | USD value; ISNULL(,0) |
| eToroRate | etoro_Hedge_Netting | Closing price |
| eToro_FX | etoro_Hedge_Netting | FX rate local→USD |
| Marex_Units | LP_EdnF_CorePosition | Net position SUM; ISNULL(,0) |
| Marex_LocalAmount | LP_EdnF_CorePosition | Local currency value; ISNULL(,0) |
| Marex_AmountUSD | LP_EdnF_CorePosition / LP_EdnF_CoreBalance | USD value; ISNULL(,0) |
| Marex_FX | LP_EdnF_CorePosition | FX rate local→USD |
| ClientUnits | Dealing_Duco_EODRecon.ClientUnits | SUM for Marex HS; ISNULL(,0) |
| ClientsLocalAmount | Dealing_Duco_EODRecon | Local currency client NOP; ISNULL(,0) |
| ClientsUSDAmount | Dealing_Duco_EODRecon.ClientAmount | USD client NOP; ISNULL(,0) |
| Marex-eToro_Units | Computed | ISNULL(Marex_Units,0) − ISNULL(eToro_Units,0) |
| Marex-Clients_Units | Computed | ISNULL(Marex_Units,0) − ISNULL(ClientUnits,0) |
| Marex-eToro_LocalAmount | Computed | ISNULL(Marex_LocalAmount,0) − ISNULL(eToroLocalAmount,0) |
| Marex-eToro_USDAmount | Computed | ISNULL(Marex_AmountUSD,0) − ISNULL(eToroUSDAmount,0) |
| Marex-Clients_USDAmount | Computed | ISNULL(Marex_AmountUSD,0) − ISNULL(ClientsUSDAmount,0) |
| UpdateDate | ETL | GETDATE() on INSERT |
