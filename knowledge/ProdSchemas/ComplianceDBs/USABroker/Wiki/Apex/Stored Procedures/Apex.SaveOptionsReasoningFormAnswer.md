# Apex.SaveOptionsReasoningFormAnswer

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveOptionsReasoningFormAnswer.sql`  
**Author:** Oleksandr Litvinov  
**Created:** 2024-02-14  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveOptionsReasoningFormAnswer` records a customer's answer to a single question on an options-reasoning form. When a customer submits answers to justify their options access, this procedure is called once per question to persist the chosen answer. It also records the submission timestamp on the form header (only if the date has not yet been set or differs from the current submission).

This is the write path for the reasoning-form answer submission flow, called by the form-submission service when the customer saves their responses — either incrementally (one answer at a time) or on final submit.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID of the customer submitting the answer. |
| `@ReasoningFormID` | `uniqueidentifier` | No | GUID of the reasoning form instance being answered. |
| `@KycQuestionID` | `int` | No | ID of the question being answered. |
| `@ReasoningFormAnswerID` | `int` | No | ID of the answer selected by the customer (from the answers dictionary). |
| `@DateSubmitted` | `datetime` | No | UTC timestamp of the submission. |

---

## 3. Result Sets

None. Write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `OptionsReasoningForm` | `Apex` | UPDATE | Updates `DateSubmitted` on the header; conditional to avoid unnecessary writes. |
| `OptionsReasoningFormQuestionsAnswers` | `Apex` | UPDATE | Sets `ReasoningFormAnswerID` for the specified question. |

---

## 5. Logic Flow

1. **Update form header:** `UPDATE Apex.OptionsReasoningForm SET DateSubmitted = @DateSubmitted WHERE ReasoningFormID = @ReasoningFormID AND GCID = @GCID AND (DateSubmitted IS NULL OR DateSubmitted != @DateSubmitted)`. The condition prevents a write if `DateSubmitted` is already set to the same value.
2. **Update question answer:** `UPDATE Apex.OptionsReasoningFormQuestionsAnswers SET ReasoningFormAnswerID = @ReasoningFormAnswerID WHERE ReasoningFormID = @ReasoningFormID AND KycQuestionID = @KycQuestionID`. This always writes (no change-detection on the answer).

Both are simple UPDATEs — no INSERT logic. The question row must already exist (created by `Apex.CreateOptionsReasoningFormQuestion`).

---

## 6. Error Handling

No explicit error handling. If the question row does not exist, the second UPDATE silently affects 0 rows (no error raised). Callers should verify success by checking `@@ROWCOUNT` or by re-reading with `GetOptionsReasoningFormQuestionsAnswers`.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.OptionsReasoningForm` | Table | Form header (DateSubmitted written here) |
| `Apex.OptionsReasoningFormQuestionsAnswers` | Table | Answer store (ReasoningFormAnswerID written here) |
| `Apex.CreateOptionsReasoningFormQuestion` | Stored Procedure | Must be called first to create the header + question rows |
| `Apex.GetOptionsReasoningFormQuestionsAnswers` | Stored Procedure | Reads the answer written here |
| `Apex.GetAllPossibleOptionsReasoningFormAnswers` | Stored Procedure | Dictionary for valid `ReasoningFormAnswerID` values |

---

## 8. Usage Notes

- This procedure **updates** existing rows only; it does not insert. The question row must be pre-created by `Apex.CreateOptionsReasoningFormQuestion` before answers can be saved.
- If the question row does not exist (e.g., `CreateOptionsReasoningFormQuestion` was not called), the answer UPDATE silently fails with 0 rows affected. Implement answer-save verification in the caller if this is a concern.
- `@DateSubmitted` on the form header is set once per submission session. If the customer saves multiple answers in the same session, only the first or a changed timestamp causes a write to `OptionsReasoningForm`.
- `@GCID` is used to scope the form header update but is not used to filter the question/answer update (which uses only `ReasoningFormID + KycQuestionID`). This means the form header has a GCID guard but the answer row does not.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveOptionsReasoningFormAnswer.sql` | Quality Score: 8.5/10*
