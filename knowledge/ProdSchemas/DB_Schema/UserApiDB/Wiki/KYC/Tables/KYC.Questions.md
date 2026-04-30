# KYC.Questions

> Master table of KYC suitability questionnaire questions with localized text, multi-selection flag, and active status.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Table |
| **Key Identifier** | LanguageId + QuestionId (composite PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

KYC.Questions stores the KYC suitability assessment questions with localized text. Each question exists once per language (composite PK: LanguageId, QuestionId). Contains 126 rows (questions across languages). Questions can be single-select or multi-select. Linked to answers via KYC.QuestionsAnswers and to options via KYC.QuestionsOption.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Localized question catalog.

---

## 3. Data Overview

126 rows (questions x languages).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | QuestionId | int | NO | - | CODE-BACKED | Part of composite PK. Question identifier. Same QuestionId appears in multiple languages. |
| 2 | LanguageId | int | NO | - | CODE-BACKED | Part of composite PK. Language of the question text. Implicit FK to Dictionary.Language. |
| 3 | QuestionText | nvarchar(250) | NO | - | CODE-BACKED | Localized display text for this question. |
| 4 | MultipleSelection | bit | NO | 0 | CODE-BACKED | Whether multiple answers can be selected. Default: 0 (single-select). |
| 5 | IsActive | int | NO | 1 | CODE-BACKED | Whether this question is currently active in the questionnaire. Default: 1 (active). |
| 6 | TranslationKey | nvarchar(250) | YES | - | CODE-BACKED | i18n key for frontend localization. |
| 7 | QuestionShortDescription | nvarchar(50) | YES | - | CODE-BACKED | Short internal description for reporting and admin tools. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYC.QuestionsAnswers | QuestionId | Implicit FK | Question-to-answer mapping |
| KYC.QuestionsOption | QuestionId | Implicit FK | Question options |
| KYC.CustomerAnswers | QuestionId | Implicit FK | Customer's selected answers |
| KYC.CustomerAnswers | QuestionId | Implicit FK | Stores user responses per question |
| KYC.GetKycQuestions | QuestionId | SP reads | Returns questions with answers |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYC.QuestionsAnswers | Table | References QuestionId |
| KYC.GetKycQuestions | Stored Procedure | Reads from |
| KYC.MetadataLoader | Stored Procedure | Reads QuestionShortDescription for metadata cache |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED PK | LanguageId, QuestionId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (unnamed) | DEFAULT | (0) for MultipleSelection |
| DF_Questions_IsActive | DEFAULT | (1) for IsActive |

---

## 8. Sample Queries

### 8.1 Active questions in English
```sql
SELECT QuestionId, QuestionText, MultipleSelection FROM KYC.Questions WITH (NOLOCK) WHERE LanguageId = 1 AND IsActive = 1 ORDER BY QuestionId
```

### 8.2 Questions with answer count
```sql
SELECT q.QuestionId, q.QuestionText, COUNT(qa.AnswerId) AS AnswerCount
FROM KYC.Questions q WITH (NOLOCK) LEFT JOIN KYC.QuestionsAnswers qa WITH (NOLOCK) ON q.QuestionId = qa.QuestionId
WHERE q.LanguageId = 1 GROUP BY q.QuestionId, q.QuestionText ORDER BY q.QuestionId
```

### 8.3 Multi-select questions
```sql
SELECT QuestionId, QuestionText FROM KYC.Questions WITH (NOLOCK) WHERE MultipleSelection = 1 AND LanguageId = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: KYC.Questions | Type: Table | Source: UserApiDB/UserApiDB/KYC/Tables/KYC.Questions.sql*
