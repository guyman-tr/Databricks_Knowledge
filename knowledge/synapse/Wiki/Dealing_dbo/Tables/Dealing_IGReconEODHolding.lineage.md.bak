# Column Lineage — Dealing_dbo.Dealing_IGReconEODHolding

**Writer**: `Dealing_dbo.SP_IGRecon`
**Pattern**: DELETE-INSERT by Date
**ETL Type**: LP Reconciliation — IG vs eToro EOD holdings

## Source Tables

| Source | Type | Role |
|---|---|---|
| Dealing_staging.LP_IG_PS_EODPositions | LP Feed (Tier 2) | IG EOD position file (daily parquet COPY INTO) |
| Dealing_dbo.Dealing_Duco_EODRecon | Internal (Tier 2) | eToro EOD holdings (IG HS filter via Fivetran) |
| Dealing_staging.External_Fivetran_dealing_active_hs_mappings | Reference (Tier 2) | IG HS → LP account mapping |
| DWH_dbo.Dim_Instrument | Reference | Instrument ID resolution from ISIN/MarketName |

## Column → Source Mapping

| Column | Source | Transform |
|---|---|---|
| Date | SP parameter @TotalDate | Sunday→Friday: `DATEADD(DAY,-2,@Date)` when `DayNumberOfWeek_Sun_Start=1` |
| HedgeServerID | Dealing_Duco_EODRecon | From Fivetran IG HS mapping; NULL for IG-only rows |
| Account_Number | LP_IG_PS_EODPositions.[Account ID] | IG account identifier; NULL for eToro-only rows |
| InstrumentID | DWH_dbo.Dim_Instrument | Via #MarketNameToID lookup or ISINCode join |
| InstrumentDisplayName | ISNULL(Duco, IG) | Prefer eToro naming |
| Symbol | Dealing_Duco_EODRecon | eToro side only |
| ISINCode | ISNULL(Duco, IG) | Primary join key |
| CurrencyPrimary | ISNULL(Duco, IG) | GBX→GBP normalisation |
| Exchange | Dealing_Duco_EODRecon | ISNULL(eToro, 0) |
| IG_Units | LP_IG_PS_EODPositions.[Position] | SUM((2×IsBuy−1)×IG_Units); Oil ×100 multiplier |
| eToro_Units | Dealing_Duco_EODRecon.eToro_Units | SUM aggregated by InstrumentID+AccountID |
| Clients_Units | Dealing_Duco_EODRecon.ClientUnits | SUM aggregated |
| IG-eToro_Units | Computed | ISNULL(IG_Units,0) − ISNULL(eToro_Units,0) |
| IG-Clients_Units | Computed | ISNULL(IG_Units,0) − ISNULL(Clients_Units,0) |
| IG_LocalAmount | LP_IG_PS_EODPositions.[Current Value] | GBX ÷100; Oil ×100 |
| eToro_LocalAmount | Dealing_Duco_EODRecon.eToroLocalAmount | GBX ÷100 |
| IG-eToro_LocalAmount | Computed | ISNULL(IG,0) − ISNULL(eToro,0) |
| IG_AmountUSD | LP_IG_PS_EODPositions.[Consideration (Base Ccy)] | MAX; trade consideration in USD |
| eToro_AmountUSD | Dealing_Duco_EODRecon.eToroUSDAmount | Passthrough |
| Clients_AmountUSD | Dealing_Duco_EODRecon.ClientAmount | Passthrough |
| IG-eToro_AmountUSD | Computed | ISNULL(IG,0) − ISNULL(eToro,0) |
| IG-Clients_AmountUSD | Computed | ISNULL(IG,0) − ISNULL(Clients,0) |
| IG_Rate | LP_IG_PS_EODPositions.[Latest] | MAX, TRY_CONVERT(DECIMAL(16,6)) |
| eToro_Rate | Dealing_Duco_EODRecon.eToroRate | MAX |
| IG-eToro_Rate | Computed | ISNULL(IG_Rate,0) − ISNULL(eToro_Rate,0) |
| IG_FXRate | LP_IG_PS_EODPositions.[Conversion Rate] | String parse: LEFT(val, LEN-1); USD=1 |
| eToro_FXRate | Dealing_Duco_EODRecon.FXratetoUSD | Passthrough |
| UpdateDate | ETL | GETDATE() on INSERT |
