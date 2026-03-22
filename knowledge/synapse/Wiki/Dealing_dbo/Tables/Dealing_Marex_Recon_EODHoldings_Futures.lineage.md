# Column Lineage — Dealing_dbo.Dealing_Marex_Recon_EODHoldings_Futures

**Writer**: `Dealing_dbo.SP_Marex_Recon`
**Pattern**: DELETE-INSERT by Date
**ETL Type**: LP Reconciliation — Marex vs Client EOD futures holdings (added May 2025)

## Source Tables

| Source | Type | Role |
|---|---|---|
| Marex futures position feed (LP staging) | LP Feed (Tier 2) | Marex EOD futures position file (exact table TBC — see review) |
| etoro_Hedge client netting data | Internal (Tier 2) | eToro client-level futures positions (CID granularity) |
| DWH_dbo.Dim_Instrument | Reference | InstrumentID resolution from CONTRACT |
| Dealing_staging.External_Fivetran_dealing_active_hs_mappings | Reference | Marex HS mapping |

## Column → Source Mapping

| Column | Source | Transform |
|---|---|---|
| Date | SP parameter | DELETE-INSERT by Date; DateToDateID() UDF |
| PositionID | Marex futures position feed | Direct; Marex position identifier |
| CID | etoro_Hedge client netting | Client identifier |
| HedgeServerID | etoro_Hedge client netting | From Fivetran LP='Marex' futures HS |
| CONTRACT | Marex futures position feed | Futures contract code |
| ContractName | Marex futures position feed | Contract description |
| InstrumentID | Dim_Instrument or mapping | CONTRACT → InstrumentID |
| InstrumentDisplayName | Dim_Instrument | eToro instrument name |
| Exchange | Dim_Instrument or Marex feed | Futures exchange venue |
| Symbol | Dim_Instrument | Ticker |
| SellCurrency | Marex futures position feed | Settlement currency |
| IsBuy | Marex futures position feed | Position direction; 1=Long, 0=Short |
| ConversionRate | etoro_Hedge client netting | eToro FX conversion rate |
| Clients_Lots | etoro_Hedge client netting | Client lot count |
| Marex_Lots | Marex futures position feed | Marex lot count |
| WA_Marex_Price | Marex futures position feed | Weighted average price |
| ForexRate | Marex futures position feed | Raw FX rate (pre-ADJ) |
| Trader | Marex futures position feed | Marex trader code |
| ACCOUNT | Marex futures position feed | Marex account code |
| Currency | Marex futures position feed | Underlying instrument currency |
| MultiplicationFactor | Marex futures position feed | Contract multiplier |
| LastTradingDay | Marex futures position feed | Expiry as integer DateID |
| ClientUnits | etoro_Hedge client netting | Clients_Lots × MultiplicationFactor |
| Marex_Units | Marex futures position feed | Marex_Lots × MultiplicationFactor |
| ClientsLocalAmount | etoro_Hedge client netting | Local currency client NOP |
| Marex_LocalAmount | Marex futures position feed | Local currency Marex position value |
| ClientsUSDAmount | etoro_Hedge client netting | USD client NOP |
| Marex_USDAmount | Marex futures position feed | USD Marex position value |
| Marex-Clients_Units | Computed | ISNULL(Marex_Units,0) − ISNULL(ClientUnits,0) |
| Marex-Clients_USDAmount | Computed | ISNULL(Marex_USDAmount,0) − ISNULL(ClientsUSDAmount,0) |
| Marex-Clients_Lots | Computed | Marex_Lots − Clients_Lots |
| Marex-Clients_Price | Computed | WA_Marex_Price − Client entry price |
| UpdateDate | ETL | GETDATE() on INSERT |
| ForexRate_AfterADJ | Marex futures position feed | ADJ-adjusted FX rate (added Jul 2025) |
| ADJ_Value | Marex futures position feed | ADJ adjustment factor (added Jul 2025) |
| OrderID | Marex futures position feed | Marex order reference |
