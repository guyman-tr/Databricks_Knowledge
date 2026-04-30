# Trade.HedgeExposureQuery

> Calculates per-instrument hedge exposure for a hedge server in two modes: summary mode returns all instruments from Trade.GetHedgeExposure; detail mode calculates single-instrument exposure using IsComputeForHedge=1 and logs the result to History.HedgingBreakdownLog (EntryType=3).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Input: @HedgeServerID, @InstrumentID (optional), @HedgeInstrument (optional); Reads: Trade.GetHedgeExposure / Trade.Position / Trade.Hedge; Writes: History.HedgingBreakdownLog |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.HedgeExposureQuery is the hedge server's main query for computing hedge exposure. It operates in two modes controlled by `@InstrumentID`:

**Summary mode** (`@InstrumentID IS NULL`): Returns all instruments with their exposure data from the pre-computed `Trade.GetHedgeExposure` view. Used for a broad overview of all instruments on a hedge server.

**Detail mode** (`@InstrumentID IS NOT NULL`): Computes the precise exposure for a single instrument using real-time data from `Trade.Position` (filtered to `IsComputeForHedge=1`) and `Trade.Hedge`. After computing the exposure, it logs an audit entry to `History.HedgingBreakdownLog` (EntryType=3) converting lot-based difference to units using the instrument's `Unit` size. Returns the single-instrument result.

The `IsComputeForHedge` flag (on Trade.Position) was introduced to replace the older `PlayerLevelID<>4` filter used in `Trade.HedgeExposureQuery_Org`. This gives finer control: individual positions can be excluded from hedge calculations regardless of their customer's player level.

The `@HedgeInstrument` parameter captures the instrument used as the hedge vehicle (can differ from the position instrument in cross-instrument hedging scenarios) and is logged to `History.HedgingBreakdownLog.HedgedInstrument`.

---

## 2. Business Logic

### 2.1 Summary Mode - All Instruments

**What**: Returns exposure for all instruments on a hedge server from the pre-computed view.

**Rules**:
- IF @InstrumentID IS NULL: `SELECT InstrumentID, Difference, Opened, Hedged FROM Trade.GetHedgeExposure WHERE HedgeServerID = @HedgeServerID`
- No logging in summary mode.
- Difference/Opened/Hedged come from the view (which uses PlayerLevelID<>4 filter internally).

### 2.2 Detail Mode - Single Instrument

**What**: Computes real-time single-instrument exposure using IsComputeForHedge=1, logs to HedgingBreakdownLog.

**Columns/Parameters Involved**: `@InstrumentID`, `@HedgeServerID`, `@HedgeInstrument`, `IsComputeForHedge`, `LotCountDecimal`, `IsBuy`, `Unit`

**Rules**:
- Step 1: Load open positions into @ExposureTable: `FROM Trade.Position WHERE InstrumentID=@InstrumentID AND HedgeServerID=@HedgeServerID AND IsComputeForHedge=1`
- Step 2: `@Opened = SUM(CASE WHEN IsBuy=1 THEN +1 ELSE -1 END * ISNULL(LotCountDecimal,0)) FROM @ExposureTable`
- Step 3: `@Hedged = SUM(CASE WHEN IsBuy=1 THEN +1 ELSE -1 END * ISNULL(LotCountDecimal,0)) FROM Trade.Hedge WHERE InstrumentID=@InstrumentID AND HedgeServerID=@HedgeServerID`
- Step 4: `@Difference = @Opened - @Hedged`
- Step 5: `@Unit = PTI.Unit FROM Trade.ProviderToInstrument PTI INNER JOIN Trade.Provider P ON PTI.ProviderID=P.ProviderID WHERE P.IsActive=1 AND PTI.InstrumentID=@InstrumentID` (note: gets Unit from the active provider, not provider-specific)
- Step 6: INSERT History.HedgingBreakdownLog: `(EntryType=3, @InstrumentID, @HedgeServerID, AmountInUnitsDecimal=@Difference*@Unit, HedgedInstrument=@HedgeInstrument, HedgedAmountInUnitsDecimal=@Hedged*@Unit)`
- Step 7: SELECT result: `@InstrumentID, @Difference, @Opened, @Hedged`

**Notes**:
- `IsComputeForHedge=1` replaces the older `PlayerLevelID<>4` approach from `Trade.HedgeExposureQuery_Org`.
- If no active provider found for the instrument, @Unit will be NULL; the log entry will have NULL AmountInUnitsDecimal (no error raised).
- @Difference is declared as INT (not DECIMAL) - this causes truncation of sub-lot differences. This is a known behavior in the current version.

