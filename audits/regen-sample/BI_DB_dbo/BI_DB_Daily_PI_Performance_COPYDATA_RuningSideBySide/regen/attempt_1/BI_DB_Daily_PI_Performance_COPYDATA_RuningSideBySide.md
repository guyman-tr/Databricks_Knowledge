# BI_DB_dbo.BI_DB_Daily_PI_Performance_COPYDATA_RuningSideBySide

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Column Count** | 21 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | `(Date ASC)` |
| **Row Count** | 56,837 |
| **Date Range** | 2024-02-12 – 2024-03-15 |
| **Writer SP** | `BI_DB_dbo.SP_Daily_PI_Performance_COPYDATA_RuningSideBySide` |
| **Production Source** | BI_DB_PI_Dashboard + BI_DB_CopyDailyData + BI_DB_PositionPnL + DWH layer |

---

## 1. Business Meaning

Daily snapshot of Popular Investor (PI) performance, run in parallel alongside the main PI performance table ("Running Side By Side") for validation or migration purposes. Each row represents one PI on a given reporting date, capturing their tier, top portfolio position by weight, last-day/YTD/MTD returns, copy AUM, copier count, and net mirror inflows. The table holds 56,837 rows for 2024-02-12 to 2024-03-15 (~3,221 distinct PIs). It is written daily by `SP_Daily_PI_Performance_COPYDATA_RuningSideBySide @yesterday` via DELETE+INSERT. The PI population is drawn from `BI_DB_dbo.BI_DB_PI_Dashboard` filtered to `PI/CP='PI'`.

---

## 2. Business Logic

### 2.1 Top Position by Portfolio Weight

For each PI, the SP selects the single instrument with the highest `Value_percenet` across all open positions in `BI_DB_PositionPnL` on `@yesterdayINT`. Position values are summed per InstrumentID as `SUM(Amount + PositionPnL)`, then divided by `(Total_Position_Value + V_Liabilities.Credit)` to compute the fractional weight. `ROW_NUMBER() OVER (PARTITION BY CID ORDER BY Value_percenet DESC)` picks the top instrument; `Lev_weighted_average` is the amount-weighted average leverage across that instrument's positions.

### 2.2 Net Mirror Inflow (NetMoneyIn)

For each PI acting as copy leader (`Dim_Mirror.ParentCID = PI.CID`), `NetMoneyIn = -1 * SUM(Fact_CustomerAction.Amount)` for `ActionTypeID IN (15,16,17,18)` (Mirror In, Mirror Out, New Mirror, UnMirror) on `@yesterdayINT`. Positive values indicate net capital inflow toward the PI; negative indicates net outflow.

---

## 3. Structure

### 3.1 Distribution & Index

ROUND_ROBIN distribution; always filter on `Date` or `DateINT` to avoid full-table scans. The clustered index on `Date ASC` supports efficient range filtering by reporting date.

### 3.2 Common Query Patterns

| Question | Approach |
|----------|----------|
| Latest PI snapshot | `WHERE DateINT = 20240315 ORDER BY CopyEquity DESC` |
| PIs with net mirror inflows | `WHERE DateINT = X AND NetMoneyIn > 0` |
| Filter by strategy | `WHERE DateINT = X AND Classification = 'ETF'` |

### 3.3 Common JOINs

| Join To | Condition | Purpose |
|---------|-----------|---------|
| BI_DB_dbo.BI_DB_CopyDailyData | `ON CID AND DateID = DateINT` | Full daily PI attributes |
| DWH_dbo.Dim_Customer | `ON CID = RealCID` | Customer demographics |
| BI_DB_dbo.BI_DB_PI_Dashboard | `ON CID AND Date` | Full PI dashboard metrics |

### 3.4 Gotchas

