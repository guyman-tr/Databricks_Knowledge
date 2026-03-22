# BI_DB_dbo.BI_DB_VarCommission

## 1. Overview

Daily **variable commission** (spread-based) tracking by instrument. Compares the actual spread-based commission earned versus the fixed commission charged, broken down by openings and closings. Used by finance to analyze commission revenue composition and hedge server attribution.

**Row grain**: One InstrumentID + InstrumentType + IsSettled + HedgeServerID per DateID

---

## 2. Business Context

Commission revenue has two components: **FullCommission** (the fixed commission charged to the customer) and **VarCommission** (the actual spread revenue: `Units * (Ask - Bid) * USD conversion`). The difference between them represents the spread markup or deficit.

**Key business rules**:
- **VarCommission formula (openings)**: `AmountInUnitsDecimal * (InitForex_Ask - InitForex_Bid) * USDConversionRate`
- **VarCommission formula (closings)**: `AmountInUnitsDecimal * (EndForex_Ask - EndForex_Bid) * USDConversionRate`
- **Same-day open+close**: Position opened and closed on @DateID gets both FullCommissionOnClose and full spread calculation.
- **Customer filter**: `IsValidCustomer = 1` (via Dim_Customer, not Fact_SnapshotCustomer).
- **Position filter**: Only positions opened OR closed on @DateID with non-null forex rates.
- **HedgeServerID**: From `Dim_PositionHedgeServerChangeLog_Snapshot` (LEFT JOIN, fallback to Dim_Position.HedgeServerID). Identifies which hedge server executed the trade.
- **Calendar fields**: CalendarYearMonth and MonthName from Dim_Date via CROSS JOIN.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 16 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | DateID ASC |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Calendar date. From SP @Date parameter. (Tier 2 -- SP_VarCommission, @Date) |
| 2 | DateID | int | YES | Date as integer YYYYMMDD. Clustered index. (Tier 2 -- SP_VarCommission, @Date) |
| 3 | InstrumentType | varchar(50) | YES | Instrument type from Dim_Instrument.InstrumentType. Values: "Stocks", "Currencies", "Indices", "Commodities", "Crypto", "ETFs". (Tier 2 -- SP_VarCommission, Dim_Instrument.InstrumentType) |
| 4 | CalendarYearMonth | char(7) | YES | Year-month from Dim_Date.CalendarYearMonth. Format: "2025-04". (Tier 2 -- SP_VarCommission, Dim_Date.CalendarYearMonth) |
| 5 | MonthName | varchar(10) | YES | Month name from Dim_Date.MonthName. Values: "January", "February", etc. (Tier 2 -- SP_VarCommission, Dim_Date.MonthName) |
| 6 | IsSettled | int | YES | Settlement flag from Dim_Position. 1 = real/settled, 0 = CFD. (Tier 2 -- SP_VarCommission, Dim_Position.IsSettled) |
| 7 | FullCommission | money | YES | Total fixed commission charged. Combines opening (FullCommissionByUnits) and closing (FullCommissionOnClose) commissions. (Tier 2 -- SP_VarCommission, Dim_Position) |
| 8 | VarCommission | money | YES | Total spread-based commission (variable). `Units * Spread * USDRate` for both openings and closings. (Tier 2 -- SP_VarCommission, computed from Dim_Position forex fields) |
| 9 | VarCommission_Openings | money | YES | Spread-based commission from positions opened on this date only. (Tier 2 -- SP_VarCommission, computed) |
| 10 | FullCommission_Openings | money | YES | Fixed commission from positions opened on this date only. FullCommissionByUnits. (Tier 2 -- SP_VarCommission, Dim_Position.FullCommissionByUnits) |
| 11 | UpdateDate | datetime | YES | SP execution timestamp. GETDATE(). (Tier 3 -- SP_VarCommission, GETDATE()) |
| 12 | InstrumentID | int | YES | Instrument identifier from Dim_Position. (Tier 2 -- SP_VarCommission, Dim_Position.InstrumentID) |
| 13 | InstrumentName | varchar(50) | YES | Instrument name from Dim_Instrument.Name. (Tier 2 -- SP_VarCommission, Dim_Instrument.Name) |
| 14 | VarCommission_Closings | money | YES | Spread-based commission from positions closed on this date only. (Tier 2 -- SP_VarCommission, computed) |
| 15 | FullCommission_Closings | money | YES | Fixed commission from positions closed on this date only. FullCommissionOnClose. (Tier 2 -- SP_VarCommission, Dim_Position.FullCommissionOnClose) |
| 16 | HedgeServerID | int | YES | Hedge server that executed the trade. From Dim_PositionHedgeServerChangeLog_Snapshot (fallback: Dim_Position.HedgeServerID). (Tier 2 -- SP_VarCommission, ISNULL(Snapshot.HedgeServerID, Dim_Position.HedgeServerID)) |

---

## 5. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|-------------|
| Dim_Position | DWH_dbo | Primary -- position commissions, forex rates, open/close dates |
| Dim_Instrument | DWH_dbo | Instrument metadata (type, name, SellCurrencyID) |
| Dim_Customer | DWH_dbo | Customer validity (IsValidCustomer=1) |
| Dim_PositionHedgeServerChangeLog_Snapshot | DWH_dbo | Hedge server assignment (LEFT JOIN) |
| Dim_Date | DWH_dbo | Calendar fields (CalendarYearMonth, MonthName) |

---

## 6. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_VarCommission |
| **Author** | Jenia Simonovitch (2020-10-18) |
| **ETL Pattern** | DELETE-INSERT by DateID |
| **Grain** | InstrumentID + InstrumentType + IsSettled + HedgeServerID per DateID |
| **Schedule** | Daily (SB_Daily, Priority 99 -- FinanceReportSPS) |
| **Parameter** | @Date (DATE) |
| **Delete Scope** | `DELETE WHERE DateID = @DateID` |
| **Architecture** | #Month (calendar) CROSS JOIN with #Commissions (aggregated positions) -> INSERT |

---

## 7. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **Filter on DateID** | Clustered index on DateID. |
| **VarCommission vs FullCommission** | VarCommission is spread-based (market dependent), FullCommission is fixed. Compare for spread analysis. |
| **Same-day positions** | Positions opened and closed on the same day appear in both _Openings and _Closings columns. |
| **HedgeServerID** | May change over a position's lifetime; this table captures the server at time of trade (via snapshot). |
| **SellCurrencyID=1** | USD-denominated instruments skip the USDConversionRate multiplication. |

---

## 8. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Finance / Commission Revenue |
| **Sub-domain** | Variable Commission Analysis |
| **Sensitivity** | Instrument-level aggregate -- low PII risk |
| **Owner** | Finance team |
| **Quality Score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 4, Object #8*
*Phases: P1, P2, P8, P9 | Skipped: P3-P7, P9B, P10, P10.5*
