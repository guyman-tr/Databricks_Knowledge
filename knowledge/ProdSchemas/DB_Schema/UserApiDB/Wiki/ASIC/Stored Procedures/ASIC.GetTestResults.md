# ASIC.GetTestResults

> Returns all non-deleted ASIC classification test results for a given user (GCID).

| Property | Value |
|----------|-------|
| **Schema** | ASIC |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

ASIC.GetTestResults is the primary read procedure for ASIC classification test outcomes. Given a user's GCID, it returns their complete history of active (non-deleted) test attempts, including whether each test was passed, the score, and when it occurred. This procedure supports the application in determining a user's current ASIC classification status and displaying their test history.

---

## 2. Business Logic

### 2.1 Active Records Filter

**What**: Returns only non-soft-deleted test results.

**Parameters/Columns Involved**: `GCID`, `Deleted`

**Rules**:
- Filters WHERE GCID = @GCID (scoped to one user)
- Filters WHERE Deleted = 0 (active records only; soft-deleted tests are excluded)
- Returns all active test attempts, typically ordered by OccurredAt

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int (IN) | NO | - | CODE-BACKED | Global Customer ID. Scopes results to a single user. |

Output columns (from ASIC.TestResults): TestId, GCID, Success, Score, OccurredAt.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | ASIC.TestResults | SELECT FROM | Reads test result rows filtered by GCID and Deleted = 0 |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
ASIC.GetTestResults (procedure)
  +-- ASIC.TestResults (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| ASIC.TestResults | Table | SELECT FROM WHERE GCID = @GCID AND Deleted = 0 |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses IX_TestResults_GCID (NONCLUSTERED on GCID DESC) on the underlying table.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get test results for a user
```sql
EXEC ASIC.GetTestResults @GCID = 12345
```

### 8.2 Direct equivalent
```sql
SELECT TestId, GCID, Success, Score, OccurredAt
FROM ASIC.TestResults WITH (NOLOCK)
WHERE GCID = 12345 AND Deleted = 0
ORDER BY OccurredAt DESC
```

### 8.3 Check if user has ever passed
```sql
DECLARE @Results TABLE (TestId INT, GCID INT, Success BIT, Score INT, OccurredAt DATETIME)
INSERT INTO @Results EXEC ASIC.GetTestResults @GCID = 12345
SELECT CASE WHEN EXISTS (SELECT 1 FROM @Results WHERE Success = 1) THEN 'Passed' ELSE 'Not Passed' END AS Status
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: ASIC.GetTestResults | Type: Stored Procedure | Source: UserApiDB/UserApiDB/ASIC/Stored Procedures/ASIC.GetTestResults.sql*
