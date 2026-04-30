# Trade.DeltaDiffDataAdd

> Inserts a new P&L/balance reconciliation snapshot into Trade.DeltaDiff and closes the temporal validity window of the previous row.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DiffID (generated via Internal.GetDeltaDiffID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records a **point-in-time reconciliation snapshot** of P&L and account balance metrics into Trade.DeltaDiff. Each call creates a new row representing the current state of realized/unrealized P&L, account balances, and commissions computed using different calculation methods (delta-diff vs. fully-calculated).

The DeltaDiff table supports financial reconciliation and audit by storing side-by-side metrics from different computation approaches. By comparing Diff* columns against Fully* columns, analysts can detect calculation drift or discrepancies between incremental and full recomputation methods.

The procedure implements a **temporal insert pattern**: it obtains a new DeltaDiffID from Internal.GetDeltaDiffID, inserts the new row with ValidTo='21000101' (representing "current"), then closes the previous current row by setting its ValidTo to the new row's ValidFrom. This creates a valid-time chain enabling time-series queries like "what were the metrics at time X?"

---

## 2. Business Logic

### 2.1 Temporal Validity Chain

**What**: Maintains a chain of non-overlapping validity windows using ValidFrom/ValidTo columns.

**Columns/Parameters Involved**: `DeltaDiffID`, `ValidFrom`, `ValidTo`

**Rules**:
- New row: ValidFrom = GETUTCDATE(), ValidTo = '21000101' (far-future sentinel meaning "currently valid")
- Previous row: UPDATE SET ValidTo = new row's ValidFrom WHERE ValidTo = '21000101' AND DeltaDiffID < @DiffID
- Uses OUTPUT INSERTED.ValidFrom into a table variable to capture the exact ValidFrom for the UPDATE
- Runs in an explicit transaction; ROLLBACK on either INSERT or UPDATE failure

### 2.2 Metrics Captured

**What**: 15 financial metrics per snapshot, spanning realized/unrealized P&L, balances, and commissions.

**Columns/Parameters Involved**: All 15 @parameters

**Rules**:
- AccountRealizedSum, AccountsUnRealizedSum: aggregate realized/unrealized sums
- Diff, Diff1AccountBalance, Diff1AccountNetPL, DiffAccountBalance, DiffAccountNetPL: delta-computed metrics
- FullyAccountBalance, FullyAccountNetPL: fully-recomputed metrics
- RealizedCommission, RealizedPNL, RealizedPNLWCom: realized with/without commission
- UnRealizedCommission, UnRealizedPNL, UnRealizedPNLWCom: unrealized with/without commission
- @ValidFrom and @ValidTo parameters exist for backward compatibility only and are NOT used

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AccountRealizedSum | dtPrice | NO | - | CODE-BACKED | Aggregate realized sum across accounts. Snapshot of total realized value at this checkpoint. |
| 2 | @AccountsUnRealizedSum | dtPrice | NO | - | CODE-BACKED | Aggregate unrealized sum across accounts. Snapshot of total unrealized value at this checkpoint. |
| 3 | @Diff | dtPrice | NO | - | CODE-BACKED | Delta difference between calculation methods. Represents the discrepancy between incremental and full computation. |
| 4 | @Diff1AccountBalance | dtPrice | NO | - | CODE-BACKED | First-order delta of account balance between calculation methods. |
| 5 | @Diff1AccountNetPL | dtPrice | NO | - | CODE-BACKED | First-order delta of account net P&L between calculation methods. |
| 6 | @DiffAccountBalance | dtPrice | NO | - | CODE-BACKED | Delta-computed account balance (incremental calculation). |
| 7 | @DiffAccountNetPL | dtPrice | NO | - | CODE-BACKED | Delta-computed account net P&L (incremental calculation). |
| 8 | @FullyAccountBalance | dtPrice | NO | - | CODE-BACKED | Fully-recomputed account balance (complete recalculation). |
| 9 | @FullyAccountNetPL | dtPrice | NO | - | CODE-BACKED | Fully-recomputed account net P&L (complete recalculation). |
| 10 | @RealizedCommission | dtPrice | NO | - | CODE-BACKED | Total realized commission at this checkpoint. |
| 11 | @RealizedPNL | dtPrice | NO | - | CODE-BACKED | Realized P&L excluding commission. |
| 12 | @RealizedPNLWCom | dtPrice | NO | - | CODE-BACKED | Realized P&L including commission (with commission). |
| 13 | @UnRealizedCommission | dtPrice | NO | - | CODE-BACKED | Total unrealized commission at this checkpoint. |
| 14 | @UnRealizedPNL | dtPrice | NO | - | CODE-BACKED | Unrealized P&L excluding commission. |
| 15 | @UnRealizedPNLWCom | dtPrice | NO | - | CODE-BACKED | Unrealized P&L including commission (with commission). |
| 16 | @ValidFrom | DATETIME | YES | NULL | CODE-BACKED | Backward compatibility only. Not used - ValidFrom is set to GETUTCDATE() internally. |
| 17 | @ValidTo | DATETIME | YES | NULL | CODE-BACKED | Backward compatibility only. Not used - ValidTo is set to '21000101' internally. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (INSERT) | Trade.DeltaDiff | Write | Inserts new reconciliation snapshot row |
| (UPDATE) | Trade.DeltaDiff | Write | Closes previous row's ValidTo temporal window |
| (EXEC) | Internal.GetDeltaDiffID | Procedure call | Obtains next DeltaDiffID via sequence/identity |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Reconciliation service) | N/A | Caller | Called periodically by the balance reconciliation process to record snapshot metrics |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeltaDiffDataAdd (procedure)
+-- Trade.DeltaDiff (table)
+-- Internal.GetDeltaDiffID (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.DeltaDiff | Table | INSERT + UPDATE - writes new snapshot and closes previous temporal window |
| Internal.GetDeltaDiffID | Stored Procedure | Called to generate the next DeltaDiffID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in repo | - | Called externally by reconciliation infrastructure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Note**: Uses explicit BEGIN TRAN / COMMIT with @@ERROR checks instead of TRY/CATCH. The RETURN @@ERROR pattern is legacy but functional.

---

## 8. Sample Queries

### 8.1 View the current (latest) DeltaDiff snapshot

```sql
SELECT  TOP 1 *
FROM    Trade.DeltaDiff WITH (NOLOCK)
WHERE   ValidTo = '21000101'
ORDER BY DeltaDiffID DESC;
```

### 8.2 Compare diff vs fully-calculated balances over time

```sql
SELECT  TOP 10 DeltaDiffID, ValidFrom,
        DiffAccountBalance, FullyAccountBalance,
        (DiffAccountBalance - FullyAccountBalance) AS BalanceDrift
FROM    Trade.DeltaDiff WITH (NOLOCK)
ORDER BY DeltaDiffID DESC;
```

### 8.3 Check for large reconciliation discrepancies

```sql
SELECT  DeltaDiffID, ValidFrom, Diff,
        DiffAccountNetPL, FullyAccountNetPL,
        ABS(DiffAccountNetPL - FullyAccountNetPL) AS NetPLDrift
FROM    Trade.DeltaDiff WITH (NOLOCK)
WHERE   ABS(DiffAccountNetPL - FullyAccountNetPL) > 100
ORDER BY ValidFrom DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.4/10 (Elements: 10.0/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeltaDiffDataAdd | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeltaDiffDataAdd.sql*
