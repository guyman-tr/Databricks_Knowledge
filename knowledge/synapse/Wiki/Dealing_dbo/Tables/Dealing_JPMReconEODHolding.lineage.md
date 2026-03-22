# Column Lineage — Dealing_dbo.Dealing_JPMReconEODHolding

**Writer**: `Dealing_dbo.SP_JPMRecon`
**Pattern**: DELETE-INSERT by Date
**ETL Type**: LP Reconciliation — JPMorgan vs eToro EOD holdings (NA, EMEA, ASIA)

## Source Tables

| Source | Type | Role |
|---|---|---|
| Dealing_staging.LP_JPM_EOD_eToro_Report_ComponentUnderlyings | LP Feed (Tier 2) | JPM EOD custodian position file |
| Dealing_staging.LP_JPM_EOD_eToro_Report_FXRates | LP Feed (Tier 2) | JPM FX rates for local→USD conversion |
| Dealing_dbo.Dealing_Duco_EODRecon | Internal (Tier 2) | eToro EOD holdings (JPM HS filter: 2,8,22,9,121,110,129) |

## Column → Source Mapping

| Column | Source | Transform |
|---|---|---|
| Date | SP parameter @DateID | MAX(ReportDateID) ≤ @DateID from LP_JPM_EOD — may lag 1 day |
| InstrumentID | ISNULL(eToro_side, JP_side) | Resolved via Duco or JP instrument mapping; NULL for HS9-only rows |
| InstrumentDisplayName | ISNULL(eToro_side, JP.[Name]) | Prefer eToro naming |
| Symbol | ISNULL(eToro_side, JP.[RIC Code]) | JP RIC Code as fallback |
| ISINCode | ISNULL(eToro_side, JP.[ISIN Code]) | Primary join key between eToro and JPM |
| CurrencyPrimary | ISNULL(eToro_side, JP.Currency) | Secondary join key; GBX normalised to GBP |
| Exchange | ISNULL(eToro_side, 0) | eToro side only; 0 if eToro absent |
| JP_Units | LP_JPM_EOD_eToro_Report_ComponentUnderlyings.Quantity | SUM grouped by ISIN+Currency; ISNULL(,0) |
| eToro_Units | Dealing_Duco_EODRecon.eToro_Units | SUM for JPM HS (2,8,22,9,121,110,129); ISNULL(,0) |
| Clients_Units | Dealing_Duco_EODRecon.ClientUnits | SUM; ISNULL(,0) |
| JP-eToro_Units | Computed | ISNULL(JP_Units,0) − ISNULL(eToro_Units,0) |
| JP-Clients_Units | Computed | ISNULL(JP_Units,0) − ISNULL(Clients_Units,0) |
| JP_LocalAmount | LP_JPM_EOD_eToro_Report_ComponentUnderlyings.[Market Value (local)] | SUM; ISNULL(,0) |
| eToro_LocalAmount | Dealing_Duco_EODRecon.eToroLocalAmount | GBX ÷100; ISNULL(,0) |
| JP-eToro_LocalAmount | Computed | ISNULL(JP_LocalAmount,0) − ISNULL(eToro_LocalAmount,0) |
| JP_AmountUSD | LP_JPM_EOD_eToro_Report_ComponentUnderlyings.[Market Value (USD)] | SUM; ISNULL(,0) |
| eToro_AmountUSD | Dealing_Duco_EODRecon.eToroUSDAmount | Passthrough; ISNULL(,0) |
| Clients_AmountUSD | Dealing_Duco_EODRecon.ClientAmount | Passthrough; ISNULL(,0) |
| JP-eToro_AmountUSD | Computed | ISNULL(JP_AmountUSD,0) − ISNULL(eToro_AmountUSD,0) |
| JP-Clients_AmountUSD | Computed | ISNULL(JP_AmountUSD,0) − ISNULL(Clients_AmountUSD,0) |
| JP_Rate | LP_JPM_EOD_eToro_Report_ComponentUnderlyings.[Current Price] | MAX per ISIN+Currency |
| eToro_Rate | Dealing_Duco_EODRecon.eToroRate | MAX |
| JP-eToro_Rate | Computed | ISNULL(JP_Rate,0) − ISNULL(eToro_Rate,0) |
| JP_FXRate | LP_JPM_EOD_eToro_Report_FXRates.Rate | MAX joined on Currency |
| eToro_FXRate | Dealing_Duco_EODRecon.FXratetoUSD | Passthrough |
| UpdateDate | ETL | GETDATE() on INSERT |
