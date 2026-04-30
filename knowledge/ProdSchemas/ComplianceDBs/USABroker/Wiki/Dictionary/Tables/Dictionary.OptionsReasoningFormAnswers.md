# Dictionary.OptionsReasoningFormAnswers

**Schema:** Dictionary
**Table:** OptionsReasoningFormAnswers
**Database:** USABroker
**Last Reviewed:** 2026-04-14

---

## 1. Business Meaning

`Dictionary.OptionsReasoningFormAnswers` is a static reference table that enumerates the selectable answers on the Options Reasoning Form — the questionnaire presented to a user when they request to downgrade or cancel their options trading access. Regulatory best-practice requires the platform to capture the user's stated reason for stepping back from a higher-risk product, so that the decision is informed rather than impulsive.

The form presents a short list of mutually exclusive options explaining why the user no longer wants options trading enabled. Each answer has a display string (`AnswerText`) and an i18n translation key (`TranslationKey`) used by the front-end to render the answer in the user's locale. The selected answer is stored in `Apex.OptionsReasoningFormQuestionsAnswers` via an implicit FK on `ReasoningFormAnswerID`.

The four answers cover the practical range of reasons: a free-text catch-all (`Other`), a correction of a prior mistake (`Incorrect Selection`), a genuine change of preference (`Changed Mind`), and a life-event driver (`Lifestyle Change`).

---

## 2. Table Elements

| Column | Data Type | Nullable | PK | Description |
|---|---|---|---|---|
| ReasoningFormAnswerID | int | NOT NULL | Yes | Stable numeric identifier for the selectable answer. |
| AnswerText | nvarchar(50) | NOT NULL | No | English display text shown to the user on the reasoning form. |
| TranslationKey | nvarchar(50) | NULL | No | i18n key used by the front-end localisation system to retrieve the translated answer text; NULL if no translation is configured. |

**Constraints:**
- `PK_Dictionary.OptionsReasoningFormAnswers` — clustered primary key on `ReasoningFormAnswerID`

---

## 3. Data Overview

4 rows as of 2026-04-14.

| ReasoningFormAnswerID | AnswerText | TranslationKey | Meaning |
|---|---|---|---|
| 1 | Other | optionsReasoning.option1 | A free-text catch-all for reasons not covered by the other options; the user provides additional context in an accompanying text field. |
| 2 | Incorrect Selection | optionsReasoning.option2 | The user previously enrolled in options by mistake and wishes to correct that selection without any underlying change in circumstances. |
| 3 | Changed Mind | optionsReasoning.option3 | The user has reconsidered their interest in options trading and voluntarily chooses to relinquish options access. |
| 4 | Lifestyle Change | optionsReasoning.option4 | A change in the user's personal circumstances (e.g., retirement, reduced income, change in risk tolerance) motivates the request to opt out of options. |

---

## 4. Relationships

### Referenced by (Foreign Keys into this table)

| Referencing Table | Referencing Column | Notes |
|---|---|---|
| Apex.OptionsReasoningFormQuestionsAnswers | ReasoningFormAnswerID | Implicit reference — stores the answer selected by the user when completing the options reasoning form. |

### References to other tables

This table has no foreign key dependencies; it is a terminal reference (lookup-only) table.

---

## 5. Common Query Patterns

```sql
-- Count how frequently each reasoning form answer is selected
SELECT a.AnswerText,
       COUNT(*) AS SelectionCount
FROM   Apex.OptionsReasoningFormQuestionsAnswers qa WITH (NOLOCK)
JOIN   Dictionary.OptionsReasoningFormAnswers a WITH (NOLOCK)
       ON qa.ReasoningFormAnswerID = a.ReasoningFormAnswerID
GROUP  BY a.AnswerText
ORDER  BY SelectionCount DESC;
```

```sql
-- Find all users who cited a lifestyle change as their reason
SELECT qa.*
FROM   Apex.OptionsReasoningFormQuestionsAnswers qa WITH (NOLOCK)
WHERE  qa.ReasoningFormAnswerID = 4; -- Lifestyle Change
```

---

## 6. Data Quality Notes

- `TranslationKey` is nullable; if a new answer row is added without a translation key the front-end will fall back to `AnswerText`.
- `AnswerText` uses `nvarchar` (Unicode), supporting future internationalisation of the default text.
- The table name ends in `Answers` (plural) while the PK column is `ReasoningFormAnswerID` (singular) — this is an existing naming inconsistency.
- The primary key constraint name contains a dot (`PK_Dictionary.OptionsReasoningFormAnswers`) which is unusual; this should be noted if the constraint is ever rebuilt.
- The set of four answers should be reviewed periodically alongside UX research to ensure the options cover the actual distribution of user reasons.

---

## 7. Change History

| Date | Change |
|---|---|
| 2026-04-14 | Initial documentation created; 4 rows verified against live data. |

---

## 8. Related Objects

| Object | Type | Relationship |
|---|---|---|
| Apex.OptionsReasoningFormQuestionsAnswers | Table | Stores each user's selected answer(s) from this dictionary when completing the reasoning form. |
| Dictionary.OptionsStatus | Table | The options status of the user is typically updated following submission of the reasoning form. |
| Dictionary.ReasoningStatus | Table | Tracks the state of the reasoning form workflow for the user. |

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Documentation generated 2026-04-14 — USABroker · Dictionary schema*
