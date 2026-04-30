# DWH.Questions_Answers_V

> Data warehouse view joining KYC questions with their possible answers, providing a flat question-answer reference dataset for reporting and analytics.

| Property | Value |
|----------|-------|
| **Schema** | DWH |
| **Object Type** | View |
| **Key Identifier** | QuestionId + AnswerId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

DWH.Questions_Answers_V is a reporting-oriented view that flattens the KYC question-answer structure into a single joinable dataset. KYC (Know Your Customer) questionnaires are used during onboarding and regulatory assessments to classify users by experience, suitability, and risk profile. Questions can have multiple possible answers, and some questions allow multiple selections.

This view serves as the reference dimension for DWH and analytics queries that need to interpret raw KYC answer codes stored in fact tables. Instead of joining three KYC tables separately, downstream consumers join to this single view to get the full context: what was the question, what answer was selected, whether multiple answers were allowed.

---

## 2. Business Logic

### 2.1 Question-Answer Flattening

**What**: Joins questions to their answer options via the junction table.

**Columns/Parameters Involved**: `QuestionId`, `AnswerId`, `MultipleSelection`

**Rules**:
- KYC.Questions INNER JOIN KYC.QuestionsAnswers ON QuestionId — links questions to their valid answer set
- KYC.QuestionsAnswers INNER JOIN KYC.Answers ON AnswerId — resolves answer text
- All JOINs are INNER JOIN — questions with no answers and orphan answer records are excluded
- MultipleSelection flag indicates whether users can select more than one answer for a question
- No filtering — returns all active questions and answers

---

## 3. Data Overview

N/A - view over KYC reference tables; row count equals total question-answer option combinations.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | QuestionId | int | NO | - | CODE-BACKED | KYC question identifier. From KYC.Questions. Groups all answer rows for the same question. |
| 2 | QuestionText | nvarchar | NO | - | CODE-BACKED | The full text of the KYC question as shown to the user. From KYC.Questions. |
| 3 | MultipleSelection | bit | NO | - | CODE-BACKED | Whether the user may select more than one answer for this question. 1=multiple allowed, 0=single answer only. From KYC.Questions. |
| 4 | AnswerId | int | NO | - | CODE-BACKED | KYC answer option identifier. From KYC.Answers via KYC.QuestionsAnswers junction. |
| 5 | AnswerText | nvarchar | NO | - | CODE-BACKED | The full text of the answer option as shown to the user. From KYC.Answers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| QuestionId, QuestionText, MultipleSelection | KYC.Questions | INNER JOIN | Source of question definitions |
| QuestionId/AnswerId linkage | KYC.QuestionsAnswers | INNER JOIN | Junction table mapping questions to answers |
| AnswerId, AnswerText | KYC.Answers | INNER JOIN | Source of answer option text |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DWH reporting queries | QuestionId, AnswerId | View read | Used as reference dimension in KYC analytics |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
DWH.Questions_Answers_V (view)
  +-- KYC.Questions (table)
  +-- KYC.QuestionsAnswers (table)
  +-- KYC.Answers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYC.Questions | Table | INNER JOIN: source of question text and MultipleSelection flag |
| KYC.QuestionsAnswers | Table | INNER JOIN: junction table linking questions to answer options |
| KYC.Answers | Table | INNER JOIN: source of answer option text |

### 6.2 Objects That Depend On This

No user-object dependents found in SQL layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view (no SCHEMABINDING, no indexed view).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all questions with their answer options
```sql
SELECT QuestionId, QuestionText, MultipleSelection, AnswerId, AnswerText
FROM DWH.Questions_Answers_V WITH (NOLOCK)
ORDER BY QuestionId, AnswerId
```

### 8.2 Find all answers for a specific question
```sql
SELECT AnswerId, AnswerText FROM DWH.Questions_Answers_V WITH (NOLOCK)
WHERE QuestionId = @QuestionId
ORDER BY AnswerId
```

### 8.3 List questions that allow multiple selections
```sql
SELECT DISTINCT QuestionId, QuestionText
FROM DWH.Questions_Answers_V WITH (NOLOCK)
WHERE MultipleSelection = 1
ORDER BY QuestionId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Object: DWH.Questions_Answers_V | Type: View | Source: UserApiDB/UserApiDB/DWH/Views/DWH.Questions_Answers_V.sql*
