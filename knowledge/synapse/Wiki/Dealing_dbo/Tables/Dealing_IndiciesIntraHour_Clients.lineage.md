# Lineage: Dealing_dbo.Dealing_IndiciesIntraHour_Clients

## Source Objects

| # | Source Object | Source Type | Schema | Relationship | Description |
|---|--------------|-------------|--------|-------------|-------------|
| 1 | DWH_dbo.Dim_Position | Table | DWH_dbo | Direct read | Client positions: InstrumentID, HedgeServerID, Volume, VolumeOnClose, AmountInUnitsDecimal, IsBuy, InitForexRate, FullCommissionByUnits, FullCommissionOnClose, NetProfit, Amount, OpenOccurred, CloseOccurred, OpenDateID, CloseDateID |
| 2 | DWH_dbo.Dim_Customer | Table | DWH_dbo | JOIN filter | Joined on CID=RealCID; filtered by IsValidCustomer=1 |
| 3 | CopyFromLake.PriceLog_History_CurrencyPrice | Table | CopyFromLake | Direct read | Bid, Ask, USDConversionRate per instrument per minute |
| 4 | Dealing_staging.etoro_History_PortfolioConversionConfigurations | Table | Dealing_staging | Lookup | Maps InstrumentID to InstrumentIDToHedge (historical) |
| 5 | Dealing_staging.etoro_Hedge_PortfolioConversionConfigurations | Table | Dealing_staging | Lookup | Maps InstrumentID to InstrumentIDToHedge (current) |

## Column Lineage

| # | Target Column | Source Object | Source Column(s) | Transform |
|---|--------------|---------------|-----------------|-----------|
| 1 | Date | SP_IntraHourIndexReport | (generated minute grid) | CONVERT(DATE, fromMinute) — date portion of the minute bucket |
| 2 | Minute_Start | SP_IntraHourIndexReport | (generated minute grid) | Start of 1-minute time bucket |
| 3 | Minute_End | SP_IntraHourIndexReport | (generated minute grid) | End of 1-minute time bucket (Minute_Start + 1 minute) |
| 4 | InstrumentID | DWH_dbo.Dim_Position | InstrumentID | Passthrough (filtered to instruments 27, 28, 32 via PortfolioConversionConfigurations) |
| 5 | VolumeBuy | DWH_dbo.Dim_Position | Volume, VolumeOnClose, IsBuy | SUM(CASE WHEN IsBuy=1 THEN Volume) for opens + SUM(CASE WHEN IsBuy=0 THEN VolumeOnClose) for closes |
| 6 | VolumeSell | DWH_dbo.Dim_Position | Volume, VolumeOnClose, IsBuy | SUM(CASE WHEN IsBuy=0 THEN Volume) for opens + SUM(CASE WHEN IsBuy=1 THEN VolumeOnClose) for closes |
| 7 | OP_Buy_Units | DWH_dbo.Dim_Position | AmountInUnitsDecimal, IsBuy | SUM(CASE WHEN IsBuy=1 THEN AmountInUnitsDecimal) — total buy-side units for open positions |
| 8 | OP_Buy | DWH_dbo.Dim_Position + CopyFromLake.PriceLog_History_CurrencyPrice | AmountInUnitsDecimal, Bid, USDConversionRate | SUM(AmountInUnitsDecimal * FirstBid * ConversionFirst) for buy positions |
| 9 | OP_Sell_Units | DWH_dbo.Dim_Position | AmountInUnitsDecimal, IsBuy | SUM(CASE WHEN IsBuy=0 THEN AmountInUnitsDecimal) — total sell-side units for open positions |
| 10 | OP_Sell | DWH_dbo.Dim_Position + CopyFromLake.PriceLog_History_CurrencyPrice | AmountInUnitsDecimal, Ask, USDConversionRate | SUM(AmountInUnitsDecimal * FirstAsk * ConversionFirst) for sell positions |
| 11 | UnrealizedStart | DWH_dbo.Dim_Position + CopyFromLake.PriceLog_History_CurrencyPrice | AmountInUnitsDecimal, InitForexRate, FullCommissionByUnits, Bid, Ask, USDConversionRate | SUM(AmountInUnitsDecimal * ConversionFirst * (price - InitForexRate) + FullCommissionByUnits) excluding positions opened in the same minute |
| 12 | UnrealizedEnd | DWH_dbo.Dim_Position + CopyFromLake.PriceLog_History_CurrencyPrice | (same as UnrealizedStart) | Self-join: UnrealizedStart value from the next minute (o2.fromMinute = o.toMinute) |
| 13 | Realized | DWH_dbo.Dim_Position | NetProfit, FullCommissionOnClose | SUM(NetProfit + FullCommissionOnClose) for positions closing in the minute |
| 14 | Bid | CopyFromLake.PriceLog_History_CurrencyPrice | Bid | LAG(LastBid, 1) — bid price at start of minute (prior minute's last bid) |
| 15 | Ask | CopyFromLake.PriceLog_History_CurrencyPrice | Ask | LAG(LastAsk, 1) — ask price at start of minute (prior minute's last ask) |
| 16 | UpdateDate | SP_IntraHourIndexReport | (none) | GETDATE() — ETL execution timestamp |
| 17 | HedgeServerID | DWH_dbo.Dim_Position | HedgeServerID | Passthrough (grouping dimension) |
