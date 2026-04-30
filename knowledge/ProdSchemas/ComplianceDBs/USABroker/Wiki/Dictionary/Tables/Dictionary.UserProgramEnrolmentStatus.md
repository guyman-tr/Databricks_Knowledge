# Dictionary.UserProgramEnrolmentStatus

**Schema:** Dictionary
**Table:** UserProgramEnrolmentStatus
**Database:** USABroker
**Last Reviewed:** 2026-04-14

---

## 1. Business Meaning

`Dictionary.UserProgramEnrolmentStatus` is a static reference table that encodes the three possible enrolment states a user can hold in any optional brokerage programme (such as FPSL, crypto staking, or proxy voting). It represents the user's expressed preference and the system's confirmation of that preference for each programme they have interacted with.

`None` (ID 0) is the sentinel for users who have never been processed through the enrolment workflow for a particular programme — their status is neither opted in nor opted out, but simply uninitialised. `OptIn` (ID 1) means the user has actively chosen to participate in the programme and the enrolment has been accepted. `OptOut` (ID 2) means the user has explicitly withdrawn from the programme after previously opting in, or has declined enrolment at the point of offer.

`Apex.UserProgramEnrolment` stores one record per user per programme, with the current `UserProgramEnrolmentStatusID` reflecting the user's live enrolment state. This allows the platform to determine at any time which programmes a user is actively participating in, and to generate accurate enrolment-change audit trails.

---

## 2. Table Elements

| Column | Data Type | Nullable | PK | Description |
|---|---|---|---|---|
| UserProgramEnrolmentStatusID | int | NOT NULL | Yes | Stable numeric identifier for the enrolment state; 0 is the sentinel for not yet processed. |
| Name | varchar(50) | NOT NULL | No | Short label for the enrolment state used in application logic, reporting, and user-facing status displays. |

**Constraints:**
- `PK_UserProgramEnrolmentStatus` — clustered primary key on `UserProgramEnrolmentStatusID`

---

## 3. Data Overview

3 rows as of 2026-04-14.

| UserProgramEnrolmentStatusID | Name | Meaning |
|---|---|---|
| 0 | None | The user's enrolment status for this programme has not been set; the enrolment workflow has not yet been initiated or completed for this user/programme combination. |
| 1 | OptIn | The user has actively chosen to participate in the programme and the platform has confirmed their enrolment; programme benefits and obligations are active. |
| 2 | OptOut | The user has withdrawn from the programme — either by declining at the point of offer or by subsequently cancelling their participation; programme benefits are no longer active. |

---

## 4. Relationships

### Referenced by (Foreign Keys into this table)

| Referencing Table | Referencing Column | Notes |
|---|---|---|
| Apex.UserProgramEnrolment | UserProgramEnrolmentStatusID | Stores the current enrolment state for each user/programme combination. |

### References to other tables

This table has no foreign key dependencies; it is a terminal reference (lookup-only) table.

---

## 5. Common Query Patterns

```sql
-- Summary of enrolment status across all programmes
SELECT up.Name AS Programme,
       pes.Name AS EnrolmentStatus,
       COUNT(*) AS UserCount
FROM   Apex.UserProgramEnrolment upe WITH (NOLOCK)
JOIN   Dictionary.UserProgram up WITH (NOLOCK)
       ON upe.UserProgramID = up.UserProgramID
JOIN   Dictionary.UserProgramEnrolmentStatus pes WITH (NOLOCK)
       ON upe.UserProgramEnrolmentStatusID = pes.UserProgramEnrolmentStatusID
GROUP  BY up.Name, pes.Name
ORDER  BY up.Name, pes.Name;
```

```sql
-- Find all users currently opted out of any programme (potential churn analysis)
SELECT upe.*
FROM   Apex.UserProgramEnrolment upe WITH (NOLOCK)
WHERE  upe.UserProgramEnrolmentStatusID = 2; -- OptOut
```

```sql
-- Count users who have opted in to FPSL
SELECT COUNT(*) AS FpslOptInCount
FROM   Apex.UserProgramEnrolment upe WITH (NOLOCK)
WHERE  upe.UserProgramID = 1                     -- FPSL
  AND  upe.UserProgramEnrolmentStatusID = 1;     -- OptIn
```

---

## 6. Data Quality Notes

- `None` (ID 0) is the default sentinel; application logic must distinguish between a user who has never been offered the programme (`None`) and one who actively opted out (`OptOut`), as these have different re-marketing and re-enrolment implications.
- The transition from `OptOut` back to `OptIn` is valid; the enrolment table should be queried for the most recent record or timestamp to determine the current state when re-enrolment history matters.
- `varchar(50)` is used; all values are ASCII-safe.
- This table applies uniformly across all programmes in `Dictionary.UserProgram`; no programme-specific status codes exist.
- For FPSL specifically, an opt-in here should be cross-referenced with `Apex.UserFpslEnrolment` for the full enrolment detail including appropriateness results.

---

## 7. Change History

| Date | Change |
|---|---|
| 2026-04-14 | Initial documentation created; 3 rows verified against live data. |

---

## 8. Related Objects

| Object | Type | Relationship |
|---|---|---|
| Apex.UserProgramEnrolment | Table | Stores the enrolment record per user per programme; references this dictionary for the current status. |
| Dictionary.UserProgram | Table | Sibling dictionary: defines which programmes a user can enrol in; combined with this table to give the full enrolment picture. |
| Apex.UserFpslEnrolment | Table | The detailed FPSL enrolment record, which supplements the general enrolment status stored via this dictionary. |
| Dictionary.AppropriatenessProduct | Table | For FPSL, appropriateness must be assessed and passed before `OptIn` status is applied. |

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Documentation generated 2026-04-14 — USABroker · Dictionary schema*
