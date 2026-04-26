---
object: BI_DB_dbo.BI_DB_CryptoDashboardNew
type: Table
lineage_generated: 2026-04-23
writer_sp: SP_BI_DB_CryptoDashboardNew
load_pattern: DELETE WHERE DateID=@dateID + INSERT (daily incremental per date)
uc_target: _Not_Migrated
---

# Column Lineage — BI_DB_CryptoDashboardNew

## ETL Pipeline

```
Instrument scope: Dim_Instrument WHERE InstrumentTypeID=10 (Real Crypto ONLY)

DWH_dbo.Fact_SnapshotCustomer + Dim_Range + Dim_Country + Dim_Regulation + Dim_PlayerLevel + Dim_Customer
  └─ Population: IsValidCustomer=1, IsDepositor=1, PlayerLevelID<>4 (exclude Internal)
  └─ → #pop (CID, CountryID, RegulationID, Country, Regulation, Club, Seniority_daily_FTD_Group)
     └─ Seniority = DATEDIFF(DAY, Dim_Customer.FirstDepositDate, @date) bucketed into 10 groups
DWH_dbo.Dim_Instrument (InstrumentTypeID=10)
  └─ → #diminstrument (crypto instruments, BuyCurrency)
DWH_dbo.Dim_Position + #pop + #diminstrument (open at @date)
  └─ → #dimposition (open crypto positions: OpenDateID<=@dateID, CloseDateID=0 OR >=@dateID)
     └─ Real_CFD = CASE WHEN IsSettled=1 THEN 'Real' ELSE 'CFD'
     └─ Manual_Copy = CASE WHEN MirrorID=0 THEN 'Manual' ELSE 'Copy'
BI_DB_dbo.BI_DB_PositionPnL (DateID=@dateID, InstrumentTypeID=10)
  └─ → #positionpnl (daily PnL snapshot for open crypto positions)
     └─ AUA = SUM(Amount + PositionPnL), Amount_in_Units, PnL
DWH_dbo.Fact_CustomerAction (DateID=@dateID, ActionTypeID IN 1,2,3,4,5,6,35,39,40)
  └─ → #CustomerAction (crypto trades, commissions, rollover fees)
DWH_dbo.Fact_FirstCustomerAction (ActionTypeID IN 1,17, FirstEver=1, DateID=@dateID)
  └─ → #FA: num_of_FA_Crypto=1 per new crypto customer today, FA_Amount_Total = SUM(-Amount)
#dimposition (OpenDateID=@dateID, IsPartialCloseChild=0)
  └─ → #posnum: Opened_Positions = COUNT positions opened today
#positionpnl
  └─ → #openposnum: Open_Positions = COUNT open positions at @date (per CID/BuyCurrency/Real_CFD/Manual_Copy)
  └─ → #activehold: Active_Hold/Real/CFD = COUNT DISTINCT CID (date-level scalars)
#CustomerAction (ActionTypeID=35, IsFeeDividend=1)
  └─ → #rolloverfee: RollOver = SUM(Amount*-1)
#CustomerAction (ActionTypeID IN 1,2,3,4,5,6,39,40) → #OpenCommission + #CloseCommission → #Commission
  └─ Revenue = FullTotalCommission + RollOver
DWH_dbo.Dim_Date (DateKey=@dateID)
  └─ DayName, SSWeekNumberOfMonth, DayNumberOfWeek_Sun_Start, IsLastDayOfMonth
  └─ YearWeek = YEAR(@date)*100 + SSWeekNumberOfYear
  └─ WeekofMonth = CONVERT(CHAR(8),YEAR(@date),112)*10000 + MONTH(@date)*100 + SSWeekNumberOfMonth
  ↓
SP_BI_DB_CryptoDashboardNew (@date)
  DELETE WHERE DateID=@dateID + INSERT (no filter — all crypto positions)
  ↓
BI_DB_dbo.BI_DB_CryptoDashboardNew
  (UC: _Not_Migrated)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|--------------|-----------|------|
| 1 | Date | SP param | @date | Direct passthrough | Tier 2 |
| 2 | DateID | SP computed | @date | CONVERT(CHAR(8),@date,112) AS INT | Tier 2 |
| 3 | DayName | Dim_Date | DayName | Passthrough via JOIN on DateKey | Tier 2 |
| 4 | SSWeekNumberOfMonth | Dim_Date | SSWeekNumberOfMonth | Passthrough via JOIN on DateKey | Tier 2 |
| 5 | YearWeek | Dim_Date + SP | SSWeekNumberOfYear | YEAR(@date)*100 + SSWeekNumberOfYear | Tier 2 |
| 6 | DayNumberOfWeek_Sun_Start | Dim_Date | DayNumberOfWeek_Sun_Start | Passthrough via JOIN on DateKey | Tier 2 |
| 7 | WeekofMonth | SP computed | @date + SSWeekNumberOfMonth | CONVERT(CHAR(8),YEAR(@date),112)*10000 + MONTH(@date)*100 + SSWeekNumberOfMonth | Tier 2 |
| 8 | IsLastDayOfMonth | Dim_Date | IsLastDayOfMonth | Passthrough via JOIN on DateKey | Tier 2 |
| 9 | Regulation | Dim_Regulation | Name | JOIN via Fact_SnapshotCustomer.RegulationID → Dim_Regulation.DWHRegulationID | Tier 1 |
| 10 | Country | Dim_Country | Name | JOIN via Fact_SnapshotCustomer.CountryID → Dim_Country.CountryID | Tier 1 |
| 11 | BuyCurrency | Dim_Instrument | BuyCurrency | Crypto ticker symbol (BTC, ETH, XRP, etc.) for InstrumentTypeID=10 | Tier 2 |
| 12 | Real_CFD | Dim_Position | IsSettled | CASE WHEN IsSettled=1 THEN 'Real' ELSE 'CFD' | Tier 2 |
| 13 | Manual_Copy | Dim_Position | MirrorID | CASE WHEN MirrorID=0 THEN 'Manual' ELSE 'Copy' | Tier 2 |
| 14 | AUA | BI_DB_PositionPnL | Amount + PositionPnL | SUM(Amount + PositionPnL) — current market value of open positions | Tier 2 |
| 15 | Amount_in_Units | BI_DB_PositionPnL | AmountInUnitsDecimal | SUM of position size in crypto units | Tier 2 |
| 16 | PnL | BI_DB_PositionPnL | PositionPnL | SUM(PositionPnL) — unrealized P&L on open positions | Tier 2 |
| 17 | Revenue | Fact_CustomerAction | FullCommission + rollover | ISNULL(FullTotalCommission,0) + ISNULL(RollOver,0) = open/close commissions + rollover fees | Tier 2 |
| 18 | num_of_FA_Crypto | Fact_FirstCustomerAction | FirstEver=1, ActionTypeID=1 | Count of new crypto customers who made their first-ever trade today | Tier 2 |
| 19 | FA_Amount_Total | Fact_FirstCustomerAction | Amount | SUM(-Amount) for first-action crypto customers on @date | Tier 2 |
| 20 | Opened_Positions | Dim_Position | OpenDateID=@dateID | COUNT(*) positions opened today (IsPartialCloseChild=0) | Tier 2 |
| 21 | Open_Positions | BI_DB_PositionPnL | PositionID | COUNT(*) open positions at @date per segment | Tier 2 |
| 22 | Active_Hold_by_Inst | BI_DB_PositionPnL | CID | COUNT DISTINCT CID per (BuyCurrency, Real_CFD, Manual_Copy) — segment-level unique holders | Tier 2 |
| 23 | UpdateDate | SP | GETDATE() | ETL run timestamp | Propagation |
| 24 | Active_Hold | BI_DB_PositionPnL | CID | COUNT DISTINCT CID with any open crypto position at @date — date-level scalar broadcast to all rows | Tier 2 |
| 25 | Active_Hold_Real | BI_DB_PositionPnL | CID | COUNT DISTINCT CID with Real (IsSettled=1) open crypto position at @date — date-level scalar | Tier 2 |
| 26 | Active_Hold_CFD | BI_DB_PositionPnL | CID | COUNT DISTINCT CID with CFD (IsSettled≠1) open crypto position at @date — date-level scalar | Tier 2 |
| 27 | Club | Dim_PlayerLevel | Name | Loyalty tier name (Bronze/Silver/Gold/Platinum/Platinum Plus/Diamond) — from Fact_SnapshotCustomer.PlayerLevelID | Tier 1 |
| 28 | Seniority_daily_FTD_Group | Dim_Customer | FirstDepositDate | DATEDIFF(DAY, FirstDepositDate, @date) bucketed: 0, 1-4, 5-7, 8-14, 15-30, 31-91, 92-183, 184-365, 366-730, 731+, No deposits | Tier 2 |
