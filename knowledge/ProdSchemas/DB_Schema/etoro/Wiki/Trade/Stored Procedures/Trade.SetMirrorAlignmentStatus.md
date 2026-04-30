# Trade.SetMirrorAlignmentStatus

> Updates the alignment status of a copy-trade mirror to either Active or InAlignment, atomically updating Trade.Mirror and appending a history record to History.Mirror, as called by the MOE (Mirror Operation Engine) service.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID, @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure transitions a copy-trade mirror between two states: Active (normal copying state) and InAlignment (a transient state where the follower's portfolio is being realigned to match the leader's current positions). Alignment occurs when a copier starts copying a new leader or resumes copying after a pause - the system needs to open/close positions to bring the follower's portfolio in line with the leader's.

Without this procedure, there would be no safe, audited way to flag a mirror as "being aligned." The alignment state is critical because it prevents conflicting operations (other mirror operations are blocked while InAlignment per MOE error code `DISALLOWED_MIRROR_IN_ALIGNMENT`). The History.Mirror record provides an immutable audit trail of when alignment started and ended.

The procedure is called by the MOE (Mirror Operation Engine) service's `MirrorOperationRepository`, specifically by the `MirrorAlignmentStatusUpdateRequestProcessor` which processes `MirrorAlignmentStatusUpdateRequest` messages from RabbitMQ. The MOE service is deployed on Azure Kubernetes Service (AKS) and replaces the Trade Server for mirror operations (Per Confluence: Moe - Mirror Operation Engine).

---

## 2. Business Logic

### 2.1 MirrorStatusID State Transition

**What**: Controls which numeric MirrorStatusID is written to Trade.Mirror based on the @InAlignment flag.

**Columns/Parameters Involved**: `@InAlignment`, `Trade.Mirror.MirrorStatusID`

**Rules**:
- `@InAlignment = 1` -> `MirrorStatusID = 3` (InAlignment state)
- `@InAlignment = 0` -> `MirrorStatusID = 0` (Active state)
- The IIF expression: `IIF(@InAlignment=1, 3, 0)` encodes both transitions in a single UPDATE

**Diagram**:
```
@InAlignment = 1 --> MirrorStatusID = 3 (InAlignment - portfolio sync in progress)
@InAlignment = 0 --> MirrorStatusID = 0 (Active - normal copy-trade running)
```

### 2.2 History Audit via MirrorOperationID

**What**: The alignment state change is recorded as a History.Mirror entry using a specific MirrorOperationID to indicate the alignment lifecycle.

**Columns/Parameters Involved**: `History.Mirror.MirrorOperationID`, `@InAlignment`

**Rules**:
- `@InAlignment = 1` -> MirrorOperationID = 12 (alignment_started)
- `@InAlignment = 0` -> MirrorOperationID = 13 (alignment_ended)
- The INSERT copies all current Mirror fields from Trade.Mirror, overriding MirrorOperationID with 12 or 13
- SessionID and ClientRequestGuid are passed from the calling service for end-to-end request tracing

**Diagram**:
```
Trade.Mirror (current state)
  |
  +-- SELECT current row (WHERE MirrorID=@MirrorID AND CID=@CID)
  |
  INSERT INTO History.Mirror with:
    MirrorOperationID = IIF(@InAlignment=1, 12, 13)
                           ^                 ^
                    alignment_started   alignment_ended
```

### 2.3 Atomic Transaction with Owner Validation

**What**: Both the UPDATE on Trade.Mirror and the INSERT into History.Mirror run inside a single transaction, and the UPDATE validates mirror ownership before the history is written.

**Columns/Parameters Involved**: `@MirrorID`, `@CID`

