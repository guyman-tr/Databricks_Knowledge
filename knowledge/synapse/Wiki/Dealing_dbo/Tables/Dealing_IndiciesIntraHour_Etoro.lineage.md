# Lineage: Dealing_dbo.Dealing_IndiciesIntraHour_Etoro

## Source Objects

| # | Source Object | Source Type | Relationship | Description |
|---|--------------|-------------|-------------|-------------|
| 1 | CopyFromLake.etoro_Hedge_ExecutionLog | Staging Table | ETL source | Hedge execution records — provides per-execution volumes (Units, ExecutionRate), IsBuy direction, LiquidityAccountID, InstrumentID, HedgeServerID |
| 2 | Dealing_staging.etoro_Hedge_Netting | Staging Table | ETL source | Current netting positions — provides Units, IsBuy, SysStartTime/SysEndTime for NOP calculation |
| 3 | Dealing_staging.etoro_History_Netting_History | Staging Table | ETL source | Historical netting positions — UNIONed with current netting for full temporal coverage |
| 4 | Dealing_staging.etoro_Trade_LiquidityAccounts | Staging Table | ETL source | Liquidity account dimension — provides LiquidityAccountName via JOIN on LiquidityAccountID |
| 5 | CopyFromLake.PriceLog_History_CurrencyPrice | Staging Table | ETL source | Minute-level bid/ask prices and USD conversion rates for price smoothing and USD-equivalent calculations |
| 6 | Dealing_staging.etoro_History_PortfolioConversionConfigurations | Staging Table | ETL source | Historical instrument-to-hedge mapping — maps original index instruments (27/28/32) to hedge instruments |
| 7 | Dealing_staging.etoro_Hedge_PortfolioConversionConfigurations | Staging Table | ETL source | Current instrument-to-hedge mapping — UNIONed with historical for full coverage |
| 8 | Dealing_dbo.SP_IntraHourIndexReport | Stored Procedure | Writer SP | Orchestrates daily DELETE+INSERT for both client and eToro sides of the intra-hour report |
| 9 | Dealing_dbo.Dealing_IndiciesIntraHour_Clients | Companion Table | Peer | Client-side companion table — same SP populates both; typically joined on Date, Minute_Start, InstrumentID, HedgeServerID |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform |
|---|--------------|--------------|--------------|-----------|
| 1 | Date | (generated) | — | CONVERT(DATE, fromMinute) from minute grid |
| 2 | InstrumentID | CopyFromLake.etoro_Hedge_ExecutionLog | InstrumentID | Passthrough; represents hedge instrument ID (mapped from original indices via PortfolioConversionConfigurations) |
| 3 | Minute_Start | (generated) | — | Minute grid start (fromMinute); 1-minute intervals covering full 24-hour day |
| 4 | Minute_End | (generated) | — | Minute grid end (toMinute = fromMinute + 1 minute) |
| 5 | LiquidityAccountName | Dealing_staging.etoro_Trade_LiquidityAccounts | LiquidityAccountName | Passthrough via JOIN on LiquidityAccountID |
| 6 | LiquidityAccountID | CopyFromLake.etoro_Hedge_ExecutionLog | LiquidityAccountID | Passthrough; used as grouping dimension |
| 7 | VolumeBuy | CopyFromLake.etoro_Hedge_ExecutionLog + CopyFromLake.PriceLog_History_CurrencyPrice | Units, ExecutionRate, USDConversionRate | SUM(Units * ExecutionRate) for IsBuy=1 executions, then multiplied by USD ConversionFirst |
| 8 | VolumeSell | CopyFromLake.etoro_Hedge_ExecutionLog + CopyFromLake.PriceLog_History_CurrencyPrice | Units, ExecutionRate, USDConversionRate | SUM(Units * ExecutionRate) for IsBuy=0 executions, then multiplied by USD ConversionFirst |
| 9 | Units_NOP | Dealing_staging.etoro_Hedge_Netting / etoro_History_Netting_History | Units, IsBuy | SUM(Units * (2*IsBuy-1)); net open position in units (positive=net long, negative=net short). ISNULL defaults to 0. |
| 10 | NOP | Dealing_staging.etoro_Hedge_Netting / etoro_History_Netting_History + CopyFromLake.PriceLog_History_CurrencyPrice | Units, IsBuy, Bid/Ask, USDConversionRate | SUM(Units * ConversionFirst * (2*IsBuy-1) * CASE IsBuy=1 THEN FirstBid ELSE FirstAsk END); USD-equivalent net open position |
| 11 | ValueStart | Dealing_staging.etoro_Hedge_Netting / etoro_History_Netting_History + CopyFromLake.PriceLog_History_CurrencyPrice | Units, IsBuy, Bid/Ask, USDConversionRate | Identical formula to NOP: SUM(Units * ConversionFirst * (2*IsBuy-1) * price); value at start of minute |
| 12 | ValueEnd | (self-join) | ValueStart | ISNULL(te1.ValueStart, 0) from self-join: te1.fromMinute = te.toMinute (next minute's ValueStart). 0 for last minute of day. |
| 13 | ValueRealized | CopyFromLake.etoro_Hedge_ExecutionLog + CopyFromLake.PriceLog_History_CurrencyPrice | VolumeSell, VolumeBuy, USDConversionRate | SUM(VolumeSell*ConversionFirst - VolumeBuy*ConversionFirst); net realized value from executions |
| 14 | UpdateDate | (generated) | — | GETDATE() at SP execution time |
| 15 | HedgeServerID | CopyFromLake.etoro_Hedge_ExecutionLog / Dealing_staging.etoro_Hedge_Netting | HedgeServerID | Passthrough; used as grouping dimension. Added 2024-04-30 (SR-249626). |
