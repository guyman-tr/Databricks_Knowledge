# Dictionary.AppropriatenessRecalculationReason

**Schema:** Dictionary
**Table:** AppropriatenessRecalculationReason
**Database:** USABroker
**Last Reviewed:** 2026-04-14

---

## 1. Business Meaning

`Dictionary.AppropriatenessRecalculationReason` is a static reference table that captures the reason why a user's appropriateness assessment was re-evaluated after an initial result had already been recorded. Appropriateness scores are not always permanent: regulatory changes, user-initiated answer updates, reaching a new verification tier, or scheduled bulk recalculations can all invalidate a prior result and trigger re-evaluation.

Storing the trigger reason alongside the recalculated result enables the compliance team to distinguish between system-driven recalculations (e.g., a regulatory rule change applied to the entire user base) and user-driven ones (e.g., a customer updating their trading-experience answers), which have different audit and reporting implications.

The `None` sentinel (ID 0) covers records created before reason tracking was introduced, or cases where the reason is not applicable.

---

## 2. Table Elements

| Column | Data Type | Nullable | PK | Description |
|---|---|---|---|---|
| AppropriatenessRecalculationReasonID | int | NOT NULL | Yes | Numeric identifier for the recalculation trigger; 0 is the conventional null/not-applicable sentinel. |
| Name | varchar(50) | NOT NULL | No | Short camelCase label identifying the business trigger that caused the recalculation. |

**Constraints:**
- `PK_AppropriatenessRecalculationReason` — clustered primary key on `AppropriatenessRecalculationReasonID`

---

## 3. Data Overview

6 rows as of 2026-04-14.

| AppropriatenessRecalculationReasonID | Name | Meaning |
|---|---|---|
| 0 | None | No recalculation reason recorded; used as the default sentinel, typically for records pre-dating reason tracking. |
| 1 | BulkRecalculation | A system-initiated batch job re-evaluated appropriateness for a large cohort of users simultaneously (e.g., after a scoring model update). |
| 2 | RegulationChanged | A change in applicable regulations required the platform to re-assess users whose prior results may no longer satisfy the new rules. |
| 3 | ReachedVerificationLevel2 | The user completed a higher tier of identity verification, unlocking additional profile data that is factored into the appropriateness algorithm. |
| 4 | AnswerChanged | The user updated one or more answers on the appropriateness questionnaire, invalidating the previously stored result. |
| 5 | Manual | A compliance officer or support agent manually triggered a recalculation outside of any automated flow. |

---

## 4. Relationships

### Referenced by (Foreign Keys into this table)

| Referencing Table | Referencing Column | Notes |
|---|---|---|
| Apex.Options | AppropriatenessRecalculationReasonID | Implicit reference — the `Options` record stores the reason code when a recalculation event is logged against a user's options profile. |

### References to other tables

This table has no foreign key dependencies; it is a terminal reference (lookup-only) table.

---

## 5. Common Query Patterns

```sql
-- Summarise how many appropriateness recalculations occurred per reason
SELECT r.Name AS RecalculationReason,
       COUNT(*) AS EventCount
FROM   Apex.Options o WITH (NOLOCK)
JOIN   Dictionary.AppropriatenessRecalculationReason r WITH (NOLOCK)
       ON o.AppropriatenessRecalculationReasonID = r.AppropriatenessRecalculationReasonID
WHERE  r.AppropriatenessRecalculationReasonID <> 0
GROUP  BY r.Name
ORDER  BY EventCount DESC;
```

```sql
-- Find all manual recalculations in the last 30 days
SELECT o.*
FROM   Apex.Options o WITH (NOLOCK)
WHERE  o.AppropriatenessRecalculationReasonID = 5;
```

---

## 6. Data Quality Notes

- ID 0 (`None`) is used as a sentinel rather than NULL, preserving referential integrity.
- The set of reasons is intentionally narrow; new automated triggers (e.g., a new verification tier) require adding a row here and updating the recalculation engine.
- `Name` is `varchar(50)` (non-Unicode); all existing values are ASCII-safe.
- There is no timestamp or `IsActive` flag; historical reasons should never be deleted to preserve audit trail integrity.

---

## 7. Change History

| Date | Change |
|---|---|
| 2026-04-14 | Initial documentation created; 6 rows verified against live data. |

---

## 8. Related Objects

| Object | Type | Relationship |
|---|---|---|
| Apex.Options | Table | Stores the recalculation reason alongside the updated appropriateness result. |
| Dictionary.AppropriatenessTestResult | Table | Sibling dictionary: records the outcome (pass/fail) of each appropriateness test. |
| Dictionary.AppropriatenessProduct | Table | Sibling dictionary: identifies which product the appropriateness assessment relates to. |

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Documentation generated 2026-04-14 — USABroker · Dictionary schema*
