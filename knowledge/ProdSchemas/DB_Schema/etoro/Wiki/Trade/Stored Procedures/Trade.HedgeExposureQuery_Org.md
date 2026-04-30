# Trade.HedgeExposureQuery_Org

> Legacy version of Trade.HedgeExposureQuery. Uses PlayerLevelID<>4 (demo account exclusion via Customer.Customer JOIN) instead of IsComputeForHedge=1, and additionally tracks EntryHedgeQuery on Trade.Position and History.PositionSlim for position-to-hedge query linkage. Superseded by Trade.HedgeExposureQuery.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Input: @HedgeServerID, @InstrumentID (optional), @HedgeInstrument (optional); Reads: Trade.GetHedgeExposure / Trade.Position / Trade.Hedge; Writes: History.HedgingBreakdownLog, Trade.Position.EntryHedgeQuery, History.PositionSlim.EntryHedgeQuery / EndHedgeQuery |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.HedgeExposureQuery_Org is the **original version** of Trade.HedgeExposureQuery, preserved as a historical artifact. It implements the same two-mode pattern but with two key differences:

1. **Position filter**: Uses `INNER JOIN Customer.Customer WHERE PlayerLevelID <> 4` to exclude demo accounts, rather than the `IsComputeForHedge=1` flag used in the current version.

2. **EntryHedgeQuery tracking**: After logging to HedgingBreakdownLog, the original version performs additional UPDATE operations to stamp position records with the HedgingBreakdownLog identity, tracking which hedge query first included each position and when positions "left" the hedge universe. This allowed reconciliation of position lifecycle relative to hedge queries. The current version dropped this tracking (simplification).

The `EntryHedgeQuery` column on both `Trade.Position` and `History.PositionSlim` tracks: which hedge query log entry was the first to see this position (EntryHedgeQuery), and which was the last hedge query active when the position closed (EndHedgeQuery). This enabled post-hoc analysis of "was this position visible in the hedge exposure calculation before it closed?"

See Trade.HedgeExposureQuery for the current active implementation.

---

## 2. Business Logic

### 2.1 Summary Mode (same as current version)

**What**: Returns all-instrument exposure from Trade.GetHedgeExposure.

**Rules**:
- IF @InstrumentID IS NULL: `SELECT InstrumentID, Difference, Opened, Hedged FROM Trade.GetHedgeExposure WHERE HedgeServerID = @HedgeServerID`
- No logging, no position tracking in summary mode.

### 2.2 Detail Mode - Position Exclusion via PlayerLevelID<>4

**What**: Same exposure calculation as current version but uses demo-account filter instead of IsComputeForHedge.

**Rules**:
- `FROM Trade.Position TP INNER JOIN Customer.Customer CC ON TP.CID = CC.CID WHERE InstrumentID=@InstrumentID AND HedgeServerID=@HedgeServerID AND PlayerLevelID <> 4`
- PlayerLevelID=4 = demo/test customer - excluded from hedge calculations.
- Rest of exposure calc (@Opened, @Hedged, @Difference, @Unit) is identical to current version.
- INSERT History.HedgingBreakdownLog (EntryType=3) - identical to current version.
- `@Identity = @@IDENTITY` - captures the new log row identity for position linking.

### 2.3 EntryHedgeQuery and EndHedgeQuery Tracking (NOT in current version)

**What**: Links each position to the hedge query that first saw it, and marks when it left the hedge universe.

**Rules**:
- Step A: UPDATE History.PositionSlim SET EndHedgeQuery=@Identity WHERE HedgeServerID=@HedgeServerID AND InstrumentID=@InstrumentID AND EndHedgeQuery=-1 AND PositionID NOT IN @ExposureTable.
  - Meaning: positions that were in PositionSlim (i.e., recently closed) but NOT in the current exposure table - mark their EndHedgeQuery. These were closed before this query ran.
- Step B: DELETE from @ExposureTable WHERE EntryHedgeQuery <> -1 (keep only positions that have never been assigned an EntryHedgeQuery, i.e., new positions).
- Step C: If remaining @ExposureTable is non-empty (new positions exist):
  - UPDATE Trade.Position SET EntryHedgeQuery=@Identity WHERE PositionID in @ExposureTable
  - If some positions were closed between INSERT and UPDATE (@@ROWCOUNT < @RecordsInExposureTable):
    - UPDATE History.PositionSlim SET EntryHedgeQuery=@Identity WHERE PositionID in @ExposureTable AND EntryHedgeQuery IN (-1, NULL)
  - This ensures every position gets its EntryHedgeQuery stamped whether it closes fast or stays open.
- Note: EntryHedgeQuery=-1 is the "not yet assigned" sentinel value.

