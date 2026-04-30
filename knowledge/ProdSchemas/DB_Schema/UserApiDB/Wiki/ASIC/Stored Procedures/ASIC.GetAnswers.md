# ASIC.GetAnswers

> Returns all question and answer pairs for a user's non-deleted ASIC test results by joining CustomerAnswers to TestResults.

| Property | Value |
|----------|-------|
| **Schema** | ASIC |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

ASIC.GetAnswers retrieves the full Q&A detail for all active (non-deleted) ASIC test attempts by a user. It joins ASIC.CustomerAnswers to ASIC.TestResults to filter out answers belonging to soft-deleted tests. This procedure is used when the system or a compliance reviewer needs to see exactly what questions were asked and what the user answered during their ASIC classification process.

---

## 2. Business Logic

### 2.1 Deleted Filter via JOIN

**What**: Excludes answers for soft-deleted test results.

**Parameters/Columns Involved**: `GCID`, `Deleted`

**Rules**:
- JOINs CustomerAnswers to TestResults ON TestId
- Filters WHERE TestResults.Deleted = 0 (active tests only)
- Filters WHERE TestResults.GCID = @GCID (scoped to one user)
- Returns all Q&A pairs across all non-deleted tests for the user

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int (IN) | NO | - | CODE-BACKED | Global Customer ID. Scopes results to a single user. |

Output columns (from CustomerAnswers JOIN TestResults): CustomerAnswerId, TestId, Question, Answer, OccurredAt (and potentially TestResults columns such as GCID, Success, Score).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | ASIC.CustomerAnswers | SELECT FROM | Source of Q&A detail rows |
| - | ASIC.TestResults | JOIN | Filters to non-deleted tests for the user |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
ASIC.GetAnswers (procedure)
  +-- ASIC.CustomerAnswers (table)
  +-- ASIC.TestResults (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| ASIC.CustomerAnswers | Table | SELECT FROM - provides Q&A rows |
| ASIC.TestResults | Table | JOIN - filters by GCID and Deleted = 0 |

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

### 8.1 Get all answers for a user
```sql
EXEC ASIC.GetAnswers @GCID = 12345
```

### 8.2 Direct equivalent
```sql
SELECT ca.CustomerAnswerId, ca.TestId, ca.Question, ca.Answer, ca.OccurredAt
FROM ASIC.CustomerAnswers ca WITH (NOLOCK)
JOIN ASIC.TestResults tr WITH (NOLOCK) ON ca.TestId = tr.TestId
WHERE tr.GCID = 12345 AND tr.Deleted = 0
```

### 8.3 Capture results into a temp table
```sql
DECLARE @Results TABLE (
    CustomerAnswerId INT, TestId INT, Question NVARCHAR(1024),
    Answer NVARCHAR(512), OccurredAt DATETIME
)
INSERT INTO @Results EXEC ASIC.GetAnswers @GCID = 12345
SELECT * FROM @Results ORDER BY OccurredAt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: ASIC.GetAnswers | Type: Stored Procedure | Source: UserApiDB/UserApiDB/ASIC/Stored Procedures/ASIC.GetAnswers.sql*
