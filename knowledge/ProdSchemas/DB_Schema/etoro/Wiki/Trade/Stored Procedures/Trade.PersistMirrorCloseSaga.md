# Trade.PersistMirrorCloseSaga

> Upserts the mirror close saga state for a customer's mirror - creates a new saga record on first call, advances the step index on subsequent calls.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID + @CID (saga identity key) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Closing a CopyTrader mirror portfolio (a customer's copy relationship) is a multi-step saga: positions must be closed one by one, balances reconciled, and the mirror record deactivated. `Trade.MirrorCloseSaga` tracks the current step in this saga per mirror+customer pair.

This procedure is the persistence mechanism for that state machine. The calling service advances the step by calling this procedure after each successfully completed step. The MERGE-based upsert ensures:
- First call: creates the saga record with initial step, action type, and request IDs
- Subsequent calls: advances the step index and updates LastModify timestamp

The `@ClientRequestId` provides idempotency at the client level (distinguishes between separate close requests for the same mirror). The `@MirrorCloseActionType` records WHY the mirror is being closed (e.g., customer stop copy, admin action, risk management).

---

## 2. Business Logic

### 2.1 MERGE Upsert (MirrorID + CID as Composite Key)

**What**: Creates or updates the saga record based on the MirrorID+CID pair.

**Columns/Parameters Involved**: `Trade.MirrorCloseSaga.MirrorID`, `Trade.MirrorCloseSaga.CID`, `Trade.MirrorCloseSaga.CurrentStepIndex`, `Trade.MirrorCloseSaga.LastModify`

**Rules**:
- MERGE ON Target.MirrorID=Source.MirrorID AND Target.CID=Source.CID
- MATCHED (existing record): UPDATE CurrentStepIndex=@CurrentStepIndex, LastModify=GETUTCDATE()
- NOT MATCHED (new record): INSERT (MirrorID, CID, CurrentStepIndex, InitialRequestGuid, MirrorCloseActionType, ClientRequestId)
- Note: no CreateTime in this saga table (unlike AccountLiquidationSaga)
- @InitialRequestGuid stored only on INSERT (origin request correlation)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorID | INT | NO | - | CODE-BACKED | The mirror portfolio ID being closed. Part of the composite MERGE key (MirrorID+CID). |
| 2 | @CID | INT | NO | - | CODE-BACKED | The customer ID owning the mirror. Part of the composite MERGE key. Ensures the saga is scoped to a specific customer's copy relationship. |
| 3 | @CurrentStepIndex | INT | NO | - | CODE-BACKED | The step index to persist. Caller increments this after each completed step to advance the saga. |
| 4 | @InitialRequestGuid | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | GUID of the originating close request. Stored only on INSERT. Used for traceability back to the originating service call. |
| 5 | @MirrorCloseActionType | INT | NO | - | CODE-BACKED | The reason/type for closing the mirror (e.g., customer stop-copy, admin action, risk close). Stored only on INSERT. |
| 6 | @ClientRequestId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Client-provided request ID for idempotency. Distinguishes between separate close attempts for the same mirror. Stored only on INSERT. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MirrorID/@CID | Trade.MirrorCloseSaga | MERGE (READ + INSERT/UPDATE) | Upserts the saga state: creates new record or advances CurrentStepIndex |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PersistMirrorCloseSaga (procedure)
+-- Trade.MirrorCloseSaga (table) [MERGE - upsert saga state by MirrorID+CID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.MirrorCloseSaga | Table | MERGE target: creates or updates the mirror close saga state |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| MERGE ON MirrorID+CID | Design | Composite key - one active saga per mirror per customer |
| SET NOCOUNT ON | Performance | Suppresses row-count messages |
| No CreateTime column | Note | Unlike AccountLiquidationSaga, MirrorCloseSaga does not track saga creation time |

---

## 8. Sample Queries

### 8.1 Persist mirror close saga step
```sql
EXEC Trade.PersistMirrorCloseSaga
    @MirrorID            = 555666,
    @CID                 = 111222,
    @CurrentStepIndex    = 5,
    @InitialRequestGuid  = '550E8400-E29B-41D4-A716-446655440000',
    @MirrorCloseActionType = 1,   -- e.g., 1=customer stop-copy
    @ClientRequestId     = 'AABBCCDD-0000-0000-0000-112233445566';
```

### 8.2 Check current saga state for a mirror
```sql
SELECT
    MirrorID,
    CID,
    CurrentStepIndex,
    InitialRequestGuid,
    MirrorCloseActionType,
    ClientRequestId,
    LastModify
FROM Trade.MirrorCloseSaga WITH (NOLOCK)
WHERE MirrorID = 555666
  AND CID = 111222;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 additional analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PersistMirrorCloseSaga | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PersistMirrorCloseSaga.sql*
