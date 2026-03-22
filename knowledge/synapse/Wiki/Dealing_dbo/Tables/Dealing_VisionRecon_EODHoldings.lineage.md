# Column Lineage — Dealing_dbo.Dealing_VisionRecon_EODHoldings

**Writer**: `Dealing_dbo.SP_Vision_Recon`
**Pattern**: DELETE-INSERT by Date
**ETL Type**: LP Reconciliation — Vision Financial Markets vs eToro EOD holdings

## Source Tables

| Source | Type | Role |
|---|---|---|
| Dealing_staging.LP_VisionET_R006_EOD_Positions_ET | LP Feed (Tier 2) | Vision EOD positions file |
| Dealing_dbo.Dealing_Duco_EODRecon | Internal (Tier 2) | eToro EOD holdings (Vision HS filter via Fivetran LP='Vision') |
| DWH_dbo.Dim_Instrument | Reference | InstrumentID resolution from CUSIP/ISIN |
| etoro_Hedge_InstrumentBoundaries | Reference | Tolerance bands per instrument |
| Dealing_staging.External_Fivetran_dealing_active_hs_mappings | Reference | Vision HS → LP account mapping |

## Column → Source Mapping

| Column | Source | Transform |
|---|---|---|
| Date | SP parameter | DELETE-INSERT by Date |
| InstrumentID | DWH_dbo.Dim_Instrument | Resolved via CUSIP or ISINCode |
| InstrumentDisplayName | ISNULL(Duco, Vision) | Prefer eToro naming |
| Symbol | Dealing_Duco_EODRecon | eToro side |
| Cusip | LP_VisionET_R006_EOD_Positions_ET | Primary join key (CUSIP) |
| ISINCode | DWH_dbo.Dim_Instrument | Supplementary; resolved from InstrumentID |
| CurrencyPrimary | ISNULL(Duco, Vision) | Local currency |
| Exchange | Dealing_Duco_EODRecon | eToro side |
| HedgeServerID | Dealing_Duco_EODRecon | From Fivetran LP='Vision' filter; NULL for Vision-only |
| eToro_Units | Dealing_Duco_EODRecon.eToro_Units | SUM for Vision HS; ISNULL(,0) |
| Vision_Units | LP_VisionET_R006_EOD_Positions_ET | SUM grouped by CUSIP+AccountNumber; ISNULL(,0) |
| Clients_Units | Dealing_Duco_EODRecon.ClientUnits | SUM; ISNULL(,0) |
| Vision-eToro_Units | Computed | ISNULL(Vision_Units,0) − ISNULL(eToro_Units,0) |
| Vision-Clients_Units | Computed | ISNULL(Vision_Units,0) − ISNULL(Clients_Units,0) |
| eToroAmountUSD | Dealing_Duco_EODRecon.eToroUSDAmount | Passthrough; ISNULL(,0) |
| Vision_AmountUSD | LP_VisionET_R006_EOD_Positions_ET | Market value USD; ISNULL(,0) |
| ClientAmountUSD | Dealing_Duco_EODRecon.ClientAmount | Passthrough; ISNULL(,0) |
| Reality-Supposed | Computed | Vision_AmountUSD − eToroAmountUSD |
| Reality-Client | Computed | Vision_AmountUSD − ClientAmountUSD |
| AccountNumber | LP_VisionET_R006_EOD_Positions_ET | Vision LP account; secondary join key |
| eToroRate | Dealing_Duco_EODRecon.eToroRate | MAX |
| Vision_Rate | LP_VisionET_R006_EOD_Positions_ET | EOD price from Vision |
| Vision-eToro_Rate | Computed | ISNULL(Vision_Rate,0) − ISNULL(eToroRate,0) |
| LowerBoundary | etoro_Hedge_InstrumentBoundaries | Join on InstrumentID |
| UpperBoundary | etoro_Hedge_InstrumentBoundaries | Join on InstrumentID |
| UpdateDate | ETL | GETDATE() on INSERT |
