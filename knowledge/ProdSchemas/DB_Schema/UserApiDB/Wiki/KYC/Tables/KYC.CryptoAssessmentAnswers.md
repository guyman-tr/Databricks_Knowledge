# KYC.CryptoAssessmentAnswers

> Maps KYC answers to crypto assessment categories, marking correctness for the crypto knowledge test.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Table |
| **Key Identifier** | Id (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

KYC.CryptoAssessmentAnswers links standard KYC answers (from KYC.Answers) to the 7 crypto risk assessment categories (from Dictionary.CryptoAssessmentAnswerCategory). Each row indicates whether an answer is correct for its category and whether it's currently enabled. Contains 240 entries. Used by GetCryptoAssessmentAnswers to build the crypto assessment quiz.

---

## 2. Business Logic

### 2.1 Correctness Tracking

**What**: Each answer in the crypto assessment has a defined correct/incorrect classification.

**Columns/Parameters Involved**: `AnswerId`, `IsCorrect`, `AnswerCategoryId`

**Rules**:
- IsCorrect=1: This answer demonstrates correct understanding of the risk category
- IsCorrect=0: This answer indicates insufficient understanding
- Assessment pass/fail is determined by counting correct answers across categories

---

## 3. Data Overview

240 rows.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int (IDENTITY) | NO | - | CODE-BACKED | Primary key. Auto-incrementing. |
| 2 | AnswerId | int | NO | - | CODE-BACKED | FK to KYC.Answers. The answer option. |
| 3 | IsCorrect | bit | NO | - | CODE-BACKED | Whether this answer demonstrates correct understanding of the crypto risk. 1=correct, 0=incorrect. |
| 4 | AnswerCategoryId | int | NO | - | CODE-BACKED | FK to Dictionary.CryptoAssessmentAnswerCategory. Risk category (1-7): Complete Loss, Cyber-Risks, Diversification, Regulatory, Liquidity, Technical, Volatility. See [Crypto Assessment Answer Category](_glossary.md#crypto-assessment-answer-category). |
| 5 | IsEnabled | bit | YES | 1 | CODE-BACKED | Whether this answer is currently active in the assessment. Default: 1 (enabled). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AnswerId | KYC.Answers | Explicit FK | Answer option |
| AnswerCategoryId | Dictionary.CryptoAssessmentAnswerCategory | Explicit FK | Risk category |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYC.GetCryptoAssessmentAnswers | - | SP reads | Returns enabled crypto assessment answers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.CryptoAssessmentAnswers (table)
  +-- KYC.Answers (table) [done in this batch]
  +-- Dictionary.CryptoAssessmentAnswerCategory (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYC.Answers | Table | FK: AnswerId |
| Dictionary.CryptoAssessmentAnswerCategory | Table | FK: AnswerCategoryId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYC.GetCryptoAssessmentAnswers | Stored Procedure | Reads from |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_KYC_CryptoAssessmentAnswers | CLUSTERED PK | Id | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (unnamed) | DEFAULT | (1) for IsEnabled |
| FK_KYC_CryptoAssessmentAnswers_AnswerCategoryId | FOREIGN KEY | AnswerCategoryId -> Dictionary.CryptoAssessmentAnswerCategory |
| FK_KYC_CryptoAssessmentAnswers_AnswerId | FOREIGN KEY | AnswerId -> KYC.Answers |

---

## 8. Sample Queries

### 8.1 Enabled answers with categories
```sql
SELECT caa.AnswerId, a.AnswerText, caa.IsCorrect, c.Name AS Category
FROM KYC.CryptoAssessmentAnswers caa WITH (NOLOCK)
JOIN KYC.Answers a WITH (NOLOCK) ON caa.AnswerId = a.AnswerId
JOIN Dictionary.CryptoAssessmentAnswerCategory c WITH (NOLOCK) ON caa.AnswerCategoryId = c.ID
WHERE caa.IsEnabled = 1
```

### 8.2 Correct answers per category
```sql
SELECT c.Name, COUNT(*) AS CorrectCount FROM KYC.CryptoAssessmentAnswers caa WITH (NOLOCK)
JOIN Dictionary.CryptoAssessmentAnswerCategory c WITH (NOLOCK) ON caa.AnswerCategoryId = c.ID
WHERE caa.IsCorrect = 1 AND caa.IsEnabled = 1 GROUP BY c.Name
```

### 8.3 All answers for a category
```sql
SELECT caa.AnswerId, a.AnswerText, caa.IsCorrect FROM KYC.CryptoAssessmentAnswers caa WITH (NOLOCK)
JOIN KYC.Answers a WITH (NOLOCK) ON caa.AnswerId = a.AnswerId WHERE caa.AnswerCategoryId = @CategoryId AND caa.IsEnabled = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: KYC.CryptoAssessmentAnswers | Type: Table | Source: UserApiDB/UserApiDB/KYC/Tables/KYC.CryptoAssessmentAnswers.sql*
