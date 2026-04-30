# KYC.GetCryptoAssessmentAnswers

> Returns enabled crypto assessment answers with correctness, category, translation key, and free-text validation from joined Answers table.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No input params |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYC.GetCryptoAssessmentAnswers returns the active crypto knowledge assessment quiz data by joining CryptoAssessmentAnswers with Answers. Filters to IsEnabled=1 only. Returns AnswerId, IsCorrect, AnswerCategoryId, TranslationKey, and FreeTextValidationExpression. Used to build the crypto assessment UI.

---

## 2. Business Logic

No complex business logic. SELECT with JOIN, filtered to enabled answers.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters. Output: AnswerId, IsCorrect, AnswerCategoryId, TranslationKey, FreeTextValidationExpression.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | KYC.CryptoAssessmentAnswers | SELECT FROM | Assessment data |
| - | KYC.Answers | INNER JOIN | Answer text and validation |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.GetCryptoAssessmentAnswers (procedure)
  +-- KYC.CryptoAssessmentAnswers (table) [done]
  +-- KYC.Answers (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYC.CryptoAssessmentAnswers | Table | SELECT FROM WITH NOLOCK |
| KYC.Answers | Table | INNER JOIN WITH NOLOCK |

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

### 8.1 Get assessment answers
```sql
EXEC KYC.GetCryptoAssessmentAnswers
```

### 8.2 Direct equivalent
```sql
SELECT caa.AnswerId, caa.IsCorrect, caa.AnswerCategoryId, q.TranslationKey, q.FreeTextValidationExpression
FROM KYC.CryptoAssessmentAnswers caa WITH (NOLOCK) INNER JOIN KYC.Answers q WITH (NOLOCK) ON q.AnswerId = caa.AnswerId WHERE caa.IsEnabled = 1
```

### 8.3 With category names
```sql
SELECT caa.AnswerId, caa.IsCorrect, c.Name AS Category, q.TranslationKey
FROM KYC.CryptoAssessmentAnswers caa WITH (NOLOCK) JOIN KYC.Answers q WITH (NOLOCK) ON q.AnswerId = caa.AnswerId
JOIN Dictionary.CryptoAssessmentAnswerCategory c WITH (NOLOCK) ON caa.AnswerCategoryId = c.ID WHERE caa.IsEnabled = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: KYC.GetCryptoAssessmentAnswers | Type: Stored Procedure | Source: UserApiDB/UserApiDB/KYC/Stored Procedures/KYC.GetCryptoAssessmentAnswers.sql*
