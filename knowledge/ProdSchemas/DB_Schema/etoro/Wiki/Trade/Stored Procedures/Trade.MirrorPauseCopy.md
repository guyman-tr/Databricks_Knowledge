# Trade.MirrorPauseCopy

> Pauses or resumes copy-trading for a single mirror: updates Trade.Mirror.PauseCopy and MirrorStatusID, then logs the state change to History.Mirror (MirrorOperationID=7 Stop Copy or 8 Resume Copy).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID + @CID (ownership-validated) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.MirrorPauseCopy is the atomic pause/resume operation for eToro's CopyTrader. When a user (copier) wants to temporarily stop their copy from following a leader without closing the mirror, they invoke this procedure to set PauseCopy=1 (pause) or PauseCopy=0 (resume).

The procedure enforces ownership by requiring both @MirrorID and @CID to match - a customer cannot pause another customer's mirror. It updates MirrorStatusID alongside PauseCopy to keep the two fields consistent (0=Active, 1=Paused). Every state change is audited by inserting a snapshot row into History.Mirror with MirrorOperationID=7 (Stop Copy) or 8 (Resume Copy).

A paused mirror remains in Trade.Mirror with IsActive=1 - it is not closed. The copier's capital stays allocated; new positions are not opened from the leader's trades while paused. When resumed, the mirror returns to active copy-trading.

Data flows: called by the CopyTrader application layer when the user clicks "Pause Copy" or "Resume Copy". PROD_BIadmins has permission. No SP callers found in the Trade schema - called externally by the application.

---

## 2. Business Logic

### 2.1 Pause/Resume State Update

**What**: Atomically updates both PauseCopy and MirrorStatusID columns in Trade.Mirror for the specified mirror.

**Columns/Parameters Involved**: `@NewState`, `Trade.Mirror.PauseCopy`, `Trade.Mirror.MirrorStatusID`

**Rules**:
- @NewState=1: PauseCopy=1, MirrorStatusID=1 (Pause/Stop Copy).
- @NewState=0: PauseCopy=0, MirrorStatusID=0 (Resume/Active Copy).
- Filter: WHERE MirrorID=@MirrorID AND CID=@CID - ownership validated; wrong owner fails silently with rowcount=0.
- If @@ROWCOUNT=0 after UPDATE: RAISERROR(60050,16,1,@MirrorID) - MirrorID not found or not owned by @CID.
- MirrorStatusID and PauseCopy must be kept in sync; this procedure is the authoritative updater for both.

**Diagram**:
```
@NewState:
  1 -> PauseCopy=1, MirrorStatusID=1, MirrorOperationID=7 (Stop Copy)
  0 -> PauseCopy=0, MirrorStatusID=0, MirrorOperationID=8 (Resume Copy)
```

### 2.2 History Audit Snapshot

**What**: After a successful update, inserts a snapshot of the current mirror state into History.Mirror for audit and timeline reconstruction.

**Columns/Parameters Involved**: `History.Mirror.MirrorOperationID`, `@SessionID`, `@ClientRequestGuid`

**Rules**:
- MirrorOperationID: CASE WHEN @NewState=1 THEN 7 (Stop Copy) ELSE 8 (Resume Copy) - from Dictionary.MirrorOperation.
- All other columns (Amount, PauseCopy, RealizedEquity, MirrorSLPercentage, InitialInvestment, DepositSummary, WithdrawalSummary, MirrorCalculationType, NetProfit) are SELECTed from Trade.Mirror immediately after the UPDATE - capturing the new state.
- @SessionID (optional, nullable): passed through for session tracking.
- @ClientRequestGuid (optional, nullable): passed through for client request deduplication/tracing (added FB-51445, 2018-06-28).
- INSERT is part of the same transaction as the UPDATE - atomic pair.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the copier who owns the mirror. Combined with @MirrorID in the WHERE clause to enforce ownership - prevents one customer from pausing another's mirror. Written to History.Mirror.CID. |
| 2 | @MirrorID | INT | NO | - | CODE-BACKED | ID of the mirror to pause or resume. Must exist in Trade.Mirror with matching @CID. If not found, RAISERROR(60050) is raised. Written to History.Mirror.MirrorID. |
| 3 | @NewState | BIT | NO | - | CODE-BACKED | Target pause state: 1=Pause (Stop Copy), 0=Resume (Resume Copy). Determines PauseCopy, MirrorStatusID, and MirrorOperationID values written in both Trade.Mirror and History.Mirror. |
| 4 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Optional session identifier from the calling application. Written to History.Mirror.SessionID. Added FB-23569 (2014-09-02) for session tracking. NULL if not provided. |
| 5 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Optional GUID for client-side request deduplication and distributed tracing. Written to History.Mirror.ClientRequestGuid. Added FB-51445 (2018-06-28). NULL if not provided. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MirrorID, @CID | Trade.Mirror | Read/Write | UPDATEs PauseCopy and MirrorStatusID; SELECTs snapshot columns for History insert |
| MirrorOperationID=7/8 | Dictionary.MirrorOperation | Reference | 7=Stop Copy (pause), 8=Resume Copy |
| @MirrorID, snapshot | History.Mirror | Write | Audit INSERT of full mirror state after pause/resume |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No SP callers found) | - | - | Called by CopyTrader application when user pauses or resumes copy; no SP callers in Trade schema. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.MirrorPauseCopy (procedure)
├── Trade.Mirror (table)
└── History.Mirror (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | UPDATEd with PauseCopy/MirrorStatusID; SELECTed for History snapshot |
| History.Mirror | Table | INSERTed with full mirror snapshot after state change |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No dependents found) | - | Called externally by CopyTrader application layer. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Wrapped in explicit BEGIN TRAN / COMMIT TRAN with TRY/CATCH. CATCH block: ROLLBACK if @@TRANCOUNT=1, COMMIT if @@TRANCOUNT>1 (nested transaction support), then THROW. RETURN(0) on success.

---

## 8. Sample Queries

### 8.1 Check pause/resume history for a mirror

```sql
SELECT HM.MirrorID, HM.CID, HM.MirrorOperationID, HM.PauseCopy,
       HM.MirrorStatusID, HM.Occurred, HM.SessionID, HM.ClientRequestGuid
FROM History.Mirror AS HM WITH (NOLOCK)
WHERE HM.MirrorID = <MirrorID>
  AND HM.MirrorOperationID IN (7, 8) -- 7=Stop Copy, 8=Resume Copy
ORDER BY HM.Occurred DESC;
```

### 8.2 Find all currently paused mirrors

```sql
SELECT TM.MirrorID, TM.CID, TM.ParentCID, TM.PauseCopy, TM.MirrorStatusID,
       TM.Amount, TM.RealizedEquity
FROM Trade.Mirror AS TM WITH (NOLOCK)
WHERE TM.PauseCopy = 1
  AND TM.IsActive = 1
ORDER BY TM.MirrorID;
```

### 8.3 Mirror state timeline for a customer

```sql
SELECT HM.MirrorID, HM.MirrorOperationID, HM.PauseCopy, HM.IsActive,
       HM.Amount, HM.Occurred
FROM History.Mirror AS HM WITH (NOLOCK)
WHERE HM.CID = <CID>
ORDER BY HM.MirrorID, HM.Occurred;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SP callers | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.MirrorPauseCopy | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.MirrorPauseCopy.sql*