- `Value_percenet` (typo — should be `Value_percent`) is the portfolio weight of the PI's **single largest position only**, not a sum across all holdings
- Latest row date is 2024-03-15; the "RuningSideBySide" (sic) naming suggests this was a temporary validation table and may no longer be actively loaded
- `NetMoneyIn` reflects mirror-flow capital to/from the PI as a **copy leader** — it is not the PI's own deposit/withdrawal activity
- `IsBlocked`, `Classification`, and `TraderType` pass through from `BI_DB_PI_Dashboard` (unresolved upstream); treat as informational until confirmed

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Reporting date (business day covered = @yesterday SP parameter). (Tier 2 — SP_Daily_PI_Performance_COPYDATA_RuningSideBySide, @yesterday) |
| 2 | DateINT | int | YES | Reporting date as YYYYMMDD integer: CONVERT(CHAR(8),@yesterday,112). (Tier 2 — SP_Daily_PI_Performance_COPYDATA_RuningSideBySide, @yesterdayINT) |
| 3 | CID | int | NO | Popular Investor customer ID sourced from BI_DB_PI_Dashboard (no upstream wiki resolved for that table). (Tier 3 — BI_DB_PI_Dashboard, no upstream wiki) |
| 4 | UserName | varchar(20) | YES | PI login username sourced from BI_DB_PI_Dashboard (no upstream wiki resolved). (Tier 3 — BI_DB_PI_Dashboard, no upstream wiki) |
| 5 | PI_level | varchar(50) | YES | PI program tier name (Cadet, Rising Star, Champion, Elite, Elite Pro) sourced from BI_DB_PI_Dashboard (no upstream wiki resolved). (Tier 3 — BI_DB_PI_Dashboard, no upstream wiki) |
| 6 | Acc_RiskIndex | int | YES | Account-level risk classification index sourced from BI_DB_PI_Dashboard; ultimate origin is BI_DB_User_Segment_Snapshot (no upstream wiki resolved). (Tier 3 — BI_DB_PI_Dashboard, no upstream wiki) |
| 7 | IsBlocked | varchar(20) | YES | PI account blocked flag ('No' / 'Yes') sourced from BI_DB_PI_Dashboard (no upstream wiki resolved). (Tier 3 — BI_DB_PI_Dashboard, no upstream wiki) |
| 8 | Classification | nvarchar(50) | YES | PI investment strategy label (Long Equity, Multi-Strategy, ETF, Crypto, Long/Short Equity, Currencies, Commodities, 100% cash balance) sourced from BI_DB_PI_Dashboard (no upstream wiki resolved). (Tier 3 — BI_DB_PI_Dashboard, no upstream wiki) |
| 9 | TraderType | nvarchar(50) | YES | PI trading style label (Long term investor, Medium term investor, Swing trader, Day trader) sourced from BI_DB_PI_Dashboard (no upstream wiki resolved). (Tier 3 — BI_DB_PI_Dashboard, no upstream wiki) |
| 10 | SymbolFull | varchar(100) | YES | Full/canonical symbol, UNIQUE in production. Used for instrument lookup. Primary identifier in Security Ops API. (Tier 1 — DWH_dbo.Dim_Instrument via Trade.InstrumentMetaData) |
| 11 | Value_percenet | decimal(38,6) | YES | Portfolio weight of the PI's top position: ROUND(Position_Value / (Total_Position_Value + Credit), 3) where Position_Value = SUM(Amount + PositionPnL) from BI_DB_PositionPnL. (Tier 2 — SP_Daily_PI_Performance_COPYDATA_RuningSideBySide, BI_DB_PositionPnL + V_Liabilities.Credit) |
| 12 | Lev_weighted_average | money | YES | Amount-weighted average leverage for the PI's top-ranked instrument: COALESCE(SUM(Leverage*Amount)/NULLIF(SUM(Amount),0),0). (Tier 2 — SP_Daily_PI_Performance_COPYDATA_RuningSideBySide, BI_DB_PositionPnL.Leverage + Amount) |
| 13 | Last_Day_Performance | float | YES | PI's last-day return as a decimal fraction sourced from BI_DB_PI_Dashboard (no upstream wiki resolved). (Tier 3 — BI_DB_PI_Dashboard, no upstream wiki) |
| 14 | YTD | float | YES | PI's year-to-date return as a decimal fraction sourced from BI_DB_PI_Dashboard (no upstream wiki resolved). (Tier 3 — BI_DB_PI_Dashboard, no upstream wiki) |
| 15 | MTD | float | YES | PI's month-to-date return as a decimal fraction sourced from BI_DB_PI_Dashboard (no upstream wiki resolved). (Tier 3 — BI_DB_PI_Dashboard, no upstream wiki) |
| 16 | CopyEquity | money | NO | Total AUM managed by this PI through copy relationships: ISNULL(SUM(Cash+Investment+PnL+DetachedPosInvestment+Dit_PnL), 0). Source: etoroGeneral_History_GuruCopiers. (Tier 1 — BI_DB_CopyDailyData.CopyAUM via etoroGeneral_History_GuruCopiers) |
| 17 | NumOfCopiers | int | NO | Number of valid depositor customers currently copying this PI as of @date. Source: COUNT(*) from etoroGeneral_History_GuruCopiers. (Tier 1 — BI_DB_CopyDailyData.NumOfCopiers via etoroGeneral_History_GuruCopiers) |
| 18 | NetMoneyIn | decimal(38,2) | NO | Net mirror-flow amount for the PI as copy leader on @yesterday: -1*SUM(Amount) for ActionTypeID IN (15,16,17,18); positive = net inflow toward the PI. (Tier 2 — SP_Daily_PI_Performance_COPYDATA_RuningSideBySide, DWH_dbo.Fact_CustomerAction via Dim_Mirror) |
| 19 | UpdateDate | datetime | NO | ETL row-load timestamp set to GETDATE() at SP execution. (Tier 2 — SP_Daily_PI_Performance_COPYDATA_RuningSideBySide, GETDATE()) |
| 20 | Manager | varchar(50) | YES | Account manager display name: FirstName + ' ' + LastName from Dim_Manager. (Tier 1 — BI_DB_CopyDailyData.Manager via DWH_dbo.Dim_Manager) |
| 21 | Country | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 — BI_DB_CopyDailyData.Country via DWH_dbo.Dim_Country) |

