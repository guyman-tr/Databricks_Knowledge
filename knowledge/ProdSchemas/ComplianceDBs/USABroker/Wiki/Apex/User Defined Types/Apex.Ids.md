# Apex.Ids

> Table-valued parameter type used to pass a batch of integer IDs (typically validation error IDs) to stored procedures for bulk operations.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | User Defined Type |
| **Key Identifier** | ID (INT, NULL) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Apex.Ids is a general-purpose table-valued parameter (TVP) type that allows callers to pass a list of integer IDs to stored procedures in a single parameter. Unlike Apex.GCIDs which is specifically for customer IDs, this type is a generic ID list container used for various ID-based bulk operations.

This type exists to support passing collections of related IDs - currently used for validation error IDs in the state machine workflow. When the Apex account processing state machine transitions and encounters validation errors, the full set of error IDs is passed as a batch to be associated with the user's state record.

The calling application constructs the ID list and passes it as a READONLY parameter. The procedure then processes all IDs in a single transaction, ensuring atomicity of the bulk operation.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple single-column TVP used for parameterized batch operations.

---

## 3. Data Overview

N/A for User Defined Type. This is a parameter type, not a persisted table. Its contents are transient and exist only during procedure execution.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | YES | - | CODE-BACKED | Generic integer identifier. In the known usage (Apex.SaveState @ValidationErrors parameter), each value is an ApexValidationErrorID referencing Dictionary.ApexValidationError. NULL is allowed, though typically all entries contain valid IDs. The nullable design allows for flexibility across different use cases. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It is a standalone type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.SaveState | @ValidationErrors | Parameter Type | Procedure accepts this TVP to save a set of validation error IDs alongside a state transition |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.SaveState | Stored Procedure | Accepts as READONLY parameter @ValidationErrors for bulk validation error association |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None. The ID column is nullable with no constraints.

---

## 8. Sample Queries

### 8.1 Declare and populate the TVP for testing

```sql
DECLARE @ids Apex.Ids;
INSERT INTO @ids (ID) VALUES (1), (4), (25);
SELECT * FROM @ids;
```

### 8.2 Use with SaveState procedure to save validation errors

```sql
DECLARE @ids Apex.Ids;
INSERT INTO @ids (ID) VALUES (4), (7); -- FirstNameError, PhoneError
EXEC Apex.SaveState
    @GCID = 12345,
    @ApexStateID = 6, -- WaitForUserDataUpdate
    @Comment = N'Validation failed: name and phone errors',
    @ValidationErrors = @ids;
```

### 8.3 JOIN pattern to resolve IDs to validation error names

```sql
DECLARE @ids Apex.Ids;
INSERT INTO @ids (ID) VALUES (4), (7), (25);
SELECT i.ID, ve.Name
FROM @ids i
INNER JOIN Dictionary.ApexValidationError ve WITH (NOLOCK)
    ON ve.ApexValidationErrorID = i.ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.Ids | Type: User Defined Type | Source: USABroker/Apex/User Defined Types/Apex.Ids.sql*
