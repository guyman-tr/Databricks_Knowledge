# BackOffice.AuditActionAdd

> Writes a BackOffice audit trail event to DB_Logs, auto-registering new action types on first use and extracting CID/GCID from the XML parameters payload.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ActionName + @ManagerID + @ActionTime |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the V1 write path for recording BackOffice audit events. Every significant operation performed by a BackOffice manager - status changes, document actions, account operations, compensation entries - is logged via this procedure. The audit trail is stored in the `DB_Logs` database via the `BackOffice.AuditAction` synonym, providing compliance visibility and accountability.

The procedure exists because audit logging must be centralized, consistent, and low-friction for callers. By accepting a free-text `@ActionName` and auto-registering new action types in `Dictionary.AuditActionType` on first use, the system allows new operations to be audited without any DDL changes. Callers simply pass the action name and XML parameters; the procedure handles type resolution, XML parsing, and validation.

Data flows as follows: a BackOffice operation (direct call, Azure Function, or application layer) calls this procedure after performing an action. The procedure resolves or creates the action type ID, extracts CID and GCID from the XML parameters (handling case-insensitive element names), validates they are valid integers, and inserts the audit record. The Azure Function `prod-WithdrawNotif-func-ne` (task scheduler for withdrawal email notifications) is a known caller. Version 2 (`AuditActionAdd_V2`) supersedes this with improved locking and returns the AuditActionID.

---

## 2. Business Logic

### 2.1 Auto-Registering Action Types

**What**: New action type names are automatically added to Dictionary.AuditActionType on first use.

**Columns/Parameters Involved**: `@ActionName`, `Dictionary.AuditActionType`

**Rules**:
- SELECT AuditActionTypeID WHERE AuditActionTypeName = @ActionName (WITH NOLOCK)
- If NULL (new action type): lock the max row, INSERT max+1, use a table variable OUTPUT to capture the new ID
- The V1 locking approach: UPDATE the max row (to acquire lock), capture via OUTPUT, then INSERT @newId=capturedId+1
- V1 does NOT use UPDLOCK/HOLDLOCK - see V2 for improved locking (race condition risk in V1 under high concurrency)
- Transaction wraps the type creation only

### 2.2 Case-Insensitive XML Parsing

**What**: CID and GCID are extracted from the XML parameters using two XPath attempts (uppercase then lowercase).

**Columns/Parameters Involved**: `@AuditActionParameters`, `@CID`, `@GCID`

**Rules**:
- Tries `//AuditParameters/CID` first, falls back to `//AuditParameters/cid` if NULL
- Tries `//AuditParameters/GCID` first, falls back to `//AuditParameters/gcid` if NULL
- Code comment: "I know that it looks domb [sic], but XML is CS and sometimes the element is called CID and sometimes it is called cid"
- After extraction: TRY_CONVERT(INT, ...) - if not a valid integer, the value is set to NULL (prevents conversion errors noted in code comments)
- @ManagerID also validated via TRY_CONVERT(INT)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ActionTime | Datetime | NO | - | CODE-BACKED | Timestamp when the BackOffice action occurred. Stored as ActionTime in BackOffice.AuditAction. |
| 2 | @ManagerID | Int | NO | - | CODE-BACKED | BackOffice manager who performed the action. Validated via TRY_CONVERT(INT) - set to NULL if non-integer. Stored as ManagerID in BackOffice.AuditAction. |
| 3 | @ActionName | Varchar(Max) | NO | - | VERIFIED | Human-readable action type name (e.g., "AccountStatusChange", "DocumentClassify"). Resolved to AuditActionTypeID in Dictionary.AuditActionType; auto-registered if not found. |
| 4 | @AuditActionParameters | XML | NO | - | VERIFIED | XML payload with action-specific parameters. Must contain an `<AuditParameters>` root element. CID and GCID are extracted automatically (case-insensitive). All other parameters are stored as-is for audit trail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ActionName | Dictionary.AuditActionType | Lookup + WRITER | Resolves action type ID; auto-inserts new types on first use |
| All params | BackOffice.AuditAction (synonym) | WRITER | Inserts audit record into DB_Logs.BackOffice.AuditAction via synonym |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| prod-WithdrawNotif-func-ne (Azure Function) | - | Caller | Task scheduler for withdrawal email notifications uses this to log audit events |
| BackOffice application layer | - | Caller | Various BackOffice operations log audit events via this procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.AuditActionAdd (procedure)
|- Dictionary.AuditActionType (table) [lookup + auto-INSERT new types]
+-- BackOffice.AuditAction (synonym) -> DB_Logs.BackOffice.AuditAction (table) [INSERT audit record]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.AuditActionType | Table | SELECT to resolve ActionName to AuditActionTypeID; INSERT if new |
| BackOffice.AuditAction | Synonym | INSERT target for audit record (redirects to DB_Logs.BackOffice.AuditAction) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.AuditActionAdd_V2 | Procedure | V2 successor with improved locking and AuditActionID return |
| prod-WithdrawNotif-func-ne | Azure Function | Calls for withdrawal notification audit logging |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Integer validation | Application | @CID, @GCID, @ManagerID set to NULL via TRY_CONVERT(INT) if not valid integers |
| Auto-registration transaction | Explicit | New AuditActionType creation wrapped in BEGIN TRAN / COMMIT |
| V1 locking risk | Design note | Uses UPDATE trick for ID generation - under high concurrency, V2's UPDLOCK/HOLDLOCK approach is safer |

---

## 8. Sample Queries

### 8.1 Log an audit event for an account status change

```sql
DECLARE @params XML = N'<AuditParameters><CID>12345</CID><GCID>98765</GCID><OldStatus>1</OldStatus><NewStatus>2</NewStatus></AuditParameters>'
EXEC BackOffice.AuditActionAdd
    @ActionTime = GETUTCDATE(),
    @ManagerID = 742,
    @ActionName = 'AccountStatusChange',
    @AuditActionParameters = @params
```

### 8.2 Query recent audit actions for a customer

```sql
SELECT ActionTime, ManagerID, AuditActionTypeID, CID, GCID
FROM BackOffice.AuditAction WITH (NOLOCK)
WHERE CID = 12345
ORDER BY ActionTime DESC
```

### 8.3 View all registered action types

```sql
SELECT AuditActionTypeID, AuditActionTypeName
FROM Dictionary.AuditActionType WITH (NOLOCK)
ORDER BY AuditActionTypeID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Task scheduler for sending Email](https://etoro-jira.atlassian.net/wiki/spaces/DBAC/pages/12562301093) | Confluence | AuditActionAdd is called by the prod-WithdrawNotif-func-ne Azure Function (task scheduler for withdrawal notification emails) |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.AuditActionAdd | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.AuditActionAdd.sql*
