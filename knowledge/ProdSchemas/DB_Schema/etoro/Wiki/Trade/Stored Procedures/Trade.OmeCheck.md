# Trade.OmeCheck

> OME audit tool: for a set of instruments and a time window, finds the earliest price tick that would have triggered each position's Stop Loss or Take Profit, allowing operations to identify cases where the Order Management Engine may have missed a SL/TP execution.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID TVP + @begintime + @endtime |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.OmeCheck is an investigative tool for eToro's Order Management Engine (OME) audit. When a Stop Loss or Take Profit order should have been triggered but wasn't, operations teams use this procedure to confirm that a price tick crossing the threshold actually occurred during the relevant time window.

The procedure reconstructs the SL/TP trigger timeline: for each position that was active during the window (opened before @endtime, closed after @begintime or still open), it joins the position's change log (each SL/TP rate change creates a new interval) against the price feed (dbo.HistoryCurrencyPrice_Active) to find the first price tick where SL or TP conditions were met. The output shows the earliest trigger point per position, whether the position is still open or was closed, and the exact price at which it would have triggered.

Real positions use raw Bid/Ask prices; spread-adjusted positions (IsRealPosition=0) use BidSpreaded/AskSpreaded. SL condition for a buy: Bid drops below StopRate. TP condition for a buy: Bid rises above LimitRate. Reversed for sells.

---

## 2. Business Logic

### 2.1 Position and Price Data Loading

**What**: Loads active positions and their price history for the given instruments and time window.

**Columns/Parameters Involved**: `Trade.GetPositionDataSlim`, `dbo.HistoryCurrencyPrice_Active`, `Trade.FnIsRealPosition`, `@begintime`, `@endtime`

**Rules**:
- Positions: Trade.GetPositionDataSlim WHERE InstrumentID IN @InstrumentID AND InitDateTime < @endtime AND (CloseOccurred > @begintime OR CloseOccurred IS NULL).
  - Captures positions that were alive at any point in the window (opened before end, closed after start).
  - Cross apply Trade.FnIsRealPosition(IsSettled, InstrumentID): determines whether to use raw or spread-adjusted prices.
- Prices: dbo.HistoryCurrencyPrice_Active WHERE InstrumentID IN @InstrumentID AND Occurred BETWEEN @begintime AND @endtime.
- Both use OPTION(RECOMPILE) to avoid cached plans.
- Clustered indexes created on temp tables for join performance.

### 2.2 Position Change Log Interval Segmentation

**What**: Joins positions with their SL/TP change history to create per-interval (StopRate, LimitRate, time range) records.

**Columns/Parameters Involved**: `History.PositionChangeLog_Active.ChangeTypeID`, `History.PositionChangeLog_Active.StopRate`, `History.PositionChangeLog_Active.LimitRate`, `History.PositionChangeLog_Active.Occurred`

**Rules**:
- ChangeTypeID IN (0,1,2,6): open event and SL/TP rate change events.
- LEAD(Occurred, 1) OVER (PARTITION BY PositionID ORDER BY Occurred): computes OccurredTO - the end of each rate-validity interval (NULL for the last/current interval).
- Each row in #PostionChangeLog represents a period during which a specific (StopRate, LimitRate) pair was in effect for the position.

### 2.3 First SL/TP Trigger Detection

**What**: For each change-log interval, finds the chronologically first price tick that would have triggered SL or TP.

**Columns/Parameters Involved**: `#CurrencyPrice_Active.Bid`, `#CurrencyPrice_Active.Ask`, `#CurrencyPrice_Active.BidSpreaded`, `#CurrencyPrice_Active.AskSpreaded`, `Trade.FnIsRealPosition`

**Rules**:
- CROSS APPLY (SELECT TOP 1 ... ORDER BY Occurred): finds the first trigger within the interval (OccurredFrom <= Occurred <= OccurredTo).
- SL trigger conditions:
  - IsBuy=1, IsRealPosition=1: Bid < StopRate (real SL for long).
  - IsBuy=1, IsRealPosition=0: BidSpreaded < StopRate (spread SL for long).
  - IsBuy=0, IsRealPosition=1: Ask > StopRate (real SL for short).
  - IsBuy=0, IsRealPosition=0: AskSpreaded > StopRate (spread SL for short).
- TP trigger conditions:
  - IsBuy=0, IsRealPosition=1: Ask < LimitRate AND LimitRate > 0.01 (real TP for short).
  - IsBuy=0, IsRealPosition=0: AskSpreaded < LimitRate (same filter).
  - IsBuy=1, IsRealPosition=1: Bid > LimitRate AND LimitRate != 0 (real TP for long).
  - IsBuy=1, IsRealPosition=0: BidSpreaded > LimitRate (spread TP for long).

### 2.4 First-Interval Deduplication and Output

**What**: Returns only the first change-log interval per position where a trigger was detected.

**Columns/Parameters Involved**: `#step1.OccurredFrom`, `MinOccurredFrom`, `Trade.Position`

