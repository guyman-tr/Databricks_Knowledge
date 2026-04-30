# Trade.GetPositionsForDataApi

> Returns open and closed position records matching a time window and optional filters (GCID, ApexID, instrument type, country), combining live Trade.Position with historical History.PositionSlim for a unified position feed consumed by EngineDataApi.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartTime/@EndTime window; optional TVP filters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides a complete position data feed (both open and closed positions) for the EngineDataApi service. For each position that was opened OR closed within the specified time window, it returns core position attributes including instrument, direction, leverage, settlement type, SL/TP rates, and customer identifiers (GCID, ApexID, CountryID). The data is used for position tracking, analytics, and compliance reporting in downstream systems.

Unlike `Trade.GetPositionsChangesForDataApi` (which surfaces change log events from History.PositionChangeLog_Active), this procedure surfaces position-level snapshots: the state of each position at open (or the full lifecycle if closed). It answers the question "what positions were touched in this period?" rather than "what changes happened?"

Data flows: Read Uncommitted isolation. UNION of: (1) `Trade.Position` view for currently open positions opened in the window; (2) `History.PositionSlim` for closed positions where OpenOccurred or CloseOccurred falls in the window. Both sources are joined to `Trade.InstrumentMetaData` (Cusip, InstrumentTypeID) and `Customer.CustomerStatic` (GCID, ApexID, CountryID, requires ApexID IS NOT NULL). Consumer: EngineDataApi service (EXECUTE permission granted).

---

## 2. Business Logic

### 2.1 One-Month Time Window Constraint

**What**: Maximum 32-day range enforced to protect performance on large open/closed position tables.

**Columns/Parameters Involved**: `@StartTime`, `@EndTime`

**Rules**:
- ABS(DATEDIFF(DAY, @StartTime, @EndTime)) > 32 raises error 16 ("Data range must be up to one month").
- Contrast with GetPositionsChangesForDataApi which limits to 1 day.
- Open positions: filter on Trade.Position.Occurred (open date) BETWEEN @StartTime AND @EndTime.
- Closed positions: History.PositionSlim.OpenOccurred BETWEEN @StartTime AND @EndTime OR CloseOccurred BETWEEN @StartTime AND @EndTime - a position appears if EITHER its open OR close falls in the window.

### 2.2 Open and Closed Position UNION

**What**: A single result set merging currently open positions with historical closed positions.

**Columns/Parameters Involved**: `CloseOccurred`, `EndForexRate`

**Rules**:
- Open positions (from Trade.Position): CloseOccurred = NULL, EndForexRate = NULL.
- Closed positions (from History.PositionSlim): CloseOccurred = actual close time, EndForexRate = closing rate.
- Both sources must have ApexID IS NOT NULL (INNER JOIN to CustomerStatic with this condition).
- Ordered by OpenOccurred for pagination.

### 2.3 Optional TVP Filters and Pagination

**What**: Same optional TVP filter pattern as GetPositionsChangesForDataApi. All five filters are optional. Pagination via @RowsToSkip / @RowsToTake.

**Columns/Parameters Involved**: `@GCIDs`, `@ApexIDs`, `@Positions`, `@InstrumentTypes`, `@CountryIDs`, `@RowsToSkip`, `@RowsToTake`

