# History.ErrorLogAdd

> Completely disabled error logging stub - the entire body is commented out; the procedure accepts 6 parameters but always returns 0 and performs no database operations.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Always returns 0; no rows written |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.ErrorLogAdd` is a disabled no-op procedure. The entire functional body - an INSERT into `History.ErrorLog` via a lookup against `Dictionary.ErrorMessage` - is commented out with `/* ... */`. The only active code is `RETURN 0`.

This procedure was designed to log server-side errors by mapping a `(ServerTypeID, ServerMessageID)` pair against `Dictionary.ErrorMessage` to resolve an `ErrorMessageID`, then writing that resolved error to `History.ErrorLog`. The design supported a structured error message catalog: rather than storing raw error text, it stored a reference to a predefined message in the Dictionary schema.

The procedure was disabled (commented out) at some point, leaving a no-op stub. Any code that calls this procedure will receive RETURN 0 (success) even though no error was logged. This means callers that rely on this procedure for error recording are silently not logging errors. No SSDT procedures in the repo currently call this procedure.

**Note**: The sister procedure `History.InsertLogErrorGeneral` is the active error logging alternative - it writes raw error details directly to `History.LogErrorGeneral` without requiring a message catalog lookup.

---

## 2. Business Logic

### 2.1 Commented-Out Intended Logic

**What**: The commented-out body shows the original design: structured error logging via Dictionary.ErrorMessage catalog lookup.

**Columns/Parameters Involved**: `@ServerTypeID`, `@ServerMessageID`, `@SeverityTypeID`, `@CID`, `@Entity`, `@Parameters`

**Rules**:
- Current state: ALL code is commented out. The procedure body is `RETURN 0` only.
- Intended design (commented): SELECT from Dictionary.ErrorMessage WHERE ServerTypeID = @ServerTypeID AND ServerMessageID = @ServerMessageID to get the ErrorMessageID, then INSERT into History.ErrorLog
- The `@Parameters` field was intended to store contextual parameters for the error as VARCHAR(MAX)
- Always returns 0 in current state, regardless of whether any error occurred
- No callers in the SSDT repo - this procedure is effectively orphaned

**Diagram**:
```
CURRENT BEHAVIOR:
    EXEC History.ErrorLogAdd(@ServerTypeID, @ServerMessageID, ...) -> RETURN 0 (no-op)

INTENDED BEHAVIOR (commented out):
    EXEC History.ErrorLogAdd(@ServerTypeID, @ServerMessageID, ...)
        -> SELECT ErrorMessageID FROM Dictionary.ErrorMessage
               WHERE ServerTypeID = @ServerTypeID AND ServerMessageID = @ServerMessageID
        -> INSERT History.ErrorLog (SeverityTypeID, CID, ErrorMessageID, Entity, Parameters)
        -> RETURN @@ERROR
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ServerTypeID | int | NO | - | CODE-BACKED | Originally: ID of the server type generating the error. Used as lookup key in Dictionary.ErrorMessage to find the matching error message definition. Currently unused (commented-out body). |
| 2 | @ServerMessageID | int | NO | - | CODE-BACKED | Originally: server-specific message number for the error condition. Combined with @ServerTypeID to uniquely identify the error in Dictionary.ErrorMessage. Currently unused. |
| 3 | @SeverityTypeID | int | NO | - | CODE-BACKED | Originally: error severity classification. Would have been stored in History.ErrorLog.SeverityTypeID. Currently unused. |
| 4 | @CID | int | NO | - | CODE-BACKED | Originally: customer ID associated with the error event. Would have been stored in History.ErrorLog.CID. Currently unused. |
| 5 | @Entity | int | NO | - | CODE-BACKED | Originally: entity identifier related to the error (e.g., PositionID, DepositID). Would have been stored in History.ErrorLog.Entity. Currently unused. |
| 6 | @Parameters | varchar(max) | NO | - | CODE-BACKED | Originally: free-text parameters/context for the error event. Would have been stored in History.ErrorLog.Parameters. Currently unused. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (commented-out) @ServerTypeID/@ServerMessageID | Dictionary.ErrorMessage | Read (commented out) | Was intended to look up the canonical ErrorMessageID for the (ServerType, MessageID) pair |
| (commented-out) all params | History.ErrorLog | Write target (commented out) | Was intended to INSERT the resolved error into the error log |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No SSDT callers | - | - | No stored procedures in the repository call this procedure. Any callers are external (not in SSDT). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ErrorLogAdd (procedure)
- No active dependencies (body is commented out)
```

### 6.1 Objects This Depends On

No active dependencies. The commented-out body would have depended on Dictionary.ErrorMessage (read) and History.ErrorLog (write).

### 6.2 Objects That Depend On This

No dependents found within SSDT.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. The procedure is a complete no-op - `RETURN 0` only. The entire INSERT logic is commented out inside a `/* */` block.

---

## 8. Sample Queries

### 8.1 Check what the intended target History.ErrorLog contains

```sql
-- History.ErrorLog is the intended target of this no-op procedure
SELECT TOP 10 *
FROM History.ErrorLog WITH (NOLOCK)
ORDER BY ErrorLogID DESC
```

### 8.2 Use the active error logging alternative instead

```sql
-- History.InsertLogErrorGeneral is the active replacement for this disabled procedure
EXEC History.InsertLogErrorGeneral
    @NameSP = 'YourProcedureName',
    @Param_XML = '<params><id>123</id></params>',
    @ErrorNumber = 547,
    @ErrorMessage = 'FK constraint violation',
    @ErrorSeverity = 16,
    @ErrorState = 1,
    @ErrorProcedure = 'YourProcedureName',
    @ErrorLine = 42
```

### 8.3 Check active error logs from InsertLogErrorGeneral

```sql
SELECT TOP 10
    ID,
    NameSP,
    ErrorNumber,
    ErrorMessage,
    ErrorSeverity,
    Occurred
FROM History.LogErrorGeneral WITH (NOLOCK)
ORDER BY ID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.5/10 (Elements: 9/10, Logic: 7/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 applicable (Phase 9B: no app code match)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: History.ErrorLogAdd | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.ErrorLogAdd.sql*
