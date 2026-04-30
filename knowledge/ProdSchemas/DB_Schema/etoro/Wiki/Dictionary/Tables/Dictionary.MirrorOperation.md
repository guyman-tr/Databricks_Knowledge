# Dictionary.MirrorOperation

> Lookup table defining the 13 CopyTrading operations — from Register/UnRegister Mirror through balance edits, state changes, pause/resume, position detach, and alignment tracking.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, PK CLUSTERED) |
| **Partition** | PRIMARY filegroup |
| **Row Count** | 13 (MCP verified) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.MirrorOperation classifies every action that can be performed on a CopyTrading (Mirror) relationship. Each time a copy relationship is created, modified, or terminated, the operation is recorded in History.Mirror with a MirrorOperationID referencing this table. This creates a complete audit trail of all CopyTrading activity.

The operations span the full copy lifecycle: creating a copy relationship (Register Mirror, 1), ending it (UnRegister Mirror, 2), modifying it (Edit balance/SL/state, 3-5, 9), controlling it (Pause/Resume Copy, 7-8), managing positions (Close Position, 6; Position Detach, 10), changing calculation method (Update MirrorCalculationType, 11), and tracking portfolio alignment (alignment_started/ended, 12-13).

**MirrorOperationID=2 (UnRegister Mirror)** is the most heavily filtered operation — it appears in WHERE clauses across 20+ Trade.TAPI procedures for identifying closed/terminated copy relationships. `MirrorOperationID IN (1, 3)` captures registration and balance edits for aggregation. `MirrorOperationID IN (12, 13)` tracks alignment operations.

---

## 2. Business Logic

### 2.1 Copy Lifecycle Operations

**What**: The complete set of operations in a copy relationship lifecycle.

**Columns/Parameters Involved**: `ID`, `MirrorOperation`

**Rules**:
- **Register Mirror (1)**: Creates a new copy relationship — copier starts copying a trader with a specified allocation. Inserted by Trade.RegisterMirror.
- **UnRegister Mirror (2)**: Terminates the copy relationship — all copied positions are closed and funds returned. The most queried operation (WHERE MirrorOperationID = 2). Filtered in Trade.MirrorReopen, Trade.GetMirrorState, Trade.PostClosePositionActions, and 15+ TAPI procedures.
- **Edit Mirror's balance (3)**: Changes the allocated funds in the copy relationship — add or remove funds without stopping the copy. Grouped with Register (IN 1, 3) in Customer.AggregateUserMirrorData.
- **Change mirror's state (4)**: Administrative state change — may change active/inactive status.
- **Edit Mirror SL (5)**: Sets or changes the Stop-Loss amount on the copy relationship.
- **Close Position (6)**: Manually closes a specific copied position within the relationship (without stopping the entire copy).
- **Pause Copy (7)**: Temporarily pauses copying — no new positions are opened but existing ones remain. Inserted by Trade.MirrorPauseCopy.
- **Resume Copy (8)**: Resumes a paused copy relationship — new positions start being copied again.
- **Edit Mirror SL Percentage (9)**: Sets or changes the Stop-Loss as a percentage of allocated funds.
- **Position Detach (10)**: Detaches a specific position from the copy relationship — it becomes an independent position. Inserted by Trade.DetachPositionsFromMirror.
- **Update MirrorCalculationType (11)**: Changes the equity calculation method (RealizedEquity ↔ UnrealizedEquity).
- **alignment_started (12)**: Portfolio alignment process has begun — system is synchronizing copier's positions with the copied trader.
- **alignment_ended (13)**: Portfolio alignment process completed.

**Diagram**:
```
Copy Relationship Lifecycle:

  Register (1) ──► Active Copy
       │               │
       │    ┌──────────┤
       │    │  Edit Balance (3)
       │    │  Edit SL (5, 9)
       │    │  Change State (4)
       │    │  Update CalcType (11)
       │    │  Close Position (6)
       │    │  Position Detach (10)
       │    │  Alignment (12, 13)
       │    └──────────┤
       │               │
       │    Pause (7) ◄──► Resume (8)
       │               │
       └──► UnRegister (2) ──► Terminated
```

### 2.2 Common Filtering Patterns

**What**: How specific operations are filtered in business logic.

**Columns/Parameters Involved**: `MirrorOperationID` (History.Mirror column)

**Rules**:
- `MirrorOperationID = 1`: Registration only — for initial copy creation records
- `MirrorOperationID = 2`: Unregistration only — most common filter, identifies ended copy relationships. Used in 20+ TAPI procedures.
- `MirrorOperationID IN (1, 3)`: Registration + balance edits — for aggregating total money flow into copies
- `MirrorOperationID IN (7, 8)`: Pause/Resume — for account statement transaction reports
- `MirrorOperationID IN (12, 13)`: Alignment operations — for monitoring stuck alignments (Monitor.FindMirrorStuckInAlignment)

---

## 3. Data Overview

