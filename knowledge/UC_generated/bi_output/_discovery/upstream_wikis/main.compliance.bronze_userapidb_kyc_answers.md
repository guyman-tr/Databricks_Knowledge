# KYC.Answers

> Master table of KYC questionnaire answer options with localized text, status tracking, free-text validation, and translation keys.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Table |
| **Key Identifier** | AnswerId (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

KYC.Answers is the master catalog of all possible answers for KYC questionnaire questions. Each answer has localized display text, a status (Active/Outdated via Dictionary.AnswerStatus), an optional regex validation for free-text input, and a translation key for multi-language support. Contains 635 answer options across all KYC question types.

This table is central to the KYC suitability assessment system. Answers are linked to questions via KYC.QuestionsAnswers (many-to-many), and customer selections are stored in KYC.CustomerAnswers. Some answers have numeric thresholds (KYC.AnswerThresholds) for range-based questions.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Answers are linked to questions via QuestionsAnswers junction table.

---

## 3. Data Overview

635 rows. Sample answers vary by question type (income ranges, experience levels, risk awareness, etc.).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AnswerId | int | NO | - | CODE-BACKED | Primary key. Answer identifier. Referenced by QuestionsAnswers, CustomerAnswers, AnswerThresholds, CryptoAssessmentAnswers. |
| 2 | LanguageId | int | NO | - | CODE-BACKED | Language of the answer text. Implicit FK to Dictionary.Language. |
| 3 | AnswerText | nvarchar(250) | NO | - | CODE-BACKED | Localized display text for this answer option. |
| 4 | StatusID | int | NO | 1 | CODE-BACKED | FK to Dictionary.AnswerStatus. 0=Outdated, 1=Active. Default: 1. See [Answer Status](_glossary.md#answer-status). |
| 5 | FreeTextValidationExpression | varchar(1000) | YES | - | CODE-BACKED | Regex pattern for validating free-text input when this answer is selected. NULL if no free-text input. |
| 6 | TranslationKey | nvarchar(250) | YES | - | CODE-BACKED | i18n translation key for multi-language support. Used by frontend to look up localized text. |
| 7 | AnswerShortDescription | nvarchar(100) | YES | - | CODE-BACKED | Short description for internal use and reporting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| StatusID | Dictionary.AnswerStatus | Explicit FK | Active/Outdated status |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYC.AnswerThresholds | AnswerID | Explicit FK | Numeric thresholds for range-based answers |
| KYC.CryptoAssessmentAnswers | AnswerId | Explicit FK | Links answers to crypto assessment categories |
| KYC.QuestionsAnswers | AnswerId | Implicit FK | Question-to-answer mapping |
| KYC.CustomerAnswers | AnswerId | Implicit FK | Customer's selected answers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.Answers (table)
  +-- Dictionary.AnswerStatus (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.AnswerStatus | Table | FK: StatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYC.AnswerThresholds | Table | FK: AnswerID |
| KYC.CryptoAssessmentAnswers | Table | FK: AnswerId |
| KYC.GetKycQuestions | Stored Procedure | JOINed via QuestionsAnswers |
| KYC.GetCryptoAssessmentAnswers | Stored Procedure | JOINed |
| KYC.MetadataLoader | Stored Procedure | Reads AnswerShortDescription for metadata cache |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_KYC_Answers | CLUSTERED PK | AnswerId | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Df_KYC_Answers_StatusID | DEFAULT | (1) - Active by default |
| FK_KYC_Answers_StatusID | FOREIGN KEY | StatusID -> Dictionary.AnswerStatus |

---

## 8. Sample Queries

### 8.1 List active answers
```sql
SELECT AnswerId, AnswerText, AnswerShortDescription FROM KYC.Answers WITH (NOLOCK) WHERE StatusID = 1 ORDER BY AnswerId
```

### 8.2 Answers for a specific question
```sql
SELECT a.AnswerId, a.AnswerText FROM KYC.Answers a WITH (NOLOCK)
JOIN KYC.QuestionsAnswers qa WITH (NOLOCK) ON a.AnswerId = qa.AnswerId
WHERE qa.QuestionId = @QuestionId AND a.StatusID = 1 ORDER BY qa.[Order]
```

### 8.3 Answers with thresholds
```sql
SELECT a.AnswerId, a.AnswerText, t.MinThreshold, t.MaxThreshold
FROM KYC.Answers a WITH (NOLOCK) JOIN KYC.AnswerThresholds t WITH (NOLOCK) ON a.AnswerId = t.AnswerID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 8.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: KYC.Answers | Type: Table | Source: UserApiDB/UserApiDB/KYC/Tables/KYC.Answers.sql*
