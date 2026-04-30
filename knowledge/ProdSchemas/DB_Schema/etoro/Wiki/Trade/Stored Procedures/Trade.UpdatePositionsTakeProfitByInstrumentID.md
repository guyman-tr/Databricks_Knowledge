# Trade.UpdatePositionsTakeProfitByInstrumentID

> Cursor-driven batch procedure that re-aligns take-profit rates for all open positions on a given instrument to the maximum allowed level (200% RateDiffPercentage by default), calling Trade.PositionEditTakeProfit per tree, writing audit records to History.SystemUpdatePositionTakeProfit and History.BrexitModifiedPositions, with per-tree error isolation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a regulatory change, corporate action, or platform policy change alters the maximum allowed take-profit percentage for an instrument, all existing positions with a take-profit rate exceeding the new limit must be adjusted downward to comply. This procedure automates that bulk adjustment.

The procedure was originally created for "Free Stocks" (FB 53719, March 2019 - likely related to the UK/EU Brexit regulatory adjustments based on the History.BrexitModifiedPositions audit table name). It:

1. Uses Trade.OldAndNewTakeProfitPerInstrumentID to identify all positions where the current TP exceeds the maximum allowed by @RateDiffPercentage
2. Iterates over each affected tree (position group) via cursor
3. Calls Trade.PositionEditTakeProfit to apply the new capped TP rate
4. Records audit data in two history tables
5. Continues to the next tree on error (per-tree isolation)

The @PositionID parameter allows targeting a single position for testing or selective re-alignment. The @RateDiffPercentage default of 200 means "cap TP at 200% above the entry rate."

---

## 2. Business Logic

### 2.1 Precision-Rounded MaxTakeProfitRate

**What**: The maximum take-profit rate is rounded to the instrument's price precision before comparison and application.

**Columns/Parameters Involved**: `Trade.ProviderToInstrument.Precision`, `MaxTakeProfitRate`

**Rules**:
- `SELECT @Precision = Precision FROM Trade.ProviderToInstrument WHERE InstrumentID = @InstrumentID`
- `ROUND(MaxTakeProfitRate, @Precision) AS MaxTakeProfitRate` applied in the cursor query
- Ensures the new TP rate is consistent with the instrument's displayed price format

### 2.2 OldAndNewTakeProfitPerInstrumentID Function

**What**: A table-valued function computes current and maximum TP rates per position for the instrument.

**Columns/Parameters Involved**: `Trade.OldAndNewTakeProfitPerInstrumentID`, `@InstrumentID`, `@RateDiffPercentage`, `@PositionID`

**Rules**:
- Returns: TreeID, CurrentRate (current price), OrigTakeProfit (current TP rate), MaxTakeProfitRate (new max TP), TpPNLDelta, CID, IsBuy, IsDiscounted
- Filter: `WHERE OrigTakeProfit <> MaxTakeProfitRate` - only processes trees where TP needs changing
- JOINed with Trade.Position to confirm the tree has an active position

### 2.3 Per-Tree PositionEditTakeProfit Execution

**What**: Each affected tree gets its take-profit updated via the standard PositionEditTakeProfit procedure.

**Columns/Parameters Involved**: `@TreeID`, `@MaxTakeProfitRate`, `Trade.PositionEditTakeProfit`

**Rules**:
- EXEC Trade.PositionEditTakeProfit @TreeID, @MaxTakeProfitRate, 0, @XMLResult OUTPUT, NULL, NULL, NULL, NULL, -1, @ErrOut OUTPUT, null
- The -1 operatorID signals system/automated update
- 0 as second positional parameter = isPercent flag (rate is absolute, not percentage)
- Each tree processed in its own BEGIN TRAN / COMMIT; on error ROLLBACK (error printed but processing continues)

### 2.4 Rollback Script Generation

**What**: A rollback exec script is generated for each tree before the update, stored in audit for manual recovery.

**Columns/Parameters Involved**: `@RollBackExec`, `History.SystemUpdatePositionTakeProfit.RollBackExec`

**Rules**:
- `@RollBackExec = CONCAT('DECLARE @XMLResult XML; ... EXEC Trade.PositionEditTakeProfit ', @TreeID, ',', @OrigTakeProfit, ',...')`
- Stores the exact call needed to restore the TP to its pre-change value
- This allows operations to reverse individual tree changes if needed

### 2.5 Dual Audit Logging

**What**: Two history tables capture the operation for compliance and operational auditing.

**Columns/Parameters Involved**: `History.SystemUpdatePositionTakeProfit`, `History.BrexitModifiedPositions`