**Diagram**:
```
HedgeExposureQuery(@HedgeServerID, @InstrumentID, @HedgeInstrument)
    |
    IF @InstrumentID IS NULL:
    |   -> SELECT from Trade.GetHedgeExposure WHERE HedgeServerID=@HedgeServerID
    |      (summary: all instruments)
    |
    ELSE:
    |   -> @ExposureTable = Trade.Position WHERE IsComputeForHedge=1 AND InstrumentID=@InstrumentID
    |   -> @Opened = net lots from @ExposureTable
    |   -> @Hedged = net lots from Trade.Hedge WHERE InstrumentID=@InstrumentID
    |   -> @Difference = @Opened - @Hedged (INT - truncates sub-lot values)
    |   -> @Unit = Trade.ProviderToInstrument JOIN Trade.Provider WHERE IsActive=1
    |   -> INSERT History.HedgingBreakdownLog (EntryType=3, lots*Unit -> units)
    |   -> SELECT @InstrumentID, @Difference, @Opened, @Hedged
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | INTEGER | NO | - | CODE-BACKED | Hedge server to query. Used to filter both Trade.Position and Trade.Hedge in detail mode; filters Trade.GetHedgeExposure in summary mode. |
| 2 | @InstrumentID | INTEGER | YES | NULL | CODE-BACKED | Optional. NULL = summary mode (all instruments from view). Non-NULL = detail mode (single instrument, real-time calc, logged to HedgingBreakdownLog). |
| 3 | @HedgeInstrument | INTEGER | YES | NULL | CODE-BACKED | Optional. The instrument used as the hedge vehicle (for cross-instrument hedging). Stored in History.HedgingBreakdownLog.HedgedInstrument. Can be NULL if no cross-instrument hedge. |
| 4 | InstrumentID | INTEGER | - | - | CODE-BACKED | Output. The instrument. In summary mode: from Trade.GetHedgeExposure. In detail mode: @InstrumentID. |
| 5 | Difference | DECIMAL/INT | - | - | CODE-BACKED | Output. Net unhedged exposure in lots (@Opened - @Hedged). Note: declared as INT in detail mode - sub-lot fractions are truncated. Summary mode returns DECIMAL from the view. |
| 6 | Opened | DECIMAL(16,6) | - | - | CODE-BACKED | Output. Net open position lots (buy - sell) with IsComputeForHedge=1 in detail mode, or from GetHedgeExposure in summary. |
| 7 | Hedged | DECIMAL(16,6) | - | - | CODE-BACKED | Output. Net hedge lots (buy - sell) from Trade.Hedge in detail mode, or from GetHedgeExposure in summary. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeServerID | Trade.GetHedgeExposure | SELECT (summary mode) | All-instrument exposure view |
| @InstrumentID, IsComputeForHedge | Trade.Position | SELECT into @ExposureTable (detail mode) | Open positions that participate in hedge calculation |
| @InstrumentID, @HedgeServerID | Trade.Hedge | SELECT (detail mode) | Live hedges for this instrument+server |
| @InstrumentID, IsActive | Trade.ProviderToInstrument + Trade.Provider | SELECT (detail mode) | Get Unit size for lots-to-units conversion |
| EntryType=3, @InstrumentID | History.HedgingBreakdownLog | INSERT (detail mode) | Audit log of hedge exposure queries |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.HedgeExposureWithNoRequests | EXEC (detail mode) | Called procedure | Calls with @InstrumentID to get per-instrument exposure before deciding if hedging is needed |
| Hedge Server (external) | - | Called by external system | Calls for summary mode to poll current exposure across all instruments |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI analytics team has execute rights |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.HedgeExposureQuery (procedure)
+-- Trade.GetHedgeExposure (view) [summary mode]
|     +-- Trade.Position (view)
|     +-- Customer.Customer (x-schema table)
|     +-- Trade.Hedge (table)
|     +-- Trade.GetInstrument (view)
+-- Trade.Position (view) [detail mode - IsComputeForHedge filter]
+-- Trade.Hedge (table) [detail mode - net hedge lots]
+-- Trade.ProviderToInstrument (table) [detail mode - Unit size]
+-- Trade.Provider (table) [detail mode - IsActive filter]
+-- History.HedgingBreakdownLog (table) [x-schema, detail mode - audit INSERT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetHedgeExposure | View | Summary mode: all-instrument exposure |
| Trade.Position | View | Detail mode: open positions with IsComputeForHedge=1 |
| Trade.Hedge | Table | Detail mode: net hedge lots |
| Trade.ProviderToInstrument | Table | Detail mode: Unit size for lots-to-units |
| Trade.Provider | Table | Detail mode: IsActive filter for provider |
| History.HedgingBreakdownLog | Table | Detail mode: audit INSERT (EntryType=3) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeExposureWithNoRequests | Procedure | Calls with @InstrumentID for per-instrument detail |
| Hedge Server (external) | External caller | Polls for exposure data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. No transaction, no error handling. Known quirk: @Difference is declared as INT which truncates sub-lot fractional exposure differences. This does not raise an error. Supersedes Trade.HedgeExposureQuery_Org (which used PlayerLevelID<>4 instead of IsComputeForHedge=1).

---

## 8. Sample Queries

### 8.1 Summary mode - all instruments on a hedge server

```sql
EXEC Trade.HedgeExposureQuery @HedgeServerID = 24;
```

### 8.2 Detail mode - single instrument with logging

```sql
EXEC Trade.HedgeExposureQuery
    @HedgeServerID = 24,
    @InstrumentID = 1,   -- EUR/USD
    @HedgeInstrument = 1;
```

### 8.3 Check recent HedgingBreakdownLog entries for an instrument

```sql
SELECT TOP 20
    LogID, EntryType, InstrumentID, HedgeServerID,
    AmountInUnitsDecimal, HedgedInstrument, HedgedAmountInUnitsDecimal, OccurredAt
FROM History.HedgingBreakdownLog WITH (NOLOCK)
WHERE InstrumentID = 1 AND HedgeServerID = 24 AND EntryType = 3
ORDER BY OccurredAt DESC;
```

### 8.4 Compare summary vs detail for the same instrument

```sql
-- Summary (from view)
EXEC Trade.HedgeExposureQuery @HedgeServerID = 24;

-- Detail (real-time calc for EUR/USD)
EXEC Trade.HedgeExposureQuery @HedgeServerID = 24, @InstrumentID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/4 (1, 11 - Phase 8: callers found, Phase 10: skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Trade.HedgeExposureWithNoRequests) | App Code: 0 repos (skipped) | Corrections: 0 applied*
*Object: Trade.HedgeExposureQuery | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.HedgeExposureQuery.sql*
