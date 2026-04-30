# Dictionary.EligibilityStatus

**Schema:** Dictionary
**Table:** EligibilityStatus
**Database:** USABroker
**Last Reviewed:** 2026-04-14

---

## 1. Business Meaning

`Dictionary.EligibilityStatus` is a static reference table that represents the binary eligibility gate controlling whether a user is permitted to proceed with a particular product, feature, or account action. It is intentionally minimal — just two values — reflecting the fact that eligibility at this level is an all-or-nothing decision: either the user satisfies all conditions and is `Allowed`, or they do not and are `Disallowed`.

The `Disallowed` state (ID 0) may result from failing an appropriateness test, not meeting residency requirements, being flagged by compliance controls, or having an incomplete verification status. The `Allowed` state (ID 1) indicates that all prerequisite checks have passed and the user may proceed.

`Apex.Options` stores this value as `EligibilityStatusID`, meaning the eligibility determination for options trading is captured per user and auditable through this dictionary.

---

## 2. Table Elements

| Column | Data Type | Nullable | PK | Description |
|---|---|---|---|---|
| EligibilityStatusID | int | NOT NULL | Yes | Numeric identifier; 0 = Disallowed, 1 = Allowed. |
| Name | nvarchar(50) | NOT NULL | No | Human-readable label for the eligibility gate outcome. |

**Constraints:**
- `PK_EligibilityStatus` — clustered primary key on `EligibilityStatusID`

---

## 3. Data Overview

2 rows as of 2026-04-14.

| EligibilityStatusID | Name | Meaning |
|---|---|---|
| 0 | Disallowed | The user does not meet the eligibility criteria for the product or feature; access is blocked. This is also the default/uninitialised state. |
| 1 | Allowed | All eligibility prerequisites have been satisfied; the user is permitted to access the product or feature. |

---

## 4. Relationships

### Referenced by (Foreign Keys into this table)

| Referencing Table | Referencing Column | Notes |
|---|---|---|
| Apex.Options | EligibilityStatusID | Stores the eligibility determination for a user's options trading access. |

### References to other tables

This table has no foreign key dependencies; it is a terminal reference (lookup-only) table.

---

## 5. Common Query Patterns

```sql
-- Count users by options eligibility status
SELECT es.Name AS EligibilityStatus,
       COUNT(*) AS UserCount
FROM   Apex.Options o WITH (NOLOCK)
JOIN   Dictionary.EligibilityStatus es WITH (NOLOCK)
       ON o.EligibilityStatusID = es.EligibilityStatusID
GROUP  BY es.Name;
```

```sql
-- Find all users currently disallowed from options trading
SELECT o.*
FROM   Apex.Options o WITH (NOLOCK)
WHERE  o.EligibilityStatusID = 0; -- Disallowed
```

---

## 6. Data Quality Notes

- With only two values, this table is effectively a boolean encoded as an integer FK; using a lookup table preserves consistency with the wider dictionary pattern and allows a future intermediate state (e.g., "PendingReview") to be added without schema changes.
- ID 0 (`Disallowed`) doubles as the uninitialised/default state; application code should not infer any specific reason from this value alone — cross-reference `AppropriatenessTestResult` and `OptionsStatus` for context.
- `nvarchar(50)` is used here (unlike most other tables that use `varchar`); this is a minor inconsistency but has no functional impact since both values are ASCII.

---

## 7. Change History

| Date | Change |
|---|---|
| 2026-04-14 | Initial documentation created; 2 rows verified against live data. |

---

## 8. Related Objects

| Object | Type | Relationship |
|---|---|---|
| Apex.Options | Table | Stores the eligibility determination per user for options trading. |
| Dictionary.AppropriatenessTestResult | Table | The appropriateness test result is a key input into the eligibility decision. |
| Dictionary.OptionsStatus | Table | The overall options application status complements the eligibility status. |
| Dictionary.OptionsStatusControl | Table | Controls whether the options eligibility gate can be overridden. |

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Documentation generated 2026-04-14 — USABroker · Dictionary schema*
