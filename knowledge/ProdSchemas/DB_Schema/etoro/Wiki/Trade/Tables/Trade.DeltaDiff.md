# Trade.DeltaDiff

> Temporal snapshot table storing delta/differential P&L and account balance metrics for reconciliation and auditing between different calculation methods.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | DeltaDiffID |
| **Partition** | No |
| **Indexes** | 3 |

---

## 1. Business Meaning

Trade.DeltaDiff stores point-in-time snapshots of P&L and balance metrics computed using different methods (diff vs. fully calculated). Each row represents a reconciliation checkpoint: realized vs. unrealized P&L, account balance, commissions, and net P&L with and without commissions. The ValidFrom/ValidTo columns form a temporal validity window—when a new row is inserted by `Trade.DeltaDiffDataAdd`, the previous "current" row (ValidTo='21000101') is updated to set ValidTo to the new row's ValidFrom. This enables time-series querying of how deltas evolved.

This table exists to support financial reconciliation and audit trails. Different systems may compute P&L differently (e.g., incremental diff vs. full recompute). Storing both side-by-side with timestamps allows analysts to investigate discrepancies and track calculation drift. The table is written exclusively by `Trade.DeltaDiffDataAdd`, which obtains DeltaDiffID from `Internal.GetDeltaDiffID` and inserts one row per reconciliation run.

Data flows: rows are INSERTed by `Trade.DeltaDiffDataAdd`. No UPDATE except the ValidTo close-out of the previous row. No DELETE. Readers are typically reporting/audit procedures (not found in grep; likely ad-hoc or BI).

---

## 2. Business Logic

### 2.1 Temporal Validity Window

