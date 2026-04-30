# ASIC.DeleteTestResult

> Soft-deletes an ASIC test result by setting the Deleted flag to 1, preserving the record for audit purposes.

| Property | Value |
|----------|-------|
| **Schema** | ASIC |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @testId (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

ASIC.DeleteTestResult implements the soft-delete pattern for ASIC classification test records. Instead of physically removing a row from ASIC.TestResults, it marks the record as deleted (Deleted = 1). The test result and its associated answers remain in the database for compliance and audit trail purposes but are excluded from all active queries that filter WHERE Deleted = 0.

This is the only supported mechanism for removing a test result - direct physical deletion is not used.

---

## 2. Business Logic

### 2.1 Soft Delete

**What**: Marks a test result as deleted without removing it from the database.

**Parameters Involved**: `@testId`

**Rules**:
- Sets Deleted = 1 on the matching TestResults row
- Does not cascade to ASIC.CustomerAnswers (answers remain, but are excluded via JOIN to non-deleted tests in GetAnswers)
- No validation - if @testId does not exist or is already deleted, the UPDATE affects 0 rows silently

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @testId | int (IN) | NO | - | CODE-BACKED | The TestId of the test result to soft-delete. |

No output - procedure performs an UPDATE only.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @testId | ASIC.TestResults | UPDATE | Sets Deleted = 1 WHERE TestId = @testId |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
ASIC.DeleteTestResult (procedure)
  +-- ASIC.TestResults (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| ASIC.TestResults | Table | UPDATE SET Deleted = 1 |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Soft-delete a test result
```sql
EXEC ASIC.DeleteTestResult @testId = 42
```

### 8.2 Verify deletion
```sql
-- Check the record is marked deleted
SELECT TestId, Deleted FROM ASIC.TestResults WITH (NOLOCK) WHERE TestId = 42
```

### 8.3 View all soft-deleted records for a user
```sql
SELECT TestId, GCID, Success, Score, OccurredAt
FROM ASIC.TestResults WITH (NOLOCK)
WHERE GCID = @GCID AND Deleted = 1
ORDER BY OccurredAt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: ASIC.DeleteTestResult | Type: Stored Procedure | Source: UserApiDB/UserApiDB/ASIC/Stored Procedures/ASIC.DeleteTestResult.sql*
