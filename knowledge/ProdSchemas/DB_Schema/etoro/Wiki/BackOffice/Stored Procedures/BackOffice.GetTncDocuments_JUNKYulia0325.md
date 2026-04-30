# BackOffice.GetTncDocuments_JUNKYulia0325

> Deprecated full-table dump of BackOffice.TncDocument with no filtering - marked JUNK, superseded by GetTncDocument (filtered by ID) and any properly scoped TnC listing procedures.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; returns all rows from BackOffice.TncDocument |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetTncDocuments_JUNKYulia0325` is a deprecated stored procedure that performs an unfiltered `SELECT *` from `BackOffice.TncDocument`. The `JUNK` prefix in the name and the `Yulia0325` suffix indicate it was marked for deletion by Yulia in March 2025 but retained in the codebase.

This procedure was created by Ilya Raichman in August 2020 as a simple diagnostic or exploratory tool. It has no business logic, no parameters, and no filtering - it returns every row and every column from the TncDocument table. It should not be called in production contexts as it returns all documents regardless of active status, regulation, or any other filter.

---

## 2. Business Logic

No business logic. Performs `SELECT * FROM BackOffice.TncDocument WITH(NOLOCK)` unconditionally.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

None.

### Output Columns

All columns from `BackOffice.TncDocument` via `SELECT *`. Column set matches the TncDocument table schema. See `BackOffice.GetTncDocument` for documented column meanings.

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT * | BackOffice.TncDocument | Read (full scan) | Returns all rows, all columns |

### 5.2 Referenced By

No active callers. Deprecated/JUNK procedure.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetTncDocuments_JUNKYulia0325 (procedure)
└── BackOffice.TncDocument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.TncDocument | Table | SELECT * - full table scan, no filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | Deprecated - JUNK marker. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| JUNK designation | Lifecycle | Name prefix JUNK + suffix Yulia0325 indicates marked for deletion by Yulia in March 2025. Should not be used in production. |
| No IsActive filter | Implementation | Returns both active and inactive/archived TnC documents. Use GetTncDocument(@documentId, @isActive) for filtered access. |

---

## 8. Sample Queries

### 8.1 Execute (not recommended)
```sql
-- Not recommended for production use. Use GetTncDocument for filtered access.
EXEC [BackOffice].[GetTncDocuments_JUNKYulia0325]
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 7.0/10, Logic: 8.0/10, Relationships: 7.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetTncDocuments_JUNKYulia0325 | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetTncDocuments_JUNKYulia0325.sql*
