# KYC.GetCustomerAnswers

> Returns a user's KYC questionnaire answers with the earliest submission date (FirstUpdated) computed from History.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYC.GetCustomerAnswers retrieves all current KYC answers for a user. For each answer, it also computes FirstUpdated by checking History.CustomerAnswers for the earliest OccurredAt for that question+GCID combination. If no history exists, OccurredAt from the current record is used. This tells when the user first answered each question.

---

## 2. Business Logic

### 2.1 FirstUpdated Calculation

**What**: Determines when user first answered each question (across answer changes).

**Columns/Parameters Involved**: `OccurredAt`, `FirstUpdated`

**Rules**:
- FirstUpdated = MIN(History.CustomerAnswers.OccurredAt) for same GCID+QuestionId
- Falls back to current OccurredAt if no history exists (ISNULL)
- Subquery with MIN() against History table

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int (IN) | NO | - | CODE-BACKED | Global Customer ID. |

Output: GCID, QuestionId, AnswerId, OccurredAt, FreeText, FirstUpdated.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | KYC.CustomerAnswers | SELECT FROM | Current answers |
| - | History.CustomerAnswers | Subquery | Earliest answer date |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.GetCustomerAnswers (procedure)
  +-- KYC.CustomerAnswers (table) [done]
  +-- History.CustomerAnswers (table, external)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYC.CustomerAnswers | Table | SELECT FROM WITH NOLOCK |
| History.CustomerAnswers | Table | Subquery for MIN(OccurredAt) |

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

### 8.1 Get customer answers
```sql
EXEC KYC.GetCustomerAnswers @gcid = 12345
```

### 8.2 Direct equivalent
```sql
SELECT GCID, QuestionId, AnswerId, OccurredAt, FreeText,
  ISNULL((SELECT MIN(h.OccurredAt) FROM History.CustomerAnswers h WITH (NOLOCK)
   WHERE h.QuestionId = ca.QuestionId AND h.GCID = ca.GCID), OccurredAt) AS FirstUpdated
FROM KYC.CustomerAnswers ca WITH (NOLOCK) WHERE GCID = 12345
```

### 8.3 With question text
```sql
DECLARE @R TABLE (GCID INT, QuestionId INT, AnswerId INT, OccurredAt DATETIME, FreeText NVARCHAR(MAX), FirstUpdated DATETIME)
INSERT INTO @R EXEC KYC.GetCustomerAnswers @gcid = 12345
SELECT r.QuestionId, q.QuestionText, r.AnswerId, a.AnswerText FROM @R r
JOIN KYC.Questions q WITH (NOLOCK) ON r.QuestionId = q.QuestionId AND q.LanguageId = 1
JOIN KYC.Answers a WITH (NOLOCK) ON r.AnswerId = a.AnswerId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: KYC.GetCustomerAnswers | Type: Stored Procedure | Source: UserApiDB/UserApiDB/KYC/Stored Procedures/KYC.GetCustomerAnswers.sql*
