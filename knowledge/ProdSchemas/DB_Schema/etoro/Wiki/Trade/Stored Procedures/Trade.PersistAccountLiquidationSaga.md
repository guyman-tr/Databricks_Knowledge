# Trade.PersistAccountLiquidationSaga

> Upserts the account liquidation saga state for a customer - creates a new saga record on first call, advances the step index on subsequent calls.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (saga identity key) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Account liquidation is a multi-step saga (distributed transaction pattern) triggered when a customer's account must be fully closed and all positions liquidated. `Trade.AccountLiquidationSaga` tracks the current step in this saga per customer, enabling resume-on-failure semantics: if the liquidation process is interrupted, it can restart from the last recorded step.

This procedure is the persistence mechanism for the saga state machine. The calling service advances the step by calling this procedure after each successfully completed step with the new `@CurrentStepIndex`. The MERGE-based upsert ensures:
- First call: creates the saga record with the initial step and action type
- Subsequent calls: advances the step index and updates LastModify timestamp

The `@InitialRequestGuid` ties the saga to the originating request for idempotency at the orchestration level. The `@AccountLiquidationActionTypeID` records WHY the liquidation was initiated (e.g., regulatory request, customer request, admin action).

---

## 2. Business Logic

### 2.1 MERGE Upsert (CID as Key)

**What**: Creates or updates the saga record based on CID uniqueness.

**Columns/Parameters Involved**: `Trade.AccountLiquidationSaga.CID`, `Trade.AccountLiquidationSaga.CurrentStepIndex`, `Trade.AccountLiquidationSaga.LastModify`

**Rules**:
- MERGE ON Target.CID = Source.CID
- MATCHED (existing record): UPDATE CurrentStepIndex=@CurrentStepIndex, LastModify=GETUTCDATE()
- NOT MATCHED (new record): INSERT (CID, CurrentStepIndex, InitialRequestGuid, AccountLiquidationAcionTypeID, CreateTime, LastModify)
  - Note: column name in table is `AccountLiquidationAcionTypeID` (typo: "Acion" not "Action") - parameter is @AccountLiquidationActionTypeID
- CreateTime is set only on INSERT (immutable first-creation timestamp)
- LastModify is set on both INSERT and UPDATE (tracks last step advance)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Primary key for the MERGE - identifies the saga record. One saga per customer at a time. |
| 2 | @CurrentStepIndex | INT | NO | - | CODE-BACKED | The step index to persist. Caller increments this after each completed step. On INSERT it is the initial step; on UPDATE it advances the saga forward. |
| 3 | @InitialRequestGuid | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | The originating request GUID that started the liquidation. Stored only on INSERT (initial saga creation). Used for idempotency at the orchestration level. |
| 4 | @AccountLiquidationActionTypeID | INT | NO | - | CODE-BACKED | The reason/type for the account liquidation (e.g., regulatory, customer request, admin). Stored only on INSERT. Maps to a lookup table for action type descriptions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Trade.AccountLiquidationSaga | MERGE (READ + INSERT/UPDATE) | Upserts the saga state: creates new record or advances CurrentStepIndex |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PersistAccountLiquidationSaga (procedure)
+-- Trade.AccountLiquidationSaga (table) [MERGE - upsert saga state by CID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.AccountLiquidationSaga | Table | MERGE target: creates or updates the account liquidation saga state |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| MERGE ON CID | Design | One active saga per customer - re-calling advances the step rather than creating duplicates |
| AccountLiquidationAcionTypeID (typo) | Note | Column in table has typo "Acion" instead of "Action" - parameter name uses correct spelling |
| SET NOCOUNT ON | Performance | Suppresses row-count messages |

---

## 8. Sample Queries

### 8.1 Persist account liquidation saga step
```sql
EXEC Trade.PersistAccountLiquidationSaga
    @CID                          = 111222,
    @CurrentStepIndex             = 3,
    @InitialRequestGuid           = '550E8400-E29B-41D4-A716-446655440000',
    @AccountLiquidationActionTypeID = 2;   -- e.g., 2=regulatory request
```

### 8.2 Check current saga state for a customer
```sql
SELECT
    CID,
    CurrentStepIndex,
    InitialRequestGuid,
    AccountLiquidationAcionTypeID,
    CreateTime,
    LastModify
FROM Trade.AccountLiquidationSaga WITH (NOLOCK)
WHERE CID = 111222;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 additional analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PersistAccountLiquidationSaga | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PersistAccountLiquidationSaga.sql*
