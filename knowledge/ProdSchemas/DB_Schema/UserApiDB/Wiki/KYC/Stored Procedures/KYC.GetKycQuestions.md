# KYC.GetKycQuestions

> Returns KYC questionnaire questions with their answers, thresholds, translation keys, and ordering for a specific language and optional question filter.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @langId + @questionId (input params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYC.GetKycQuestions is the primary procedure for building the KYC suitability questionnaire UI. It joins Questions, QuestionsAnswers, Answers, and AnswerThresholds to return a complete question-answer structure for a given language. Optionally filters to a specific question. Returns question text, answer text, status, thresholds, ordering, and translation keys.

---

## 2. Business Logic

### 2.1 Full Question-Answer Assembly

**What**: Assembles complete questionnaire from 4 tables.

**Columns/Parameters Involved**: `@questionId`, `@langId`

**Rules**:
- Questions -> LEFT JOIN QuestionsAnswers -> LEFT JOIN Answers (matching language) -> LEFT JOIN AnswerThresholds
- @questionId NULL returns all questions
- Language filter on both Questions and Answers (LanguageId match)
- Uses NOLOCK on all tables

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @questionId | int (IN) | YES | NULL | CODE-BACKED | Optional: specific question to retrieve. NULL returns all questions. |
| 2 | @langId | int (IN) | NO | - | CODE-BACKED | Language ID for localized text. Maps to Dictionary.Language. |

Output: QuestionId, MultipleSelection, LanguageId, QuestionText, QuestionTranslationKey, AnswerId, AnswerText, StatusID, MinThreshold, MaxThreshold, Order, FreeTextValidationExpression, AnswerTranslationKey.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | KYC.Questions | SELECT FROM | Question data |
| - | KYC.QuestionsAnswers | LEFT JOIN | Question-answer mapping |
| - | KYC.Answers | LEFT JOIN | Answer text and validation |
| - | KYC.AnswerThresholds | LEFT JOIN | Numeric thresholds |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.GetKycQuestions (procedure)
  +-- KYC.Questions (table) [done]
  +-- KYC.QuestionsAnswers (table) [done]
  +-- KYC.Answers (table) [done]
  +-- KYC.AnswerThresholds (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYC.Questions | Table | SELECT FROM |
| KYC.QuestionsAnswers | Table | LEFT JOIN |
| KYC.Answers | Table | LEFT JOIN |
| KYC.AnswerThresholds | Table | LEFT JOIN |

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

### 8.1 All questions in English
```sql
EXEC KYC.GetKycQuestions @langId = 1
```

### 8.2 Specific question
```sql
EXEC KYC.GetKycQuestions @questionId = 5, @langId = 1
```

### 8.3 Questions in German
```sql
EXEC KYC.GetKycQuestions @langId = 2
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: KYC.GetKycQuestions | Type: Stored Procedure | Source: UserApiDB/UserApiDB/KYC/Stored Procedures/KYC.GetKycQuestions.sql*