**What**: Each row has ValidFrom and ValidTo; the "current" row has ValidTo='21000101'.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo`, `DeltaDiffID`

**Rules**:
- ValidFrom: set to GETUTCDATE() on INSERT
- ValidTo: default '21000101' for new rows; when a newer row is inserted, the previous row's ValidTo is set to the new row's ValidFrom
- Trade.DeltaDiffDataAdd: UPDATE Trade.DeltaDiff SET ValidTo = @NewValidFrom WHERE ValidTo = '21000101' AND DeltaDiffID < @DiffID

### 2.2 P&L and Balance Metrics

**What**: Multiple metric pairs support diff-vs-full reconciliation.

**Columns/Parameters Involved**: All dbo.dtPrice columns

**Rules**:
- AccountRealizedSum, AccountsUnRealizedSum: aggregate realized/unrealized
- Diff: overall differential
- Diff1AccountBalance, Diff1AccountNetPL: diff method 1 balance/net P&L
- DiffAccountBalance, DiffAccountNetPL: diff method balance/net P&L
- FullyAccountBalance, FullyAccountNetPL: fully calculated balance/net P&L
- RealizedCommission, UnRealizedCommission: commissions
- RealizedPNL, UnRealizedPNL: P&L without commission
- RealizedPNLWCom, UnRealizedPNLWCom: P&L with commission

### 2.3 DeltaDiffID Allocation

**What**: DeltaDiffID is allocated by Internal.GetDeltaDiffID before INSERT.

**Columns/Parameters Involved**: `DeltaDiffID`

**Rules**:
- PK on DeltaDiffID
- Clustered index on ValidFrom for time-range queries
- Nonclustered index on ValidTo

---

## 3. Data Overview

| DeltaDiffID | AccountRealizedSum | AccountsUnRealizedSum | Diff | FullyAccountBalance | FullyAccountNetPL | ValidFrom | ValidTo | Meaning |
|-------------|-------------------|----------------------|------|---------------------|------------------|-----------|---------|---------|
| (empty) | - | - | - | - | - | - | - | Table currently has 0 rows. Populated by Trade.DeltaDiffDataAdd when reconciliation jobs run. |

*Live data sample (2026-03): 0 rows. Table is populated by scheduled or on-demand reconciliation.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DeltaDiffID | bigint | NO | - | CODE-BACKED | Primary key. Allocated by Internal.GetDeltaDiffID. Monotonically increasing per reconciliation run. |
| 2 | AccountRealizedSum | dbo.dtPrice | NO | - | CODE-BACKED | Sum of realized P&L across accounts. |
| 3 | AccountsUnRealizedSum | dbo.dtPrice | NO | - | CODE-BACKED | Sum of unrealized P&L across accounts. |
| 4 | Diff | dbo.dtPrice | NO | - | CODE-BACKED | Overall differential between calculation methods. |
| 5 | Diff1AccountBalance | dbo.dtPrice | NO | - | CODE-BACKED | Account balance from diff method 1. |
| 6 | Diff1AccountNetPL | dbo.dtPrice | NO | - | CODE-BACKED | Net P&L from diff method 1. |
| 7 | DiffAccountBalance | dbo.dtPrice | NO | - | CODE-BACKED | Account balance from diff method. |
| 8 | DiffAccountNetPL | dbo.dtPrice | NO | - | CODE-BACKED | Net P&L from diff method. |
| 9 | FullyAccountBalance | dbo.dtPrice | NO | - | CODE-BACKED | Account balance from fully calculated method. |
| 10 | FullyAccountNetPL | dbo.dtPrice | NO | - | CODE-BACKED | Net P&L from fully calculated method. |
| 11 | RealizedCommission | dbo.dtPrice | NO | - | CODE-BACKED | Realized commission component. |
| 12 | RealizedPNL | dbo.dtPrice | NO | - | CODE-BACKED | Realized P&L without commission. |
| 13 | RealizedPNLWCom | dbo.dtPrice | NO | - | CODE-BACKED | Realized P&L with commission. |
| 14 | UnRealizedCommission | dbo.dtPrice | NO | - | CODE-BACKED | Unrealized commission component. |
| 15 | UnRealizedPNL | dbo.dtPrice | NO | - | CODE-BACKED | Unrealized P&L without commission. |
| 16 | UnRealizedPNLWCom | dbo.dtPrice | NO | - | CODE-BACKED | Unrealized P&L with commission. |
| 17 | ValidFrom | datetime | NO | getdate() | CODE-BACKED | Start of validity window. Set on INSERT. |
| 18 | ValidTo | datetime | NO | '21000101' | CODE-BACKED | End of validity. '21000101' for current row; updated when newer row inserted. |

---

## 5. Relationships

### 5.1 References To

This table has no declared foreign keys. All columns are scalar or computed; no references to other tables.

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.DeltaDiffDataAdd | - | Writer | INSERT and UPDATE ValidTo |
| Internal.GetDeltaDiffID | - | Reader (allocator) | Provides DeltaDiffID for INSERT |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeltaDiff (table)
└── Internal.GetDeltaDiffID (procedure) [provides DeltaDiffID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetDeltaDiffID | Procedure | Allocates DeltaDiffID for each INSERT |
| dbo.dtPrice | User-Defined Type | Price/decimal type for all monetary columns |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.DeltaDiffDataAdd | Procedure | INSERT, UPDATE ValidTo |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DeltaDiffDataAdd | NC PK | DeltaDiffID | - | - | Active |
| CIX_Trade_DeltaDiff__ValidFrom | CLUSTERED | ValidFrom | - | - | Active |
| IX_Trade_DeltaDiff__ValidTo | NC | ValidTo | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DeltaDiffDataAdd | PRIMARY KEY | Unique DeltaDiffID |
| DF_DeltaDiffDataAdd__ValidFrom | DEFAULT | ValidFrom = getdate() |
| DF_DelatDiffDataAdd__ValidTo | DEFAULT | ValidTo = '21000101' |

---

## 8. Sample Queries

### 8.1 Get current reconciliation snapshot
```sql
SELECT DeltaDiffID, AccountRealizedSum, AccountsUnRealizedSum, Diff,
       FullyAccountBalance, FullyAccountNetPL, RealizedPNL, UnRealizedPNL,
       ValidFrom, ValidTo
  FROM Trade.DeltaDiff WITH (NOLOCK)
 WHERE ValidTo = '21000101'
```

### 8.2 Reconciliation history by time range
```sql
SELECT DeltaDiffID, ValidFrom, ValidTo,
       Diff, DiffAccountBalance, FullyAccountBalance,
       RealizedPNL, UnRealizedPNL, RealizedPNLWCom, UnRealizedPNLWCom
  FROM Trade.DeltaDiff WITH (NOLOCK)
 WHERE ValidFrom >= '2026-01-01'
   AND ValidFrom < '2026-02-01'
 ORDER BY ValidFrom
```

### 8.3 Latest N reconciliation checkpoints
```sql
SELECT TOP 10 DeltaDiffID, ValidFrom, ValidTo, Diff,
       AccountRealizedSum, AccountsUnRealizedSum,
       FullyAccountBalance, FullyAccountNetPL
  FROM Trade.DeltaDiff WITH (NOLOCK)
 ORDER BY ValidFrom DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 7.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: DDL + Procedures*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Trade.DeltaDiffDataAdd) | Live rows: 0 | Corrections: 0 applied*
*Object: Trade.DeltaDiff | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.DeltaDiff.sql*