**Rules**:
- CROSS APPLY to get MIN(OccurredFrom) per PositionID across #step1.
- WHERE MinOccurredFrom = OccurredFrom: keeps only the earliest trigger interval per position (eliminates duplicate positions from multiple intervals).
- LEFT JOIN Trade.Position: PositionStatus='Open' if still in Trade.Position, 'close' if not.
- TriggerRate column: the actual price at the trigger moment (Bid/BidSpreaded/Ask/AskSpreaded based on direction and IsRealPosition).

**Diagram**:
```
PositionChangeLog intervals per position:
  [open at T0, SL=100] [SL changed to 95 at T1] [SL changed to 90 at T2]
        |
        v First price tick crossing threshold in each interval
  First trigger found -> MinOccurredFrom row kept -> output
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | Trade.IdIntList (READONLY TVP) | NO | - | CODE-BACKED | List of InstrumentIDs to audit. Each row has Id (int). All positions and price data filtered to this instrument set. |
| 2 | @begintime | datetime | NO | - | CODE-BACKED | Start of the audit time window. Positions must have CloseOccurred > @begintime (or be open). Price data filtered to Occurred >= @begintime. |
| 3 | @endtime | datetime | NO | - | CODE-BACKED | End of the audit time window. Positions must have InitDateTime < @endtime. Price data filtered to Occurred <= @endtime. PositionChangeLog events filtered to Occurred <= OccurredTO within the window. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.IdIntList | UDT Reference | TVP type for instrument batch |
| PositionID, InstrumentID | Trade.GetPositionDataSlim | Read | Active positions in time window with SL/TP/direction data |
| IsSettled, InstrumentID | Trade.FnIsRealPosition | CROSS APPLY | Determines real vs spread price selection per position |
| InstrumentID | dbo.HistoryCurrencyPrice_Active | Read | NOLOCK; price tick history for trigger detection |
| PositionID | History.PositionChangeLog_Active | Read | NOLOCK; SL/TP change history; ChangeTypeID IN (0,1,2,6) |
| PositionID | Trade.Position | LEFT JOIN/Read | Checks whether position is still open at query time |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No SP callers found) | - | - | Ad-hoc OME audit tool; called by operations/BI teams to investigate missed SL/TP executions. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OmeCheck (procedure)
├── Trade.IdIntList (TVP type)
├── Trade.GetPositionDataSlim (view)
├── Trade.FnIsRealPosition (function)
├── dbo.HistoryCurrencyPrice_Active (table)
├── History.PositionChangeLog_Active (table/view)
└── Trade.Position (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.IdIntList | User Defined Type | TVP parameter for instrument list |
| Trade.GetPositionDataSlim | View | Positions active in the time window |
| Trade.FnIsRealPosition | Function | Real vs spread price flag per position |
| dbo.HistoryCurrencyPrice_Active | Table | Price tick data for SL/TP trigger detection |
| History.PositionChangeLog_Active | Table | SL/TP rate change history for interval segmentation |
| Trade.Position | View | Open position check for PositionStatus output |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No dependents found) | - | Investigative reporting query; result set consumed by analyst. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Creates three inline temp-table indexes for join performance:
- `CIX ON #Position (PositionID)`
- `CIX ON #PostionChangeLog (OccurredFrom, IsBuy, InstrumentID)`
- `CIX ON #CurrencyPrice_Active (Occurred, InstrumentID, Bid, Ask, BidSpreaded, AskSpreaded)` (NOTE: three clustered index CIX names on different tables - valid in SQL Server as temp table index names are scoped to the table).

### 7.2 Constraints

N/A for stored procedure. No transaction (read-only). No TRY/CATCH. Uses DROP TABLE IF EXISTS at start to handle re-runs in the same session.

---

## 8. Sample Queries

### 8.1 Check positions with missed SL triggers for specific instruments over a time window

```sql
DECLARE @instruments Trade.IdIntList;
INSERT INTO @instruments VALUES (1234), (5678);
EXEC Trade.OmeCheck
    @InstrumentID = @instruments,
    @begintime = '2026-03-01 00:00:00',
    @endtime   = '2026-03-02 00:00:00';
```

### 8.2 Check position change log for SL/TP rate changes

```sql
SELECT PositionID, ChangeTypeID, StopRate, LimitRate, Occurred
FROM History.PositionChangeLog_Active WITH (NOLOCK)
WHERE PositionID = <PositionID>
  AND ChangeTypeID IN (0, 1, 2, 6)
ORDER BY Occurred;
```

### 8.3 Find prices crossing a StopRate for a buy position

```sql
SELECT InstrumentID, Occurred, Bid, BidSpreaded
FROM dbo.HistoryCurrencyPrice_Active WITH (NOLOCK)
WHERE InstrumentID = <InstrumentID>
  AND Occurred BETWEEN <OccurredFrom> AND <OccurredTo>
  AND Bid < <StopRate>
ORDER BY Occurred;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SP callers | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.OmeCheck | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.OmeCheck.sql*
