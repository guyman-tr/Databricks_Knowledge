# Dealing_dbo.Dealing_Employee_Zero_StocksETFs

> Daily eToro employee trading revenue ("Zero") per instrument, tracking the cumulative realized + unrealized P&L impact of employee account trading activity.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Derived — Dim_Position + BI_DB_PositionPnL for employee accounts |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

Dealing_Employee_Zero_StocksETFs calculates the daily eToro revenue ("Zero") generated from employee trading activity, broken down by instrument. "Zero" is eToro's internal term for the company's revenue from the spread and market-making side of client/employee positions.

Despite the table name suggesting "StocksETFs", the InstrumentTypeID filter was commented out in the SP, so it actually covers all 6 instrument types (Stocks, ETF, Crypto, Currencies, Commodities, Indices).

**Employee filter**: Accounts satisfying:
- `PlayerLevelID = 4` (employee level)
- `AccountTypeID IN (7, 13)` — Employee Account (7) and Analyst/CF employees (13)
- `AccountStatusID = 1` or NULL (active)
- `PlayerStatusID != 2` (not suspended)
- `CountryID = 250` (Israel)

~3.2M rows since Jan 2021. This data helps monitor whether employee trading generates or costs revenue for eToro's dealing operation.

---

## 2. Business Logic

### 2.1 Employee Zero Calculation

**What**: The eToro revenue impact (Zero) from employee positions, combining realized and unrealized components.

**Column**: `Employee_Zero`

**Rules**:
- **Realized** (positions closed today):
  - Same-day open+close: `NetProfit + FullCommissionOnClose`
  - Multi-day close: `NetProfit - PreviousDayPositionPnL + FullCommissionOnClose - FullCommissionByUnits`
- **Unrealized** (positions still open at EOD):
  - Same-day open: `DailyPnL + FullCommissionByUnits`
  - Multi-day open: `DailyPnL`
- Final: `SUM(CalculatedZero)` across all realized + unrealized positions for each instrument
- Positive = eToro revenue from employee positions; Negative = eToro cost

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on Date. ~3.2M rows.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total employee Zero for a date | `WHERE Date = @Date` then `SUM(Employee_Zero)` |
| Employee Zero by instrument type | `WHERE Date = @Date GROUP BY InstrumentType` |
| Monthly employee Zero trend | `GROUP BY YEAR(Date), MONTH(Date) ORDER BY 1,2` |

### 3.3 Gotchas

- **Table name is misleading**: It covers ALL instrument types despite "StocksETFs" in the name (the InstrumentTypeID filter was commented out)
- **Employee_Zero can be negative**: This means eToro lost money on the dealing side of employee positions
- **CountryID=250 filter**: Only Israeli employees. Non-Israel employees may be excluded.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Reporting date. (Tier 2 — SP_Employee_Zero_StocksETFs) |
| 2 | Employee_Zero | decimal(16,6) | YES | Total eToro revenue ("Zero") from employee positions for this instrument on this date. `SUM(RealizedZero + UnrealizedZero)`. Positive=eToro revenue, negative=eToro cost. (Tier 2 — SP_Employee_Zero_StocksETFs) |
| 3 | UpdateDate | datetime | YES | ETL load timestamp — `GETDATE()`. (Tier 2 — SP_Employee_Zero_StocksETFs) |
| 4 | InstrumentID | int | YES | Instrument identifier. From Dim_Position, grouped at instrument level. (Tier 2 — SP_Employee_Zero_StocksETFs) |
| 5 | InstrumentType | varchar(50) | YES | Asset class from Dim_Instrument.InstrumentType. 6 types despite table name suggesting only Stocks/ETF. (Tier 2 — SP_Employee_Zero_StocksETFs) |

---

## 5. Lineage

Full lineage: see [Dealing_Employee_Zero_StocksETFs.lineage.md](Dealing_Employee_Zero_StocksETFs.lineage.md)

| Step | Object | Description |
|------|--------|-------------|
| Source | Fact_SnapshotCustomer | Employee account identification (PlayerLevelID=4, AccountTypeID IN 7,13) |
| Source | Dim_Position | Position lifecycle, NetProfit, FullCommission |
| Source | BI_DB_PositionPnL | DailyPnL, PositionPnL for Zero calculation |
| Source | Dim_Instrument | InstrumentType |
| ETL | SP_Employee_Zero_StocksETFs | Compute realized + unrealized Zero per instrument |
| Target | Dealing_Employee_Zero_StocksETFs | Daily employee Zero by instrument |

---

*Generated: 2026-03-21 | Quality: 7.5/10 (★★★★☆) | Phases: 9/14*
*Tiers: 0 T1, 5 T2, 0 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 5/10, Sources: 7/10*
*Object: Dealing_dbo.Dealing_Employee_Zero_StocksETFs | Type: Table | Production Source: Derived (employee positions)*
