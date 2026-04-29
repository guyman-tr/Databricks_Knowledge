# Lineage — Dealing_dbo.Dealing_Apex_PnL_Daily

## Source Objects

| # | Source Object | Type | Schema | Relationship | Confidence |
|---|--------------|------|--------|--------------|------------|
| 1 | LP_APEX_EXT982_3EU | Staging Table | Dealing_staging | NOP / holdings positions (Apex external file) | High — SP code |
| 2 | LP_APEX_EXT872_3EU_217314 | Staging Table | Dealing_staging | Trade activity (buys/sells, volume) and instrument resolution | High — SP code |
| 3 | LP_APEX_EXT869_3EU | Staging Table | Dealing_staging | Dividends, additional fees, transfers | High — SP code |
| 4 | PriceLog_History_CurrencyPrice | Staging Table | Dealing_staging | eToro internal bid/ask prices for DB-price NOP valuation | High — SP code |
| 5 | Dim_Instrument | Dimension | DWH_dbo | Instrument resolution (Symbol/CUSIP/ISIN → InstrumentID, display name) | High — SP code |
| 6 | Dealing_DailyZeroPnL_Stocks | Fact Table | Dealing_dbo | Zero PnL adjustment for fully-closed positions | High — SP code |
| 7 | Dim_Date | Dimension | DWH_dbo | Calendar logic (IsBankHoliday, DayNumberOfWeek) for date parameter resolution | High — SP code |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier |
|---|--------------|--------------|---------------|-----------|------|
| 1 | Date | SP_Apex_PnL | @Date parameter | SET to @Date (the report date passed to SP) | Tier 2 |
| 2 | AccountNumber | LP_APEX_EXT982_3EU / LP_APEX_EXT872_3EU_217314 / LP_APEX_EXT869_3EU | AccountNumber | COALESCE across NOP, Trades, Dividends feeds | Tier 2 |
| 3 | Symbol | LP_APEX_EXT982_3EU / LP_APEX_EXT872_3EU_217314 / LP_APEX_EXT869_3EU | Symbol | COALESCE across NOP, Trades, Dividends feeds | Tier 2 |
| 4 | NOP_Start | LP_APEX_EXT982_3EU | MarketValue | Passthrough (with scientific notation parsing); daily uses @PreviousDay | Tier 2 |
| 5 | NOP_Start_DBPrice | LP_APEX_EXT982_3EU + PriceLog_History_CurrencyPrice | TradeQuantity × Bid | Computed: TradeQuantity_Start × Price_Start_DB | Tier 2 |
| 6 | NOP_End | LP_APEX_EXT982_3EU | MarketValue | Passthrough (with scientific notation parsing); uses @DateID | Tier 2 |
| 7 | NOP_End_DBPrice | LP_APEX_EXT982_3EU + PriceLog_History_CurrencyPrice | TradeQuantity × Bid | Computed: TradeQuantity_End × Price_End_DB | Tier 2 |
| 8 | Trades | LP_APEX_EXT872_3EU_217314 | Quantity × Price + FeeSec + Fee5 | SUM of (Quantity × Price + fees); daily uses ReportDateID = @DateID only | Tier 2 |
| 9 | Dividends | LP_APEX_EXT869_3EU | Amount | SUM where TerminalID = '$+DIV'; negated; daily uses ReportDateID = @DateID | Tier 2 |
| 10 | PnL | Computed | NOP_End - NOP_Start - Trades + Dividends + AdditionalFees | Apex-priced PnL formula | Tier 2 |
| 11 | PnL_DBPrice | Computed | NOP_End_DBPrice - NOP_Start_DBPrice - Trades + Dividends + AdditionalFees | eToro DB-priced PnL formula | Tier 2 |
| 12 | UpdateDate | SP_Apex_PnL | GETDATE() | ETL load timestamp | Tier 2 |
| 13 | InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | COALESCE across NOP/Trades/Dividends instrument resolution; matched via Symbol/CUSIP/ISIN | Tier 2 |
| 14 | InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | COALESCE across NOP/Trades/Dividends instrument resolution | Tier 2 |
| 15 | Price_Start | LP_APEX_EXT982_3EU | ClosingPrice | Apex closing price at prior business day; CAST to decimal(16,6) | Tier 2 |
| 16 | Price_Start_DB | PriceLog_History_CurrencyPrice | Bid | eToro internal bid at prior business day EOD (GBX/100 adjustment for SellCurrencyID=666) | Tier 2 |
| 17 | Price_End | LP_APEX_EXT982_3EU | ClosingPrice | Apex closing price at @DateID; CAST to decimal(16,6) | Tier 2 |
| 18 | Price_End_DB | PriceLog_History_CurrencyPrice | Bid | eToro internal bid at @DateID EOD (GBX/100 adjustment) | Tier 2 |
| 19 | AdditionalFees | LP_APEX_EXT869_3EU | Amount | SUM where TerminalID NOT IN ('$+DIV','CSCSG','FWWRD','MGLOA','MGJNL'); negated; daily scope | Tier 2 |
| 20 | Volume | LP_APEX_EXT872_3EU_217314 | ABS(Quantity × Price + fees) | SUM of absolute trade values; daily uses ReportDateID = @DateID | Tier 2 |
| 21 | Zero | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | TotalZero | SUM(TotalZero) for Date = @Date, joined via InstrumentID and AccountNumber→HedgeServerID mapping | Tier 2 |
