# Trade.SSRS_GetOrphanedPositionsData

> SSRS monitoring procedure that detects orphaned copy positions - open copy-trade child positions whose parent leader position has been closed in the last 72 hours but were not automatically closed.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - auto-scoped to last 72 hours |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

In copy trading, when a leader closes a position, all copier positions linked to it (child positions via `ParentPositionID`) should also be automatically closed. An "orphaned" position is one where this cascade failed - the parent was closed but the child copy position remains open without any close order queued.

This procedure identifies such orphaned positions by finding open positions in `Trade.Position` where: (1) the parent position is confirmed closed in `History.PositionSlim` within the last 72 hours, (2) there is no exit order in `Trade.OrdersExit`, and (3) there is no pending close order in `Trade.OrderForClose`. These are positions that slipped through the copy-close cascade.

Operations and risk teams use this report to detect and manually resolve stuck copy positions. A high volume of orphaned positions may indicate a bug in the copy-close cascade process or a system outage during which parent closes were processed but child closes were not triggered. The 72-hour lookback window is hard-coded.

---

## 2. Business Logic

### 2.1 Orphan Detection Logic

**What**: Defines the exact conditions that qualify a position as "orphaned."

**Columns/Parameters Involved**: `ParentPositionID`, `CloseOccurred`, `OE.PositionID`, `OFE.PositionID`

**Rules**:
- `S.ParentPositionID > 0`: The open position is a copy-trade child (has a parent leader position). Zero would indicate it is not a copy.
- `H.CloseOccurred BETWEEN @fromDate AND @toDate`: The parent was closed within the last 72 hours (rolling window from execution time).
- `OE.PositionID IS NULL`: No exit order exists for the parent position in `Trade.OrdersExit`.
- `OFE.PositionID IS NULL`: No pending close order exists for the parent position in `Trade.OrderForClose`.
- All four conditions must be true: the child is open, the parent closed recently, and there is no evidence of a close order being processed.

**Diagram**:
```
Trade.Position (open child copy position)
    ParentPositionID > 0           <- it is a copy
    INNER JOIN History.PositionSlim ON ParentPositionID
        H.CloseOccurred within last 72h  <- parent closed recently
    LEFT JOIN OrdersExit WHERE IS NULL  <- no exit order processed
    LEFT JOIN OrderForClose WHERE IS NULL <- no pending close order
    = ORPHANED POSITION (copy cascade failure)
```

### 2.2 Fixed 72-Hour Rolling Window

**What**: The procedure automatically scopes itself to a rolling 72-hour window - no parameters required.

**Columns/Parameters Involved**: Internal `@fromDate`, `@toDate`

**Rules**:
- `@fromDate = DATEADD(HOUR, -72, GETUTCDATE())` - 72 hours before execution.
- `@toDate = GETUTCDATE()` - current UTC time.
- No user-provided date parameters. The report always shows orphans from the last 3 days.
- This window is intentional: orphaned positions older than 72 hours would likely have been detected and resolved in previous report runs.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

This procedure has no input parameters.

