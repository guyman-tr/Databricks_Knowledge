# Column Lineage — Dealing_dbo.Dealing_Marex_Recon_Trades_Futures

**Writer**: `Dealing_dbo.SP_Marex_Recon`
**Pattern**: DELETE-INSERT by Date
**ETL Type**: LP Reconciliation — Marex vs eToro vs Client futures trade activity (added May 2025)

## Source Tables

| Source | Type | Role |
|---|---|---|
| Marex futures trade feed (LP staging) | LP Feed (Tier 2) | Marex execution-level trade file (exact table TBC — see review) |
| Dealing_dbo.Dealing_Duco_ActivityRecon | Internal (Tier 2) | eToro trade activity (Marex futures HS filter) |
| etoro_Hedge client trade data | Internal (Tier 2) | CID-level client trade executions |
| DWH_dbo.Dim_Instrument | Reference | InstrumentID resolution |
| Dealing_staging.External_Fivetran_dealing_active_hs_mappings | Reference | Marex HS mapping |

## Column → Source Mapping

| Column | Source | Transform |
|---|---|---|
| Date | SP parameter | DELETE-INSERT by Date |
| PositionID | Marex futures trade feed | Marex position reference |
| CID | etoro_Hedge client data | Client identifier |
| HedgeServerID | Dealing_Duco_ActivityRecon | Marex futures HS; NULL for Marex-only |
| InstrumentID | Dim_Instrument | Resolved from CONTRACT/ISIN |
| InstrumentDisplayName | Dim_Instrument | eToro name |
| Exchange | Dim_Instrument or Marex feed | Futures exchange |
| Symbol | Dim_Instrument | Ticker |
| SellCurrency | Marex futures trade feed | Settlement currency |
| IsBuy | Marex futures trade feed | Direction flag |
| IsOpen | Marex futures trade feed | Open=1 / Close=0 |
| OrderID | Marex futures trade feed | Order reference |
| ConversionRate | etoro_Hedge client data | eToro FX conversion |
| Clients_Lots | etoro_Hedge client data | Client executed lots |
| Marex_Lots | Marex futures trade feed | Marex executed lots |
| Marex_Price | Marex futures trade feed | Execution price |
| ForexRate | Marex futures trade feed | Raw FX rate (pre-ADJ) |
| ACCOUNT | Marex futures trade feed | Marex account code |
| CURRENCY SYMBOL | Marex futures trade feed | Currency symbol (direct from LP file) |
| CHIT NUMBER | Marex futures trade feed | Marex trade reference |
| ExecutionID | Marex futures trade feed | Unique execution identifier |
| MULTIPLICATION FACTOR | Marex futures trade feed | Contract multiplier |
| LST TRD DATE | Marex futures trade feed | Expiry as integer DateID |
| Commission | Marex futures trade feed | Per-execution commission |
| ClientUnits | etoro_Hedge client data | Client executed units |
| Marex_Units | Marex futures trade feed | Marex executed units; ISNULL(,0) |
| eToro_Units | Dealing_Duco_ActivityRecon.eToro_Units | SUM, Marex futures HS; ISNULL(,0) |
| eToroRate | Dealing_Duco_ActivityRecon.eToro_Rate | AVG |
| ClientsLocalAmount | etoro_Hedge client data | Client local currency trade amount |
| Marex_LocalAmount | Marex futures trade feed | Local notional |
| eToroLocalAmount | Dealing_Duco_ActivityRecon.eToroLocalAmount | Passthrough |
| ClientsUSDAmount | etoro_Hedge client data | Client USD trade amount |
| eToroUSDAmount | Dealing_Duco_ActivityRecon.eToroUSDAmount | Passthrough |
| Marex_USDAmount | Marex futures trade feed | USD notional |
| Marex-Clients_Units | Computed | ISNULL(Marex_Units,0) − ISNULL(ClientUnits,0) |
| Marex-Clients_USDAmount | Computed | ISNULL(Marex_USDAmount,0) − ISNULL(ClientsUSDAmount,0) |
| Marex-Clients_Lots | Computed | Marex_Lots − Clients_Lots |
| Marex-Clients_Price | Computed | Marex_Price − Client entry price |
| Marex-eToro_Units | Computed | ISNULL(Marex_Units,0) − ISNULL(eToro_Units,0) |
| Marex-eToro_USDAmount | Computed | ISNULL(Marex_USDAmount,0) − ISNULL(eToroUSDAmount,0) |
| UpdateDate | ETL | GETDATE() on INSERT |
| ForexRate_AfterADJ | Marex futures trade feed | ADJ-adjusted FX (added Jul 2025) |
| ADJ_Value | Marex futures trade feed | ADJ adjustment factor (added Jul 2025) |
| eToroRate_AfterADJ | Dealing_Duco_ActivityRecon + ADJ | eToro rate after ADJ (added Jul 2025) |
