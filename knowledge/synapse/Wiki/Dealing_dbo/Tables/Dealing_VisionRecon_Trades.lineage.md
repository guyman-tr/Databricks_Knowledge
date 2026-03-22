# Column Lineage — Dealing_dbo.Dealing_VisionRecon_Trades

**Writer**: `Dealing_dbo.SP_Vision_Recon`
**Pattern**: DELETE-INSERT by Date
**ETL Type**: LP Reconciliation — Vision Financial Markets vs eToro daily trade activity

## Source Tables

| Source | Type | Role |
|---|---|---|
| Dealing_staging.LP_VisionET_R002_EOD_Trades_ET | LP Feed (Tier 2) | Vision daily trade file |
| Dealing_dbo.Dealing_Duco_ActivityRecon | Internal (Tier 2) | eToro trade activity (Vision HS filter via Fivetran LP='Vision') |
| DWH_dbo.Dim_Instrument | Reference | InstrumentID resolution from CUSIP/ISIN |
| Dealing_staging.External_Fivetran_dealing_active_hs_mappings | Reference | Vision HS → LP account mapping |

## Column → Source Mapping

| Column | Source | Transform |
|---|---|---|
| Date | SP parameter | DELETE-INSERT by Date |
| InstrumentID | DWH_dbo.Dim_Instrument | Resolved via CUSIP or ISINCode |
| InstrumentDisplayName | ISNULL(Duco, Vision) | Prefer eToro naming |
| Symbol | Dealing_Duco_ActivityRecon | eToro side |
| Cusip | LP_VisionET_R002_EOD_Trades_ET | Primary join key |
| ISINCode | DWH_dbo.Dim_Instrument | Supplementary; resolved from InstrumentID |
| CurrencyPrimary | ISNULL(Duco, Vision) | Local currency |
| Exchange | Dealing_Duco_ActivityRecon | eToro side |
| HedgeServerID | Dealing_Duco_ActivityRecon | From Fivetran LP='Vision' filter; NULL for Vision-only |
| IsBuy | LP_VisionET_R002_EOD_Trades_ET | B/C order codes → 1 (Buy); others → 0 (Sell) |
| eToro_Units | Dealing_Duco_ActivityRecon.eToro_Units | SUM for Vision HS; ISNULL(,0) |
| Vision_Units | LP_VisionET_R002_EOD_Trades_ET | SUM by CUSIP+AccountNumber+IsBuy; ISNULL(,0) |
| Client_Units | Dealing_Duco_ActivityRecon.ClientUnits | SUM; ISNULL(,0) |
| Vision-eToro_Units | Computed | ISNULL(Vision_Units,0) − ISNULL(eToro_Units,0) |
| Vision-Clients_Units | Computed | ISNULL(Vision_Units,0) − ISNULL(Client_Units,0) |
| eToroAmountUSD | Dealing_Duco_ActivityRecon.eToroUSDAmount | Passthrough; ISNULL(,0) |
| Vision_AmountUSD | LP_VisionET_R002_EOD_Trades_ET | Notional USD; ISNULL(,0) |
| ClientAmountUSD | Dealing_Duco_ActivityRecon.ClientAmount | Passthrough; ISNULL(,0) |
| Vision-eToro_AmountUSD | Computed | ISNULL(Vision_AmountUSD,0) − ISNULL(eToroAmountUSD,0) |
| Vision-Client_AmountUSD | Computed | ISNULL(Vision_AmountUSD,0) − ISNULL(ClientAmountUSD,0) |
| AccountNumber | LP_VisionET_R002_EOD_Trades_ET | Vision LP account; secondary join key |
| eToroRate | Dealing_Duco_ActivityRecon.eToro_Rate | AVG |
| Vision_Rate | LP_VisionET_R002_EOD_Trades_ET | Execution price |
| Vision-eToro_Rate | Computed | ISNULL(Vision_Rate,0) − ISNULL(eToroRate,0) |
| UpdateDate | ETL | GETDATE() on INSERT |
