# dbo.V_QuestionsAnswers

> View joining KYC Questions, QuestionsAnswers, and Answers tables to provide a complete Q-A catalog with language, activity status, and ordering.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | QuestionId + LanguageId + AnswerId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.V_QuestionsAnswers is a localized question-answer catalog view. Unlike V_KYC (LEFT JOINs, single language), this uses INNER JOINs and includes LanguageId, IsActive, Order, and StatusID. It matches Answers to Questions on both QuestionId and LanguageId, providing language-specific Q-A pairs.

---

## 2. Business Logic

No complex business logic. 3-table INNER JOIN: Questions -> QuestionsAnswers -> Answers (matching LanguageId).

---

## 3. Data Overview

N/A - view.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | QuestionId | int | NO | - | CODE-BACKED | Question identifier. |
| 2 | LanguageId | int | NO | - | CODE-BACKED | Language for this Q-A pair. |
| 3 | QuestionText | nvarchar(250) | NO | - | CODE-BACKED | Localized question text. |
| 4 | MultipleSelection | bit | NO | - | CODE-BACKED | Multi-select flag. |
| 5 | IsActive | int | NO | - | CODE-BACKED | Whether question is active. |
| 6 | Order | int | YES | - | CODE-BACKED | Display order of answer within question. |
| 7 | AnswerId | int | NO | - | CODE-BACKED | Answer identifier. |
| 8 | AnswerText | nvarchar(250) | NO | - | CODE-BACKED | Localized answer text. |
| 9 | StatusID | int | NO | - | CODE-BACKED | Answer status: 0=Outdated, 1=Active. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | KYC.Questions | FROM | Question data |
| - | KYC.QuestionsAnswers | INNER JOIN | Q-A mapping |
| - | KYC.Answers | INNER JOIN | Answer data (matched by LanguageId) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.V_QuestionsAnswers (view)
  +-- KYC.Questions (table) [done]
  +-- KYC.QuestionsAnswers (table) [done]
  +-- KYC.Answers (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYC.Questions | Table | FROM |
| KYC.QuestionsAnswers | Table | INNER JOIN |
| KYC.Answers | Table | INNER JOIN |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 English Q-A catalog
```sql
SELECT * FROM dbo.V_QuestionsAnswers WITH (NOLOCK) WHERE LanguageId = 1 ORDER BY QuestionId, [Order]
```

### 8.2 Active questions only
```sql
SELECT DISTINCT QuestionId, QuestionText FROM dbo.V_QuestionsAnswers WITH (NOLOCK) WHERE IsActive = 1 AND LanguageId = 1
```

### 8.3 Answers for a question
```sql
SELECT AnswerId, AnswerText, StatusID, [Order] FROM dbo.V_QuestionsAnswers WITH (NOLOCK)
WHERE QuestionId = @QId AND LanguageId = 1 ORDER BY [Order]
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Object: dbo.V_QuestionsAnswers | Type: View | Source: UserApiDB/UserApiDB/dbo/Views/dbo.V_QuestionsAnswers.sql*
