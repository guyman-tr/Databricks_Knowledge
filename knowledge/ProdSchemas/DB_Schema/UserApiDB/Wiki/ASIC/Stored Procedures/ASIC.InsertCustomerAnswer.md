# ASIC.InsertCustomerAnswer

> Inserts a single question and answer pair into ASIC.CustomerAnswers for a given test attempt.

| Property | Value |
|----------|-------|
| **Schema** | ASIC |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @TestId, @Question, @Answer (input params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

ASIC.InsertCustomerAnswer records one Q&A pair from an ASIC classification test session. It is called once per question after a test is completed (or in progress), linking each question and its answer to the parent test result via TestId. Multiple calls are expected per test - one per question in the ASIC questionnaire.

This procedure is always used in conjunction with ASIC.InsertTestResult: first the test result row is inserted (returning a TestId), then InsertCustomerAnswer is called for each question using that TestId.

---

## 2. Business Logic

No complex logic. Straightforward single-row INSERT into ASIC.CustomerAnswers. OccurredAt is likely supplied by the caller or defaults to the current timestamp at insert time.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TestId | int (IN) | NO | - | CODE-BACKED | FK to ASIC.TestResults.TestId. Links this answer to its parent test. |
| 2 | @Question | nvarchar(1024) (IN) | NO | - | CODE-BACKED | Full text of the question asked during the ASIC test. |
| 3 | @Answer | nvarchar(512) (IN) | NO | - | CODE-BACKED | Full text of the user's response to the question. |
| 4 | @OccurredAt | datetime (IN) | NO | - | NAME-INFERRED | When the answer was recorded. Typically passed by the caller to match the test's timestamp. |

No output - procedure performs an INSERT only.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TestId | ASIC.CustomerAnswers | INSERT INTO | Adds one Q&A row linked to a test result |
| @TestId | ASIC.TestResults | FK (implicit) | @TestId must exist in TestResults |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
ASIC.InsertCustomerAnswer (procedure)
  +-- ASIC.CustomerAnswers (table)
      +-- ASIC.TestResults (table, FK on TestId)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| ASIC.CustomerAnswers | Table | INSERT INTO |
| ASIC.TestResults | Table | FK constraint enforced on TestId |

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

### 8.1 Insert a single answer
```sql
EXEC ASIC.InsertCustomerAnswer
    @TestId     = 42,
    @Question   = N'What is your primary investment objective?',
    @Answer     = N'Capital growth',
    @OccurredAt = '2026-04-11 09:00:00'
```

### 8.2 Typical usage pattern (insert test then answers)
```sql
-- Step 1: insert test result
EXEC ASIC.InsertTestResult @GCID = 12345, @Success = 1, @Score = 85, @OccurredAt = '2026-04-11 09:00:00'
-- Returns @TestId (e.g., 42)

-- Step 2: insert each Q&A pair
EXEC ASIC.InsertCustomerAnswer @TestId = 42, @Question = N'Question 1?', @Answer = N'Answer A', @OccurredAt = '2026-04-11 09:00:00'
EXEC ASIC.InsertCustomerAnswer @TestId = 42, @Question = N'Question 2?', @Answer = N'Answer B', @OccurredAt = '2026-04-11 09:00:00'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.8/10 (Elements: 8/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 5/6*
*Object: ASIC.InsertCustomerAnswer | Type: Stored Procedure | Source: UserApiDB/UserApiDB/ASIC/Stored Procedures/ASIC.InsertCustomerAnswer.sql*
