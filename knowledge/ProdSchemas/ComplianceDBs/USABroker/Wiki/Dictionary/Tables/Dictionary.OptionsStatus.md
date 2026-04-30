# Dictionary.OptionsStatus

**Schema:** Dictionary
**Table:** OptionsStatus
**Database:** USABroker
**Last Reviewed:** 2026-04-14

---

## 1. Business Meaning

`Dictionary.OptionsStatus` is a static reference table that tracks the lifecycle stage of a user's options trading application. Options trading is not automatically enabled at account opening; the user must explicitly apply, pass an appropriateness assessment, and receive a formal approval or rejection from the platform's compliance workflow.

The five statuses form an ordered progression: `None` (not yet applied), `Pending` (application submitted, awaiting review), `InProcess` (active review underway), `Approved` (application granted; user may trade options), and `Rejected` (application denied). The `None` sentinel is also used for users who have never expressed interest in options trading.

`Apex.Options` stores the current `OptionsStatusID` for each user, making this dictionary the central reference point for options workflow reporting, alerting, and access control decisions.

---

## 2. Table Elements

| Column | Data Type | Nullable | PK | Description |
|---|---|---|---|---|
| OptionsStatusID | int | NOT NULL | Yes | Numeric identifier for the options application lifecycle stage; 0 is the sentinel for no application. |
| Name | nvarchar(50) | NOT NULL | No | Label representing the stage used in application logic, reporting, and compliance dashboards. |

**Constraints:**
- `PK_OptionsStatus` — clustered primary key on `OptionsStatusID`

---

## 3. Data Overview

5 rows as of 2026-04-14.

| OptionsStatusID | Name | Meaning |
|---|---|---|
| 0 | None | No options application exists for this user; they have not yet expressed interest in options trading or the record has been reset. |
| 1 | Pending | The user has submitted an options application; it is queued for review but processing has not yet commenced. |
| 2 | InProcess | The options application is actively being reviewed — appropriateness scoring, compliance checks, or manual review is underway. |
| 3 | Approved | The options application was approved; the user has been granted options trading access on the platform. |
| 4 | Rejected | The options application was denied; the user does not meet the eligibility criteria and options trading remains disabled. |

---

## 4. Relationships

### Referenced by (Foreign Keys into this table)

| Referencing Table | Referencing Column | Notes |
|---|---|---|
| Apex.Options | OptionsStatusID | Stores the current options application lifecycle status for each user's options record. |

### References to other tables

This table has no foreign key dependencies; it is a terminal reference (lookup-only) table.

---

## 5. Common Query Patterns

```sql
-- Options application funnel by status
SELECT os.Name AS OptionsStatus,
       COUNT(*) AS UserCount
FROM   Apex.Options o WITH (NOLOCK)
JOIN   Dictionary.OptionsStatus os WITH (NOLOCK)
       ON o.OptionsStatusID = os.OptionsStatusID
GROUP  BY os.Name, os.OptionsStatusID
ORDER  BY os.OptionsStatusID;
```

```sql
-- Find applications stuck in InProcess for more than 48 hours
SELECT o.*
FROM   Apex.Options o WITH (NOLOCK)
WHERE  o.OptionsStatusID = 2  -- InProcess
  AND  o.UpdatedAt < DATEADD(HOUR, -48, GETUTCDATE());
```

---

## 6. Data Quality Notes

- The `Pending` → `InProcess` → `Approved/Rejected` progression is the expected happy path; transitions that skip `InProcess` may indicate automated fast-path approvals and should be monitored.
- ID 0 (`None`) is used as a sentinel to avoid NULLable FKs; it does not mean the user was rejected — use ID 4 for rejections.
- `nvarchar(50)` is used for `Name`; consistent with other Options-related dictionaries.
- A `Rejected` user (ID 4) may reapply; the history of status transitions is auditable through `Apex.Options` timestamps.

---

## 7. Change History

| Date | Change |
|---|---|
| 2026-04-14 | Initial documentation created; 5 rows verified against live data. |

---

## 8. Related Objects

| Object | Type | Relationship |
|---|---|---|
| Apex.Options | Table | The primary options record per user; stores the current OptionsStatusID. |
| Dictionary.OptionsStatusControl | Table | Sibling dictionary: controls whether the options status gate is blocked or allowed at a system level. |
| Dictionary.EligibilityStatus | Table | The eligibility determination that is set once OptionsStatus reaches Approved. |
| Dictionary.ReasoningStatus | Table | Tracks the reasoning form workflow that is triggered when a user requests to downgrade from Approved. |
| Dictionary.AppropriatenessTestResult | Table | The appropriateness result that must be Passed before an application can move to Approved. |

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Documentation generated 2026-04-14 — USABroker · Dictionary schema*
