# Lineage: Dealing_dbo.Dealing_Employees_Report

## Source Tables
| Source | Role |
|--------|------|
| DWH_dbo.Dim_Position | Position data (PositionID, CID, InstrumentID, Amount, Leverage, IsBuy, IsMirrorPosition, NetProfit, Units, Volume, VolumeOnClose, OpenOccurred, CloseOccurred, StopRate, InitForexRate, EndForexRate, OpenDateID, CloseDateID) |
| DWH_dbo.Dim_Instrument | InstrumentType, Symbol, Exchange, IsReal (Real_CFD flag) |
| DWH_dbo.Dim_Customer | AccountTypeID IN (7,13) AND IsValidCustomer=0 filter; CountryID |
| BI_DB_dbo.BI_DB_PositionPnL | PositionPnL, DailyPnL, Price, RateBid, RateAsk, NOP, ConversionRate, Units (for open positions) |
| DWH_dbo.V_Liabilities | BonusCredit, RealizedEquity, TotalPositionsAmount, TotalCash, TotalMirrorPositionsAmount, TotalMirrorCash, Credit |
| BI_DB_dbo.DWH_GainDaily | Gain_MTD, Gain_YTD, Gain_d, Gain_QTD, Gain_w, Gain_m, Gain_y |
| DWH_dbo.Dim_Country | Country name lookup |

## Column Lineage

| Target Column | Source | Transformation |
|---------------|--------|----------------|
| Date | Generated | @Date parameter |
| PositionID | Dim_Position.PositionID | Both open (CloseDateID IS NULL) and closed (CloseDateID=@DateID) on @Date |
| CID | Dim_Position.CID | Employee CID (AccountTypeID IN 7,13) |
| InstrumentID | Dim_Position.InstrumentID | Direct |
| InstrumentType | Dim_Instrument.InstrumentType | Instrument asset class |
| Symbol | Dim_Instrument.Symbol | Instrument symbol |
| Amount | Dim_Position.Amount | Position invested amount USD |
| Duration_seconds | Derived | `DATEDIFF(SECOND, OpenOccurred, CloseOccurred)` (NULL for open) |
| Duration_minutes | Derived | `DATEDIFF(MINUTE, OpenOccurred, CloseOccurred)` |
| Duration | Derived | `DATEDIFF(DAY, OpenOccurred, CloseOccurred)` |
| Leverage | Dim_Position.Leverage | Leverage multiplier |
| Direction | Derived | `CASE WHEN IsBuy=1 THEN 'Buy' ELSE 'Sell' END` |
| CopyTarde | Derived | `CASE WHEN IsMirrorPosition=1 THEN 'Copy' ELSE 'Manual' END` |
| ReaL_CFD | Dim_Instrument.IsReal | `CASE WHEN IsReal=1 THEN 'Real' ELSE 'CFD' END` |
| Total_daily_Volume | Derived | Total opens+closes volume for this CID on @Date |
| Total_daily_clicks | Derived | Count of trades opened+closed for CID on @Date |
| NetProfit | Dim_Position.NetProfit | Realized P&L (NULL for open positions) |
| PositionPnL | BI_DB_PositionPnL.PositionPnL | Current P&L (open) or final P&L (closed) |
| DateID | Generated | @DateID |
| NOP | BI_DB_PositionPnL.NOP | Net open position value |
| DailyPnL | Derived | Open: BI_DB_PositionPnL.DailyPnL; Same-day close: NetProfit; Prior-day close: NetProfit−previos_Position_PnL |
| BonusCredit | V_Liabilities.BonusCredit | Bonus credit balance |
| RealizedEquity | V_Liabilities.RealizedEquity | Realized equity |
| UpdateDate | Generated | `GETDATE()` |
| MirrorID | Dim_Position.MirrorID | Copy relationship ID (if IsMirrorPosition=1) |
| Total_Daily_Commission | Derived | Sum of commissions for CID on @Date |
| OpenOccurred | Dim_Position.OpenOccurred | Position open timestamp |
| CloseOccurred | Dim_Position.CloseOccurred | Position close timestamp (NULL if open) |
| StopRate | Dim_Position.StopRate | Stop-loss rate |
| Exchange | Dim_Instrument.Exchange | Exchange name |
| TotalPositionsAmount | V_Liabilities.TotalPositionsAmount | Sum of all position amounts for CID |
| TotalCash | V_Liabilities.TotalCash | Total cash balance |
| TotalMirrorPositionsAmount | V_Liabilities | Total copy positions amount |
| TotalMirrorCash | V_Liabilities | Total copy cash |
| Credit | V_Liabilities.Credit | Credit balance |
| CopyPositionPnL | BI_DB_PositionPnL | P&L from copy positions |
| All_Positions_PNL | Derived | Total P&L across all positions |
| CountryID | Dim_Customer.CountryID | Employee country ID |
| Country | Dim_Country.CountryName | Employee country name |
| Gain_MTD / YTD / d / QTD / w / m / y | DWH_GainDaily | Various period gain percentages |
| Units | BI_DB_PositionPnL.Units | Position units |
| Volume | Dim_Position.Volume | Clicks on open |
| VolumeOnClose | Dim_Position.VolumeOnClose | Clicks on close |
| OpenDateID | Dim_Position.OpenDateID | Open date integer key |
| CloseDateID | Dim_Position.CloseDateID | Close date integer key |
| previos_Position_PnL | BI_DB_PositionPnL | Previous day's PositionPnL (for DailyPnL calc on prior-day closes) |
| InitForexRate | Dim_Position.InitForexRate | Opening price |
| EndForexRate | Dim_Position.EndForexRate | Closing price |
| Price / Change_Price / RateBid / RateAsk | BI_DB_PositionPnL | Current market price data |
| Previous_Price / Previous_Change_Price / Previous_Amount / Previous_Units / Previous_DailyPnL / PreviousBid / PreviousAsk | BI_DB_PositionPnL | Prior-day values for comparison |
| ConversionRate | BI_DB_PositionPnL.ConversionRate | USD conversion rate |
| IsChild | Dim_Position | Child position flag (copy sub-position) |
| IsParent | Dim_Position | Parent position flag |
| OriginalPositionID | Dim_Position.OriginalPositionID | Original position in copy chain |

## Generic Pipeline
| Property | Value |
|----------|-------|
| Datalake Path | Gold/sql_dp_prod_we/Dealing_dbo/Dealing_Employees_Report/ |
