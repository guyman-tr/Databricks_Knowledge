# Dictionary.ReasoningStatus

**Schema:** Dictionary
**Table:** ReasoningStatus
**Database:** USABroker
**Last Reviewed:** 2026-04-14

---

## 1. Business Meaning

`Dictionary.ReasoningStatus` is a static reference table that tracks the workflow state of the Options Reasoning Form process — the journey a user goes through when they request to downgrade or opt out of options trading access. When an options-enabled user wishes to reduce their trading permissions, the platform presents a reasoning questionnaire to capture a documented rationale before processing the downgrade.

The five statuses reflect the stages of that workflow. `None` is the baseline for users who are not in a reasoning workflow. `PendingReasoningScreen` means the user has been prompted but not yet completed the form. `PendingManualReview` means the completed form has been escalated for a human compliance reviewer to assess. `Allowed` means the reasoning process is complete and the downgrade may proceed. `DisallowedByManualReview` means a compliance reviewer determined the downgrade cannot proceed at this time.

`Apex.Options` stores the `ReasoningStatusID` as an implicit reference, providing a complete picture of where each user stands in the options downgrade workflow.

---

## 2. Table Elements

| Column | Data Type | Nullable | PK | Description |
|---|---|---|---|---|
| ReasoningStatusID | int | NOT NULL | Yes | Numeric identifier for the reasoning workflow stage; 0 is the sentinel for not in workflow. |
| ReasoningStatusText | nvarchar(50) | NOT NULL | No | Descriptive label for the workflow stage; note the non-standard column name (not `Name`) reflecting the text-centric nature of the status. |

**Constraints:**
- `PK_Dictionary.ReasoningStatus` — clustered primary key on `ReasoningStatusID`

---

## 3. Data Overview

5 rows as of 2026-04-14.

| ReasoningStatusID | ReasoningStatusText | Meaning |
|---|---|---|
| 0 | None | The user is not in a reasoning workflow; no options downgrade has been requested or the workflow has never been initiated. |
| 1 | PendingReasoningScreen | The platform has prompted the user to complete the Options Reasoning Form, but the user has not yet submitted their answers. |
| 2 | PendingManualReview | The user has submitted the reasoning form; a compliance reviewer must assess the submission before the downgrade can proceed. |
| 3 | Allowed | The reasoning workflow is complete and the result is favourable; the options downgrade is approved to proceed. |
| 4 | DisallowedByManualReview | A compliance reviewer assessed the reasoning form submission and determined that the options downgrade should not proceed at this time. |

---

## 4. Relationships

### Referenced by (Foreign Keys into this table)

| Referencing Table | Referencing Column | Notes |
|---|---|---|
| Apex.Options | ReasoningStatusID | Implicit reference — stores the current reasoning workflow stage alongside the user's options status. |

### References to other tables

This table has no foreign key dependencies; it is a terminal reference (lookup-only) table.

---

## 5. Common Query Patterns

```sql
-- Count users by reasoning workflow stage
SELECT rs.ReasoningStatusText AS Stage,
       COUNT(*) AS UserCount
FROM   Apex.Options o WITH (NOLOCK)
JOIN   Dictionary.ReasoningStatus rs WITH (NOLOCK)
       ON o.ReasoningStatusID = rs.ReasoningStatusID
GROUP  BY rs.ReasoningStatusText, rs.ReasoningStatusID
ORDER  BY rs.ReasoningStatusID;
```

```sql
-- Find users stuck on the reasoning screen for more than 7 days
SELECT o.*
FROM   Apex.Options o WITH (NOLOCK)
WHERE  o.ReasoningStatusID = 1  -- PendingReasoningScreen
  AND  o.UpdatedAt < DATEADD(DAY, -7, GETUTCDATE());
```

---

## 6. Data Quality Notes

- The column name `ReasoningStatusText` deviates from the `Name` convention used in most other Dictionary tables; this must be accounted for in any generic dictionary-query tooling.
- The primary key constraint name contains a dot (`PK_Dictionary.ReasoningStatus`) — an unusual pattern that should be noted if the constraint is ever rebuilt.
- `nvarchar(50)` is appropriate given the text content; all current values are ASCII-safe.
- `DisallowedByManualReview` (ID 4) implies the user remains in an `Approved` options status; the platform must handle this state combination carefully to avoid inconsistent access decisions.
- ID 0 (`None`) is the default and the sentinel; it is distinct from the completed state (`Allowed`, ID 3).

---

## 7. Change History

| Date | Change |
|---|---|
| 2026-04-14 | Initial documentation created; 5 rows verified against live data. |

---

## 8. Related Objects

| Object | Type | Relationship |
|---|---|---|
| Apex.Options | Table | Stores the current reasoning workflow status alongside the options application status per user. |
| Dictionary.OptionsReasoningFormAnswers | Table | The answers that populate the reasoning form whose submission advances the reasoning workflow. |
| Dictionary.OptionsStatus | Table | The options application status that the reasoning workflow may result in changing. |
| Dictionary.OptionsStatusControl | Table | The administrative control that may be updated as a result of the reasoning workflow outcome. |

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Documentation generated 2026-04-14 — USABroker · Dictionary schema*
