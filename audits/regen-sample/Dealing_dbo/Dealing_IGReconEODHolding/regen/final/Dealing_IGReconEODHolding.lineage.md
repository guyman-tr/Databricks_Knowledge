# Lineage: Dealing_dbo.Dealing_IGReconEODHolding

## Source Objects

| Source Object | Schema | Role | Wiki Path |
|---|---|---|---|
| Dealing_Duco_EODRecon | Dealing_dbo | eToro-side EOD holdings (hedge + client NOP) | `knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_Duco_EODRecon.md` |
| LP_IG_PS_EODPositions | Dealing_staging | IG LP EOD position file (parquet) | _No wiki_ |
| LP_IG_PS_EODPositions_daily | Dealing_staging | Daily IG position file loaded via COPY INTO | _No wiki_ |
| External_Fivetran_dealing_active_hs_mappings | Dealing_staging | IG hedge-server → LP account mapping (Fivetran) | _No wiki_ |
| Dim_Instrument | DWH_dbo | Instrument metadata for ISIN/name resolution | `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Instrument.md` |
| Dim_Date | DWH_dbo | Weekend day-of-week lookup | _No wiki_ |
| Dealing_Duco_ActivityRecon | Dealing_dbo | (Same SP writes trades companion table) | `knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_Duco_ActivityRecon.md` |

## Column Lineage

| # | Target Column | Source | Source Column(s) | Transform | Tier |
|---|---|---|---|---|---|
| 1 | Date | SP_IGRecon | @Date parameter | Sunday→Friday−2 via Dim_Date.DayNumberOfWeek_Sun_Start; Saturday skipped | Tier 2 |
| 2 | HedgeServerID | Dealing_Duco_EODRecon | HedgeServerID | Passthrough from eToro side; NULL for IG-only rows (FULL OUTER JOIN) | Tier 2 |
| 3 | Account_Number | LP_IG_PS_EODPositions | [Account ID] | Passthrough from IG side; NULL for eToro-only rows | Tier 2 |
| 4 | InstrumentID | Dealing_Duco_EODRecon / LP_IG_PS_EODPositions | InstrumentID / ISIN+#MarketNameToID | eToro side: passthrough. IG side: resolved via Dim_Instrument.ISINCode or hardcoded #MarketNameToID mapping | Tier 2 |
| 5 | InstrumentDisplayName | Dealing_Duco_EODRecon / Dim_Instrument | InstrumentDisplayName | ISNULL(eToro_side, IG_side) | Tier 2 |
| 6 | Symbol | Dealing_Duco_EODRecon | Symbol | Passthrough from eToro side | Tier 2 |
| 7 | ISINCode | Dealing_Duco_EODRecon / LP_IG_PS_EODPositions | ISINCode / ISIN | ISNULL(eToro_side, IG_side) | Tier 2 |
| 8 | CurrencyPrimary | Dealing_Duco_EODRecon / LP_IG_PS_EODPositions | SellCurrency / Ccy | eToro: CASE GBX→GBP normalization. IG: Ccy passthrough. ISNULL(eToro, IG) | Tier 2 |
| 9 | Exchange | Dealing_Duco_EODRecon | Exchange | ISNULL(eToro_side, 0); IG side has no Exchange column | Tier 2 |
| 10 | IG_Units | LP_IG_PS_EODPositions | Position | SUM((2*IsBuy−1) × ABS(Position)); Oil ×100 multiplier | Tier 2 |
| 11 | eToro_Units | Dealing_Duco_EODRecon | eToro_Units | SUM(eToro_Units) grouped by instrument+account | Tier 2 |
| 12 | Clients_Units | Dealing_Duco_EODRecon | ClientUnits | SUM(ClientUnits) grouped by instrument+account | Tier 2 |
| 13 | IG-eToro_Units | Computed | IG_Units, eToro_Units | ISNULL(IG_Units,0) − ISNULL(eToro_Units,0) | Tier 2 |
| 14 | IG-Clients_Units | Computed | IG_Units, Clients_Units | ISNULL(IG_Units,0) − ISNULL(Clients_Units,0) | Tier 2 |
| 15 | IG_LocalAmount | LP_IG_PS_EODPositions | [Current Value] | TRY_CONVERT to decimal; Oil ×100 multiplier; SUM grouped | Tier 2 |
| 16 | eToro_LocalAmount | Dealing_Duco_EODRecon | eToroLocalAmount | GBX ÷100 normalization; SUM grouped | Tier 2 |
| 17 | IG-eToro_LocalAmount | Computed | IG_LocalAmount, eToro_LocalAmount | ISNULL(IG,0) − ISNULL(eToro,0) | Tier 2 |
| 18 | IG_AmountUSD | LP_IG_PS_EODPositions | [Consideration (Base Ccy)] | TRY_CONVERT to decimal; SUM((2*IsBuy−1) × value) grouped | Tier 2 |
| 19 | eToro_AmountUSD | Dealing_Duco_EODRecon | eToroUSDAmount | SUM grouped by instrument+account | Tier 2 |
| 20 | Clients_AmountUSD | Dealing_Duco_EODRecon | ClientAmount | SUM grouped by instrument+account | Tier 2 |
| 21 | IG-eToro_AmountUSD | Computed | IG_AmountUSD, eToro_AmountUSD | ISNULL(IG,0) − ISNULL(eToro,0) | Tier 2 |
| 22 | IG-Clients_AmountUSD | Computed | IG_AmountUSD, Clients_AmountUSD | ISNULL(IG,0) − ISNULL(Clients,0) | Tier 2 |
| 23 | IG_Rate | LP_IG_PS_EODPositions | Latest | TRY_CONVERT(DECIMAL, Latest); MAX grouped | Tier 2 |
| 24 | eToro_Rate | Dealing_Duco_EODRecon | eToroRate | GBX ÷100 normalization; MAX grouped | Tier 2 |
| 25 | IG-eToro_Rate | Computed | IG_Rate, eToro_Rate | ISNULL(IG_Rate,0) − ISNULL(eToro_Rate,0) | Tier 2 |
| 26 | IG_FXRate | LP_IG_PS_EODPositions | [Conversion Rate] | CASE USD→1, else parse string (strip trailing char); MAX grouped | Tier 2 |
| 27 | eToro_FXRate | Dealing_Duco_EODRecon | FXratetoUSD | MAX(FXratetoUSD) grouped | Tier 2 |
| 28 | UpdateDate | SP_IGRecon | GETDATE() | ETL batch timestamp | Tier 3 |
