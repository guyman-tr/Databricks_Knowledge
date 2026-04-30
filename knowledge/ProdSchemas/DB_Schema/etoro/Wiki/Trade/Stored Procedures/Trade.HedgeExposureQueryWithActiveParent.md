# Trade.HedgeExposureQueryWithActiveParent

> Variant of Trade.HedgeExposureQuery that adds an active-parent filter: positions are only included if they are root positions (ParentPositionID=0) or their parent still exists in Trade.Position. Uses IsComputeForHedge=1. Summary mode uses Trade.GetHedgeExposureWithActiveParent view.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Input: @HedgeServerID, @InstrumentID (optional), @HedgeInstrument (optional); Reads: Trade.GetHedgeExposureWithActiveParent / Trade.Position / Trade.Hedge; Writes: History.HedgingBreakdownLog |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.HedgeExposureQueryWithActiveParent is a variant of Trade.HedgeExposureQuery that excludes orphaned child positions from the exposure calculation. An "orphaned" child position is one where the parent (copy-trade parent) no longer exists in Trade.Position - the parent was closed or removed but the child position is still open.

In copy-trading, child positions (`ParentPositionID != 0`) exist because customers copied a "people investor" (popular investor) who opened a position. If the popular investor closes their position but the child position is somehow not yet closed, it becomes orphaned. Including orphaned positions in hedge exposure calculations would overstate the real exposure and cause unnecessary hedging activity.

The filter is: `TP.ParentPositionID = 0 OR TP2.PositionID = TP.ParentPositionID` (LEFT JOIN Trade.Position TP2 ON TP.ParentPositionID = TP2.PositionID) - meaning either the position has no parent (root), or the parent was found in Trade.Position (active parent).

The SP also uses `IsComputeForHedge=1` (same as Trade.HedgeExposureQuery, not the older PlayerLevelID<>4 approach).

Summary mode routes to `Trade.GetHedgeExposureWithActiveParent` which applies both demo exclusion (PlayerLevelID<>4) and orphan exclusion at the view level.

Note: This version does NOT include the EntryHedgeQuery / EndHedgeQuery tracking from Trade.HedgeExposureQuery_Org.

---

## 2. Business Logic

### 2.1 Summary Mode - All Instruments with Active Parent Filter

**What**: Returns exposure from Trade.GetHedgeExposureWithActiveParent view.

**Rules**:
- IF @InstrumentID IS NULL: `SELECT InstrumentID, Difference, Opened, Hedged FROM Trade.GetHedgeExposureWithActiveParent WHERE HedgeServerID = @HedgeServerID`
- The view applies dual filters: PlayerLevelID<>4 (no demo) + orphan exclusion.

### 2.2 Detail Mode - Single Instrument with Active-Parent Check

**What**: Computes real-time single-instrument exposure with orphan exclusion.

**Columns/Parameters Involved**: `@InstrumentID`, `@HedgeServerID`, `IsComputeForHedge`, `ParentPositionID`, `LotCountDecimal`, `IsBuy`, `Unit`

**Rules**:
- Load @ExposureTable: `FROM Trade.Position TP LEFT JOIN Trade.Position TP2 ON TP.ParentPositionID = TP2.PositionID WHERE TP.InstrumentID=@InstrumentID AND TP.HedgeServerID=@HedgeServerID AND (TP.ParentPositionID=0 OR TP2.PositionID=TP.ParentPositionID) AND TP.IsComputeForHedge=1`
- `@Opened = SUM(IsBuy? +1 : -1 * ISNULL(LotCountDecimal,0)) FROM @ExposureTable`
- `@Hedged = SUM(IsBuy? +1 : -1 * ISNULL(LotCountDecimal,0)) FROM Trade.Hedge WHERE InstrumentID=@InstrumentID AND HedgeServerID=@HedgeServerID`
- `@Difference = @Opened - @Hedged` (INT - truncation of sub-lot values, same as Trade.HedgeExposureQuery)
- `@Unit FROM Trade.ProviderToInstrument INNER JOIN Trade.Provider WHERE IsActive=1 AND PTI.InstrumentID=@InstrumentID`
- INSERT History.HedgingBreakdownLog: `(EntryType=3, @InstrumentID, @HedgeServerID, AmountInUnitsDecimal=@Difference*@Unit, HedgedInstrument=@HedgeInstrument, HedgedAmountInUnitsDecimal=@Hedged*@Unit)`
- SELECT result: `@InstrumentID, @Difference, @Opened, @Hedged`

**Active parent filter logic**:
```
TP.ParentPositionID = 0          -> root position (no parent) - always included
OR TP2.PositionID = TP.ParentPositionID -> parent exists in Trade.Position - included
(LEFT JOIN means TP2 IS NULL if parent not found -> this row excluded by the OR condition)
```

