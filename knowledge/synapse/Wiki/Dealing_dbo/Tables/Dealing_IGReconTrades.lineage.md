# Column Lineage — Dealing_dbo.Dealing_IGReconTrades

**Writer**: `Dealing_dbo.SP_IGRecon`
**Pattern**: DELETE-INSERT by Date
**ETL Type**: LP Reconciliation — IG vs eToro daily trade activity

## Source Tables

| Source | Type | Role |
|---|---|---|
| Dealing_staging.LP_IG_OH_OrderHistory | LP Feed (Tier 2) | IG executed order history (parquet) |
| Dealing_dbo.Dealing_Duco_ActivityRecon | Internal (Tier 2) | eToro trade activity (IG HS filter) |
| Dealing_staging.LP_IG_PS_EODPositions | Reference (Tier 2) | FX rates for currency conversion |
| Dealing_staging.External_Fivetran_dealing_active_hs_mappings | Reference | IG HS/LA mapping |

## Column → Source Mapping

| Column | Source | Transform |
|---|---|---|
| Date | SP parameter @TotalDate | Sunday→Friday adjustment |
| HedgeServerID | Dealing_Duco_ActivityRecon | Fivetran IG HS filter; NULL for IG-only |
| Account_Number | LP_IG_OH_OrderHistory.[Account ID] | NULL for eToro-only |
| InstrumentID | DWH_dbo.Dim_Instrument | Via #MarketNameToID or ISIN |
| InstrumentDisplayName | ISNULL(Duco, IG) | Prefer eToro side |
| Symbol | Dealing_Duco_ActivityRecon | eToro side |
| ISINCode | ISNULL(Duco, IG) | Join key |
| Buy/Sell | ISNULL(Duco, IG) | IG: `CASE WHEN [Deal Size]<0 THEN 'Sell' ELSE 'Buy'` |
| CurrencyPrimary | ISNULL(Duco, IG) | GBX→GBP |
| Exchange | Dealing_Duco_ActivityRecon | ISNULL(eToro, 0) |
| IG_Units | LP_IG_OH_OrderHistory.[Deal Size]+[Lot Size] | SUM×LotSize; rejected excl; Oil ×100 |
| eToro_Units | Dealing_Duco_ActivityRecon.eToro_Units | SUM |
| Clients_Units | Dealing_Duco_ActivityRecon.ClientUnits | SUM |
| IG-eToro_Units | Computed | ISNULL(IG,0)−ISNULL(eToro,0) |
| IG-Clients_Units | Computed | ISNULL(IG,0)−ISNULL(Clients,0) |
| IG_Rate | LP_IG_OH_OrderHistory.[Deal Level] | Weighted avg = SUM(Level×Size)/SUM(Size) |
| eToro_Rate | Dealing_Duco_ActivityRecon.eToro_AvgRate | AVG; GBX ÷100 |
| IG-eToro_Rate | Computed | ISNULL(IG,0)−ISNULL(eToro,0) |
| IG_LocalAmount | LP_IG_OH_OrderHistory | DealLevel×DealSize×LotSize (signed); Oil ×100 |
| eToro_LocalAmount | Dealing_Duco_ActivityRecon.eToroLocalAmount | GBX ÷100 |
| IG-eToro_LocalAmount | Computed | ISNULL(IG,0)−ISNULL(eToro,0) |
| IG_AmountUSD | LP_IG_OH_OrderHistory + FX | IG_LocalAmount × MAX(IG_FXRate) |
| eToro_AmountUSD | Dealing_Duco_ActivityRecon.eToroUSDAmount | Passthrough |
| Clients_AmountUSD | Dealing_Duco_ActivityRecon.ClientAmount | Passthrough |
| IG-eToro_AmountUSD | Computed | ISNULL(IG,0)−ISNULL(eToro,0) |
| IG-Clients_AmountUSD | Computed | ISNULL(IG,0)−ISNULL(Clients,0) |
| IG_FXRate | LP_IG_PS_EODPositions.[Conversion Rate] | MAX from #IG_FXRates (EOD FX) |
| eToro_FXRate | Dealing_Duco_ActivityRecon.FXratetoUSD | AVG |
| UpdateDate | ETL | GETDATE() |
