# Apex.GetAllPossibleOptionsReasoningFormAnswers

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetAllPossibleOptionsReasoningFormAnswers.sql`  
**Author:** Oleksandr Litvinov  
**Created:** 2024-02-21  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.GetAllPossibleOptionsReasoningFormAnswers` retrieves the complete catalogue of valid answer choices for the options-reasoning form. When a customer completes a reasoning form to justify their options-trading request, each question presents a set of pre-defined answer options. This procedure returns that answer dictionary — the full set of answer IDs, their display text, and their i18n translation keys.

It is called by form-rendering services to populate answer dropdowns, by validation services to confirm submitted `ReasoningFormAnswerID` values are valid, and by reporting tools to decode stored answer IDs into human-readable text.

---

## 2. Parameters

None. Returns the full answer dictionary.

---

## 3. Result Sets

**Result Set 1 – All Possible Reasoning Form Answers**

| Column | Source Table | Alias | Description |
|--------|-------------|-------|-------------|
| `ReasoningFormAnswerID` | `Dictionary.OptionsReasoningFormAnswers` | `ReasonId` | Surrogate ID for the answer option; stored in `OptionsReasoningFormQuestionsAnswers.ReasoningFormAnswerID`. |
| `AnswerText` | `Dictionary.OptionsReasoningFormAnswers` | — | English display text of the answer option. |
| `TranslationKey` | `Dictionary.OptionsReasoningFormAnswers` | — | Internationalisation key for multi-language rendering. |

Returns all rows in the dictionary table (no filtering).

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `OptionsReasoningFormAnswers` | `Dictionary` | SELECT | Cross-schema read from the `Dictionary` schema. No locking hints. |

---

## 5. Logic Flow

1. Simple `SELECT` from `Dictionary.OptionsReasoningFormAnswers`.
2. Aliases `ReasoningFormAnswerID` as `ReasonId` for the result set.
3. Returns all rows with no filter.

Reference-data read; minimal logic.

---

## 6. Error Handling

No explicit error handling. Returns empty if the dictionary table has no rows (configuration error).

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Dictionary.OptionsReasoningFormAnswers` | Table | Only data source; note the cross-schema `Dictionary` reference |
| `Apex.GetOptionsReasoningFormQuestionsAnswers` | Stored Procedure | Uses `ReasoningFormAnswerID` values from this dictionary |
| `Apex.SaveOptionsReasoningFormAnswer` | Stored Procedure | Validates submitted answers against this catalogue |
| `Apex.CreateOptionsReasoningFormQuestion` | Stored Procedure | Creates question rows that reference answers from this catalogue |

---

## 8. Usage Notes

- The column alias `ReasonId` (rather than `ReasoningFormAnswerID`) is intentional — it is a shorter, consumer-friendly name for serialisation in API responses.
- `TranslationKey` enables the front-end to display localised answer text without a separate API call for each language.
- This is a read-only reference table; the data is maintained by the dictionary/configuration team, not by application logic.
- The result set is static enough to be cached in the application layer. Invalidate the cache on deployment when dictionary values are updated.
- Cross-schema access (`Dictionary.OptionsReasoningFormAnswers`) means this procedure depends on the `Dictionary` schema being present in the same database.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetAllPossibleOptionsReasoningFormAnswers.sql` | Quality Score: 8.5/10*
