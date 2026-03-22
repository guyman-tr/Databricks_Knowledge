# Dealing_dbo.Dealing_Employees_Report

## 1. Overview
Daily position-level report of all open and closed positions belonging to employee accounts (AccountTypeID IN 7, 13). Contains both current open positions and positions closed on the reporting date, enriched with P&L, pricing, equity, and gain metrics. The largest table in this batch at ~231.4M rows.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Distribution** | HASH(CID) |
| **Index** | Clustered (Date ASC) |
| **Row Count** | ~231.4M |
| **Date Range** | Historical → present (last: 2026-03-10) |
| **Grain** | One row per Date × PositionID (open + closed) |
| **Refresh** | Daily, via SP_Employees_Report |

## 2. Business Context
eToro maintains dedicated account types for employees (AccountTypeID=7=employee, 13=employee_special). These accounts are EXCLUDED from standard client analytics (IsValidCustomer=0) but require their own monitoring for compliance, compensation analysis, and internal risk management. This table provides the Dealing desk and HR/compliance teams with a full trading activity view for employees — covering every open position and every position closed on each date. The wide column set (71 cols) mirrors the shape of client trading analytics tables, enabling similar analysis patterns on the employee population. The SP uses a composite DailyPnL logic: open positions use BI_DB_PositionPnL.DailyPnL directly; same-day closes use NetProfit; prior-day closes use NetProfit − previos_Position_PnL.

## 3. Elements

