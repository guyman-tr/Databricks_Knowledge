# dbo.V_CustomerQuestionsAnswers

> View joining KYC.CustomerAnswers with V_QuestionsAnswers to provide user answers with full localized question/answer text, status, and ordering.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | GCID + QuestionId + AnswerId (from CustomerAnswers) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.V_CustomerQuestionsAnswers is similar to dbo.V_CustomerAnswers but uses INNER JOIN (not LEFT JOIN) with V_QuestionsAnswers instead of V_KYC. This means it includes LanguageId, IsActive, Order, and StatusID columns - providing localized, language-specific question-answer pairs. Only returns answers that have matching question-answer mappings (no orphans).

---

## 2. Business Logic

No complex business logic. INNER JOIN from CustomerAnswers to V_QuestionsAnswers on QuestionId + AnswerId.

---

## 3. Data Overview

N/A - view over 180M+ row CustomerAnswers table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | User who answered. From KYC.CustomerAnswers. |
| 2 | OccurredAt | datetime | NO | - | CODE-BACKED | When answer was submitted. |
| 3 | FreeText | nvarchar(max) | YES | - | CODE-BACKED | Free-text response. |
| 4 | QuestionId | int | NO | - | CODE-BACKED | Question identifier. From V_QuestionsAnswers. |
| 5 | LanguageId | int | NO | - | CODE-BACKED | Language of question/answer text. |
| 6 | QuestionText | nvarchar(250) | NO | - | CODE-BACKED | Localized question text. |
| 7 | MultipleSelection | bit | NO | - | CODE-BACKED | Multi-select flag. |
| 8 | IsActive | int | NO | - | CODE-BACKED | Whether question is active. |
| 9 | Order | int | YES | - | CODE-BACKED | Display order of answer within question. |
| 10 | AnswerId | int | NO | - | CODE-BACKED | Answer identifier. |
| 11 | AnswerText | nvarchar(250) | NO | - | CODE-BACKED | Localized answer text. |
| 12 | StatusID | int | NO | - | CODE-BACKED | Answer status: 0=Outdated, 1=Active. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | KYC.CustomerAnswers | FROM | User answer data |
| - | dbo.V_QuestionsAnswers | INNER JOIN | Localized Q-A metadata |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.V_CustomerQuestionsAnswers (view)
  +-- KYC.CustomerAnswers (table) [done]
  +-- dbo.V_QuestionsAnswers (view) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYC.CustomerAnswers | Table | FROM |
| dbo.V_QuestionsAnswers | View | INNER JOIN |

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

### 8.1 User answers in English
```sql
SELECT GCID, QuestionText, AnswerText, OccurredAt FROM dbo.V_CustomerQuestionsAnswers WITH (NOLOCK)
WHERE GCID = @GCID AND LanguageId = 1
```

### 8.2 Active answers only
```sql
SELECT * FROM dbo.V_CustomerQuestionsAnswers WITH (NOLOCK) WHERE GCID = @GCID AND StatusID = 1 AND IsActive = 1
```

### 8.3 Ordered by question
```sql
SELECT QuestionText, AnswerText, [Order] FROM dbo.V_CustomerQuestionsAnswers WITH (NOLOCK)
WHERE GCID = @GCID AND LanguageId = 1 ORDER BY QuestionId, [Order]
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Object: dbo.V_CustomerQuestionsAnswers | Type: View | Source: UserApiDB/UserApiDB/dbo/Views/dbo.V_CustomerQuestionsAnswers.sql*
