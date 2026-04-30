# Apex.CreateOptionsReasoningFormQuestion

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.CreateOptionsReasoningFormQuestion.sql`  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.CreateOptionsReasoningFormQuestion` initialises a reasoning-form instance and registers a question within it — idempotently. When the options reasoning workflow begins for a customer, the service calls this procedure once per question to:
1. Create the form header row (`OptionsReasoningForm`) if it does not already exist for the given `ReasoningFormID` + `GCID`.
2. Create the question-answer slot (`OptionsReasoningFormQuestionsAnswers`) if it does not already exist for the given `ReasoningFormID` + `KycQuestionID`.

The idempotency (IF NOT EXISTS checks before each INSERT) means the procedure can be called multiple times safely — re-processing the same event or retrying a failed call will not create duplicate rows.

---

## 2. Parameters

| Parameter | Type | Nullable | Default | Description |
|-----------|------|----------|---------|-------------|
| `@GCID` | `int` | No | — | Global Customer ID of the customer for whom the form is being created. |
| `@ReasoningFormID` | `uniqueidentifier` | No | — | GUID that uniquely identifies this reasoning form instance. |
| `@KycQuestionID` | `int` | No | — | ID of the KYC question to register on the form. |
| `@OldKycAnswerID` | `int` | No | — | The customer's previous answer to this question (pre-populated context). |
| `@PreviousAppropriatenessTestDate` | `datetime` | Yes | `NULL` | Date of the appropriateness test preceding this reasoning form; written only on header creation. |

---

## 3. Result Sets

None. Write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `OptionsReasoningForm` | `Apex` | SELECT (NOLOCK EXISTS) + INSERT | Form header; created once per `ReasoningFormID` + `GCID`. |
| `OptionsReasoningFormQuestionsAnswers` | `Apex` | SELECT (NOLOCK EXISTS) + INSERT | Question slot; created once per `ReasoningFormID` + `KycQuestionID`. |

---

## 5. Logic Flow

1. **Form header check:**
   - `IF NOT EXISTS (SELECT 1 FROM Apex.OptionsReasoningForm WITH (NOLOCK) WHERE ReasoningFormID = @ReasoningFormID AND GCID = @GCID)`:
     - INSERT header row: `ReasoningFormID`, `GCID`, `DateCreated = GETUTCDATE()`, `DateSubmitted = NULL`, `PreviousAppropriatenessTestDate`.

2. **Question slot check:**
   - `IF NOT EXISTS (SELECT 1 FROM Apex.OptionsReasoningFormQuestionsAnswers WITH (NOLOCK) WHERE ReasoningFormID = @ReasoningFormID AND KycQuestionID = @KycQuestionID)`:
     - INSERT question row: `ReasoningFormID`, `KycQuestionID`, `OldKycAnswerID`. `ReasoningFormAnswerID` is left NULL (not yet answered).

Both checks are independent — creating the header does not depend on the question row status, and vice versa.

---

## 6. Error Handling

No explicit error handling. The IF NOT EXISTS pattern provides idempotency but has a theoretical TOCTOU race under very high concurrency for the same form/question combination. In practice this is safe because form creation is a low-frequency operation per GCID.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.OptionsReasoningForm` | Table | Form header — INSERT target |
| `Apex.OptionsReasoningFormQuestionsAnswers` | Table | Question-answer slots — INSERT target |
| `Apex.SaveOptionsReasoningFormAnswer` | Stored Procedure | Must be called after this to populate `ReasoningFormAnswerID` |
| `Apex.GetOptionsReasoningFormQuestionsAnswers` | Stored Procedure | Reads the rows created here |
| `Apex.SaveOptionsReasoningStatus` | Stored Procedure | Links the `ReasoningFormID` created here to the customer's `Options` record |

---

## 8. Usage Notes

- The standard call sequence is: (1) `CreateOptionsReasoningFormQuestion` — once per question, (2) `SaveOptionsReasoningStatus` — to link the form to the `Options` record, (3) `SaveOptionsReasoningFormAnswer` — once per submitted answer.
- The `DateCreated` is set to `GETUTCDATE()` on first creation; subsequent calls for the same form are no-ops for the header and do not update `DateCreated`.
- `@PreviousAppropriatenessTestDate` is only written when the header is first created. If the header already exists, this parameter is ignored — it cannot be updated via this procedure.
- `ReasoningFormAnswerID` is left NULL in the question row at creation time; it is populated by `Apex.SaveOptionsReasoningFormAnswer` when the customer answers the question.
- Calling this procedure for a question that already exists on the form (same `ReasoningFormID` + `KycQuestionID`) is a no-op — existing answers are not disturbed.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.CreateOptionsReasoningFormQuestion.sql` | Quality Score: 8.5/10*
