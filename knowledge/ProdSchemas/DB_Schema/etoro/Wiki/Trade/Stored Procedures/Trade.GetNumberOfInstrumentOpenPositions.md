# Trade.GetNumberOfInstrumentOpenPositions

> Returns the count of open positions for a specific instrument, with an optional filter for settled/unsettled positions, used for instrument-level exposure monitoring and position limit checks.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID - the instrument to count open positions for |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetNumberOfInstrumentOpenPositions` returns the total count of open positions (`StatusID=1`) for a given instrument across all customers. The optional `@IsSettled` parameter allows callers to further filter to either settled or unsettled positions.

This procedure exists to provide instrument-level open interest data. It is used for:
- **Instrument exposure monitoring**: How many open positions exist for an instrument (e.g., before disabling trading).
- **Position limit enforcement**: Checking whether an instrument is approaching system-wide position limits.
- **Settlement tracking**: With `@IsSettled=1`, counting positions that have been settled (e.g., stock delivery complete); with `@IsSettled=0`, counting positions still pending settlement.

`COUNT_BIG` is used instead of `COUNT` to handle instruments with very large position counts that might overflow INT. `OPTION (RECOMPILE)` forces a fresh plan for each execution, preventing parameter sniffing issues given the wide variance in position counts across instruments.

Data flows: Called by monitoring and risk management services. Returns a single row: `NumberOfOpenPositions` as BIGINT.

---

## 2. Business Logic

### 2.1 Open Positions Only (StatusID=1)

**What**: Counts only currently open positions.

**Columns/Parameters Involved**: `StatusID`

**Rules**:
- `StatusID = 1`: Open positions only. Closed positions (StatusID=2), cancelled (StatusID=3), etc. are excluded.
- This provides the current live open interest count for the instrument, not historical.

### 2.2 Optional Settlement Filter

**What**: `@IsSettled` enables filtering to settled or unsettled positions when needed.

**Columns/Parameters Involved**: `@IsSettled`, `IsSettled`

**Rules**:
- `@IsSettled IS NULL` (default): Returns total open positions regardless of settlement state (includes both settled and unsettled).
- `@IsSettled = 1`: Returns only open positions that have been settled. Used for settled stock/ETF positions.
- `@IsSettled = 0`: Returns only open positions not yet settled. Used to monitor pending settlement queue.
- Two separate query branches (`IF/ELSE`) rather than `WHERE (IsSettled = @IsSettled OR @IsSettled IS NULL)` - the explicit branching allows `OPTION (RECOMPILE)` to produce optimal plans for each case.

### 2.3 COUNT_BIG and OPTION RECOMPILE

**What**: Performance and capacity safeguards.

**Rules**:
- `COUNT_BIG(1)`: Returns BIGINT. Necessary for high-volume instruments (e.g., major stocks or crypto) where COUNT(INT) could overflow.
- `OPTION (RECOMPILE)`: Forces recompilation on each execution. Prevents the optimizer from caching a plan optimized for a high-volume instrument that would be inefficient for a low-volume instrument, or vice versa.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | The instrument to count open positions for. |
| 2 | @IsSettled | BIT | YES | NULL | CODE-BACKED | Optional settlement filter. NULL = all open positions. 1 = settled open positions only. 0 = unsettled open positions only. |

**Output columns** (result set):

| # | Column | Description |
|---|--------|-------------|
| 1 | NumberOfOpenPositions | Count of open positions (StatusID=1) for the instrument, optionally filtered by IsSettled. BIGINT (COUNT_BIG) to handle high-volume instruments. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.PositionTbl | Primary read | COUNT_BIG of open positions WHERE InstrumentID=@InstrumentID AND StatusID=1, optionally filtered by IsSettled. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetNumberOfInstrumentOpenPositions (procedure)
└── Trade.PositionTbl (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | COUNT_BIG(1) WHERE InstrumentID=@InstrumentID AND StatusID=1 [AND IsSettled=@IsSettled] WITH (NOLOCK) OPTION (RECOMPILE) |

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

### 8.1 Count all open positions for an instrument

```sql
EXEC Trade.GetNumberOfInstrumentOpenPositions @InstrumentID = 1000;
```

### 8.2 Count only unsettled open positions

```sql
EXEC Trade.GetNumberOfInstrumentOpenPositions @InstrumentID = 1000, @IsSettled = 0;
```

### 8.3 Count only settled open positions (e.g., stock holdings)

```sql
EXEC Trade.GetNumberOfInstrumentOpenPositions @InstrumentID = 1000, @IsSettled = 1;
```

### 8.4 Direct equivalent query

```sql
SELECT COUNT_BIG(1) AS NumberOfOpenPositions
FROM Trade.PositionTbl WITH (NOLOCK)
WHERE InstrumentID = 1000
  AND StatusID = 1
  AND IsSettled = 0  -- or omit for all
OPTION (RECOMPILE);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetNumberOfInstrumentOpenPositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetNumberOfInstrumentOpenPositions.sql*
