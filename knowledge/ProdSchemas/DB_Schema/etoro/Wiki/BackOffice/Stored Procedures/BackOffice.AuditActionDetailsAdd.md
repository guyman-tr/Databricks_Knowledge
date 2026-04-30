# BackOffice.AuditActionDetailsAdd

> Bulk-inserts field-level change records for a BackOffice audit event directly into DB_Logs.BackOffice.AuditActionDetail, recording before/after values for each modified field.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @AuditDetails.AuditActionId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the companion write path to `AuditActionAdd_V2` for field-level audit detail logging. While `AuditActionAdd_V2` records the top-level event (who, what action, when, for which customer), this procedure records the granular field changes: which specific fields were modified and what their old and new values were. Together, the two procedures create a complete audit trail for BackOffice operations.

The procedure exists because field-level change tracking requires a separate, variable-length storage mechanism - a single action can change 1 or 20 fields. The table-valued parameter design allows the entire set of changed fields to be sent in one batch call rather than one call per field, keeping audit logging efficient even for complex multi-field operations.

Data flows as follows: the BackOffice application calls `AuditActionAdd_V2` first to get an AuditActionID, then assembles all modified field/old-value/new-value triplets into a table matching `BackOffice.AuditDetailTableType`, and calls this procedure with that TVP. The procedure bulk-inserts all rows into `DB_Logs.BackOffice.AuditActionDetail` (using a direct cross-database reference, not the synonym) and returns the count of inserted rows.

---

## 2. Business Logic

### 2.1 Bulk Field-Level Audit Insertion

**What**: All field change rows are inserted in a single set-based operation.

**Columns/Parameters Involved**: `@AuditDetails`, `DB_Logs.BackOffice.AuditActionDetail`

**Rules**:
- INSERT...SELECT from TVP directly - no row-by-row processing
- No validation of AuditActionId existence - if the parent record doesn't exist in DB_Logs, the insert will fail with a FK error (if FK is enforced in DB_Logs)
- Returns @@ROWCOUNT as RowsInserted - allows caller to verify how many rows were actually written
- Uses cross-database reference directly (`DB_Logs.BackOffice.AuditActionDetail`) unlike AuditActionAdd which uses the synonym

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameter:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AuditDetails | BackOffice.AuditDetailTableType | NO | - | VERIFIED | TVP containing field-level change records. READONLY. Each row = one field change for a parent audit action. Columns: AuditActionId (links to AuditActionAdd_V2 result), FieldName (Latin1_General_BIN collation), OldValue (NVARCHAR MAX), NewValue (NVARCHAR MAX). |

**Result Set:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | RowsInserted | INT | NO | - | CODE-BACKED | @@ROWCOUNT after the bulk INSERT - number of field change rows successfully written to DB_Logs.BackOffice.AuditActionDetail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AuditDetails | BackOffice.AuditDetailTableType | Type reference | TVP type defining the field-change row structure |
| @AuditDetails.AuditActionId | DB_Logs.BackOffice.AuditActionDetail | WRITER | Bulk-inserts field change detail rows directly to DB_Logs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.AuditActionAdd_V2 | AuditActionID result | Workflow dependency | Callers get AuditActionID from V2, then call this to add field details |
| BackOffice application layer | - | Caller | Called after AuditActionAdd_V2 to complete the audit record |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.AuditActionDetailsAdd (procedure)
|- BackOffice.AuditDetailTableType (UDT) [TVP type]
+-- DB_Logs.BackOffice.AuditActionDetail (table) [INSERT target - direct cross-DB reference]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.AuditDetailTableType | User Defined Type | Defines parameter type for @AuditDetails TVP |
| DB_Logs.BackOffice.AuditActionDetail | Table (cross-DB) | INSERT target for field-level audit records (direct reference, not synonym) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application layer | External | Calls to complete audit trail with field-level change details after AuditActionAdd_V2 |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row-count messages during INSERT |
| No parent validation | Design | AuditActionId existence is not checked - assumes AuditActionAdd_V2 was called first |
| Direct cross-DB reference | Design note | Uses DB_Logs.BackOffice.AuditActionDetail directly (not via synonym like AuditActionAdd) |

---

## 8. Sample Queries

### 8.1 Log field changes for an audit action

```sql
DECLARE @details AS BackOffice.AuditDetailTableType
INSERT INTO @details (AuditActionId, FieldName, OldValue, NewValue)
VALUES
    (999, N'AccountStatusID', N'1', N'2'),
    (999, N'ClosedDate', NULL, N'2026-03-17')

EXEC BackOffice.AuditActionDetailsAdd @AuditDetails = @details
```

### 8.2 Full audit trail workflow with V2

```sql
-- Step 1: Log the action, get the ID
DECLARE @params XML = N'<AuditParameters><CID>12345</CID></AuditParameters>'
DECLARE @result TABLE (AuditActionID INT)
INSERT INTO @result
EXEC BackOffice.AuditActionAdd_V2
    @ActionTime = GETUTCDATE(), @ManagerID = 742,
    @ActionName = N'AccountStatusChange', @AuditActionParameters = @params

-- Step 2: Log the field details
DECLARE @actionId INT = (SELECT AuditActionID FROM @result)
DECLARE @details AS BackOffice.AuditDetailTableType
INSERT INTO @details (AuditActionId, FieldName, OldValue, NewValue)
VALUES (@actionId, N'AccountStatusID', N'1', N'2')
EXEC BackOffice.AuditActionDetailsAdd @AuditDetails = @details
```

### 8.3 Check field-level details for a recent audit action

```sql
SELECT AuditActionId, FieldName, OldValue, NewValue
FROM DB_Logs.BackOffice.AuditActionDetail WITH (NOLOCK)
WHERE AuditActionId = 999
ORDER BY FieldName
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.AuditActionDetailsAdd | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.AuditActionDetailsAdd.sql*
