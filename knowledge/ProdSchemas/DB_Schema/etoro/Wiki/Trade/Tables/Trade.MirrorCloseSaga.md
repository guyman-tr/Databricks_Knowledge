# Trade.MirrorCloseSaga

> Saga pattern table for managing the multi-step process of closing a mirror (CopyTrader relationship), tracking state until all child positions are closed.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | MirrorID (PK) |
| **Partition** | No |
| **Indexes** | 1 (PK) |

---

## 1. Business Meaning

**WHAT:** `MirrorCloseSaga` is a state machine table that tracks the progress of closing a CopyTrader mirror relationship. When a user closes a mirror (stops copying a trader), the system must close many child positions across multiple steps. This table stores the current step index, the initial request identifier, and metadata so that the close operation can resume or be audited if interrupted.

**WHY:** Mirror closes are complex: a single mirror can have dozens or hundreds of open positions. Closing them atomically is not feasible. The saga pattern allows the system to process closes in steps, persist progress, and recover from failures. Without this table, partial mirror closes would leave orphaned positions or inconsistent state.

**HOW:** When a mirror close is initiated, `Trade.PersistMirrorCloseSaga` is called to INSERT or UPDATE a row. The `CurrentStepIndex` advances as each step completes. Readers such as `Trade.GetMirrorCloseSagaByID` query by MirrorID to check progress. When the saga completes, `Trade.ArchiveMirrorCloseSaga` moves the row to `History.MirrorCloseSaga` and removes it from this table.

---

## 2. Business Logic

### 2.1 Saga Creation and Updates (PersistMirrorCloseSaga)

**What**: When a mirror close is started or a step completes, the caller invokes `Trade.PersistMirrorCloseSaga` with MirrorID, CID, CurrentStepIndex, InitialRequestGuid, MirrorCloseActionType, and ClientRequestId. The procedure MERGEs into this table: if the row exists, it updates CurrentStepIndex and LastModify; otherwise it INSERTs.

**Columns/Parameters Involved**: MirrorID, CID, CurrentStepIndex, InitialRequestGuid, MirrorCloseActionType, ClientRequestId, CreateDate, LastModify

**Rules**:
- MirrorID is the PK; one active saga per mirror
- CurrentStepIndex tracks which step of the close process is in progress
- LastModify is set to GETUTCDATE() on each update

### 2.2 Saga Archival

**What**: When the mirror close completes (all child positions closed), `Trade.ArchiveMirrorCloseSaga` copies the row to `History.MirrorCloseSaga` (with LastStepIndex) and deletes it from this table.

**Columns/Parameters Involved**: MirrorID, CID, CurrentStepIndex, CreateDate, LastModify, InitialRequestGuid, MirrorCloseActionType, ClientRequestId

**Rules**:
- History table receives LastStepIndex (final step) and SagaCloseReason
- Rows remain in Trade only while the saga is active

### 2.3 MirrorCloseActionType

**What**: Indicates the business reason for closing the mirror (e.g., user-initiated, copy stop, system event). Used for auditing and routing.

**Columns/Parameters Involved**: MirrorCloseActionType

**Rules**:
- Nullable; 0 observed in live data
- May map to a dictionary or enum in application code

---

## 3. Data Overview

| MirrorID | CID | CurrentStepIndex | MirrorCloseActionType | CreateDate | Meaning |
|----------|-----|------------------|----------------------|------------|---------|
| 1865738 | 14952796 | 2 | 0 | 2025-02-10 | Mirror close saga at step 2 |
| 1865742 | 14952802 | 2 | 0 | 2025-02-10 | Another mirror close in progress |
| 1865754 | 14952802 | 2 | 0 | 2025-02-10 | Same customer, different mirror |
| 1871318 | 20025788 | 0 | 0 | 2025-05-18 | Saga just started (step 0) |