---

## 5. Lineage

### 5.1 Production Sources

| Source | Role |
|--------|------|
| BI_DB_dbo.BI_DB_PI_Dashboard | PI population and performance metrics (CID, UserName, PI_level, performance KPIs) |
| BI_DB_dbo.BI_DB_PositionPnL | Open positions for top-position weight calculation |
| DWH_dbo.Dim_Instrument | SymbolFull lookup (passthrough, Trade.InstrumentMetaData) |
| DWH_dbo.V_Liabilities | Credit denominator for Value_percenet |
| DWH_dbo.Fact_CustomerAction | Mirror flow events (ActionTypeID 15–18) for NetMoneyIn |
| DWH_dbo.Dim_Mirror | Maps MirrorID → ParentCID to identify the PI as copy leader |
| DWH_dbo.Dim_Customer | PI validation (GuruStatusID ≥ 2, IsValidCustomer=1) |
| BI_DB_dbo.BI_DB_CopyDailyData | CopyEquity (from CopyAUM), NumOfCopiers, Manager, Country |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_PI_Dashboard (WHERE Date=@yesterday AND [PI/CP]='PI')
  → #pop (CID, UserName, PI_level, Acc_RiskIndex, IsBlocked, Classification,
           TraderType, Last_Day_Performance, YTD, MTD)

BI_DB_dbo.BI_DB_PositionPnL (WHERE DateID=@yesterdayINT) JOIN #pop
  + DWH_dbo.Dim_Instrument (SymbolFull)
  → #position_Inst_sum → #position_sum
  + DWH_dbo.V_Liabilities (Credit, WHERE DateID=@yesterdayINT)
  → #positionvalue (Value_percenet per CID+InstrumentID)
  → #TopPositionValue (top instrument per CID by Value_percenet)