| Column | Data Type | Nullable | Description | Tier | Source |
|--------|-----------|----------|-------------|------|--------|
| Date | date | Yes | Report date | T2 | SP_Employees_Report: @Date parameter |
| PositionID | bigint | Yes | Position identifier | T2 | DWH_dbo.Dim_Position |
| CID | int | Yes | Employee customer ID (AccountTypeID IN 7,13; IsValidCustomer=0) | T2 | DWH_dbo.Dim_Customer |
| InstrumentID | int | Yes | Instrument identifier | T2 | DWH_dbo.Dim_Position |
| InstrumentType | varchar(100) | Yes | Asset class (Stocks, Crypto, Currencies, Commodities, Indices, ETF) | T2 | DWH_dbo.Dim_Instrument |
| Symbol | varchar(100) | Yes | Instrument ticker symbol | T2 | DWH_dbo.Dim_Instrument |
| Amount | money | Yes | Invested amount in USD | T2 | DWH_dbo.Dim_Position |
| Duration_seconds | bigint | Yes | Position holding time in seconds (NULL for open) | T2 | `DATEDIFF(SECOND, OpenOccurred, CloseOccurred)` |
| Duration_minutes | bigint | Yes | Position holding time in minutes | T2 | `DATEDIFF(MINUTE, OpenOccurred, CloseOccurred)` |
| Duration | bigint | Yes | Position holding time in days | T2 | `DATEDIFF(DAY, OpenOccurred, CloseOccurred)` |
| Leverage | int | Yes | Leverage multiplier | T2 | DWH_dbo.Dim_Position |
| Direction | varchar(10) | Yes | 'Buy' or 'Sell' | T2 | Dim_Position.IsBuy |
| CopyTarde | varchar(10) | Yes | 'Copy' if IsMirrorPosition=1, else 'Manual' (typo: 'Tarde' should be 'Trade') | T2 | Dim_Position.IsMirrorPosition |
| ReaL_CFD | varchar(10) | Yes | 'Real' or 'CFD' based on IsReal flag | T2 | DWH_dbo.Dim_Instrument.IsReal |
| Total_daily_Volume | int | Yes | Total opens+closes volume for this CID on @Date | T2 | SP_Employees_Report: aggregated |
| Total_daily_clicks | int | Yes | Count of trades opened+closed for CID on @Date | T2 | SP_Employees_Report: aggregated |
| NetProfit | money | Yes | Realized P&L (NULL for open positions) | T2 | DWH_dbo.Dim_Position |
| PositionPnL | decimal(18,2) | Yes | Current P&L: for open positions = BI_DB_PositionPnL; for closed = final NetProfit | T2 | BI_DB_dbo.BI_DB_PositionPnL |
| DateID | int | Yes | Date integer key (YYYYMMDD) | T2 | SP_Employees_Report |
| NOP | money | Yes | Net open position value | T2 | BI_DB_dbo.BI_DB_PositionPnL |
| DailyPnL | decimal(18,2) | Yes | Daily P&L: open=PositionPnL.DailyPnL; same-day close=NetProfit; prior-day close=NetProfit−previos_Position_PnL | T2 | SP_Employees_Report: composite logic |
| BonusCredit | money | Yes | Employee bonus credit balance | T2 | DWH_dbo.V_Liabilities |
| RealizedEquity | money | Yes | Realized equity value | T2 | DWH_dbo.V_Liabilities |
| UpdateDate | datetime | Yes | ETL metadata: row write timestamp | T2 | SP_Employees_Report: `GETDATE()` |
| MirrorID | int | Yes | Copy relationship ID (if IsMirrorPosition=1) | T2 | DWH_dbo.Dim_Position |
| Total_Daily_Commission | money | Yes | Sum of commissions for this CID on @Date | T2 | SP_Employees_Report |
| OpenOccurred | datetime | Yes | Position open timestamp | T2 | DWH_dbo.Dim_Position |
| CloseOccurred | datetime | Yes | Position close timestamp (NULL if open) | T2 | DWH_dbo.Dim_Position |
| StopRate | decimal(16,8) | Yes | Stop-loss rate | T2 | DWH_dbo.Dim_Position |
| Exchange | varchar(100) | Yes | Exchange name | T2 | DWH_dbo.Dim_Instrument |
| TotalPositionsAmount | money | Yes | Sum of all position amounts for CID | T2 | DWH_dbo.V_Liabilities |
| TotalCash | money | Yes | Total cash balance | T2 | DWH_dbo.V_Liabilities |
| TotalMirrorPositionsAmount | money | Yes | Total copy positions amount | T2 | DWH_dbo.V_Liabilities |
| TotalMirrorCash | money | Yes | Total copy cash | T2 | DWH_dbo.V_Liabilities |
| Credit | money | Yes | Credit balance | T2 | DWH_dbo.V_Liabilities |
| CopyPositionPnL | money | Yes | P&L from copy positions | T2 | BI_DB_dbo.BI_DB_PositionPnL |
| All_Positions_PNL | money | Yes | Total P&L across all positions for CID | T2 | SP_Employees_Report: aggregated |
| CountryID | int | Yes | Employee country ID | T2 | DWH_dbo.Dim_Customer |
| Country | varchar(100) | Yes | Employee country name | T2 | DWH_dbo.Dim_Country |
| Gain_MTD | float | Yes | Month-to-date gain percentage | T2 | BI_DB_dbo.DWH_GainDaily |
| Gain_YTD | float | Yes | Year-to-date gain percentage | T2 | BI_DB_dbo.DWH_GainDaily |
| Gain_d | float | Yes | Daily gain percentage | T2 | BI_DB_dbo.DWH_GainDaily |
| Gain_QTD | float | Yes | Quarter-to-date gain percentage | T2 | BI_DB_dbo.DWH_GainDaily |
| Gain_w | float | Yes | Week-to-date gain percentage | T2 | BI_DB_dbo.DWH_GainDaily |
| Gain_m | float | Yes | Month gain percentage | T2 | BI_DB_dbo.DWH_GainDaily |
| Gain_y | float | Yes | Year gain percentage | T2 | BI_DB_dbo.DWH_GainDaily |
| Units | decimal(16,6) | Yes | Position units | T2 | BI_DB_dbo.BI_DB_PositionPnL |
| Volume | int | Yes | Trade open click count | T2 | DWH_dbo.Dim_Position |
| VolumeOnClose | int | Yes | Trade close click count | T2 | DWH_dbo.Dim_Position |
| OpenDateID | int | Yes | Open date integer key | T2 | DWH_dbo.Dim_Position |
| CloseDateID | int | Yes | Close date integer key | T2 | DWH_dbo.Dim_Position |
| previos_Position_PnL | decimal(16,4) | Yes | Prior day's PositionPnL — used for DailyPnL calculation on prior-day closes (typo: 'previos' not 'previous') | T2 | BI_DB_dbo.BI_DB_PositionPnL |
| InitForexRate | numeric(18,6) | Yes | Opening price | T2 | DWH_dbo.Dim_Position |
| EndForexRate | decimal(18,6) | Yes | Closing price | T2 | DWH_dbo.Dim_Position |
| Price | numeric(38,6) | Yes | Current market price | T2 | BI_DB_dbo.BI_DB_PositionPnL |
| Change_Price | numeric(18,6) | Yes | Price change vs prior day | T2 | BI_DB_dbo.BI_DB_PositionPnL |
| RateBid | numeric(36,12) | Yes | Current bid price | T2 | BI_DB_dbo.BI_DB_PositionPnL |
| RateAsk | numeric(36,12) | Yes | Current ask price | T2 | BI_DB_dbo.BI_DB_PositionPnL |
| Previous_Price | numeric(38,6) | Yes | Prior day's market price | T2 | BI_DB_dbo.BI_DB_PositionPnL |
| Previous_Change_Price | numeric(38,6) | Yes | Prior day's price change | T2 | BI_DB_dbo.BI_DB_PositionPnL |
| Previous_Amount | money | Yes | Prior day's invested amount | T2 | BI_DB_dbo.BI_DB_PositionPnL |
| Previous_Units | numeric(16,6) | Yes | Prior day's position units | T2 | BI_DB_dbo.BI_DB_PositionPnL |
| Previous_DailyPnL | decimal(16,4) | Yes | Prior day's DailyPnL | T2 | BI_DB_dbo.BI_DB_PositionPnL |
| PreviousBid | numeric(36,12) | Yes | Prior day's bid price | T2 | BI_DB_dbo.BI_DB_PositionPnL |
| PreviousAsk | numeric(36,12) | Yes | Prior day's ask price | T2 | BI_DB_dbo.BI_DB_PositionPnL |
| ConversionRate | decimal(16,8) | Yes | USD conversion rate | T2 | BI_DB_dbo.BI_DB_PositionPnL |
| IsChild | int | Yes | Child position flag (sub-position in a copy) | T2 | DWH_dbo.Dim_Position |
| IsParent | int | Yes | Parent position flag | T2 | DWH_dbo.Dim_Position |
| OriginalPositionID | bigint | Yes | Original position ID in copy chain | T2 | DWH_dbo.Dim_Position |

