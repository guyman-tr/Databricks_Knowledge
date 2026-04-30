# Dictionary.OptionsStatusControl

**Schema:** Dictionary
**Table:** OptionsStatusControl
**Database:** USABroker
**Last Reviewed:** 2026-04-14

---

## 1. Business Meaning

`Dictionary.OptionsStatusControl` is a static reference table that encodes the administrative control state layered on top of a user's options application status. While `Dictionary.OptionsStatus` captures where the user's application stands in the approval workflow, `OptionsStatusControl` captures whether a separate system-level or compliance-level gate is blocking or permitting options activity regardless of the application state.

This separation of concerns allows the platform to place a hold on a user's options access (`Blocked`) even if their application is otherwise `Approved`, without needing to change the application status itself. Conversely, `Allowed` signals that no administrative override is active and the application status alone governs access. `None` is the uninitialised sentinel.

`Apex.Options` stores `OptionsStatusControlID` alongside `OptionsStatusID`, meaning both dimensions must be evaluated together to determine whether a user can actually trade options at any given moment.

---

## 2. Table Elements

| Column | Data Type | Nullable | PK | Description |
|---|---|---|---|---|
| OptionsStatusControlID | int | NOT NULL | Yes | Numeric identifier for the administrative control state; 0 is the sentinel for not set. |
| Name | nvarchar(50) | NOT NULL | No | Label representing the control state; used by access-control logic and compliance tooling. |

**Constraints:**
- `PK_OptionsStatusControl` — clustered primary key on `OptionsStatusControlID`

---

## 3. Data Overview

3 rows as of 2026-04-14.

| OptionsStatusControlID | Name | Meaning |
|---|---|---|
| 0 | None | No administrative control override is set; options access is governed purely by the application status and eligibility flags. |
| 1 | Blocked | A compliance or system-level hold has been placed on this user's options access; trading is disallowed even if the application is Approved. |
| 2 | Allowed | An administrative review has confirmed that options access may proceed; no blocking override is in place. |

---

## 4. Relationships

### Referenced by (Foreign Keys into this table)

| Referencing Table | Referencing Column | Notes |
|---|---|---|
| Apex.Options | OptionsStatusControlID | Stores the administrative control gate alongside the application workflow status for each user. |

### References to other tables

This table has no foreign key dependencies; it is a terminal reference (lookup-only) table.

---

## 5. Common Query Patterns

```sql
-- Find all users with an active Blocked control override
SELECT o.*
FROM   Apex.Options o WITH (NOLOCK)
WHERE  o.OptionsStatusControlID = 1; -- Blocked
```

```sql
-- Users who are Approved but currently Blocked (compliance hold)
SELECT o.*
FROM   Apex.Options o WITH (NOLOCK)
WHERE  o.OptionsStatusID = 3           -- Approved
  AND  o.OptionsStatusControlID = 1;  -- Blocked
```

---

## 6. Data Quality Notes

- The `Blocked` state (ID 1) is an important compliance tool; any automation that grants options access must check both `OptionsStatusID = 3` (Approved) AND `OptionsStatusControlID <> 1` (not Blocked).
- ID 0 (`None`) is the default for new records; the distinction between `None` and `Allowed` (ID 2) should be clarified in application logic — `None` means the control layer has not been evaluated, while `Allowed` means it has been evaluated and cleared.
- `nvarchar(50)` is used, consistent with other Options-related dictionaries.
- No audit table exists within this dictionary for control-state changes; changes to `Apex.Options.OptionsStatusControlID` should be tracked through the application's change-log mechanism.

---

## 7. Change History

| Date | Change |
|---|---|
| 2026-04-14 | Initial documentation created; 3 rows verified against live data. |

---

## 8. Related Objects

| Object | Type | Relationship |
|---|---|---|
| Apex.Options | Table | The primary options record; stores both OptionsStatusID and OptionsStatusControlID, which must be evaluated together. |
| Dictionary.OptionsStatus | Table | Sibling dictionary: the application-level workflow status that OptionsStatusControl overrides or permits. |
| Dictionary.EligibilityStatus | Table | The final eligibility gate; effectively the AND of OptionsStatus and OptionsStatusControl. |

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Documentation generated 2026-04-14 — USABroker · Dictionary schema*