### Output Columns (Result Set)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | BIGINT | NO | - | CODE-BACKED | The orphaned child copy position's ID. Currently open in Trade.Position. This is the position that needs manual intervention to close. |
| 2 | ParentPositionID | BIGINT | NO | - | CODE-BACKED | The leader's (parent) position ID. This position is confirmed closed in History.PositionSlim. The orphaned child should have been closed when this parent was closed. |
| 3 | ParentCloseTime | DATETIME | YES | - | CODE-BACKED | Timestamp when the parent leader position was closed (History.PositionSlim.CloseOccurred). Bounded within the 72-hour window. |
| 4 | Side | VARCHAR | NO | - | CODE-BACKED | Human-readable trade direction of the parent position: 'BUY' when History.PositionSlim.IsBuy = 1, 'SELL' when 0. Indicates whether the parent (and thus the orphaned copy) was a long or short position. |
| 5 | EndForexRate | DECIMAL | YES | - | CODE-BACKED | The closing forex conversion rate of the parent position at close time (from History.PositionSlim). Used for P&L recalculation if the orphan is manually closed at the same rate. |
| 6 | FullCommissionOnClose | MONEY | YES | - | CODE-BACKED | Total commission charged when the parent position was closed (from History.PositionSlim). Reference value for the expected commission on the orphaned position's manual close. |
| 7 | LastOpConversionRate | DECIMAL | YES | - | CODE-BACKED | Last overnight/overnight-operation conversion rate on the parent position at close (from History.PositionSlim). Reference for cost basis calculations on the orphaned position. |
| 8 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument identifier of the orphaned position. FK to Trade.InstrumentMetaData.InstrumentID. Identifies the asset that needs manual close. |
| 9 | Symbol | NVARCHAR | YES | - | CODE-BACKED | Instrument ticker symbol (e.g., 'AAPL', 'BTC'). Sourced from Trade.InstrumentMetaData. NULL if no metadata record. |
| 10 | CID | INT | NO | - | CODE-BACKED | Customer ID of the copier who holds the orphaned position. Sourced from Customer.CustomerStatic. Used to notify the customer or for account-level reconciliation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.Position | Lookup (READ) | Source of open copy positions (child positions with ParentPositionID > 0) |
| ParentPositionID | History.PositionSlim | Lookup (INNER JOIN) | Confirms parent position closed within 72h via CloseOccurred |
| CID | Customer.CustomerStatic | Lookup (INNER JOIN) | Retrieves customer CID for the orphaned position's holder |
| InstrumentID | Trade.InstrumentMetaData | Lookup (LEFT JOIN) | Retrieves instrument Symbol for display |
| (check) | Trade.OrdersExit | Existence check (LEFT JOIN IS NULL) | Verifies no exit order exists for the parent's PositionID |
| (check) | Trade.OrderForClose | Existence check (LEFT JOIN IS NULL) | Verifies no pending close order exists for the parent's PositionID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called directly from SSRS report server.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SSRS_GetOrphanedPositionsData (procedure)
├── Trade.Position (view)
├── History.PositionSlim (table - cross-schema)
├── Customer.CustomerStatic (table - cross-schema)
├── Trade.InstrumentMetaData (table)
├── Trade.OrdersExit (table)
└── Trade.OrderForClose (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | INNER source: open copy child positions (ParentPositionID > 0) |
| History.PositionSlim | Table (cross-schema) | INNER JOIN: confirms parent closed within 72h, provides close-time attributes |
| Customer.CustomerStatic | Table (cross-schema) | INNER JOIN: retrieves CID for the copier customer |
| Trade.InstrumentMetaData | Table | LEFT JOIN: retrieves instrument Symbol |
| Trade.OrdersExit | Table | LEFT JOIN with IS NULL check: verifies no exit order exists |
| Trade.OrderForClose | Table | LEFT JOIN with IS NULL check: verifies no pending close order exists |

### 6.2 Objects That Depend On This

No dependents found. Called directly from SSRS report server.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Run orphaned positions report (standard execution)

```sql
EXEC Trade.SSRS_GetOrphanedPositionsData
```

### 8.2 Preview orphaned positions directly with same logic

```sql
DECLARE @fromDate DATETIME = DATEADD(HOUR, -72, GETUTCDATE())
DECLARE @toDate   DATETIME = GETUTCDATE()

SELECT TOP 20
    S.PositionID AS PositionID,
    H.PositionID AS ParentPositionID,
    H.CloseOccurred AS ParentCloseTime,
    IIF(H.IsBuy=1,'BUY','SELL') AS Side,
    tim.Symbol,
    CS.CID
FROM Trade.Position S WITH (NOLOCK)
    INNER JOIN History.PositionSlim H WITH (NOLOCK)
        ON H.PositionID = S.ParentPositionID
    INNER JOIN Customer.CustomerStatic CS WITH (NOLOCK)
        ON S.CID = CS.CID
    LEFT JOIN Trade.InstrumentMetaData tim WITH (NOLOCK)
        ON S.InstrumentID = tim.InstrumentID
    LEFT JOIN Trade.OrdersExit OE WITH (NOLOCK)
        ON OE.PositionID = H.PositionID
    LEFT JOIN Trade.OrderForClose OFE WITH (NOLOCK)
        ON OFE.PositionID = H.PositionID
WHERE S.ParentPositionID > 0
    AND H.CloseOccurred BETWEEN @fromDate AND @toDate
    AND OE.PositionID IS NULL
    AND OFE.PositionID IS NULL
ORDER BY H.CloseOccurred DESC
```

### 8.3 Count orphaned positions per instrument

```sql
SELECT
    tim.Symbol,
    S.InstrumentID,
    COUNT(*) AS OrphanedCount
FROM Trade.Position S WITH (NOLOCK)
    INNER JOIN History.PositionSlim H WITH (NOLOCK)
        ON H.PositionID = S.ParentPositionID
    LEFT JOIN Trade.InstrumentMetaData tim WITH (NOLOCK)
        ON S.InstrumentID = tim.InstrumentID
    LEFT JOIN Trade.OrdersExit OE WITH (NOLOCK)
        ON OE.PositionID = H.PositionID
    LEFT JOIN Trade.OrderForClose OFE WITH (NOLOCK)
        ON OFE.PositionID = H.PositionID
WHERE S.ParentPositionID > 0
    AND H.CloseOccurred >= DATEADD(HOUR, -72, GETUTCDATE())
    AND OE.PositionID IS NULL
    AND OFE.PositionID IS NULL
GROUP BY S.InstrumentID, tim.Symbol
ORDER BY OrphanedCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SSRS_GetOrphanedPositionsData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SSRS_GetOrphanedPositionsData.sql*
