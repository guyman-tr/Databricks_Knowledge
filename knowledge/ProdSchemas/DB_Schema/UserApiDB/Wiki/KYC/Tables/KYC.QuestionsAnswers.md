# KYC.QuestionsAnswers

> Junction table mapping questions to their available answers with display order.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Table |
| **Key Identifier** | QuestionId + AnswerId (composite PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

KYC.QuestionsAnswers is the many-to-many junction table linking KYC questions to their available answer options. Each row maps one question to one answer, with an optional Order column for controlling display sequence. Contains 870 mappings. Used by GetKycQuestions to build the full question-answer structure.

---

## 2. Business Logic

No complex business logic. Junction table with optional ordering.

---

## 3. Data Overview

870 rows.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | QuestionId | int | NO | - | CODE-BACKED | Part of composite PK. References KYC.Questions. |
| 2 | AnswerId | int | NO | - | CODE-BACKED | Part of composite PK. References KYC.Answers. |
| 3 | Order | int | YES | - | CODE-BACKED | Display order of this answer within the question. NULL for unordered answers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no explicit FK constraints.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYC.GetKycQuestions | QuestionId | SP reads | JOINed to build question-answer structure |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies (no explicit FKs).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYC.GetKycQuestions | Stored Procedure | LEFT JOIN |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_QuestionsToAnswers | CLUSTERED PK | QuestionId, AnswerId | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Answers for a question
```sql
SELECT qa.AnswerId, a.AnswerText, qa.[Order] FROM KYC.QuestionsAnswers qa WITH (NOLOCK)
JOIN KYC.Answers a WITH (NOLOCK) ON qa.AnswerId = a.AnswerId WHERE qa.QuestionId = @QuestionId ORDER BY qa.[Order]
```

### 8.2 Questions per answer
```sql
SELECT AnswerId, COUNT(*) AS QuestionCount FROM KYC.QuestionsAnswers WITH (NOLOCK) GROUP BY AnswerId HAVING COUNT(*) > 1
```

### 8.3 Full question-answer catalog
```sql
SELECT q.QuestionId, q.QuestionText, a.AnswerId, a.AnswerText, qa.[Order]
FROM KYC.QuestionsAnswers qa WITH (NOLOCK)
JOIN KYC.Questions q WITH (NOLOCK) ON qa.QuestionId = q.QuestionId AND q.LanguageId = 1
JOIN KYC.Answers a WITH (NOLOCK) ON qa.AnswerId = a.AnswerId ORDER BY q.QuestionId, qa.[Order]
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: KYC.QuestionsAnswers | Type: Table | Source: UserApiDB/UserApiDB/KYC/Tables/KYC.QuestionsAnswers.sql*
