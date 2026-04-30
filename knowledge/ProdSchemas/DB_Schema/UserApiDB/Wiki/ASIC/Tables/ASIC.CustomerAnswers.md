# ASIC.CustomerAnswers

> Stores individual question and answer pairs for each ASIC classification test attempt, providing a full record of user responses.

| Property | Value |
|----------|-------|
| **Schema** | ASIC |
| **Object Type** | Table |
| **Key Identifier** | CustomerAnswerId (PK IDENTITY) |
| **Partition** | No |
| **Indexes** | 2 (PK + NC on TestId) |

---

## 1. Business Meaning

ASIC.CustomerAnswers captures the detail of each ASIC classification test: every question asked and the answer the user provided. Each row is one Q&A pair linked to a specific test via TestId. A single test in ASIC.TestResults will have one or more corresponding rows here, one per question in the test.

This table enables auditors and compliance teams to review exactly what questions were presented and what responses were given for any historical test attempt.

---

## 2. Business Logic

No complex business logic. This is a child detail table for ASIC.TestResults. Rows are inserted by ASIC.InsertCustomerAnswer immediately after a test is completed and are read back via ASIC.GetAnswers. The Question and Answer columns store the full text of each question and response (not IDs), making records self-contained for audit purposes.

---

## 3. Data Overview

Transactional table - multiple rows per test (one per question). Volume scales with the number of test attempts and the number of questions per test. Records are never deleted directly; they are implicitly excluded when their parent TestResults row is soft-deleted (Deleted = 1).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CustomerAnswerId | int IDENTITY | NO | - | CODE-BACKED | Primary key. Auto-generated unique identifier for each Q&A row. |
| 2 | TestId | int | NO | - | CODE-BACKED | FK to ASIC.TestResults.TestId. Groups all Q&A pairs for a single test attempt. Indexed for fast retrieval. |
| 3 | Question | nvarchar(1024) | NO | - | CODE-BACKED | Full text of the question asked during the test. Stored as text (not ID) for audit self-sufficiency. |
| 4 | Answer | nvarchar(512) | NO | - | CODE-BACKED | Full text of the user's answer. Stored as text for audit self-sufficiency. |
| 5 | OccurredAt | datetime | NO | - | CODE-BACKED | When this Q&A pair was recorded. Typically matches the parent test's OccurredAt. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TestId | ASIC.TestResults | FK | Each answer row belongs to one test result |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ASIC.GetAnswers | TestId | SP reads | Returns answers joined to non-deleted test results |
| ASIC.InsertCustomerAnswer | - | SP writes | Inserts new Q&A rows into this table |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
ASIC.CustomerAnswers (table)
  +-- ASIC.TestResults (table, FK on TestId)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| ASIC.TestResults | Table | FK constraint on TestId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ASIC.GetAnswers | Stored Procedure | Reads from |
| ASIC.InsertCustomerAnswer | Stored Procedure | Inserts into |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomerAnswers | CLUSTERED PK | CustomerAnswerId ASC | - | - | Active |
| IX_CustomerAnswers_TestId | NONCLUSTERED | TestId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Definition |
|-----------|------|------------|
| PK_CustomerAnswers | PRIMARY KEY | CustomerAnswerId |
| FK_CustomerAnswers_TestResults | FOREIGN KEY | TestId -> ASIC.TestResults.TestId |

---

## 8. Sample Queries

### 8.1 Get all answers for a specific test
```sql
SELECT CustomerAnswerId, Question, Answer, OccurredAt
FROM ASIC.CustomerAnswers WITH (NOLOCK)
WHERE TestId = @TestId
ORDER BY CustomerAnswerId
```

### 8.2 Get answers for all active tests for a user
```sql
SELECT ca.TestId, ca.Question, ca.Answer, ca.OccurredAt
FROM ASIC.CustomerAnswers ca WITH (NOLOCK)
JOIN ASIC.TestResults tr WITH (NOLOCK) ON ca.TestId = tr.TestId
WHERE tr.GCID = @GCID AND tr.Deleted = 0
ORDER BY ca.OccurredAt DESC
```

### 8.3 Count answers per test
```sql
SELECT TestId, COUNT(*) AS AnswerCount
FROM ASIC.CustomerAnswers WITH (NOLOCK)
GROUP BY TestId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Object: ASIC.CustomerAnswers | Type: Table | Source: UserApiDB/UserApiDB/ASIC/Tables/ASIC.CustomerAnswers.sql*
