# dbo.V_KYC

> Base view assembling the KYC question-answer catalog with thresholds from 4 KYC tables into a flat structure.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | QuestionId + AnswerId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.V_KYC is the base KYC metadata view that joins Questions, QuestionsAnswers, Answers, and AnswerThresholds into a flat question-answer structure with thresholds. This view is the foundation for V_CustomerAnswers (which adds user-specific answer data). Includes MultipleSelection flag.

---

## 2. Business Logic

No complex business logic. 4-table LEFT JOIN chain: Questions -> QuestionsAnswers -> Answers -> AnswerThresholds.

---

## 3. Data Overview

N/A - view over KYC metadata tables.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | QuestionId | int | NO | - | CODE-BACKED | Question identifier. From KYC.Questions. |
| 2 | QuestionText | nvarchar(250) | NO | - | CODE-BACKED | Question display text. |
| 3 | AnswerId | int | YES | - | CODE-BACKED | Answer identifier. NULL if question has no answers mapped. |
| 4 | AnswerText | nvarchar(250) | YES | - | CODE-BACKED | Answer display text. |
| 5 | MinThreshold | int | YES | - | CODE-BACKED | Range minimum. From AnswerThresholds. |
| 6 | MaxThreshold | int | YES | - | CODE-BACKED | Range maximum. From AnswerThresholds. |
| 7 | MultipleSelection | bit | NO | - | CODE-BACKED | Whether question allows multiple answers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | KYC.Questions | FROM | Question data |
| - | KYC.QuestionsAnswers | LEFT JOIN | Q-A mapping |
| - | KYC.Answers | LEFT JOIN | Answer text |
| - | KYC.AnswerThresholds | LEFT JOIN | Thresholds |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.V_CustomerAnswers | - | LEFT JOIN | User answer enrichment |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.V_KYC (view)
  +-- KYC.Questions (table) [done]
  +-- KYC.QuestionsAnswers (table) [done]
  +-- KYC.Answers (table) [done]
  +-- KYC.AnswerThresholds (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYC.Questions | Table | FROM |
| KYC.QuestionsAnswers | Table | LEFT JOIN |
| KYC.Answers | Table | LEFT JOIN |
| KYC.AnswerThresholds | Table | LEFT JOIN |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.V_CustomerAnswers | View | LEFT JOIN |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Full Q-A catalog
```sql
SELECT * FROM dbo.V_KYC WITH (NOLOCK) ORDER BY QuestionId, AnswerId
```

### 8.2 Questions with thresholds
```sql
SELECT * FROM dbo.V_KYC WITH (NOLOCK) WHERE MinThreshold IS NOT NULL
```

### 8.3 Multi-select questions
```sql
SELECT DISTINCT QuestionId, QuestionText FROM dbo.V_KYC WITH (NOLOCK) WHERE MultipleSelection = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Object: dbo.V_KYC | Type: View | Source: UserApiDB/UserApiDB/dbo/Views/dbo.V_KYC.sql*