## 4. Relationships
| Related Object | Relationship | Join Condition |
|----------------|--------------|----------------|
| DWH_dbo.Dim_Position | Position source | PositionID, AccountTypeID IN (7,13) |
| DWH_dbo.Dim_Customer | Employee filter | AccountTypeID IN (7,13), IsValidCustomer=0 |
| BI_DB_dbo.BI_DB_PositionPnL | Current P&L data | PositionID, Date |
| DWH_dbo.V_Liabilities | Account equity | CID, Date |
| BI_DB_dbo.DWH_GainDaily | Period gain metrics | CID, Date |
| DWH_dbo.Dim_Instrument | Instrument metadata | InstrumentID |
| DWH_dbo.Dim_Country | Country lookup | CountryID |

## 5. ETL Details
| Property | Value |
|----------|-------|
| **Primary SP** | `Dealing_dbo.SP_Employees_Report` |
| **Parameters** | `@Date DATE` |
| **Load Pattern** | DELETE + INSERT for @Date |
| **Population** | AccountTypeID IN (7,13) AND IsValidCustomer=0 |
| **Key Logic** | 1) Get employee CIDs. 2) Pull open positions (CloseDateID IS NULL as of @Date). 3) Pull closed positions (CloseDateID=@DateID). 4) Join BI_DB_PositionPnL for P&L/price data. 5) Join V_Liabilities for equity. 6) Join DWH_GainDaily for period gains. 7) Compute DailyPnL composite logic. 8) Compute aggregates (Total_daily_Volume, Total_daily_clicks). |

## 6. Data Lifecycle
- **Retention**: No automated cleanup
- **Volume**: ~231.4M rows — large; queries must filter on Date (clustered index)

## 7. Known Gaps
- Column name typos: `CopyTarde` (should be `CopyTrade`), `previos_Position_PnL` (should be `previous`)
- 231.4M rows is very large — HASH(CID) distribution helps CID-filtered queries
- `IsValidCustomer=0` filter means employees are excluded from all standard client metrics

## 8. Quality Score
**7.5/10** — Comprehensive employee position report with full P&L attribution. Typos in column names noted but documented. DailyPnL composite logic is a critical nuance.
