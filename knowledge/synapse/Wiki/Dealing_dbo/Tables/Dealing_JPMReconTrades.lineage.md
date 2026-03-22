# Column Lineage — Dealing_dbo.Dealing_JPMReconTrades

**Writer**: `Dealing_dbo.SP_JPMRecon`
**Pattern**: DELETE-INSERT by Date
**ETL Type**: LP Reconciliation — JPMorgan vs eToro daily trade activity (NA, EMEA, ASIA)

## Source Tables

| Source | Type | Role |
|---|---|---|
| Dealing_staging.LP_JPM_ETORO_NA_Trade_Summary | LP Feed (Tier 2) | JPM North America trade summary |
| Dealing_staging.LP_JPM_ETORO_EMEA_Trade_Summary | LP Feed (Tier 2) | JPM EMEA trade summary |
| Dealing_staging.LP_JPM_ETORO_ASIA_Trade_Summary | LP Feed (Tier 2) | JPM Asia trade summary |
| Dealing_staging.LP_JPM_EOD_eToro_Report_FXRates | LP Feed (Tier 2) | FX rates for commission USD conversion |
| Dealing_dbo.Dealing_Duco_ActivityRecon | Internal (Tier 2) | eToro trade activity (JPM HS filter: 2,8,22,9,121,110,129,319) |

## Column → Source Mapping

| Column | Source | Transform |
|---|---|---|
| Date | SP parameter @DateID | MAX(ReportDateID) ≤ @DateID; may lag 1 day |
| InstrumentID | ISNULL(eToro_side, JP_side) | Resolved via ISIN mapping; NULL for HS9-only rows |
| InstrumentDisplayName | ISNULL(Duco, JP.[Name]) | Prefer eToro naming |
| Symbol | ISNULL(Duco, JP.[RIC Code]) | JP RIC Code as fallback |
| ISINCode | ISNULL(Duco, JP.[ISIN Code]) | Primary join key |
| Buy/Sell | ISNULL(Duco, JP) | 'Buy' or 'Sell' from both sides |
| CurrencyPrimary | ISNULL(Duco, JP.Currency) | GBX→GBP normalisation |
| JP_Units | LP_JPM_ETORO_*_Trade_Summary | SUM UNION across 3 regions; ISNULL(,0) |
| eToro_Units | Dealing_Duco_ActivityRecon.eToro_Units | SUM for JPM HS; ISNULL(,0) |
| Clients_Units | Dealing_Duco_ActivityRecon.ClientUnits | SUM; ISNULL(,0) |
| JP-eToro_Units | Computed | ISNULL(JP_Units,0) − ISNULL(eToro_Units,0) |
| JP-Clients_Units | Computed | ISNULL(JP_Units,0) − ISNULL(Clients_Units,0) |
| JP_Rate | LP_JPM_ETORO_*_Trade_Summary | Execution price from trade summary |
| eToro_Rate | Dealing_Duco_ActivityRecon.eToro_Rate | AVG; GBX ÷100 |
| JP-eToro_Rate | Computed | ISNULL(JP_Rate,0) − ISNULL(eToro_Rate,0) |
| JP_LocalAmount | LP_JPM_ETORO_*_Trade_Summary | SUM notional; ISNULL(,0) |
| eToro_LocalAmount | Dealing_Duco_ActivityRecon.eToroLocalAmount | GBX ÷100; ISNULL(,0) |
| JP-eToro_LocalAmount | Computed | ISNULL(JP,0) − ISNULL(eToro,0) |
| JP_AmountUSD | LP_JPM_ETORO_*_Trade_Summary | SUM USD notional; ISNULL(,0) |
| eToro_AmountUSD | Dealing_Duco_ActivityRecon.eToroUSDAmount | Passthrough; ISNULL(,0) |
| Clients_AmountUSD | Dealing_Duco_ActivityRecon.ClientAmount | Passthrough; ISNULL(,0) |
| JP-eToro_AmountUSD | Computed | ISNULL(JP,0) − ISNULL(eToro,0) |
| JP-Clients_AmountUSD | Computed | ISNULL(JP,0) − ISNULL(Clients,0) |
| JP_FXRate | LP_JPM_EOD_eToro_Report_FXRates.Rate | MAX joined on Currency |
| eToro_FXRate | Dealing_Duco_ActivityRecon.FXratetoUSD | Passthrough |
| Total_Commission_USD | LP_JPM_ETORO_*_Trade_Summary + FX | Commission × JP_FXRate |
| Exchange | Dealing_Duco_ActivityRecon.Exchange | ISNULL(eToro, 0) |
| UpdateDate | ETL | GETDATE() on INSERT |
