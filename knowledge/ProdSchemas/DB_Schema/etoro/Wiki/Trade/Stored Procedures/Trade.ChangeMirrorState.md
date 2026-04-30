# Trade.ChangeMirrorState

> Deactivates a CopyTrader mirror (sets IsActive=0, MirrorStatusID=2 PendingClose) and logs the unregister operation to Trade.PostDetachOperation with MirrorOperationID=4.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ChangeMirrorState handles mirror deactivation in the CopyTrader system. When a copier stops copying a leader, this procedure sets the mirror to inactive (IsActive=0) and PendingClose (MirrorStatusID=2), then queues the unregister operation in Trade.PostDetachOperation for async downstream processing (closing positions, settling funds, etc.).

This procedure exists because mirror deactivation is a multi-step process. Immediately closing all copied positions would cause market impact and race conditions. Instead, this procedure marks the mirror as closing and delegates position-level operations to the async pipeline via PostDetachOperation.

For detach scenarios (@IsDetach=1), the procedure also validates that no position trees have base value significantly below current amount (error 60120), preventing detachment when positions are in an inconsistent state.

---

## 2. Business Logic

### 2.1 Mirror Deactivation

**What**: Sets the mirror to inactive and pending close.

**Columns/Parameters Involved**: `@NewState`, `@CloseMirrorActionType`, `Trade.Mirror.IsActive`, `Trade.Mirror.MirrorStatusID`

**Rules**:
- Only @NewState=0 is permitted (error 60055 for any other value)
- UPDATE sets IsActive=@NewState (0), CloseMirrorActionType=@CloseMirrorActionType, MirrorStatusID=2 (PendingClose)
- Only updates WHERE IsActive=1 (active mirrors)
- Error 60050 if no active mirror found with the given MirrorID

### 2.2 CID Validation

**What**: Optional CID ownership check.

**Columns/Parameters Involved**: `@CID`, `Trade.Mirror.CID`

**Rules**:
- If @CID <> -5656 (magic number chosen to be hard to guess): validates CID matches the mirror's owner
- Error 60050 if mirror not found or not active
- Error 60064 if CID mismatch
- @CID=-5656 bypasses validation (internal/system calls)

### 2.3 Detach Validation

**What**: For detach operations, validates position tree consistency.

**Columns/Parameters Involved**: `@IsDetach`, `Trade.PositionTbl`, `dbo.RealOpenPositions`

**Rules**:
- When @IsDetach=1: checks if any child positions in this mirror have a root position where UnitsBaseValueCents < Amount*100 with a difference > 100 cents
- Error 60120 (DB_DETACH_POSITION_FAIL) if such positions exist
- This prevents detachment when position base values are inconsistent with current amounts

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorID | INT | NO | - | CODE-BACKED | The CopyTrader mirror to deactivate. |
| 2 | @NewState | TINYINT | NO | - | CODE-BACKED | New mirror state. Only 0 (inactive) is permitted. |
| 3 | @CloseMirrorActionType | INT | YES | 0 | CODE-BACKED | Reason for closing the mirror. Written to Trade.Mirror.CloseMirrorActionType. 0=default. |
| 4 | @CID | INT | YES | -5656 | CODE-BACKED | Customer ID for ownership validation. -5656=skip validation (system/internal calls). |
| 5 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Trading session ID for audit. Written to PostDetachOperation. |
| 6 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Correlation GUID from client request for tracing. |
| 7 | @IsDetach | BIT | YES | 0 | CODE-BACKED | 1=detach operation (additional validation against position tree consistency), 0=regular mirror close. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MirrorID | Trade.Mirror | UPDATE + SELECT | Deactivates mirror, reads state for PostDetachOperation snapshot |
| (writes) | Trade.PostDetachOperation | INSERT | Logs unregister operation with MirrorOperationID=4 for async processing |
| @CID, @MirrorID | Trade.PositionTbl | SELECT | Detach validation - checks child positions |
| @CID, @MirrorID | dbo.RealOpenPositions | JOIN | Detach validation - checks root position base values |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | (external) | EXEC | Called when copier stops copying or detaches |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ChangeMirrorState (procedure)
+-- Trade.Mirror (table)
+-- Trade.PostDetachOperation (table)
+-- Trade.PositionTbl (table)
+-- dbo.RealOpenPositions (synonym/view)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | UPDATE IsActive/MirrorStatusID/CloseMirrorActionType, SELECT for snapshot |
| Trade.PostDetachOperation | Table | INSERT unregister record |
| Trade.PositionTbl | Table | SELECT for detach validation |
| dbo.RealOpenPositions | Synonym/View | JOIN for detach base value validation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application services | External | Called for mirror deactivation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Transaction | BEGIN TRAN / COMMIT / ROLLBACK | Atomic state change + PostDetachOperation insert |
| TRY/CATCH with THROW | Error Handling | Rollback and re-throw on failure |

---

## 8. Sample Queries

### 8.1 Check active mirrors for a customer

```sql
SELECT MirrorID, CID, ParentCID, Amount, IsActive, MirrorStatusID
FROM   Trade.Mirror WITH (NOLOCK)
WHERE  CID = @CID AND IsActive = 1;
```

### 8.2 View pending close operations

```sql
SELECT H_M_MirrorID, H_M_CID, H_M_MirrorOperationID, StatusID
FROM   Trade.PostDetachOperation WITH (NOLOCK)
WHERE  H_M_MirrorOperationID = 4
       AND StatusID = 0
ORDER BY ID DESC;
```

### 8.3 Check mirror deactivation history

```sql
SELECT MirrorID, MirrorStatusID, CloseMirrorActionType, IsActive
FROM   Trade.Mirror WITH (NOLOCK)
WHERE  MirrorID = @MirrorID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Header references FB 51445 (ClientRequestGuid) and RD 6136 (Reopen Mirror).

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ChangeMirrorState | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ChangeMirrorState.sql*