**Rules**:
- The UPDATE includes `AND CID = @CID` to prevent one customer from aligning another's mirror
- If @@ROWCOUNT = 0 after UPDATE (mirror not found or CID mismatch), RAISERROR(60125) is raised with @MirrorID and @CID as parameters
- The transaction is rolled back on any error; nested transaction safety: if @@TRANCOUNT > 1, COMMIT is called instead of ROLLBACK (outer transaction handles rollback)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the mirror owner. Used as a security check: the UPDATE only succeeds if the mirror belongs to this CID. Error 60125 raised if no row matched. |
| 2 | @MirrorID | INT | NO | - | CODE-BACKED | Unique identifier of the copy-trade mirror to update. Combined with @CID in the WHERE clause for ownership validation. |
| 3 | @InAlignment | bit | NO | - | VERIFIED | Alignment direction: 1 = start alignment (sets MirrorStatusID=3 InAlignment, logs MirrorOperationID=12 alignment_started), 0 = end alignment (sets MirrorStatusID=0 Active, logs MirrorOperationID=13 alignment_ended). (Per Confluence: MOE - inline code comment "0:Active;3:InAlignment") |
| 4 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Session identifier from the calling service for end-to-end request tracing. Written to History.Mirror for audit linkage. |
| 5 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Client-side request GUID from the calling service for distributed tracing. Written to History.Mirror. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MirrorID, @CID | Trade.Mirror | Modifier | Updates MirrorStatusID (Active=0 / InAlignment=3) for the specified mirror |
| @MirrorID, @CID | History.Mirror | Writer | Appends an audit record with MirrorOperationID 12 (alignment started) or 13 (alignment ended) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MOE MirrorOperationRepository | MirrorAlignmentStatusUpdateRequestProcessor | CALLER | Called by the Mirror Operation Engine service when processing MirrorAlignmentStatusUpdateRequest RabbitMQ messages (Per Confluence: Moe - Mirror Operation Engine) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SetMirrorAlignmentStatus (procedure)
├── Trade.Mirror (table) [updates MirrorStatusID]
└── History.Mirror (table) [inserts alignment start/end record]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Updated: MirrorStatusID set to 0 (Active) or 3 (InAlignment); current row also read for the History INSERT |
| History.Mirror | Table | Inserted into: audit record with MirrorOperationID 12 or 13 to record alignment lifecycle |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MOE - Mirror Operation Engine (AKS service) | External service | Calls this procedure via MirrorOperationRepository to toggle alignment state |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Mirror ownership check | Business validation | RAISERROR(60125) if UPDATE affects 0 rows (mirror not found or CID mismatch) |
| Transaction safety | Implementation | Nested transaction: ROLLBACK if @@TRANCOUNT=1, COMMIT if @@TRANCOUNT>1 (outer transaction owns rollback) |
| MirrorStatusID values | Hardcoded | 0=Active, 3=InAlignment (per inline code comment "0:Active;3:InAlignment") |
| MirrorOperationID values | Hardcoded | 12=alignment_started, 13=alignment_ended (per inline code comment) |

---

## 8. Sample Queries

### 8.1 Start alignment for a mirror

```sql
EXEC Trade.SetMirrorAlignmentStatus
    @CID = 12345,
    @MirrorID = 67890,
    @InAlignment = 1,
    @SessionID = 9999999,
    @ClientRequestGuid = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
```

### 8.2 End alignment for a mirror

```sql
EXEC Trade.SetMirrorAlignmentStatus
    @CID = 12345,
    @MirrorID = 67890,
    @InAlignment = 0,
    @SessionID = 9999999,
    @ClientRequestGuid = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
```

### 8.3 Check alignment history for a mirror

```sql
SELECT TOP 20
    hm.MirrorID, hm.CID, hm.MirrorOperationID, hm.Occurred,
    hm.SessionID, hm.ClientRequestGuid
FROM History.Mirror hm WITH (NOLOCK)
WHERE hm.MirrorID = 67890
AND hm.MirrorOperationID IN (12, 13) -- alignment_started / alignment_ended
ORDER BY hm.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Moe - Mirror Operation Engine](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/12857836033/Moe+-+Mirror+Operation+Engine) | Confluence | SetMirrorAlignmentStatus is called by MirrorOperationRepository in the MOE service; processed by MirrorAlignmentStatusUpdateRequestProcessor; MOE is deployed on AKS and replaces Trade Server for mirror operations; error code UPDATE_MIRROR_ALIGNMENT_STATUS_FAILURE; MirrorStatusID 0=Active 3=InAlignment confirmed; MirrorOperationID 12=alignment_started 13=alignment_ended confirmed |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 caller (MOE service) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SetMirrorAlignmentStatus | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SetMirrorAlignmentStatus.sql*