**Rules**:
- SystemUpdatePositionTakeProfit: OperationID (batch correlator), Occurred, TreeID, OrigTakeProfit, MaxTakeProfitRate, RateDiffPercentage, ConversionRate, CurrentRate, RollBackExec, Description, TpPNLDelta
- BrexitModifiedPositions: InstrumentID, TreeID, CID, NewTakeProfit, IsBuy, IsDiscounted - a compliance/regulatory audit table
- Both records inserted in the same transaction as the PositionEditTakeProfit call

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | int | NO | - | CODE-BACKED | The instrument whose positions are to have their take-profit rates re-aligned. Used to look up Precision, passed to OldAndNewTakeProfitPerInstrumentID, and stored in audit records. |
| 2 | @RateDiffPercentage | decimal(16,8) | YES | 200 | CODE-BACKED | Maximum allowed take-profit as a percentage above the current rate. Default 200 = cap at 200% above entry rate. Passed to Trade.OldAndNewTakeProfitPerInstrumentID to compute MaxTakeProfitRate for each tree. Only trees where OrigTakeProfit exceeds this computed max are updated. |
| 3 | @PositionID | bigint | YES | NULL | CODE-BACKED | Optional: restrict processing to a single position (for testing or selective fix). When NULL, all positions on the instrument above the TP cap are processed. Passed to Trade.OldAndNewTakeProfitPerInstrumentID as a filter. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.ProviderToInstrument | SELECT (read) | Reads Precision for rounding MaxTakeProfitRate |
| @InstrumentID | Trade.OldAndNewTakeProfitPerInstrumentID | Function call | Returns per-tree TP comparison data for the instrument |
| TreeID | Trade.Position | JOIN | Validates tree has an active open position |
| @InstrumentID | Trade.GetMinorConversionRate | Scalar function | Gets conversion rate for the instrument (used in audit) |
| @TreeID | Trade.PositionEditTakeProfit | EXEC (per tree) | Applies new capped TP rate; -1 = system operator |
| Per-tree outcome | History.SystemUpdatePositionTakeProfit | INSERT | Full audit record per tree with rollback script |
| Per-tree outcome | History.BrexitModifiedPositions | INSERT | Regulatory/compliance audit record per tree |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External operational tooling | Application call | Caller | No internal SP callers found; invoked from ops tools for bulk TP re-alignment after regulatory/policy changes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdatePositionsTakeProfitByInstrumentID (procedure)
|- Trade.ProviderToInstrument (table) [READ - Precision for rate rounding]
|- Trade.GetMinorConversionRate (function) [SCALAR - conversion rate for audit]
|- Trade.OldAndNewTakeProfitPerInstrumentID (function) [TVF - per-tree TP comparison data]
|- Trade.Position (view) [JOIN - confirm active positions]
|- Trade.PositionEditTakeProfit (procedure) [EXEC per tree - applies new TP rate]
|- History.SystemUpdatePositionTakeProfit (table) [INSERT - full audit with rollback script]
+-- History.BrexitModifiedPositions (table) [INSERT - regulatory compliance audit]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | READ: Precision column for ROUND(MaxTakeProfitRate, @Precision) |
| Trade.GetMinorConversionRate | Scalar Function | Called once to get @ConversionRate for the instrument (stored in audit) |
| Trade.OldAndNewTakeProfitPerInstrumentID | Table-Valued Function | Called in cursor SELECT; returns TreeID, OrigTakeProfit, MaxTakeProfitRate per position |
| Trade.Position | View | JOINed in cursor SELECT to validate TreeID has active position |
| Trade.PositionEditTakeProfit | Procedure | EXECuted per tree with new MaxTakeProfitRate; system operator = -1 |
| History.SystemUpdatePositionTakeProfit | Table | INSERTed: audit record per tree with rollback exec script |
| History.BrexitModifiedPositions | Table | INSERTed: regulatory audit per tree |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External operational tooling | Application | Calls for bulk TP re-alignment during regulatory changes or corporate actions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Per-tree error isolation | Design | CATCH inside cursor loop: ROLLBACK individual tree, print error, continue to next tree |
| TP change only | Filter | WHERE OrigTakeProfit <> MaxTakeProfitRate - skips trees already within the cap |
| Precision rounding | Accuracy | MaxTakeProfitRate rounded to Precision before comparison and application |
| RollBackExec generated | Audit | Pre-change exec string stored for manual rollback capability |
| OperationID from MAX+1 | Correlation | `SELECT ISNULL(MAX(OperationID),0)+1 FROM History.SystemUpdatePositionTakeProfit` - batch identifier |

---

## 8. Sample Queries

### 8.1 Re-align all TP rates for an instrument (default 200% cap)

```sql
EXEC Trade.UpdatePositionsTakeProfitByInstrumentID
    @InstrumentID = 1234
```

### 8.2 Apply a tighter TP cap (150%)

```sql
EXEC Trade.UpdatePositionsTakeProfitByInstrumentID
    @InstrumentID = 1234,
    @RateDiffPercentage = 150
```

### 8.3 Check which positions would be affected (preview)

```sql
SELECT
    A.TreeID,
    A.OrigTakeProfit,
    A.MaxTakeProfitRate,
    A.TpPNLDelta,
    A.CID,
    A.IsBuy
FROM Trade.OldAndNewTakeProfitPerInstrumentID(1234, 200, NULL) A
JOIN Trade.Position B ON A.TreeID = B.TreeID
WHERE A.OrigTakeProfit <> A.MaxTakeProfitRate
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdatePositionsTakeProfitByInstrumentID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdatePositionsTakeProfitByInstrumentID.sql*
