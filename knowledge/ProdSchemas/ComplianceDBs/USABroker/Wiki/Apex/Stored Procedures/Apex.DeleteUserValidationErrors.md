# Apex.DeleteUserValidationErrors

> Deletes all validation error records for a customer by GCID, used during account cleanup or closure.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Deletes from Apex.UserValidationErrors |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Apex.DeleteUserValidationErrors removes all records from Apex.UserValidationErrors for a specified customer (GCID). This is part of the account data cleanup process, typically called during account closure or data deletion workflows.

---

## 2. Business Logic

No complex business logic. Simple DELETE WHERE GCID = @GCID.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. All records matching this GCID are deleted from Apex.UserValidationErrors. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Apex.UserValidationErrors | Delete | Removes all rows for the specified GCID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.DeleteUserValidationErrors (procedure)
└── Apex.UserValidationErrors (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Apex.UserValidationErrors | Table | DELETE by GCID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Delete records for a customer

```sql
EXEC Apex.DeleteUserValidationErrors @GCID = 12345;
```

### 8.2 Verify deletion

```sql
EXEC Apex.DeleteUserValidationErrors @GCID = 12345;
SELECT * FROM Apex.UserValidationErrors WITH (NOLOCK) WHERE GCID = 12345;
-- Should return empty
```

### 8.3 Check before deleting

```sql
SELECT COUNT(*) FROM Apex.UserValidationErrors WITH (NOLOCK) WHERE GCID = 12345;
EXEC Apex.DeleteUserValidationErrors @GCID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.DeleteUserValidationErrors | Type: Stored Procedure | Source: USABroker/Apex/Stored Procedures/Apex.DeleteUserValidationErrors.sql*
