# BackOffice.AuditDetailTableType

> Table-valued parameter type for passing a batch of field-level change records to the audit logging procedure, capturing before/after values for each modified field.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | User Defined Type |
| **Key Identifier** | AuditActionId + FieldName (logical key) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.AuditDetailTableType` is a Table-Valued Type (TVT) used as a TVP (table-valued parameter) for the `BackOffice.AuditActionDetailsAdd` stored procedure. It defines the schema for passing a batch of field-level audit detail records in a single call. Each row describes one field that was changed as part of a back-office action: the action it belongs to, the field name, its old value, and its new value.

This type exists to enable efficient, set-based insertion of audit details - a single call to `AuditActionDetailsAdd` can log changes to many fields at once, rather than requiring one call per field. Without this type, batch audit logging would require either looping in the application or a less structured mechanism.

Data flows through this type from the back-office application layer. When a back-office user makes a change (e.g., updates a customer's account status, modifies a campaign, edits a document), the application collects all modified field-value pairs, assembles them into a table matching this type's schema, and calls `AuditActionDetailsAdd`. The rows are bulk-inserted into `DB_Logs.BackOffice.AuditActionDetail`.

---

## 2. Business Logic

### 2.1 Field-Level Change Logging Pattern

**What**: Each row captures one field change associated with a parent audit action record.

**Columns/Parameters Involved**: `AuditActionId`, `FieldName`, `OldValue`, `NewValue`

**Rules**:
- `AuditActionId` links to an existing record in the audit action table (created beforehand via `BackOffice.AuditActionAdd` or `AuditActionAdd_V2`). Multiple rows can share the same AuditActionId when multiple fields change in one operation.
- `FieldName` uses `Latin1_General_BIN` collation, making field name comparisons case-sensitive and binary. This prevents accidental collision between field names that differ only by case.
- Both `OldValue` and `NewValue` are `NVARCHAR(MAX)` with binary collation, storing the string representation of any field value regardless of original data type.
- NULL `OldValue` indicates the field had no prior value (e.g., a new record or a previously unset field).
- NULL `NewValue` would indicate a field was cleared (though this would be unusual in practice).

**Diagram**:
```
Back-office action (e.g., customer status change)
        |
        v
AuditActionAdd -> returns AuditActionId = 5001
        |
        v
Assemble TVP rows:
  (5001, 'AccountStatusID', '1', '3')
  (5001, 'ManagerID', '12', '45')
        |
        v
AuditActionDetailsAdd(@AuditDetails)
        |
        v
INSERT INTO DB_Logs.BackOffice.AuditActionDetail
```

---

## 3. Data Overview

N/A for User Defined Type. This type is passed as a TVP parameter and does not persist data directly.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AuditActionId | int | YES | - | CODE-BACKED | Foreign key to the parent audit action record in DB_Logs.BackOffice.AuditActionDetail.AuditActionId. Groups all field changes belonging to the same back-office operation. Should be non-NULL in valid usage. |
| 2 | FieldName | nvarchar(255) | NO | - | CODE-BACKED | Name of the database field or application property that was changed. Uses Latin1_General_BIN collation for case-sensitive, binary comparison. Maps to AuditActionDetail.FieldName in the audit log. |
| 3 | OldValue | nvarchar(max) | YES | - | CODE-BACKED | String representation of the field value before the change. NULL if the field had no prior value. Uses Latin1_General_BIN collation. Stored as text regardless of original data type. |
| 4 | NewValue | nvarchar(max) | YES | - | CODE-BACKED | String representation of the field value after the change. NULL if the field was cleared. Uses Latin1_General_BIN collation. Stored as text regardless of original data type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AuditActionId | DB_Logs.BackOffice.AuditActionDetail.AuditActionId | Implicit | Links detail rows to the parent audit action record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.AuditActionDetailsAdd | @AuditDetails | TVP parameter | This type is declared as the parameter type: `@AuditDetails BackOffice.AuditDetailTableType READONLY`. The SP bulk-inserts all rows into DB_Logs.BackOffice.AuditActionDetail. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.AuditActionDetailsAdd | Stored Procedure | Receives this type as the `@AuditDetails` TVP parameter. Inserts all rows into DB_Logs.BackOffice.AuditActionDetail. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type. No indexes defined on this type.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FieldName NOT NULL | NOT NULL | FieldName must always be provided - a detail record without a field name is meaningless. |
| COLLATE Latin1_General_BIN on FieldName, OldValue, NewValue | Collation | Binary, case-sensitive collation for all string columns, ensuring exact string matching and storage of audit values without case-folding. |

---

## 8. Sample Queries

### 8.1 Pass audit details for a customer status change

```sql
DECLARE @Details BackOffice.AuditDetailTableType;

INSERT INTO @Details (AuditActionId, FieldName, OldValue, NewValue)
VALUES
    (5001, 'AccountStatusID', '1', '3'),
    (5001, 'ManagerID', '12', '45');

EXEC BackOffice.AuditActionDetailsAdd @AuditDetails = @Details;
```

### 8.2 Log a single field change

```sql
DECLARE @Details BackOffice.AuditDetailTableType;

INSERT INTO @Details (AuditActionId, FieldName, OldValue, NewValue)
VALUES (7890, 'KycState', '0', '2');

EXEC BackOffice.AuditActionDetailsAdd @AuditDetails = @Details;
```

### 8.3 Query audit trail for a specific action in the logs DB

```sql
SELECT
    ad.AuditActionId,
    ad.FieldName,
    ad.OldValue,
    ad.NewValue
FROM DB_Logs.BackOffice.AuditActionDetail ad WITH (NOLOCK)
WHERE ad.AuditActionId = 5001
ORDER BY ad.FieldName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.AuditDetailTableType | Type: User Defined Type | Source: etoro/etoro/BackOffice/User Defined Types/BackOffice.AuditDetailTableType.sql*