*Live data: MirrorCloseActionType 0 dominates; CurrentStepIndex 0 or 2 observed.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MirrorID | int | NO | - | CODE-BACKED | References `CopyTrade.Mirror.MirrorID`. The mirror (CopyTrader relationship) being closed. PK. |
| 2 | CID | int | NO | - | CODE-BACKED | References `Customer.CustomerStatic.CID`. The copier (follower) whose mirror is being closed. |
| 3 | CurrentStepIndex | int | NO | - | CODE-BACKED | Zero-based index of the current step in the multi-step close process. |
| 4 | InitialRequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Correlates the saga to the original close request. |
| 5 | MirrorCloseActionType | int | YES | - | CODE-BACKED | Reason/category for closing the mirror. Observed: 0. |
| 6 | CreateDate | datetime | YES | GETUTCDATE() | CODE-BACKED | When the saga was first created. |
| 7 | LastModify | datetime | YES | GETUTCDATE() | CODE-BACKED | Last update timestamp. Set on each step advance. |
| 8 | ClientRequestId | uniqueidentifier | YES | - | CODE-BACKED | Client-originated correlation ID for tracing. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|----------------|-------------------|-------------|
| MirrorID | CopyTrade.Mirror | Implicit FK | Mirror being closed |
| CID | Customer.CustomerStatic | Implicit FK | Follower customer |
| MirrorCloseActionType | Dictionary (if exists) | Implicit FK | Close reason lookup |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PersistMirrorCloseSaga | Target | WRITER | MERGE insert/update |
| Trade.GetMirrorCloseSagaByID | saga | READER | Fetch by MirrorID |
| Trade.ArchiveMirrorCloseSaga | saga | DELETER | Archive to History and DELETE |
| History.MirrorCloseSaga | - | Archive target | Receives archived rows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
CopyTrade.Mirror (table)
Customer.CustomerStatic (table)
    |
    v
Trade.MirrorCloseSaga (table)
    |
    +-- Trade.PersistMirrorCloseSaga (proc) - writes
    +-- Trade.GetMirrorCloseSagaByID (proc) - reads
    +-- Trade.ArchiveMirrorCloseSaga (proc) - archives and deletes
    v
History.MirrorCloseSaga (archive)
```

### 6.1 Objects This Depends On

- CopyTrade.Mirror (MirrorID)
- Customer.CustomerStatic (CID)

### 6.2 Objects That Depend On This

- Trade.PersistMirrorCloseSaga
- Trade.GetMirrorCloseSagaByID
- Trade.ArchiveMirrorCloseSaga
- History.MirrorCloseSaga (archive target)

---

## 7. Technical Details

### 7.1 Indexes

| Index | Type | Key Columns | Description |
|-------|------|-------------|-------------|
| PK_TradeMirrorCloseSaga | CLUSTERED PK | MirrorID ASC | Primary key |

### 7.2 Constraints

| Constraint | Type | Description |
|------------|------|-------------|
| PK_TradeMirrorCloseSaga | PRIMARY KEY | MirrorID |
| DF_TradeMirrorCloseSaga_CreateDate | DEFAULT | GETUTCDATE() for CreateDate |
| DF_TradeMirrorCloseSaga_LastModify | DEFAULT | GETUTCDATE() for LastModify |

---

## 8. Sample Queries

```sql
-- Fetch saga by mirror
SELECT MirrorID, CID, CurrentStepIndex, MirrorCloseActionType, CreateDate, LastModify
FROM Trade.MirrorCloseSaga WITH (NOLOCK)
WHERE MirrorID = 1865738;

-- Count active sagas
SELECT COUNT(*) AS ActiveSagaCount
FROM Trade.MirrorCloseSaga WITH (NOLOCK);

-- Sagas by step
SELECT CurrentStepIndex, COUNT(*) AS Cnt
FROM Trade.MirrorCloseSaga WITH (NOLOCK)
GROUP BY CurrentStepIndex;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.2/10 | Source: DDL, PersistMirrorCloseSaga, GetMirrorCloseSagaByID, ArchiveMirrorCloseSaga, live data*
