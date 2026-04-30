# History.InsertManualOperationPositionClose_Crisis

> Creates a new manual crisis close operation audit record and returns the generated OperationID, which callers use to link individual position-level close records in History.ManualPositionClose_Crisis.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @@IDENTITY returned as OperationID result set |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.InsertManualOperationPositionClose_Crisis` is the entry-point writer for the two-table crisis close audit system. When a DBA or automated system initiates a manual crisis close operation, this procedure is called first to create the operation header record in `History.ManualOperationPositionClose_Crisis`. It returns the new auto-generated OperationID, which the caller then passes to `Trade.ManualPositionClose_Crisis` to link each individual position close back to this operation.

The design separates operation metadata (who, why, description - stored here) from position detail (which positions were actually closed - stored in History.ManualPositionClose_Crisis). This allows one operation to encompass multiple position closes while keeping the audit trail clean.

The procedure has no explicit transaction, no error handling, and no SET NOCOUNT ON. The IDENTITY value is returned via `SELECT @@IDENTITY AS OperationID` rather than an OUTPUT parameter.

---

## 2. Business Logic

### 2.1 Crisis Operation Header Creation

**What**: Creates one operation header record with the operator's identity and reason, returns the generated OperationID.

**Columns/Parameters Involved**: @OperationDescription, @UserName, @AuditClosePositionReasonID

**Rules**:
- @UserName defaults to empty string if not provided (VARCHAR(255), default='')
- @AuditClosePositionReasonID defaults to -1 if not provided (INT, default=-1); -1 is the sentinel for "unspecified reason"
- @OperationDescription is the only required parameter with no default (VARCHAR(2000)); the caller must provide context for the operation
- OperationID is IDENTITY-generated in the target table; returned to caller as `SELECT @@IDENTITY AS OperationID`
- ManualOperationReasonID in the table is populated from @AuditClosePositionReasonID (parameter name differs from column name)
- No TRY/CATCH, no BEGIN TRAN - if the INSERT fails, the exception propagates unhandled to the caller

**Typical call pattern**:
```
1. EXEC History.InsertManualOperationPositionClose_Crisis
       @OperationDescription='Emergency close - circuit breaker event',
       @UserName='dba_user',
       @AuditClosePositionReasonID=5
   -> returns OperationID = 12345

2. EXEC Trade.ManualPositionClose_Crisis
       @PositionID=987654, @OperationID=12345, ...
   -> inserts to History.ManualPositionClose_Crisis (OperationID=12345, PositionID=987654)
```

### 2.2 @@IDENTITY Return Pattern

**What**: Uses @@IDENTITY (not SCOPE_IDENTITY()) to return the generated key.

**Rules**:
- @@IDENTITY returns the last IDENTITY value inserted in the current session, regardless of scope
- Since the INSERT target is a synonym (History.ManualOperationPositionClose_Crisis -> DB_Logs.History.ManualOperationPositionClose_Crisis), if any cross-database trigger fires on the target table, @@IDENTITY would return the trigger's IDENTITY rather than the table's IDENTITY
- SCOPE_IDENTITY() would be safer (returns only the IDENTITY from the current scope), but @@IDENTITY is used here
- The result is returned as a single-column result set `OperationID`, not an OUTPUT parameter

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OperationDescription | varchar(2000) | NO | - | CODE-BACKED | Free-text description of the crisis close operation. Required (no default). Stored in ManualOperationPositionClose_Crisis.OperationDescription. Should describe the business reason for the manual intervention (e.g., "Emergency close during market halt", "Regulatory close order for account X"). |
| 2 | @UserName | varchar(255) | YES | '' | CODE-BACKED | Identity of the operator initiating the crisis close. Defaults to empty string if not provided. Stored in ManualOperationPositionClose_Crisis.UserName. Typically the DBA or system account name. |
| 3 | @AuditClosePositionReasonID | int | YES | -1 | CODE-BACKED | Structured reason code for the crisis close. Mapped to ManualOperationReasonID column in the target table (parameter name differs from column name). -1 = unspecified reason (default). |
| 4 | OperationID (result set) | int | - | - | CODE-BACKED | The IDENTITY value generated for the new operation record, returned as `SELECT @@IDENTITY AS OperationID`. Callers capture this and pass it to Trade.ManualPositionClose_Crisis as @OperationID to link position-level close records to this operation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | History.ManualOperationPositionClose_Crisis (synonym) | Write target | Inserts one operation header record; returns @@IDENTITY as OperationID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Crisis close callers | (application or DBA call) | Application/DBA | Called before Trade.ManualPositionClose_Crisis to create the operation header and obtain OperationID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.InsertManualOperationPositionClose_Crisis (procedure)
└── History.ManualOperationPositionClose_Crisis (synonym -> DB_Logs.History.ManualOperationPositionClose_Crisis)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ManualOperationPositionClose_Crisis | Synonym -> Table (DB_Logs) | INSERT target - one operation header row per crisis close batch |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Crisis close workflow callers | Application/DBA | Calls to create operation record before calling Trade.ManualPositionClose_Crisis |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

No TRY/CATCH, no BEGIN TRAN, no SET NOCOUNT ON. Uses @@IDENTITY (not SCOPE_IDENTITY()) - potential @@IDENTITY hijack risk if triggers exist on the synonym target. Returns OperationID as a result set column, not an OUTPUT parameter.

---

## 8. Sample Queries

### 8.1 Create a new crisis close operation and capture the OperationID

```sql
DECLARE @OperationID INT

EXEC History.InsertManualOperationPositionClose_Crisis
    @OperationDescription = 'Emergency close during market circuit breaker',
    @UserName = 'admin_dba',
    @AuditClosePositionReasonID = 5

-- Note: OperationID is returned as a result set, not OUTPUT parameter
-- Capture it from the result set in the calling application
```

### 8.2 Find recent operations by a specific operator

```sql
SELECT TOP 20
    op.OperationID,
    op.UserName,
    op.ManualOperationReasonID,
    op.OperationDescription,
    COUNT(pc.PositionID) AS PositionsClosed
FROM History.ManualOperationPositionClose_Crisis op WITH (NOLOCK)
LEFT JOIN History.ManualPositionClose_Crisis pc WITH (NOLOCK)
    ON op.OperationID = pc.OperationID
WHERE op.UserName = 'admin_dba'
GROUP BY op.OperationID, op.UserName, op.ManualOperationReasonID, op.OperationDescription
ORDER BY op.OperationID DESC
```

### 8.3 Audit trail for a specific operation

```sql
SELECT
    op.OperationID,
    op.UserName,
    op.ManualOperationReasonID,
    op.OperationDescription,
    pc.PositionID
FROM History.ManualOperationPositionClose_Crisis op WITH (NOLOCK)
INNER JOIN History.ManualPositionClose_Crisis pc WITH (NOLOCK)
    ON op.OperationID = pc.OperationID
WHERE op.OperationID = 12345
ORDER BY pc.PositionID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 applicable (Phase 9B: no app code match)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: History.InsertManualOperationPositionClose_Crisis | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.InsertManualOperationPositionClose_Crisis.sql*
