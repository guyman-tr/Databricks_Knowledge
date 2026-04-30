# Hedge.DeleteZeroRowNetOpenHedgePersistData

> Maintenance procedure that removes zero-exposure rows from the global net open exposure cache, cleaning up instruments that have reached a fully closed net position.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - targets rows with NetOpenUnits = 0 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure removes stale zero-unit rows from `Hedge.PositionsNetOpenDollarTbl`, the global net open exposure cache that holds one row per instrument. When a customer's aggregate net position on an instrument reaches zero (all positions cancelled or offset), the row still remains in the table with `NetOpenUnits = 0`. This procedure cleans up those rows, keeping the table lean and accurate.

The procedure is part of the three-operation lifecycle for `Hedge.PositionsNetOpenDollarTbl`: the table is batch-upserted by `Hedge.SetNetOpenDollarPersistData`, fully truncated by `Hedge.ClearNetOpenExposuresPersistData`, and incrementally cleaned of zero rows by this procedure.

This cleanup is called as part of the hedging engine's operational cycle when the hedge system needs to compact its in-memory representation of customer exposure. Without this cleanup, instruments with no net open customer positions would continue to appear as entries in the table, potentially causing the hedge engine to consider hedging against instruments that require no hedge.

---

## 2. Business Logic

### 2.1 Zero-Unit Cleanup Predicate

**What**: The cleanup criterion is `NetOpenUnits = 0`, representing instruments where the aggregate customer position has fully closed out.

**Columns/Parameters Involved**: `NetOpenUnits` in `Hedge.PositionsNetOpenDollarTbl`

**Rules**:
- Only `NetOpenUnits = 0` triggers deletion - `NetOpenDollars` rounding residuals are ignored
- A row with `NetOpenUnits = 0` means all customer positions on that instrument have been offset or closed at the hedge server level
- The `Redeemed` column logic used in the companion `DeleteZeroRowPositionsHedgePersistData` is NOT applied here - this table has no such column
- After deletion, the instrument disappears entirely from the table until new customer exposure is reported

**Diagram**:
```
Hedge.PositionsNetOpenDollarTbl
  InstrumentID | NetOpenUnits | ...
  ----------------------------------------
  1            | 15,500,000   | (KEEP - active exposure)
  5            | 2,300,000    | (KEEP - active exposure)
  17           | 0            | (DELETE - zero net exposure)
  42           | 0            | (DELETE - zero net exposure)
```

### 2.2 Companion to SetNetOpenDollarPersistData / ClearNetOpenExposuresPersistData

**What**: This procedure is one of three operations that manage `Hedge.PositionsNetOpenDollarTbl`, each serving a distinct role in the exposure data lifecycle.

**Rules**:
- `SetNetOpenDollarPersistData` - UPSERT: adds new instruments and updates existing ones with latest exposure data
- `ClearNetOpenExposuresPersistData` - TRUNCATE: wipes the entire table at the start of a full rebuild cycle
- `DeleteZeroRowNetOpenHedgePersistData` - CLEANUP: incrementally removes individual instruments that have no exposure, used between full rebuilds

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | CODE-BACKED | No input parameters. The target table and deletion criterion (`NetOpenUnits = 0`) are hardcoded. Operates on the entire `Hedge.PositionsNetOpenDollarTbl` table unconditionally. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DELETE target | Hedge.PositionsNetOpenDollarTbl | Direct DML | Deletes rows where `NetOpenUnits = 0`. The `Ix_NetOpenUnits` nonclustered index on this column supports efficient identification of zero-value rows. |

### 5.2 Referenced By (other objects point to this)

No application code callers detected. Likely invoked by the hedging engine's operational cycle or a SQL Agent job as part of the exposure persistence maintenance sequence.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.DeleteZeroRowNetOpenHedgePersistData (procedure)
└── Hedge.PositionsNetOpenDollarTbl (table) - DELETE target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.PositionsNetOpenDollarTbl | Table | DELETE WHERE NetOpenUnits = 0 - removes zero-exposure instruments from the global net open cache |

### 6.2 Objects That Depend On This

No dependents found. This is a leaf maintenance operation.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Deletion predicate | Business Rule | `NetOpenUnits = 0` - only rows with zero units are deleted; rows with positive or negative exposure are always retained |
| SET NOCOUNT | N/A | Not set in this proc; rows-affected count is returned to caller |

---

## 8. Sample Queries

### 8.1 Check rows that would be deleted

```sql
SELECT InstrumentID, IsBuy, NetOpenUnits, NetOpenDollars, LastUpdated
FROM Hedge.PositionsNetOpenDollarTbl WITH (NOLOCK)
WHERE NetOpenUnits = 0
ORDER BY LastUpdated DESC
```

### 8.2 Monitor zero-unit row count over time

```sql
SELECT
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN NetOpenUnits = 0 THEN 1 ELSE 0 END) AS ZeroUnitRows,
    SUM(CASE WHEN NetOpenUnits > 0 THEN 1 ELSE 0 END) AS ActiveRows
FROM Hedge.PositionsNetOpenDollarTbl WITH (NOLOCK)
```

### 8.3 Compare with companion procedure on PositionsHedgeTbl

```sql
-- Zero-unit rows in global net open table
SELECT 'PositionsNetOpenDollarTbl' AS TableName, COUNT(*) AS ZeroRows
FROM Hedge.PositionsNetOpenDollarTbl WITH (NOLOCK)
WHERE NetOpenUnits = 0
UNION ALL
-- Zero-amount rows in per-hedge-server table
SELECT 'PositionsHedgeTbl', COUNT(*)
FROM Hedge.PositionsHedgeTbl WITH (NOLOCK)
WHERE AmountInUnitsDecimal = 0 AND Redeemed = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.DeleteZeroRowNetOpenHedgePersistData | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.DeleteZeroRowNetOpenHedgePersistData.sql*
