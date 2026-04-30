# Dictionary.AppropriatenessTestResult

**Schema:** Dictionary
**Table:** AppropriatenessTestResult
**Database:** USABroker
**Last Reviewed:** 2026-04-14

---

## 1. Business Meaning

`Dictionary.AppropriatenessTestResult` is a static reference table that encodes the three possible outcomes of a user's appropriateness assessment: not yet evaluated (`None`), assessment failed (`Failed`), and assessment passed (`Passed`). This binary pass/fail outcome — with a sentinel for the uninitialised state — drives downstream access-control decisions across the platform.

A `Passed` result allows the user to proceed with trading the assessed product type (e.g., Options, CFDs, FPSL). A `Failed` result triggers a restriction or an offer to proceed with a risk acknowledgement, depending on the product and jurisdiction. The `None` state indicates the assessment has not yet been run for that product.

The table is referenced by `Apex.Options`, which stores the current appropriateness test result for each user/product combination as part of the options eligibility workflow.

---

## 2. Table Elements

| Column | Data Type | Nullable | PK | Description |
|---|---|---|---|---|
| AppropriatenessTestResultID | int | NOT NULL | Yes | Numeric identifier for the assessment outcome; 0 is the conventional null/not-applicable sentinel. |
| Name | varchar(50) | NOT NULL | No | Short label representing the assessment verdict stored in referencing tables. |

**Constraints:**
- `PK_AppropriatenessTestResult` — clustered primary key on `AppropriatenessTestResultID`

---

## 3. Data Overview

3 rows as of 2026-04-14.

| AppropriatenessTestResultID | Name | Meaning |
|---|---|---|
| 0 | None | The appropriateness test has not yet been executed for this user/product combination; the outcome is unknown or not applicable. |
| 1 | Failed | The user did not demonstrate sufficient knowledge or experience for the assessed product type; access may be restricted or require additional acknowledgement. |
| 2 | Passed | The user demonstrated adequate knowledge and experience; they are eligible to trade the assessed product type without additional restrictions. |

---

## 4. Relationships

### Referenced by (Foreign Keys into this table)

| Referencing Table | Referencing Column | Notes |
|---|---|---|
| Apex.Options | AppropriatenessTestResultID | Stores the current appropriateness verdict for a user's options application. |

### References to other tables

This table has no foreign key dependencies; it is a terminal reference (lookup-only) table.

---

## 5. Common Query Patterns

```sql
-- Count users by current appropriateness test result
SELECT r.Name AS TestResult,
       COUNT(*) AS UserCount
FROM   Apex.Options o WITH (NOLOCK)
JOIN   Dictionary.AppropriatenessTestResult r WITH (NOLOCK)
       ON o.AppropriatenessTestResultID = r.AppropriatenessTestResultID
GROUP  BY r.Name
ORDER  BY UserCount DESC;
```

```sql
-- Retrieve all users who have failed the appropriateness test
SELECT o.*
FROM   Apex.Options o WITH (NOLOCK)
WHERE  o.AppropriatenessTestResultID = 1; -- Failed
```

---

## 6. Data Quality Notes

- Only three values exist and the set is not expected to grow; any new outcome categories would require application-level changes beyond simply adding a row.
- ID 0 (`None`) is a sentinel to avoid NULLable foreign keys; application code must treat it as "not evaluated" rather than "failed."
- The `Failed` / `Passed` distinction must align precisely with the scoring thresholds defined in the appropriateness questionnaire configuration.
- `Name` is `varchar(50)` (non-Unicode); all values are ASCII-safe.

---

## 7. Change History

| Date | Change |
|---|---|
| 2026-04-14 | Initial documentation created; 3 rows verified against live data. |

---

## 8. Related Objects

| Object | Type | Relationship |
|---|---|---|
| Apex.Options | Table | Stores the appropriateness test result per user as part of the options eligibility record. |
| Dictionary.AppropriatenessProduct | Table | Sibling dictionary: identifies which product the test result applies to. |
| Dictionary.AppropriatenessRecalculationReason | Table | Sibling dictionary: records why a previously stored result was recalculated. |
| Dictionary.EligibilityStatus | Table | Related concept: the broader eligibility status that may be driven in part by the appropriateness result. |

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Documentation generated 2026-04-14 — USABroker · Dictionary schema*
