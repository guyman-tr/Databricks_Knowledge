# History.PositionSplit

> Records which closed positions have been processed for each stock split event, serving as the idempotency marker that prevents a position from being adjusted twice for the same split.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (PositionID, SplitID) composite PK clustered |
| **Partition** | No (ON [HISTORY] filegroup) |
| **Indexes** | 2 (1 clustered PK + 1 nonclustered) |

---

## 1. Business Meaning

`History.PositionSplit` is the completion registry for stock split adjustments on closed positions. When a publicly traded company performs a stock split (e.g., a 4-for-1 split), every open and closed position in that instrument must have its rates and unit counts retroactively adjusted so that position data remains economically accurate - the closing rate must reflect the new share price, and unit counts must reflect the new share count.

This table answers one specific question per split: "Has this closed position already been adjusted for split #N?" Each row represents one (position, split) pair that has been successfully processed. Before updating any position in `History.Position`, the split procedure checks that no row exists here for (PositionID, SplitID) - if one already exists, the position is skipped. This makes the split operation safely restartable and idempotent.

Data is written atomically via the `OUTPUT` clause inside `History.SplitClosePositions`: when `History.Position` is updated with split-adjusted rates (InitForexRate * PriceRatio, AmountInUnitsDecimal * AmountRatio, etc.), the OUTPUT clause simultaneously inserts (DELETED.PositionID, @SplitID, GETUTCDATE()) into this table - guaranteeing that the registry update cannot succeed unless the position update succeeds. The table contains ~317,000 rows covering 37 distinct split events from January 2014 through November 2025.

---

## 2. Business Logic

### 2.1 Split Adjustment Idempotency

**What**: Ensures each closed position is adjusted exactly once per split event, making the adjustment process safely restartable.

**Columns/Parameters Involved**: `PositionID`, `SplitID`

**Rules**:
- `History.SplitClosePositions` queries: `LEFT JOIN History.PositionSplit HPS ON HPOS.PositionID = HPS.PositionID AND HPS.SplitID = @SplitID WHERE HPS.PositionID IS NULL`
- Only positions where no matching row exists in History.PositionSplit are processed
- Insertion happens via `OUTPUT DELETED.PositionID, @SplitID, GETUTCDATE() INTO History.PositionSplit` - atomically with the UPDATE to History.Position
- If the adjustment job is interrupted and restarted, already-processed positions are excluded automatically
- The composite PK (PositionID, SplitID) enforces uniqueness - a position can only be adjusted once per split

**Diagram**:
```
History.SplitClosePositions (@SplitID)
    |
    +-> SELECT positions from History.Position
        LEFT JOIN History.PositionSplit WHERE SplitID = @SplitID
        WHERE HPS.PositionID IS NULL   <- unprocessed only
    |
    +-> WHILE unprocessed positions exist:
        |
        +-> UPDATE TOP(2000) History.Position
            SET InitForexRate *= PriceRatio,
                AmountInUnitsDecimal *= AmountRatio,
                LimitRate, StopRate, EndForexRate, etc.
            OUTPUT DELETED.PositionID, @SplitID, GETUTCDATE()
                INTO History.PositionSplit   <- THIS TABLE
```

### 2.2 Rate and Unit Adjustments Applied

**What**: For each stock split, History.Position is updated with adjusted rates and units.

**Columns/Parameters Involved**: `SplitID` (references History.SplitRatio for PriceRatioUnAdjusted, AmountRatioUnAdjusted)

**Rules**:
- PriceRatio and AmountRatio come from History.SplitRatio for the given SplitID
- Rates adjusted: InitForexRate, LimitRate, StopRate, EndForexRate, OrderPriceRate, MarketPriceRate, LastOpPriceRate, SpreadedPipBid, SpreadedPipAsk
- Units adjusted: AmountInUnitsDecimal, LotCountDecimal
- Rounding applied using instrument Precision from Trade.ProviderToInstrument
- Minimum unit count: 0.000001 (floor to prevent zero units)
- Only applies to stock positions (InstrumentTypeID = 5)

---

## 3. Data Overview

317,548 rows covering 37 distinct split events from 2014-01-22 to 2025-11-04.