| ID | MirrorOperation | Meaning |
|---|---|---|
| 1 | Register Mirror | Creates new copy relationship. Copier allocates funds to start copying a trader. Initial operation for every copy. |
| 2 | UnRegister Mirror | Terminates copy relationship. All copied positions are closed, funds returned. Most queried operation ID. |
| 3 | Edit Mirror's balance | Adds or removes funds from the copy allocation without stopping the copy. |
| 4 | Change mirror's state | Administrative state change on the copy relationship. |
| 5 | Edit Mirror SL | Sets or changes the absolute dollar Stop-Loss on the copy. |
| 6 | Close Position | Manually closes a specific copied position. The copy relationship continues. |
| 7 | Pause Copy | Temporarily pauses the copy. Existing positions remain; no new positions are opened. |
| 8 | Resume Copy | Resumes a previously paused copy. New positions start being copied again. |
| 9 | Edit Mirror SL Percentage | Sets or changes Stop-Loss as a percentage of allocated funds. |
| 10 | Position Detach | Detaches a position from the copy — it becomes an independent (non-copied) position. |
| 11 | Update MirrorCalculationType | Changes equity calculation between RealizedEquity and UnrealizedEquity. |
| 12 | alignment_started | Portfolio alignment process initiated — synchronizing copier positions with copied trader. |
| 13 | alignment_ended | Portfolio alignment process completed. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Primary key identifying the copy operation. Range 1-13. Referenced by History.Mirror.MirrorOperationID (FK). Heavily filtered in Trade.TAPI procedures (ID=2 for unregistration). Used in WHERE, CASE, and IIF expressions across 35+ procedures. |
| 2 | MirrorOperation | varchar(40) | NO | - | VERIFIED | Human-readable operation name. Not nullable. Joined in Monitor procedures (UnclosedMirrorPositionsBySSE, ClosedPositionsBySSE) and Trade alerts for display. Used in account statement reports as transaction type labels. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.Mirror | MirrorOperationID | Explicit FK | Every copy operation is recorded with its type |
| Trade.Tv_RegisterMirror | H_M_MirrorOperationID | UDT column | TVP for bulk registration |
| Monitor.UnclosedMirrorPositionsBySSE | MirrorOperationID | JOIN | Monitor resolves operation name |
| Monitor.ClosedPositionsBySSE | MirrorOperationID | JOIN | Monitor resolves operation name |
| Monitor.FindMirrorStuckInAlignment | MirrorOperationID | WHERE IN (12,13) | Finds stuck alignments |
| Trade.RegisterMirror | MirrorOperationID | INSERT | Creates registration record |
| Trade.MirrorReopen | MirrorOperationID | WHERE = 2 | Checks for prior unregistration |
| Trade.GetMirrorState | MirrorOperationID | WHERE = 2 | Validates mirror isn't unregistered |
| Trade.PostClosePositionActions | MirrorOperationID | WHERE = 2 | Post-close checks |
| Trade.DetachPositionsFromMirror | @MirrorOperationID | Parameter INSERT | Detach operation logging |
| Trade.MirrorPauseCopy | MirrorOperationID | Expression/INSERT | Pause operation (7 or 8) |
| Trade.TAPI_GetHistoryMirrorByCidAndParentCidAgg | MirrorOperationID | WHERE = 2 | API history filter |
| Customer.AggregateUserMirrorData | MirrorOperationID | WHERE IN (1,3), CASE | Aggregation of copy activity |
| dbo.AccountStatement_GetTransactionsReport* | MirrorOperationID | WHERE/IIF 1/2/7/8 | Account statements |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.MirrorOperation (table)
  └── referenced by History.Mirror (FK)
  └── consumed by 35+ procedures across Trade, Monitor, Customer, dbo schemas
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.Mirror | Table | FK on MirrorOperationID |
| Monitor.UnclosedMirrorPositionsBySSE | Stored Procedure | JOINs for operation name |
| Monitor.ClosedPositionsBySSE | Stored Procedure | JOINs for operation name |
| Trade.RegisterMirror | Stored Procedure | Writes operation 1 |
| Trade.DetachPositionsFromMirror | Stored Procedure | Writes operation 10 |
| Trade.MirrorPauseCopy | Stored Procedure | Writes operation 7/8 |
| Trade.TAPI* (20+ procedures) | Stored Procedures | Filter by operation ID |
| Customer.AggregateUserMirrorData | Stored Procedure | Aggregates by operation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary | PRIMARY KEY | Unique operation identifier, PRIMARY filegroup |

---

## 8. Sample Queries

### 8.1 List all mirror operations
```sql
SELECT  ID,
        MirrorOperation
FROM    Dictionary.MirrorOperation WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Count copy operations by type
```sql
SELECT  dmo.MirrorOperation,
        COUNT(*)            AS OperationCount
FROM    History.Mirror hm WITH (NOLOCK)
JOIN    Dictionary.MirrorOperation dmo WITH (NOLOCK)
        ON hm.MirrorOperationID = dmo.ID
GROUP BY dmo.MirrorOperation
ORDER BY OperationCount DESC;
```

### 8.3 Find recent unregistrations (copy stops)
```sql
SELECT  TOP 100
        hm.MirrorID,
        hm.ParentCID,
        hm.ChildCID,
        hm.InsertDate
FROM    History.Mirror hm WITH (NOLOCK)
WHERE   hm.MirrorOperationID = 2  -- UnRegister Mirror
ORDER BY hm.InsertDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from MCP live data (13 operations) and codebase analysis across 35+ procedures in Trade, Monitor, Customer, and dbo schemas.

---

*Generated: 2026-03-13 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 35 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.MirrorOperation | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.MirrorOperation.sql*
