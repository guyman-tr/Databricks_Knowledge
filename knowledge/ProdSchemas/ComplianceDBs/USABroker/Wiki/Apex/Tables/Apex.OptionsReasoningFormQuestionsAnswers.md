# Apex.OptionsReasoningFormQuestionsAnswers

> Child table of OptionsReasoningForm storing the individual KYC question-answer pairs for each reasoning form, capturing which questions the customer changed and their reasoning.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Table |
| **Key Identifier** | ReasoningFormID + KycQuestionID (composite UNIQUE) |
| **Partition** | No |
| **Indexes** | 1 unique constraint (ReasoningFormID, KycQuestionID) |

---

## 1. Business Meaning

Apex.OptionsReasoningFormQuestionsAnswers stores the individual question-level details for each options reasoning form. When a customer changes their suitability questionnaire answers and must complete a reasoning form, each modified question gets a row here recording: which KYC question was changed (KycQuestionID), what the previous answer was (OldKycAnswerID), and what reasoning the customer provided for the change (ReasoningFormAnswerID from Dictionary.OptionsReasoningFormAnswers).

This table provides the granular audit trail required by regulators - showing exactly which suitability questions were changed and why. The reasoning form header is in OptionsReasoningForm; this table contains the per-question details.

Data is created by Apex.CreateOptionsReasoningFormQuestion (inserts both the header and question rows). Answers are saved by Apex.SaveOptionsReasoningFormAnswer. Read by Apex.GetOptionsReasoningFormQuestionsAnswers.

---

## 2. Business Logic

### 2.1 Question Change Tracking with Reasoning

**What**: Each row captures a before-state (old answer) and an after-state reasoning (why the answer changed) for one KYC question.

**Columns/Parameters Involved**: `KycQuestionID`, `OldKycAnswerID`, `ReasoningFormAnswerID`

**Rules**:
- Questions are created with OldKycAnswerID populated and ReasoningFormAnswerID=NULL
- When the customer provides their reasoning, ReasoningFormAnswerID is updated with the chosen answer (1=Other, 2=Incorrect Selection, 3=Changed Mind, 4=Lifestyle Change)
- A NULL ReasoningFormAnswerID indicates the customer hasn't yet provided reasoning for this question
- Multiple questions per form are typical (customer may change several answers at once)

---

## 3. Data Overview

| ReasoningFormID | KycQuestionID | ReasoningFormAnswerID | OldKycAnswerID | Meaning |
|----------------|---------------|----------------------|----------------|---------|
| 9F4A1E8E-... | 2 | NULL | 49 | KYC question 2 was changed. Previous answer was ID 49. Customer has not yet selected a reasoning answer for this change. |
| 9F4A1E8E-... | 10 | NULL | 0 | KYC question 10 was changed. Previous answer was 0 (none/not answered). Awaiting reasoning. |
| 9F4A1E8E-... | 11 | NULL | 0 | Same form, KYC question 11 also changed from default. Multiple questions changed in one session. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReasoningFormID | uniqueidentifier | NO | - | CODE-BACKED | FK to Apex.OptionsReasoningForm. Links this question-answer pair to its parent reasoning form. Part of the UNIQUE constraint with KycQuestionID. |
| 2 | KycQuestionID | int | NO | - | CODE-BACKED | Identifier of the KYC (Know Your Customer) suitability question that was changed. References the suitability questionnaire system (external). Part of the UNIQUE constraint with ReasoningFormID. |
| 3 | ReasoningFormAnswerID | int | YES | - | CODE-BACKED | The customer's selected reasoning for changing this question. Implicit FK to Dictionary.OptionsReasoningFormAnswers: 1=Other, 2=Incorrect Selection, 3=Changed Mind, 4=Lifestyle Change. See [Options Reasoning Form Answers](_glossary.md#options-reasoning-form-answers). NULL until the customer provides their reasoning. |
| 4 | OldKycAnswerID | int | YES | - | CODE-BACKED | The answer ID the customer previously had for this KYC question before the change. Provides the "before" state for the audit trail. A value of 0 indicates the question was not previously answered. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ReasoningFormID | Apex.OptionsReasoningForm | FK | Parent reasoning form |
| ReasoningFormAnswerID | Dictionary.OptionsReasoningFormAnswers | Implicit | Reasoning answer choice |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.CreateOptionsReasoningFormQuestion | @ReasoningFormID, @KycQuestionID | Writer | Creates question rows |
| Apex.SaveOptionsReasoningFormAnswer | @ReasoningFormID | Writer | Updates reasoning answer |
| Apex.GetOptionsReasoningFormQuestionsAnswers | @ReasoningFormID | Reader | Retrieves all questions for a form |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.OptionsReasoningFormQuestionsAnswers (table)
└── Apex.OptionsReasoningForm (table) [FK target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Apex.OptionsReasoningForm | Table | FK for ReasoningFormID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.CreateOptionsReasoningFormQuestion | Stored Procedure | Writer |
| Apex.SaveOptionsReasoningFormAnswer | Stored Procedure | Writer |
| Apex.GetOptionsReasoningFormQuestionsAnswers | Stored Procedure | Reader |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| UNIQUE_FormId_KycQuestionId | NC UNIQUE | ReasoningFormID ASC, KycQuestionID ASC | - | - | Active |

Note: This table has no clustered PK - only a unique nonclustered constraint. The table is a heap.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UNIQUE_FormId_KycQuestionId | UNIQUE | (ReasoningFormID, KycQuestionID) - one answer per question per form |
| FK_OptionsReasoningFormQuestionsAnswers_OptionsReasoningForm | FOREIGN KEY | ReasoningFormID -> Apex.OptionsReasoningForm(ReasoningFormID) |

---

## 8. Sample Queries

### 8.1 Get all questions and answers for a reasoning form

```sql
SELECT qa.ReasoningFormID, qa.KycQuestionID, qa.OldKycAnswerID,
       qa.ReasoningFormAnswerID, rfa.AnswerText AS ReasoningAnswer
FROM Apex.OptionsReasoningFormQuestionsAnswers qa WITH (NOLOCK)
LEFT JOIN Dictionary.OptionsReasoningFormAnswers rfa WITH (NOLOCK)
    ON rfa.ReasoningFormAnswerID = qa.ReasoningFormAnswerID
WHERE qa.ReasoningFormID = '9F4A1E8E-3522-467C-B17A-6F843E64747D'
ORDER BY qa.KycQuestionID;
```

### 8.2 Find questions still awaiting reasoning answers

```sql
SELECT qa.ReasoningFormID, qa.KycQuestionID, qa.OldKycAnswerID,
       f.GCID, f.DateCreated
FROM Apex.OptionsReasoningFormQuestionsAnswers qa WITH (NOLOCK)
INNER JOIN Apex.OptionsReasoningForm f WITH (NOLOCK) ON f.ReasoningFormID = qa.ReasoningFormID
WHERE qa.ReasoningFormAnswerID IS NULL
ORDER BY f.DateCreated DESC;
```

### 8.3 Count reasoning answers by type

```sql
SELECT rfa.AnswerText, COUNT(*) AS UsageCount
FROM Apex.OptionsReasoningFormQuestionsAnswers qa WITH (NOLOCK)
INNER JOIN Dictionary.OptionsReasoningFormAnswers rfa WITH (NOLOCK)
    ON rfa.ReasoningFormAnswerID = qa.ReasoningFormAnswerID
GROUP BY rfa.AnswerText
ORDER BY UsageCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.OptionsReasoningFormQuestionsAnswers | Type: Table | Source: USABroker/Apex/Tables/Apex.OptionsReasoningFormQuestionsAnswers.sql*