DWH_dbo.Fact_CustomerAction (WHERE ActionTypeID BETWEEN 15 AND 18, DateID=@yesterdayINT)
  JOIN DWH_dbo.Dim_Mirror (MirrorID → ParentCID)
  JOIN DWH_dbo.Dim_Customer (PI validation)
  → #NetMoneyIn (RealCID, NetMoneyIn = -1*SUM(Amount))

BI_DB_dbo.BI_DB_CopyDailyData (WHERE DateID=@yesterdayINT)
  → #copydata (CopyAUM, NumOfCopiers, Manager, Country)
    |
    v
SP_Daily_PI_Performance_COPYDATA_RuningSideBySide @yesterday:
  DELETE WHERE DateINT=@yesterdayINT
  INSERT JOIN #pop + #TopPositionValue + #NetMoneyIn + #copydata
    v
BI_DB_dbo.BI_DB_Daily_PI_Performance_COPYDATA_RuningSideBySide
  (ROUND_ROBIN, CLUSTERED INDEX Date ASC)
```

Idempotent daily load: DELETE+INSERT on `DateINT` replaces the day's rows on re-run.

---

## 6. Relationships

### 6.1 References To (ETL read path)

| Object | Schema | Column Link | Purpose |
|--------|--------|-------------|---------|
| BI_DB_PI_Dashboard | BI_DB_dbo | CID, Date | PI population and performance metrics |
| BI_DB_PositionPnL | BI_DB_dbo | CID + DateID | Open position data |
| Dim_Instrument | DWH_dbo | InstrumentID | SymbolFull |
| V_Liabilities | DWH_dbo | CID + DateID | Credit for position weight denominator |
| Fact_CustomerAction | DWH_dbo | MirrorID + DateID | Mirror flow amounts |
| Dim_Mirror | DWH_dbo | MirrorID → ParentCID | Copy leader mapping |
| Dim_Customer | DWH_dbo | RealCID | PI validation |
| BI_DB_CopyDailyData | BI_DB_dbo | CID + DateID | CopyAUM, NumOfCopiers, Manager, Country |

### 6.2 Referenced By

No views or stored procedures found referencing this table (P7 scan returned 0 results).

---

## 7. Sample Queries

Latest PI snapshot ranked by copy equity.
```sql
SELECT CID, UserName, PI_level, Country, Manager,
       SymbolFull, Value_percenet, Lev_weighted_average,
       Last_Day_Performance, YTD, MTD,
       CopyEquity, NumOfCopiers, NetMoneyIn
FROM [BI_DB_dbo].[BI_DB_Daily_PI_Performance_COPYDATA_RuningSideBySide]
WHERE DateINT = 20240315
ORDER BY CopyEquity DESC;
```

PIs with positive net mirror inflows filtered by ETF classification.
```sql
SELECT CID, UserName, SymbolFull, Value_percenet,
       CopyEquity, NumOfCopiers, NetMoneyIn,
       Last_Day_Performance, YTD
FROM [BI_DB_dbo].[BI_DB_Daily_PI_Performance_COPYDATA_RuningSideBySide]
WHERE DateINT = 20240315
  AND NetMoneyIn > 0
  AND Classification = 'ETF'
ORDER BY NetMoneyIn DESC;
```

---

## 8. Atlassian Knowledge

- No Confluence pages or Jira issues found mentioning this table by name.
- The "RuningSideBySide" naming (sic) pattern suggests a parallel-run validation deployment — contact the BI/Data Platform team for context on whether this table is still active.

---

*Generated: 2026-04-28 | Regen Harness Attempt 1*
*Object: BI_DB_dbo.BI_DB_Daily_PI_Performance_COPYDATA_RuningSideBySide | Type: Table*
*Production Source: BI_DB_PI_Dashboard + BI_DB_CopyDailyData + DWH layer via SP_Daily_PI_Performance_COPYDATA_RuningSideBySide*