**Rules**:
- Empty TVP = no filter for that dimension.
- All filters ANDed.
- Pagination: OFFSET/FETCH activated when both @RowsToSkip >= 0 and @RowsToTake > 0.
- Uses READ UNCOMMITTED isolation (SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED) for maximum throughput.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartTime | DATETIME | NO | - | CODE-BACKED | Start of the query window. Open positions are filtered on Occurred >= @StartTime; closed positions on OpenOccurred or CloseOccurred >= @StartTime. |
| 2 | @EndTime | DATETIME | NO | - | CODE-BACKED | End of the query window. Must be within 32 days of @StartTime or procedure raises error. |
| 3 | @GCIDs | Trade.IdIntList READONLY | NO | - | CODE-BACKED | Optional TVP: filter by Group Customer IDs. Empty = no filter. |
| 4 | @ApexIDs | Trade.ApexIDsList READONLY | NO | - | CODE-BACKED | Optional TVP: filter by Apex external IDs. Empty = no filter. |
| 5 | @Positions | Trade.PositionIDsTbl READONLY | NO | - | CODE-BACKED | Optional TVP: filter by specific PositionIDs. Empty = no filter. |
| 6 | @InstrumentTypes | Trade.IdIntList READONLY | NO | - | CODE-BACKED | Optional TVP: filter by InstrumentTypeID values from Trade.InstrumentMetaData. Empty = no filter. |
| 7 | @CountryIDs | Trade.IdIntList READONLY | NO | - | CODE-BACKED | Optional TVP: filter by customer CountryID values. Empty = no filter. |
| 8 | @RowsToSkip | INT | YES | NULL | CODE-BACKED | Pagination offset. NULL or invalid = return all rows. |
| 9 | @RowsToTake | INT | YES | NULL | CODE-BACKED | Pagination page size. Must be > 0 for pagination to activate. |

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 10 | PositionID | BIGINT | NO | - | CODE-BACKED | The trading position identifier. |
| 11 | GCID | INT | YES | - | CODE-BACKED | Group Customer ID from Customer.CustomerStatic. |
| 12 | ApexID | VARCHAR | NO | - | CODE-BACKED | External Apex system customer identifier. INNER JOIN requires ApexID IS NOT NULL. |
| 13 | CID | INT | NO | - | CODE-BACKED | Customer ID of the position owner. |
| 14 | InstrumentID | INT | NO | - | CODE-BACKED | Traded instrument. FK to Trade.Instrument / Trade.InstrumentMetaData. |
| 15 | StopRate | DECIMAL | NO | - | CODE-BACKED | Stop-loss rate. 0 if no stop-loss set. |
| 16 | LimitRate | DECIMAL | NO | - | CODE-BACKED | Take-profit rate (LimitRate IS the take-profit). 0 if no take-profit set. |
| 17 | MirrorID | INT | YES | - | CODE-BACKED | CopyTrader mirror ID. 0/NULL = manual trade. |
| 18 | ParentPositionID | BIGINT | YES | - | CODE-BACKED | Leader's position this was copied from. 0 = root or manual. |
| 19 | IsSettled | BIT | NO | - | VERIFIED | Legacy settlement flag: 1=real stock position, 0=CFD. |
| 20 | SettlementTypeID | INT | NO | - | VERIFIED | Modern settlement: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. |
| 21 | IsBuy | BIT | NO | - | VERIFIED | Direction: 1=Buy/Long, 0=Sell/Short. |
| 22 | Leverage | INT | NO | - | VERIFIED | Leverage multiplier. 1=no leverage. |
| 23 | AmountInUnitsDecimal | DECIMAL | YES | - | CODE-BACKED | Position size in instrument units (e.g., shares). |
| 24 | Amount | DECIMAL | NO | - | CODE-BACKED | Invested amount in USD. |
| 25 | IsDiscounted | BIT | NO | - | CODE-BACKED | Fee discount applied flag. |
| 26 | InitForexRate | DECIMAL | NO | - | CODE-BACKED | Instrument price at open (open rate). |
| 27 | OpenOccurred | DATETIME | NO | - | CODE-BACKED | Timestamp when position was opened. Used as ORDER BY column for pagination. |
| 28 | Cusip | VARCHAR | YES | - | CODE-BACKED | CUSIP identifier of the instrument from Trade.InstrumentMetaData. |
| 29 | InstrumentTypeID | INT | NO | - | CODE-BACKED | Instrument category type. |
| 30 | CountryID | INT | YES | - | CODE-BACKED | Customer country of residence. |
| 31 | CloseOccurred | DATETIME | YES | - | CODE-BACKED | Timestamp when position closed. NULL for open positions (from Trade.Position branch). |
| 32 | EndForexRate | DECIMAL | YES | - | CODE-BACKED | Instrument price at close. NULL for open positions (from Trade.Position branch). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Open positions | Trade.Position | UNION branch 1 | Currently open positions opened in the time window |
| Closed positions | History.PositionSlim | UNION branch 2 | Positions whose open or close date falls in the window |
| InstrumentID | Trade.InstrumentMetaData | JOIN | Cusip and InstrumentTypeID lookup |
| CID | Customer.CustomerStatic | JOIN (inner, ApexID IS NOT NULL) | GCID, ApexID, CountryID lookup; Apex-registered customers only |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| EngineDataApi (DB user) | GRANT EXECUTE | Permission | The EngineDataApi service consumes this for position data feeds |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionsForDataApi (procedure)
├── Trade.Position (view) [open positions]
│     ├── Trade.PositionTbl (table)
│     └── Trade.PositionTreeInfo (table)
├── History.PositionSlim (table) [closed positions]
├── Trade.InstrumentMetaData (table)
└── Customer.CustomerStatic (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | UNION branch: open positions filtered by Occurred in time window |
| History.PositionSlim | Table | UNION branch: closed positions filtered by OpenOccurred or CloseOccurred in time window |
| Trade.InstrumentMetaData | Table | JOIN for Cusip and InstrumentTypeID |
| Customer.CustomerStatic | Table | INNER JOIN for GCID, ApexID, CountryID (requires ApexID IS NOT NULL) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| EngineDataApi (application service) | External | Builds normalized position lifecycle feed for downstream analytics and compliance |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Date range validation | Business rule | ABS(DATEDIFF(DAY, @StartTime, @EndTime)) <= 32; RAISERROR 16 if violated |
| READ UNCOMMITTED | Isolation | SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED at procedure start |
| ApexID filter | JOIN constraint | INNER JOIN CustomerStatic WHERE ApexID IS NOT NULL |

---

## 8. Sample Queries

### 8.1 Get positions opened or closed in a specific week (no filters)

```sql
DECLARE @GCIDs Trade.IdIntList;
DECLARE @ApexIDs Trade.ApexIDsList;
DECLARE @Positions Trade.PositionIDsTbl;
DECLARE @InstrumentTypes Trade.IdIntList;
DECLARE @CountryIDs Trade.IdIntList;

EXEC Trade.GetPositionsForDataApi
    @StartTime = '2024-01-08 00:00:00',
    @EndTime   = '2024-01-15 00:00:00',
    @GCIDs = @GCIDs, @ApexIDs = @ApexIDs,
    @Positions = @Positions, @InstrumentTypes = @InstrumentTypes,
    @CountryIDs = @CountryIDs;
```

### 8.2 Get paginated positions for specific customers, first page

```sql
DECLARE @GCIDs Trade.IdIntList;
INSERT INTO @GCIDs VALUES (1983593), (5054942);
DECLARE @ApexIDs Trade.ApexIDsList;
DECLARE @Positions Trade.PositionIDsTbl;
DECLARE @InstrumentTypes Trade.IdIntList;
DECLARE @CountryIDs Trade.IdIntList;

EXEC Trade.GetPositionsForDataApi
    @StartTime = '2024-01-01', @EndTime = '2024-01-31',
    @GCIDs = @GCIDs, @ApexIDs = @ApexIDs,
    @Positions = @Positions, @InstrumentTypes = @InstrumentTypes,
    @CountryIDs = @CountryIDs,
    @RowsToSkip = 0, @RowsToTake = 100;
```

### 8.3 Check closed vs open mix in a result

```sql
-- CloseOccurred IS NULL = open position; IS NOT NULL = closed
-- Inline equivalent:
SELECT PositionID, CID, InstrumentID, IsBuy, OpenOccurred, CloseOccurred,
       CASE WHEN CloseOccurred IS NULL THEN 'Open' ELSE 'Closed' END AS PositionState
FROM (
    SELECT PositionID, CID, InstrumentID, IsBuy, Occurred AS OpenOccurred, NULL AS CloseOccurred
    FROM Trade.Position WITH (NOLOCK)
    UNION
    SELECT PositionID, CID, InstrumentID, IsBuy, OpenOccurred, CloseOccurred
    FROM History.PositionSlim WITH (NOLOCK)
    WHERE CloseOccurred BETWEEN '2024-01-08' AND '2024-01-15'
) combined
ORDER BY OpenOccurred;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 28 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionsForDataApi | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPositionsForDataApi.sql*