**Diagram**:
```
HedgeExposureQueryWithActiveParent(@HedgeServerID, @InstrumentID, @HedgeInstrument)
    |
    IF @InstrumentID IS NULL:
    |   -> SELECT from Trade.GetHedgeExposureWithActiveParent WHERE HedgeServerID=@HedgeServerID
    |      (summary: demo-excluded + orphan-excluded exposure)
    |
    ELSE:
    |   -> @ExposureTable = Trade.Position TP
    |       LEFT JOIN Trade.Position TP2 ON TP.ParentPositionID = TP2.PositionID
    |       WHERE InstrumentID=@InstrumentID AND HedgeServerID=@HedgeServerID
    |           AND IsComputeForHedge=1
    |           AND (ParentPositionID=0 OR TP2.PositionID = TP.ParentPositionID)
    |       (excludes orphaned child positions)
    |   -> @Opened, @Hedged, @Difference (same pattern as HedgeExposureQuery)
    |   -> @Unit from ProviderToInstrument+Provider
    |   -> INSERT History.HedgingBreakdownLog (EntryType=3)
    |   -> SELECT @InstrumentID, @Difference, @Opened, @Hedged
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | INTEGER | NO | - | CODE-BACKED | Hedge server to query. Same as Trade.HedgeExposureQuery. |
| 2 | @InstrumentID | INTEGER | YES | NULL | CODE-BACKED | NULL = summary mode (uses GetHedgeExposureWithActiveParent view). Non-NULL = detail mode with active-parent position filter. |
| 3 | @HedgeInstrument | INTEGER | YES | NULL | CODE-BACKED | Hedge vehicle instrument. Stored in History.HedgingBreakdownLog.HedgedInstrument. |
| 4 | InstrumentID | INTEGER | - | - | CODE-BACKED | Output. Financial instrument. |
| 5 | Difference | INT | - | - | CODE-BACKED | Output. @Opened - @Hedged. INT causes sub-lot truncation (same quirk as HedgeExposureQuery). |
| 6 | Opened | DECIMAL(16,6) | - | - | CODE-BACKED | Output. Net open lots (buy - sell) from active-parent-filtered positions. |
| 7 | Hedged | DECIMAL(16,6) | - | - | CODE-BACKED | Output. Net hedge lots (buy - sell) from Trade.Hedge. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeServerID | Trade.GetHedgeExposureWithActiveParent | SELECT (summary mode) | Active-parent-filtered exposure view |
| @InstrumentID, ParentPositionID | Trade.Position (self-join) | SELECT + LEFT JOIN (detail mode) | Open positions with active parent check |
| @InstrumentID, @HedgeServerID | Trade.Hedge | SELECT (detail mode) | Net hedge lots |
| @InstrumentID, IsActive | Trade.ProviderToInstrument + Trade.Provider | SELECT (detail mode) | Unit size for lots-to-units |
| EntryType=3 | History.HedgingBreakdownLog | INSERT (detail mode) | Audit log of hedge exposure queries |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.HedgeExposureWithNoRequestsWithActiveParent | EXEC (detail mode) | Called procedure | Uses this SP for per-instrument exposure with orphan exclusion |
| Hedge Server (external) | - | Called by external system | Alternate polling query for more conservative exposure estimates |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI analytics team has execute rights |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.HedgeExposureQueryWithActiveParent (procedure)
+-- Trade.GetHedgeExposureWithActiveParent (view) [summary mode]
|     +-- Trade.Position (view) - PlayerLevelID<>4 + active parent filter
|     +-- Customer.Customer (x-schema table)
|     +-- Trade.Hedge (table)
|     +-- Trade.GetInstrument (view)
+-- Trade.Position (view) [detail mode - IsComputeForHedge + active-parent self-join]
+-- Trade.Hedge (table) [detail mode - net hedge lots]
+-- Trade.ProviderToInstrument (table) [detail mode - Unit size]
+-- Trade.Provider (table) [detail mode - IsActive filter]
+-- History.HedgingBreakdownLog (table) [x-schema, detail mode - audit INSERT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetHedgeExposureWithActiveParent | View | Summary mode: demo-excluded + orphan-excluded exposure |
| Trade.Position | View | Detail mode: open position load with active-parent self-join |
| Trade.Hedge | Table | Detail mode: net hedge lots |
| Trade.ProviderToInstrument | Table | Detail mode: Unit size |
| Trade.Provider | Table | Detail mode: IsActive filter |
| History.HedgingBreakdownLog | Table | Detail mode: audit INSERT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeExposureWithNoRequestsWithActiveParent | Procedure | Calls for per-instrument exposure with active-parent filter |
| Hedge Server (external) | External caller | Conservative exposure polling |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. The self-join on Trade.Position (TP2) for active-parent checking may have performance implications on large position tables. No EntryHedgeQuery tracking (unlike HedgeExposureQuery_Org). @Difference declared as INT - truncates sub-lot differences.

---

## 8. Sample Queries

### 8.1 Summary mode - all instruments with active-parent filter

```sql
EXEC Trade.HedgeExposureQueryWithActiveParent @HedgeServerID = 24;
```

### 8.2 Detail mode - single instrument with active-parent check

```sql
EXEC Trade.HedgeExposureQueryWithActiveParent
    @HedgeServerID = 24,
    @InstrumentID = 1,
    @HedgeInstrument = 1;
```

### 8.3 Compare with standard exposure query to see orphan impact

```sql
-- Standard (includes orphaned child positions):
EXEC Trade.HedgeExposureQuery @HedgeServerID = 24, @InstrumentID = 1;

-- With active parent (excludes orphaned child positions):
EXEC Trade.HedgeExposureQueryWithActiveParent @HedgeServerID = 24, @InstrumentID = 1;
-- Difference in Opened = exposure from orphaned copy-trade positions
```

### 8.4 Identify orphaned positions directly

```sql
SELECT TP.PositionID, TP.ParentPositionID, TP.InstrumentID, TP.HedgeServerID
FROM Trade.Position TP WITH (NOLOCK)
LEFT JOIN Trade.Position TP2 WITH (NOLOCK) ON TP.ParentPositionID = TP2.PositionID
WHERE TP.ParentPositionID <> 0 AND TP2.PositionID IS NULL
  AND TP.HedgeServerID = 24;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/4 (1, 11 - Phase 8: only grants, Phase 10: skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos (skipped) | Corrections: 0 applied*
*Object: Trade.HedgeExposureQueryWithActiveParent | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.HedgeExposureQueryWithActiveParent.sql*
