# Apex.GetOptionsReasoningFormQuestionsAnswers

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetOptionsReasoningFormQuestionsAnswers.sql`  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.GetOptionsReasoningFormQuestionsAnswers` retrieves the question-and-answer content of a submitted options-reasoning form for a specific customer. When a customer's appropriateness test result requires justification (e.g., they failed but are appealing, or their previous answers need review), a reasoning form is presented containing KYC questions with pre-populated previous answers. This procedure returns the current state of those questions and answers for a given form instance.

It is used by compliance review dashboards, form-submission processors, and audit services to inspect what questions were asked, what the customer previously answered (`OldKycAnswerID`), what new answer was submitted (`ReasoningFormAnswerID`), and when the form was created.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID of the customer who submitted the reasoning form. |
| `@ReasoningFormID` | `uniqueidentifier` | No | The GUID of the specific reasoning form instance to retrieve. |

---

## 3. Result Sets

**Result Set 1 – Question/Answer Rows for the Form**

| Column | Source Table | Alias | Description |
|--------|-------------|-------|-------------|
| `KycQuestionID` | `Apex.OptionsReasoningFormQuestionsAnswers` | — | ID of the KYC question presented on the form. |
| `ReasoningFormAnswerID` | `Apex.OptionsReasoningFormQuestionsAnswers` | — | ID of the answer selected by the customer. NULL if not yet answered. |
| `OldKycAnswerID` | `Apex.OptionsReasoningFormQuestionsAnswers` | — | ID of the customer's previous answer to this question, pre-populated for context. |
| `PreviousAppropriatenessTestDate` | `Apex.OptionsReasoningForm` | — | Date of the appropriateness test that preceded this reasoning form. |
| `DateCreated` | `Apex.OptionsReasoningForm` | `FormCreatedDate` | UTC timestamp when the reasoning form header was created. |

Returns 0 rows if the `ReasoningFormID` does not match a form for the given GCID.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `OptionsReasoningForm` | `Apex` | SELECT | Form header; filtered by `ReasoningFormID` and `GCID`. |
| `OptionsReasoningFormQuestionsAnswers` | `Apex` | SELECT | JOIN on `ReasoningFormID`; one row per question. |

---

## 5. Logic Flow

1. Joins `Apex.OptionsReasoningForm` (header, `f`) to `Apex.OptionsReasoningFormQuestionsAnswers` (line items, `fa`) on `fa.ReasoningFormID = f.ReasoningFormID`.
2. Filters by `f.ReasoningFormID = @ReasoningFormID AND f.GCID = @GCID`.
3. Returns per-question columns plus the form header dates.

Multiple rows are returned — one per question on the reasoning form.

---

## 6. Error Handling

No explicit error handling. Returns empty if the form/GCID combination is not found.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.OptionsReasoningForm` | Table | Header table (form metadata) |
| `Apex.OptionsReasoningFormQuestionsAnswers` | Table | Detail table (per-question answers) |
| `Apex.CreateOptionsReasoningFormQuestion` | Stored Procedure | Creates the header and question rows read here |
| `Apex.SaveOptionsReasoningFormAnswer` | Stored Procedure | Writes the answer (`ReasoningFormAnswerID`) read here |
| `Apex.GetAllPossibleOptionsReasoningFormAnswers` | Stored Procedure | Returns the answer lookup dictionary |

---

## 8. Usage Notes

- `ReasoningFormAnswerID` will be NULL for any question not yet answered; front-end form renderers should treat NULL as "unanswered."
- `OldKycAnswerID` is the answer recorded during the customer's original appropriateness test; it is presented alongside the new question to provide context.
- The double filter on both `ReasoningFormID` and `GCID` prevents cross-customer data leakage in the event of a GUID collision (extremely unlikely but correct to guard against).
- Use `Apex.GetAllPossibleOptionsReasoningFormAnswers` to resolve `ReasoningFormAnswerID` and `OldKycAnswerID` to human-readable answer text.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetOptionsReasoningFormQuestionsAnswers.sql` | Quality Score: 8.5/10*
