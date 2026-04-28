# Lineage: Dealing_dbo.Dealing_Apex_PnL

## Source Objects

| # | Source Object | Type | Schema | Database | Relationship |
|---|--------------|------|--------|----------|-------------|
| 1 | LP_APEX_EXT982_3EU | Staging Table | Dealing_staging | Synapse | NOP Start/End positions (MarketValue, ClosingPrice, TradeQuantity) |
| 2 | LP_APEX_EXT872_3EU_217314 | Staging Table | Dealing_staging | Synapse | Trade executions (Quantity, Price, Fees) and instrument matching (Symbol, ISIN, CUSIP) |
| 3 | LP_APEX_EXT869_3EU | Staging Table | Dealing_staging | Synapse | Dividends and additional fees (Amount, TerminalID) |
| 4 | LP_APEX_EXT981_3EU | Staging Table | Dealing_staging | Synapse | Account equity (TotalEquity) — used for sibling table Dealing_Apex_PnL_EE only |
| 5 | Dim_Instrument | Dimension Table | DWH_dbo | Synapse | Instrument lookup — InstrumentID, InstrumentDisplayName, Symbol, ISINCode, CUSIP, Exchange, BuyCurrencyID, SellCurrencyID |
| 6 | PriceLog_History_CurrencyPrice | Staging Table | Dealing_staging | Synapse | eToro price rates (AskSpreaded, BidSpreaded) at end-of-trading-session |
| 7 | Dim_Date | Dimension Table | DWH_dbo | Synapse | Date logic — bank holidays, week numbers, day-of-week for Friday/Saturday resolution |
| 8 | Dealing_DailyZeroPnL_Stocks | Fact Table | Dealing_dbo | Synapse | Zero PnL adjustment (TotalZero) by HedgeServerID and InstrumentID |
| 9 | DateToDateID | Function | Dealing_dbo | Synapse | Converts DATE to INT DateID format (YYYYMMDD) |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|--------------|--------------|---------------|-----------|------|
| Date | SP parameter | @Date | Direct assignment | Tier 2 |
| AccountNumber | LP_APEX_EXT982_3EU / LP_APEX_EXT872_3EU_217314 / LP_APEX_EXT869_3EU | AccountNumber | COALESCE across NOP, Trades, Dividends temp tables | Tier 2 |
| Symbol | LP_APEX_EXT982_3EU / LP_APEX_EXT872_3EU_217314 / LP_APEX_EXT869_3EU | Symbol | COALESCE across NOP, Trades, Dividends temp tables | Tier 2 |
| NOP_Start | LP_APEX_EXT982_3EU | MarketValue | Parsed from scientific notation (e+ format), Friday-before EOD | Tier 2 |
| NOP_Start_DBPrice | LP_APEX_EXT982_3EU + PriceLog_History_CurrencyPrice | TradeQuantity * Bid | Computed: TradeQuantity_Start * Price_Start_DB | Tier 2 |
| NOP_End | LP_APEX_EXT982_3EU | MarketValue | Parsed from scientific notation, current-day EOD | Tier 2 |
| NOP_End_DBPrice | LP_APEX_EXT982_3EU + PriceLog_History_CurrencyPrice | TradeQuantity * Bid | Computed: TradeQuantity_End * Price_End_DB | Tier 2 |
| Trades | LP_APEX_EXT872_3EU_217314 | Quantity * Price + FeeSec + Fee5 | SUM aggregation over Saturday-to-current-day window | Tier 2 |
| Dividends | LP_APEX_EXT869_3EU | Amount | SUM WHERE TerminalID = '$+DIV', negated | Tier 2 |
| PnL | Computed | NOP_End - NOP_Start - Trades + Dividends + AdditionalFees | ETL formula: ISNULL(NOP_End,0) - ISNULL(NOP_Start,0) - ISNULL(Trades,0) + ISNULL(Dividends,0) + ISNULL(AdditionalFees,0) | Tier 2 |
| PnL_DBPrice | Computed | NOP_End_DBPrice - NOP_Start_DBPrice - Trades + Dividends + AdditionalFees | Same formula using DB price NOP values | Tier 2 |
| UpdateDate | ETL | GETDATE() | ETL load timestamp | Tier 2 |
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | Dim-lookup passthrough via Symbol/ISIN/CUSIP matching from Apex staging data | Tier 1 |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Dim-lookup passthrough | Tier 2 |
| Price_Start | LP_APEX_EXT982_3EU | ClosingPrice | CAST to decimal(16,6), Friday-before EOD | Tier 2 |
| Price_Start_DB | PriceLog_History_CurrencyPrice | BidSpreaded | Last bid price before trading session close on Friday-before; GBX/100 adjustment for SellCurrencyID=666 | Tier 2 |
| Price_End | LP_APEX_EXT982_3EU | ClosingPrice | CAST to decimal(16,6), current-day EOD | Tier 2 |
| Price_End_DB | PriceLog_History_CurrencyPrice | BidSpreaded | Last bid price before trading session close on current day; GBX/100 adjustment | Tier 2 |
| AdditionalFees | LP_APEX_EXT869_3EU | Amount | SUM WHERE TerminalID NOT IN ('$+DIV','CSCSG','FWWRD','MGLOA','MGJNL'), negated | Tier 2 |
| Volume | LP_APEX_EXT872_3EU_217314 | ABS(Quantity * Price + FeeSec + Fee5) | SUM of absolute trade values | Tier 2 |
| Zero | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | TotalZero | SUM by HedgeServerID (mapped to AccountNumber) and InstrumentID | Tier 2 |