| PositionID | SplitID | SplitDate | Meaning |
|---|---|---|---|
| 2152413634 | 11497 | 2025-11-04 12:42:03 | Closed position adjusted for split event #11497 on 2025-11-04 |
| 2152413664 | 11497 | 2025-11-04 12:42:03 | Another position adjusted in the same batch run for split #11497 |
| 2152413643 | 11496 | 2025-11-04 12:08:10 | Adjusted for the prior split event #11496, processed 34 min earlier |
| 8765432 | 1001 | 2014-01-22 08:32:42 | Earliest recorded split adjustment - a 2014 position corrected for an early split |

*Average ~8,580 positions per split event. SplitDate is GETUTCDATE() at time of adjustment, not the corporate split announcement date.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | VERIFIED | ID of the closed trading position in History.Position that was adjusted. Part of the composite clustered PK (PositionID, SplitID). Also included in the SplitID-only NCI for SplitID-first lookups. |
| 2 | SplitID | int | NO | - | VERIFIED | ID of the stock split event. References History.SplitRatio.ID (which contains the PriceRatio, AmountRatio, InstrumentID, and MinDate for the split). Together with PositionID forms the composite PK ensuring one adjustment per (position, split). Indexed independently (ix_HistoryPositionSplit on SplitID INCLUDE PositionID) for finding all positions in a split. |
| 3 | SplitDate | datetime | NO | getutcdate() | VERIFIED | UTC timestamp when the adjustment was applied to this position. Set via GETUTCDATE() in the OUTPUT clause of History.SplitClosePositions. Represents the actual processing time, not the corporate split announcement or effective date. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | History.Position | Implicit | The closed position that was adjusted for the split |
| SplitID | History.SplitRatio | Implicit | The stock split definition (ratio, instrument, effective date) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.SplitClosePositions | OUTPUT clause INSERT | WRITER | Atomically inserts rows as closed positions are split-adjusted |
| Trade.SplitOpenPositions | (likely similar) | WRITER | Adjusts open positions - may write to this or a parallel table |
| History.PositionSplitError | PositionID + SplitID | Related | Companion error table for failed split adjustments |
| Monitor.MonitorSplit | SELECT | READER | Monitors split processing progress |
| dbo.AccountStatement_* | SELECT | READER | Account statement reports reference split history |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PositionSplit (table)
(leaf - no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.SplitClosePositions | Stored Procedure | WRITER (OUTPUT clause) + READER (LEFT JOIN for idempotency check) |
| Trade.SplitOpenPositions | Stored Procedure | WRITER/READER - handles open position split adjustments |
| Monitor.MonitorSplit | Stored Procedure | READER - monitors split job progress |
| Trade.GetOrderForClosePositionsOvt | Stored Procedure | READER - references split history |
| dbo.AccountStatement_GetTransactionsReport_v* | Stored Procedure | READER - account statement reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryPositionSplit | CLUSTERED PK | PositionID ASC, SplitID ASC | - | - | Active |
| ix_HistoryPositionSplit | NONCLUSTERED | SplitID ASC | PositionID | - | Active |

*Both indexes: DATA_COMPRESSION=PAGE, on [HISTORY] filegroup.*
*ix_HistoryPositionSplit enables fast lookup of all positions processed for a given SplitID.*

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_HistoryPositionSplit_SplitDate | DEFAULT | `getutcdate()` on SplitDate - auto-sets UTC timestamp at insert |

---

## 8. Sample Queries

### 8.1 All positions adjusted for a specific split

```sql
SELECT PositionID, SplitDate
FROM History.PositionSplit WITH (NOLOCK)
WHERE SplitID = @SplitID
ORDER BY SplitDate ASC
```

### 8.2 All splits applied to a specific position

```sql
SELECT SplitID, SplitDate
FROM History.PositionSplit WITH (NOLOCK)
WHERE PositionID = @PositionID
ORDER BY SplitDate ASC
```

### 8.3 Split completion summary - count of positions per split event

```sql
SELECT
    ps.SplitID,
    COUNT(*) AS PositionsAdjusted,
    MIN(ps.SplitDate) AS ProcessingStarted,
    MAX(ps.SplitDate) AS ProcessingCompleted
FROM History.PositionSplit ps WITH (NOLOCK)
GROUP BY ps.SplitID
ORDER BY ps.SplitID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.3/10 (Elements: 10/10, Logic: 10/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (History.SplitClosePositions full read) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PositionSplit | Type: Table | Source: etoro/etoro/History/Tables/History.PositionSplit.sql*
