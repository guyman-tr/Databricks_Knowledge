# BackOffice.AuditActionAdd_V2

> V2 successor to AuditActionAdd - writes a BackOffice audit trail event with improved UPDLOCK/HOLDLOCK locking for type auto-registration, and returns the new AuditActionID.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ActionName + @ManagerID + @ActionTime |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the V2 (improved) write path for BackOffice audit trail events, superseding `AuditActionAdd`. It logs every significant BackOffice manager operation to the `DB_Logs` database via the `BackOffice.AuditAction` synonym. The two key improvements over V1: safer concurrent ID generation (UPDLOCK/HOLDLOCK instead of the UPDATE trick), and returning the newly created AuditActionID to the caller - enabling downstream systems to reference the specific audit record (e.g., for linking with `AuditActionDetailsAdd`).

The procedure uses the same auto-registration pattern for new action types and the same case-insensitive XML parsing as V1. It is the preferred version for callers that need the AuditActionID for subsequent calls to `BackOffice.AuditActionDetailsAdd`.

Data flows as follows: a BackOffice operation calls V2 when it needs the AuditActionID back. The procedure auto-registers new action types with improved locking, parses CID/GCID from the XML, inserts the audit record using OUTPUT to capture the new ActionID, and returns it as a single-row result set.

---

## 2. Business Logic

### 2.1 Improved Action Type Auto-Registration (UPDLOCK/HOLDLOCK)

**What**: V2 uses safer locking for concurrent new type creation vs the V1 UPDATE trick.

**Columns/Parameters Involved**: `@ActionName`, `Dictionary.AuditActionType`

**Rules**:
- SELECT MAX(AuditActionTypeID) WITH (UPDLOCK, HOLDLOCK) to prevent concurrent inserts from calculating the same next ID
- @AuditActionTypeID = ISNULL(MAX, 0) + 1 (handles empty table gracefully with ISNULL vs V1's OUTPUT trick)
- Transaction wraps only the type creation (BEGIN TRANSACTION / COMMIT TRANSACTION)

### 2.2 Returns AuditActionID (V2 vs V1 Difference)

**What**: V2 returns the newly inserted AuditActionID to the caller.

**Columns/Parameters Involved**: `BackOffice.AuditAction.ActionID` (OUTPUT)

**Rules**:
- Uses OUTPUT INSERTED.ActionID INTO @InsertedAuditActionID table variable
- Final SELECT returns the AuditActionID - single row result set
- Callers use this ID for subsequent calls to AuditActionDetailsAdd to associate detail records

### 2.3 Case-Insensitive XML Parsing (inherited from V1)

**What**: CID and GCID extracted with uppercase/lowercase fallback. Same as V1 but uses .value() instead of .nodes().

**Rules**:
- .value('(//AuditParameters/CID)[1]', 'VARCHAR(15)') - more efficient than .nodes() used in V1
- Fallback to lowercase element name if NULL
- TRY_CONVERT(INT, ...) validation for @CID, @GCID, @ManagerID

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ActionTime | DATETIME | NO | - | CODE-BACKED | Timestamp when the BackOffice action occurred. Stored as ActionTime in BackOffice.AuditAction. |
| 2 | @ManagerID | INT | NO | - | CODE-BACKED | BackOffice manager who performed the action. Validated via TRY_CONVERT(INT) - set to NULL if non-integer. |
| 3 | @ActionName | VARCHAR(1024) | NO | - | VERIFIED | Human-readable action type name. Resolved to AuditActionTypeID; auto-registered if not found. Max 1024 chars (vs Varchar(Max) in V1). |
| 4 | @AuditActionParameters | XML | NO | - | VERIFIED | XML payload with action parameters. CID and GCID auto-extracted (case-insensitive). Full XML stored in AuditAction. |

**Result Set (one row):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 5 | AuditActionID | INT | NO | - | VERIFIED | The ActionID of the newly inserted audit record in BackOffice.AuditAction (DB_Logs). Used by callers to link detail records via AuditActionDetailsAdd. Key V2 addition vs V1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ActionName | Dictionary.AuditActionType | Lookup + WRITER | Resolves/auto-creates action type with UPDLOCK/HOLDLOCK |
| All params | BackOffice.AuditAction (synonym) | WRITER | INSERT + OUTPUT ActionID -> DB_Logs.BackOffice.AuditAction |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.AuditActionDetailsAdd | AuditActionID result | Caller dependency | Callers use V2's returned AuditActionID to add detail rows via AuditActionDetailsAdd |
| BackOffice application layer | - | Caller | Operations needing the audit record ID use V2 |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.AuditActionAdd_V2 (procedure)
|- Dictionary.AuditActionType (table) [lookup + auto-INSERT with UPDLOCK/HOLDLOCK]
+-- BackOffice.AuditAction (synonym) -> DB_Logs.BackOffice.AuditAction (table) [INSERT + OUTPUT ActionID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.AuditActionType | Table | SELECT (UPDLOCK/HOLDLOCK) to resolve/create AuditActionTypeID |
| BackOffice.AuditAction | Synonym | INSERT with OUTPUT to capture ActionID; redirects to DB_Logs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.AuditActionDetailsAdd | Procedure | Consumes the returned AuditActionID to add detail records |
| BackOffice application layer | External | Preferred over V1 when AuditActionID is needed |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UPDLOCK/HOLDLOCK | Concurrency | Prevents duplicate AuditActionTypeID generation under concurrent inserts (V1 vulnerability fixed) |
| Integer validation | Application | @CID, @GCID, @ManagerID nullified via TRY_CONVERT(INT) if not valid |
| V2 vs V1 | Design | V2 is the preferred version: safer locking + returns ActionID. V1 retained for backward compatibility. |

---

## 8. Sample Queries

### 8.1 Log an audit event and capture the returned ActionID

```sql
DECLARE @params XML = N'<AuditParameters><CID>12345</CID><GCID>98765</GCID></AuditParameters>'
DECLARE @auditResult TABLE (AuditActionID INT)

INSERT INTO @auditResult
EXEC BackOffice.AuditActionAdd_V2
    @ActionTime = GETUTCDATE(),
    @ManagerID = 742,
    @ActionName = N'DocumentClassify',
    @AuditActionParameters = @params

SELECT AuditActionID FROM @auditResult
```

### 8.2 Compare locking approach with V1

```sql
-- V1 uses UPDATE trick for ID generation (less safe under concurrency)
-- V2 uses SELECT MAX WITH (UPDLOCK, HOLDLOCK) - safer
-- Both auto-register new action types:
SELECT AuditActionTypeID, AuditActionTypeName
FROM Dictionary.AuditActionType WITH (NOLOCK)
ORDER BY AuditActionTypeID DESC
```

### 8.3 Verify recent audit entries with type names

```sql
SELECT TOP 10
    a.ActionTime,
    a.ManagerID,
    t.AuditActionTypeName,
    a.CID,
    a.GCID
FROM BackOffice.AuditAction a WITH (NOLOCK)
JOIN Dictionary.AuditActionType t WITH (NOLOCK)
    ON a.AuditActionTypeID = t.AuditActionTypeID
ORDER BY a.ActionTime DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Task scheduler for sending Email](https://etoro-jira.atlassian.net/wiki/spaces/DBAC/pages/12562301093) | Confluence | AuditActionAdd (V1 and V2 family) is called by the prod-WithdrawNotif-func-ne Azure Function for withdrawal notification audit logging |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.AuditActionAdd_V2 | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.AuditActionAdd_V2.sql*
