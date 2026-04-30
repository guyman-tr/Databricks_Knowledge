# Hedge.DeleteZeroRowPositionsHedgePersistData

> Maintenance procedure that removes fully-closed zero-unit position rows from the hedge server persistence cache, keeping the table clean by eliminating instruments with no remaining customer exposure.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - targets rows with AmountInUnitsDecimal = 0 AND Redeemed = 0 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure removes stale position rows from `Hedge.PositionsHedgeTbl`, the hedge server's local persistence cache of aggregate customer positions. When a customer's aggregate position on an instrument has been fully closed (no remaining units) and no portion is pending redemption, the row is eligible for cleanup. This procedure deletes those rows, ensuring the hedge server's working table reflects only instruments with active exposure.

The procedure is part of the three-operation lifecycle of `Hedge.PositionsHedgeTbl`: rows are batch-upserted by `SetHedgePersistData`, the table is fully truncated by `ClearHedgeExposuresPersistData`, and this procedure removes individual zero-balance rows between full refreshes. Without this cleanup, the table would accumulate fully-closed position rows that the hedge engine might incorrectly treat as requiring active hedging.

The two-condition predicate (`AmountInUnitsDecimal = 0 AND Redeemed = 0`) ensures partially redeemed positions are NOT removed - a position in mid-redemption (Redeemed > 0) is retained even if the primary amount has reached zero, since redemption processing may still be in progress.

---

## 2. Business Logic

### 2.1 Two-Condition Cleanup Predicate

**What**: Both conditions must be met to delete a row - a position with any pending redemption is NOT cleaned up, even if the primary amount is zero.

**Columns/Parameters Involved**: `AmountInUnitsDecimal`, `Redeemed` in `Hedge.PositionsHedgeTbl`

**Rules**:
- `AmountInUnitsDecimal = 0`: The aggregate position size (long or short) has reached zero - no more customer exposure in this direction
- `Redeemed = 0`: No units are in the redemption pipeline - the position is fully settled
- BOTH conditions together define "fully closed"
- A row with `AmountInUnitsDecimal = 0` but `Redeemed > 0` is a position being redeemed - it MUST stay until redemption completes
- The `Ix_AmountInUnitsDecimalRedeemed` nonclustered index (columns: AmountInUnitsDecimal ASC, Redeemed ASC) directly supports this deletion predicate

**Diagram**:
```
Hedge.PositionsHedgeTbl
  AmountInUnitsDecimal | Redeemed | Action
  ----------------------------------------
  5,000,000            | 0        | KEEP - active position
  0                    | 500,000  | KEEP - redemption pending
  0                    | 0        | DELETE - fully closed
```

### 2.2 Companion to SetHedgePersistData / ClearHedgeExposuresPersistData

**What**: Three operations manage the lifecycle of `Hedge.PositionsHedgeTbl`, each covering a distinct scenario.

**Rules**:
- `SetHedgePersistData` - UPSERT: bulk-loads fresh position data via TVP, adding new rows and updating existing ones
- `ClearHedgeExposuresPersistData` - TRUNCATE: wipes all rows for a full refresh cycle; used when the hedge server restarts or resyncs from scratch
- `DeleteZeroRowPositionsHedgePersistData` - CLEANUP: incremental removal of individual rows that have become fully closed; used during normal operation between full refreshes

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | CODE-BACKED | No input parameters. The target table, deletion criteria, and logic are hardcoded. Deletes all rows in `Hedge.PositionsHedgeTbl` where both `AmountInUnitsDecimal = 0` and `Redeemed = 0`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DELETE target | Hedge.PositionsHedgeTbl | Direct DML | Deletes rows where `AmountInUnitsDecimal = 0 AND Redeemed = 0`. The `Ix_AmountInUnitsDecimalRedeemed` index on these two columns supports efficient identification of qualifying rows. |

### 5.2 Referenced By (other objects point to this)

No application code callers detected. Likely invoked by the hedging engine's operational cycle or a SQL Agent job as part of the persistence cache maintenance sequence (analogous to `DeleteZeroRowNetOpenHedgePersistData` for the companion global net open table).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.DeleteZeroRowPositionsHedgePersistData (procedure)
└── Hedge.PositionsHedgeTbl (table) - DELETE target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.PositionsHedgeTbl | Table | DELETE WHERE AmountInUnitsDecimal = 0 AND Redeemed = 0 - removes fully-closed per-direction position rows from the hedge server persistence cache |

### 6.2 Objects That Depend On This

No dependents found. This is a leaf maintenance operation.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Two-column predicate | Business Rule | `AmountInUnitsDecimal = 0 AND Redeemed = 0` - both the primary position amount and the redemption amount must be zero for a row to be deleted. Protects mid-redemption rows. |
| Index-assisted | Performance | The `Ix_AmountInUnitsDecimalRedeemed` NC index on (AmountInUnitsDecimal, Redeemed) was created specifically to support this query |

---

## 8. Sample Queries

### 8.1 Check rows eligible for deletion

```sql
SELECT InstrumentID, HedgeServerID, IsBuy, AmountInUnitsDecimal, Redeemed, LastUpdated
FROM Hedge.PositionsHedgeTbl WITH (NOLOCK)
WHERE AmountInUnitsDecimal = 0
AND   Redeemed = 0
ORDER BY LastUpdated DESC
```

### 8.2 Position state distribution (active vs redeemed vs closed)

```sql
SELECT
    SUM(CASE WHEN AmountInUnitsDecimal > 0 AND Redeemed = 0 THEN 1 ELSE 0 END) AS ActiveRows,
    SUM(CASE WHEN AmountInUnitsDecimal = 0 AND Redeemed > 0 THEN 1 ELSE 0 END) AS RedemptionPendingRows,
    SUM(CASE WHEN AmountInUnitsDecimal = 0 AND Redeemed = 0 THEN 1 ELSE 0 END) AS EligibleForCleanup,
    COUNT(*) AS TotalRows
FROM Hedge.PositionsHedgeTbl WITH (NOLOCK)
```

### 8.3 Compare cleanup eligibility with companion global table

```sql
-- Per-server table (this SP's target)
SELECT 'PositionsHedgeTbl' AS TableName,
       COUNT(*) AS ZeroRows
FROM Hedge.PositionsHedgeTbl WITH (NOLOCK)
WHERE AmountInUnitsDecimal = 0 AND Redeemed = 0
UNION ALL
-- Global net table (companion SP's target)
SELECT 'PositionsNetOpenDollarTbl',
       COUNT(*)
FROM Hedge.PositionsNetOpenDollarTbl WITH (NOLOCK)
WHERE NetOpenUnits = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.DeleteZeroRowPositionsHedgePersistData | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.DeleteZeroRowPositionsHedgePersistData.sql*