**Diagram**:
```
HedgeExposureQuery_Org(@HedgeServerID, @InstrumentID, @HedgeInstrument)
    |
    IF @InstrumentID IS NULL:
    |   -> SELECT from Trade.GetHedgeExposure (same as current)
    |
    ELSE:
    |   -> @ExposureTable = Trade.Position INNER JOIN Customer.Customer WHERE PlayerLevelID<>4
    |                       (OLD filter - current uses IsComputeForHedge=1)
    |   -> @Opened, @Hedged, @Difference, @Unit (same as current)
    |   -> INSERT History.HedgingBreakdownLog (EntryType=3)
    |   -> @Identity = @@IDENTITY
    |   |
    |   -> UPDATE History.PositionSlim: EndHedgeQuery=@Identity (positions that left the hedge)
    |   -> DELETE @ExposureTable WHERE EntryHedgeQuery <> -1 (keep only new positions)
    |   -> IF new positions remain:
    |       -> UPDATE Trade.Position: EntryHedgeQuery=@Identity (stamp first-seen)
    |       -> IF some already closed: UPDATE History.PositionSlim: EntryHedgeQuery=@Identity
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
| 2 | @InstrumentID | INTEGER | YES | NULL | CODE-BACKED | NULL = summary mode; non-NULL = detail mode with EntryHedgeQuery tracking. |
| 3 | @HedgeInstrument | INTEGER | YES | NULL | CODE-BACKED | Hedge vehicle instrument. Stored in History.HedgingBreakdownLog.HedgedInstrument. |
| 4 | InstrumentID | INTEGER | - | - | CODE-BACKED | Output. Same as Trade.HedgeExposureQuery. |
| 5 | Difference | INT | - | - | CODE-BACKED | Output. @Opened - @Hedged. INT type causes truncation (same quirk as current version). |
| 6 | Opened | DECIMAL(16,6) | - | - | CODE-BACKED | Output. Net open position lots (buy - sell) excluding PlayerLevelID=4. |
| 7 | Hedged | DECIMAL(16,6) | - | - | CODE-BACKED | Output. Net hedge lots (buy - sell) from Trade.Hedge. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeServerID | Trade.GetHedgeExposure | SELECT (summary mode) | All-instrument exposure view |
| @InstrumentID, PlayerLevelID<>4 | Trade.Position + Customer.Customer | SELECT into @ExposureTable (detail mode) | Open positions excluding demo accounts |
| @InstrumentID, @HedgeServerID | Trade.Hedge | SELECT (detail mode) | Net hedge lots |
| @InstrumentID, IsActive | Trade.ProviderToInstrument + Trade.Provider | SELECT (detail mode) | Unit size for lots-to-units conversion |
| EntryType=3 | History.HedgingBreakdownLog | INSERT (detail mode) | Audit log of hedge exposure queries |
| EndHedgeQuery=-1 | History.PositionSlim | UPDATE (detail mode) | Marks positions that left the hedge universe |
| EntryHedgeQuery=-1 | Trade.Position | UPDATE (detail mode) | Stamps first hedge query that saw each new position |
| EntryHedgeQuery=-1/NULL | History.PositionSlim | UPDATE (detail mode, conditional) | Stamps EntryHedgeQuery for positions that closed before UPDATE ran |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.HedgeExposureQuery | Supersedes | Historical reference | Current callers use HedgeExposureQuery; this is the legacy version |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI analytics team has execute rights |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.HedgeExposureQuery_Org (procedure)
+-- Trade.GetHedgeExposure (view) [summary mode]
+-- Trade.Position (view) [detail mode - PlayerLevelID<>4 filter]
+-- Customer.Customer (x-schema table) [detail mode - demo exclusion]
+-- Trade.Hedge (table) [detail mode - net hedge lots]
+-- Trade.ProviderToInstrument (table) [detail mode - Unit size]
+-- Trade.Provider (table) [detail mode - IsActive filter]
+-- History.HedgingBreakdownLog (table) [x-schema, detail mode - audit INSERT]
+-- History.PositionSlim (table) [x-schema, detail mode - EndHedgeQuery UPDATE]
+-- Trade.Position (table) [detail mode - EntryHedgeQuery UPDATE via view]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetHedgeExposure | View | Summary mode exposure |
| Trade.Position | View/Table | Detail mode: open position load + EntryHedgeQuery UPDATE |
| Customer.Customer | Table | Detail mode: demo account exclusion (PlayerLevelID<>4) |
| Trade.Hedge | Table | Detail mode: net hedge lots |
| Trade.ProviderToInstrument | Table | Detail mode: Unit size |
| Trade.Provider | Table | Detail mode: IsActive filter |
| History.HedgingBreakdownLog | Table | Detail mode: audit INSERT |
| History.PositionSlim | Table | Detail mode: EndHedgeQuery + EntryHedgeQuery UPDATE |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeExposureQuery | Procedure | Supersedes this; same caller base uses non-_Org version |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. Uses @@IDENTITY (not SCOPE_IDENTITY) for capturing HedgingBreakdownLog ID. No error handling, no transaction. Preserved as historical artifact alongside the current Trade.HedgeExposureQuery. The EntryHedgeQuery tracking adds significant write overhead vs the current version.

---

## 8. Sample Queries

### 8.1 Compare with current version

```sql
-- Legacy (with EntryHedgeQuery tracking, PlayerLevelID<>4 filter):
EXEC Trade.HedgeExposureQuery_Org @HedgeServerID = 24, @InstrumentID = 1;

-- Current (IsComputeForHedge=1, no EntryHedgeQuery tracking):
EXEC Trade.HedgeExposureQuery @HedgeServerID = 24, @InstrumentID = 1;
```

### 8.2 Check EntryHedgeQuery stamps on positions

```sql
-- Positions that have been seen by at least one hedge query
SELECT TOP 50 PositionID, InstrumentID, EntryHedgeQuery
FROM Trade.PositionTbl WITH (NOLOCK)
WHERE EntryHedgeQuery <> -1 AND EntryHedgeQuery IS NOT NULL
ORDER BY EntryHedgeQuery DESC;
```

### 8.3 Check EndHedgeQuery on closed positions

```sql
SELECT TOP 20 PositionID, InstrumentID, EndHedgeQuery, EntryHedgeQuery
FROM History.PositionSlim WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY EndHedgeQuery DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/4 (1, 11 - Phase 8: only grants, Phase 10: skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos (skipped) | Corrections: 0 applied*
*Object: Trade.HedgeExposureQuery_Org | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.HedgeExposureQuery_Org.sql*
