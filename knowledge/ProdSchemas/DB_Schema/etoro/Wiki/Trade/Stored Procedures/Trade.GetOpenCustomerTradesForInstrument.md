# Trade.GetOpenCustomerTradesForInstrument

> Returns the total count of all positions for a specific instrument as an OUTPUT parameter, used to check instrument-level trade volume regardless of position status.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID - the instrument to count trades for |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetOpenCustomerTradesForInstrument` counts ALL positions for a given instrument from `Trade.Position` (the view, not the raw table) and returns the count via an OUTPUT parameter. Despite the name "Open" in the procedure, there is no `StatusID` filter - it counts all positions including open, closed, and cancelled. The name reflects its original purpose: counting active customer engagement with an instrument.

This procedure is primarily used to determine whether any trades exist for an instrument before performing operations that require the instrument to be free of positions (e.g., instrument deprecation, product lifecycle changes, or admin cleanup tasks).

Key distinction from `GetNumberOfInstrumentOpenPositions`:
- `GetOpenCustomerTradesForInstrument`: ALL positions (no status filter), reads `Trade.Position` view, returns via OUTPUT parameter.
- `GetNumberOfInstrumentOpenPositions`: Open positions only (StatusID=1), reads `Trade.PositionTbl` directly, returns as result set column.

Data flows: Called by admin/operations services performing pre-condition checks on instruments. Returns via `@NumOfTrades INT OUTPUT`.

---

## 2. Business Logic

### 2.1 All Positions - No Status Filter

**What**: Counts all positions for the instrument regardless of open/closed state.

**Columns/Parameters Involved**: `@NumOfTrades`, `Trade.Position`

**Rules**:
- `SELECT @NumOfTrades = COUNT(*) FROM Trade.Position WHERE InstrumentID = @InstrumentID`: No `StatusID` filter.
- `Trade.Position` is a view (not `Trade.PositionTbl` directly). The view may apply its own filters or joins.
- `COUNT(*)` includes all rows matching the InstrumentID - open, closed, and any other status.
- Result is assigned to `@NumOfTrades OUTPUT` (not a result set).
- No `SET NOCOUNT ON`, but there is no result set to suppress - the count goes to the OUTPUT parameter.

### 2.2 OUTPUT Parameter Return

**What**: Returns the count via OUTPUT parameter rather than a SELECT result set.

**Columns/Parameters Involved**: `@NumOfTrades INT OUTPUT`

**Rules**:
- The caller must declare and pass `@NumOfTrades` as an OUTPUT variable.
- This pattern is used in stored procedure chains where the count is needed for a subsequent decision without the overhead of a result set.
- If no rows exist for the instrument, `@NumOfTrades` will be 0 (COUNT(*) always returns a value, even for empty sets).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | The instrument to count positions for. |
| 2 | @NumOfTrades | INT | NO | - (OUTPUT) | CODE-BACKED | OUTPUT parameter. Receives the total count of all positions for the instrument (no status filter). 0 if no positions found. |

**Output**: Via OUTPUT parameter only. No result set returned.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.Position | Primary read | COUNT(*) of all positions WHERE InstrumentID=@InstrumentID. No status filter. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOpenCustomerTradesForInstrument (procedure)
└── Trade.Position (view)
    └── Trade.PositionTbl (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | SELECT COUNT(*) WHERE InstrumentID=@InstrumentID - all positions, no status filter |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Check if any trades exist for an instrument

```sql
DECLARE @TradeCount INT;
EXEC Trade.GetOpenCustomerTradesForInstrument
    @InstrumentID = 1000,
    @NumOfTrades = @TradeCount OUTPUT;

IF @TradeCount = 0
    PRINT 'No trades for this instrument - safe to deprecate';
ELSE
    PRINT CONCAT('Instrument has ', @TradeCount, ' trades');
```

### 8.2 Equivalent direct query

```sql
SELECT COUNT(*) AS NumOfTrades
FROM Trade.Position
WHERE InstrumentID = 1000;
```

### 8.3 Compare with open-positions-only count

```sql
-- All positions (any status) - GetOpenCustomerTradesForInstrument equivalent
SELECT COUNT(*) AS AllTrades FROM Trade.Position WHERE InstrumentID = 1000;

-- Open positions only - GetNumberOfInstrumentOpenPositions equivalent
SELECT COUNT_BIG(1) AS OpenTrades FROM Trade.PositionTbl WITH (NOLOCK)
WHERE InstrumentID = 1000 AND StatusID = 1 OPTION (RECOMPILE);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOpenCustomerTradesForInstrument | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOpenCustomerTradesForInstrument.sql*
