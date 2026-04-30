# History.LogTreesManualModifications

> Audit log of admin-initiated bulk changes to copy-trade tree risk parameters (stop-loss, take-profit, trailing stop loss) per instrument, recording before/after values for each modified tree.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK (append-only audit log) |
| **Partition** | No |
| **Indexes** | None |

---

## 1. Business Meaning

History.LogTreesManualModifications is an audit trail for operations and risk management interventions on copy-trade trees. When the trading operations team needs to bulk-adjust risk parameters (stop-loss rates, take-profit rates, trailing stop loss settings) across all trees for a specific instrument - typically during high-volatility events, market halts, or risk recalibrations - the procedure Trade.ChangeTreePropertiesPerInstrument is executed. For every tree that it actually modifies, it writes one row to this table recording the original and new values.

Without this log, there would be no traceable record of which trees were modified by admin action versus customer action. This is important for dispute resolution (a customer asking "why did my stop-loss change?") and for audit compliance (demonstrating that risk interventions were intentional and documented).

The table has no PK, no indexes, and no FK constraints - it is a pure append-only log. Rows are written exclusively by Trade.ChangeTreePropertiesPerInstrument through a cursor-based loop. An entry is only created when at least one property (stop-loss, limit/take-profit, or TSL flag) actually changed for that tree.

---

## 2. Business Logic

### 2.1 Change Threshold Filtering - Only Meaningful Changes Are Logged

**What**: The writer procedure filters out trivially small changes using a minimum percentage threshold before both applying and logging changes. This prevents noise from floating-point rounding in rate calculations.

**Columns/Parameters Involved**: `OrigStopLoss`, `NewStopLoss`, `OrigLimitRate`, `NewLimitRate`, `OrigIsTslEnabled`, `NewIsTslEnabled`

**Rules**:
- Default threshold: @MinPercentageChange = 1% - changes smaller than 1% on both SL and TP are skipped entirely (not applied, not logged)
- The threshold is checked BEFORE writing to this table - a row in this log means the change exceeded the threshold
- TSL flag changes bypass the percentage check - any TSL enable/disable is always applied and logged
- NULL handling: When NewStopLoss or NewLimitRate was NULL in the procedure (meaning "do not change this value"), the INSERT stores ISNULL(@NewStopLoss, @OrigStopLoss) - so Orig=New for unchanged properties

### 2.2 Before/After Pair Pattern

**What**: Each row captures both the original and new values for all three modifiable properties, enabling complete rollback audit and before/after comparison.

**Columns/Parameters Involved**: `OrigStopLoss`, `NewStopLoss`, `OrigLimitRate`, `NewLimitRate`, `OrigIsTslEnabled`, `NewIsTslEnabled`

**Rules**:
- When only stop-loss changed: OrigLimitRate = NewLimitRate (values identical), OrigIsTslEnabled = NewIsTslEnabled
- When only TSL was toggled: OrigStopLoss = NewStopLoss, OrigLimitRate = NewLimitRate, but IsTsl values differ
- A row where all Orig = New should not exist (the writer only INSERTs when at least one change occurred)
- "OrigLimitRate" and "NewLimitRate" represent the take-profit rate (called @OrigTakeProfit/@NewTakeProfit in the procedure code) - the column naming is slightly misleading

**Diagram**:
```
Admin runs: Trade.ChangeTreePropertiesPerInstrument
  @InstrumentID = 5  (e.g., EUR/USD)
  @SLPercentage = 5  (new SL = current_rate - 5%)
  @TPPercentage = 10 (new TP = current_rate + 10%)
  @NewTSL = NULL     (don't change TSL)
  @MinPercentageChange = 1

For each qualifying tree:
  IF |NewSL - OrigSL| / OrigSL > 1% OR |NewTP - OrigTP| / OrigTP > 1%:
    EXEC Trade.UpdateTree(TreeID, NewTP, NewSL, TSL)
    INSERT History.LogTreesManualModifications:
      TreeID, CID, InstrumentID=5
      OrigStopLoss=1.0800, NewStopLoss=1.0350    <- changed
      OrigLimitRate=1.1200, NewLimitRate=1.1650   <- changed
      OrigIsTslEnabled=0, NewIsTslEnabled=0       <- unchanged (NULL=keep original)
```

---

## 3. Data Overview

No data available in test environment (0 rows). This table is only populated when Trade.ChangeTreePropertiesPerInstrument is run, which is an infrequent admin operation triggered during market stress events or periodic risk recalibrations.

Typical production rows would look like:

| TreeID | CID | InstrumentID | OrigStopLoss | NewStopLoss | OrigLimitRate | NewLimitRate | OrigIsTslEnabled | NewIsTslEnabled | Occurred |
|---|---|---|---|---|---|---|---|---|---|
| 123456789 | 45678 | 5 | 1.0800 | 1.0350 | 1.1200 | 1.1650 | 0 | 0 | 2024-03-15 09:12:33 |
| 123456790 | 89012 | 5 | 1.0750 | 1.0305 | 1.1150 | 1.1595 | 1 | 1 | 2024-03-15 09:12:33 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TreeID | bigint | YES | - | CODE-BACKED | The copy-trade tree whose risk parameters were modified. References Trade.PositionTreeInfo.TreeID (no FK enforced). Each tree represents a collection of positions opened by a customer copying a specific leader. The full tree hierarchy is stored in Trade.PositionTreeInfo. NULL is theoretically possible but should not occur in practice. |
| 2 | CID | int | YES | - | CODE-BACKED | Customer ID of the tree owner (the copier). Sourced directly from Trade.ChangeTreeInfoPerInstrument view, which reads it from the tree's position data. NULL theoretically possible but not expected. Used to correlate admin modifications with customer account history for dispute resolution. |
| 3 | InstrumentID | int | YES | - | CODE-BACKED | The instrument for which the bulk parameter adjustment was run. All trees in the same execution of Trade.ChangeTreePropertiesPerInstrument share the same InstrumentID. References History.Instrument.InstrumentID (and Trade.Instrument). |
| 4 | OrigStopLoss | dbo.dtPrice | YES | - | CODE-BACKED | Stop-loss rate in effect before the admin modification. dbo.dtPrice is a UDT (decimal type for price values). For BUY trees: stop-loss is below the current price. For SELL trees: stop-loss is above. Stored as the actual rate (not as a percentage). |
| 5 | NewStopLoss | dbo.dtPrice | YES | - | CODE-BACKED | Stop-loss rate applied after the admin modification. Stored as ISNULL(@NewStopLoss, @OrigStopLoss) - when stop-loss was not the target of this run, NewStopLoss = OrigStopLoss (no change). When changed: the new absolute rate is stored after percentage-based recalculation from current market rate. |
| 6 | OrigLimitRate | dbo.dtPrice | YES | - | CODE-BACKED | Take-profit rate in effect before the admin modification. Named "LimitRate" in the schema (legacy naming), but corresponds to @OrigTakeProfit in the procedure code. For BUY trees: above current price. For SELL trees: below current price. |
| 7 | NewLimitRate | dbo.dtPrice | YES | - | CODE-BACKED | Take-profit rate applied after the admin modification. Named "LimitRate" but represents the new take-profit (@NewTakeProfit in the procedure). Stored as ISNULL(@NewTakeProfit, @OrigTakeProfit) when take-profit was not changed. |
| 8 | OrigIsTslEnabled | tinyint | YES | - | CODE-BACKED | Trailing Stop Loss (TSL) flag before the modification. 0=TSL disabled (fixed stop-loss), 1=TSL enabled (stop-loss trails the price as it moves favorably). TSL enables the stop-loss to automatically move up (for BUY) as the position gains. |
| 9 | NewIsTslEnabled | tinyint | YES | - | CODE-BACKED | Trailing Stop Loss flag after the modification. When @NewTSL parameter was NULL (default), this equals OrigIsTslEnabled (no change). When @NewTSL was specified, this reflects the admin's target TSL state (0=force disable, 1=force enable) across all qualifying trees for the instrument. |
| 10 | Occurred | datetime | YES | getutcdate() | CODE-BACKED | UTC timestamp when this audit row was inserted (when the modification was applied). DEFAULT is getutcdate() - all rows share the same procedure execution timestamp for a given batch run, making it easy to group all changes from one admin operation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TreeID | Trade.PositionTreeInfo | Implicit | References the copy-trade tree that was modified. No FK enforced. |
| CID | Customer.CustomerStatic | Implicit | References the customer who owns the tree. No FK enforced. |
| InstrumentID | History.Instrument / Trade.Instrument | Implicit | The instrument for which the bulk operation was run. No FK enforced. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ChangeTreePropertiesPerInstrument | (INSERT) | Writer | The only writer - inserts one row per modified tree during bulk risk parameter adjustment |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.LogTreesManualModifications (table)
  - No code-level dependencies (leaf table)
```

### 6.1 Objects This Depends On

No dependencies. Free-standing audit log table.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ChangeTreePropertiesPerInstrument | Stored Procedure | Sole writer - inserts one log row per tree modified in each bulk risk adjustment run |

---

## 7. Technical Details

### 7.1 Indexes

N/A - No indexes defined on this table.

Note: The absence of indexes reflects the infrequent, append-only nature of this table. With no expected high-frequency queries (only occasional admin audits), no indexing overhead is justified. For production auditing queries, a full scan is acceptable given the expected low row count.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_HistoryLogTreesManualModifications_Occurred | DEFAULT | Occurred = getutcdate() - UTC timestamp automatically applied on insert |

---

## 8. Sample Queries

### 8.1 Find all trees modified in a specific bulk operation (by date)

```sql
SELECT
    TreeID,
    CID,
    InstrumentID,
    OrigStopLoss,
    NewStopLoss,
    OrigLimitRate,
    NewLimitRate,
    OrigIsTslEnabled,
    NewIsTslEnabled,
    Occurred
FROM [History].[LogTreesManualModifications] WITH (NOLOCK)
WHERE CAST(Occurred AS DATE) = '2024-03-15'
  AND InstrumentID = 5
ORDER BY Occurred, TreeID
```

### 8.2 Find all admin modifications to a specific customer's trees

```sql
SELECT
    ltmm.TreeID,
    ltmm.InstrumentID,
    ltmm.OrigStopLoss,
    ltmm.NewStopLoss,
    ltmm.OrigLimitRate,
    ltmm.NewLimitRate,
    ltmm.OrigIsTslEnabled,
    ltmm.NewIsTslEnabled,
    ltmm.Occurred
FROM [History].[LogTreesManualModifications] ltmm WITH (NOLOCK)
WHERE ltmm.CID = @CustomerCID
ORDER BY ltmm.Occurred DESC
```

### 8.3 Summary of bulk operations by instrument and date

```sql
SELECT
    CAST(Occurred AS DATE) AS OperationDate,
    InstrumentID,
    COUNT(*) AS TreesModified,
    MIN(Occurred) AS StartedAt,
    MAX(Occurred) AS CompletedAt,
    SUM(CASE WHEN OrigIsTslEnabled <> NewIsTslEnabled THEN 1 ELSE 0 END) AS TSLChanges,
    SUM(CASE WHEN OrigStopLoss <> NewStopLoss THEN 1 ELSE 0 END) AS SLChanges,
    SUM(CASE WHEN OrigLimitRate <> NewLimitRate THEN 1 ELSE 0 END) AS TPChanges
FROM [History].[LogTreesManualModifications] WITH (NOLOCK)
GROUP BY CAST(Occurred AS DATE), InstrumentID
ORDER BY OperationDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Trade.ChangeTreePropertiesPerInstrument) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.LogTreesManualModifications | Type: Table | Source: etoro/etoro/History/Tables/History.LogTreesManualModifications.sql*
