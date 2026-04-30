# Dictionary.UserProgram

**Schema:** Dictionary
**Table:** UserProgram
**Database:** USABroker
**Last Reviewed:** 2026-04-14

---

## 1. Business Meaning

`Dictionary.UserProgram` is a static reference table that enumerates the optional value-added programmes that a brokerage user can enrol in beyond their standard account. Each programme offers a distinct financial service or shareholder-participation feature that the user must explicitly opt into, and the enrolment state is tracked separately in `Apex.UserProgramEnrolment`.

The programmes currently offered span three domains: securities lending (`FPSL` — Fully Paid Securities Lending), cryptocurrency staking (`CryptoStaking`, `EthStaking`), and shareholder proxy voting (`ProxyVotingManualPositions`, `ProxyVotingCopiedPositions`). The `None` sentinel (ID 0) is used where no specific programme applies.

FPSL allows users to lend out fully paid securities in exchange for a fee. The two staking programmes allow users to participate in proof-of-stake blockchain validation rewards. The proxy voting programmes allow users to exercise their shareholder voting rights — either by setting manual positions or by mirroring the positions of a followed investor (copied positions).

---

## 2. Table Elements

| Column | Data Type | Nullable | PK | Description |
|---|---|---|---|---|
| UserProgramID | int | NOT NULL | Yes | Stable numeric identifier for the programme; 0 is the sentinel for no specific programme. |
| Name | varchar(50) | NOT NULL | No | Short programme code used throughout the application layer; note ID 4 has a trailing space in the live data. |

**Constraints:**
- `PK_UserProgram` — clustered primary key on `UserProgramID`

---

## 3. Data Overview

6 rows as of 2026-04-14.

| UserProgramID | Name | Meaning |
|---|---|---|
| 0 | None | No specific programme; used as the sentinel/default when no enrolment programme is associated with a record. |
| 1 | FPSL | Fully Paid Securities Lending — the user lends eligible, fully paid securities from their account to approved borrowers in exchange for lending fees. Requires a separate appropriateness assessment. |
| 2 | CryptoStaking | Cryptocurrency Staking — the user participates in proof-of-stake validation for supported cryptocurrency assets, earning staking rewards proportional to their holdings. |
| 3 | EthStaking | Ethereum Staking — a specific staking programme for ETH holdings, separate from the general crypto staking programme due to Ethereum's distinct staking mechanism and lock-up characteristics. |
| 4 | ProxyVotingManualPositions | Proxy Voting (Manual Positions) — the user actively sets their own shareholder voting positions for companies held in their portfolio. |
| 5 | ProxyVotingCopiedPositions | Proxy Voting (Copied Positions) — the user's proxy voting positions are automatically aligned with those of a followed investor (copy-trading context). |

---

## 4. Relationships

### Referenced by (Foreign Keys into this table)

| Referencing Table | Referencing Column | Notes |
|---|---|---|
| Apex.UserProgramEnrolment | UserProgramID | Each enrolment record links a user to a specific programme and tracks their opt-in/opt-out status. |

### References to other tables

This table has no foreign key dependencies; it is a terminal reference (lookup-only) table.

---

## 5. Common Query Patterns

```sql
-- Count active enrolments by programme
SELECT up.Name AS Programme,
       COUNT(*) AS EnrolmentCount
FROM   Apex.UserProgramEnrolment upe WITH (NOLOCK)
JOIN   Dictionary.UserProgram up WITH (NOLOCK)
       ON upe.UserProgramID = up.UserProgramID
WHERE  upe.UserProgramEnrolmentStatusID = 1  -- OptIn
GROUP  BY up.Name
ORDER  BY EnrolmentCount DESC;
```

```sql
-- Find all users enrolled in FPSL
SELECT upe.*
FROM   Apex.UserProgramEnrolment upe WITH (NOLOCK)
WHERE  upe.UserProgramID = 1; -- FPSL
```

---

## 6. Data Quality Notes

- The live data for ID 4 (`ProxyVotingManualPositions`) contains a trailing space character — `"ProxyVotingManualPositions "`. Application code should use `RTRIM()` or compare by ID rather than by Name string equality to avoid matching issues.
- `FPSL` (ID 1) is also referenced by the appropriateness product table (`Dictionary.AppropriatenessProduct` ID 2); the programmes and their appropriateness requirements are related but tracked separately.
- `EthStaking` (ID 3) is a sub-programme of `CryptoStaking` (ID 2); both may be active simultaneously for a user with ETH holdings, depending on platform policy.
- The two proxy voting programmes (IDs 4 and 5) are mutually exclusive by design — a user either sets manual positions or copies another investor's positions.
- `varchar(50)` is sufficient; all names are ASCII.

---

## 7. Change History

| Date | Change |
|---|---|
| 2026-04-14 | Initial documentation created; 6 rows verified against live data. Trailing space noted on ID 4. |

---

## 8. Related Objects

| Object | Type | Relationship |
|---|---|---|
| Apex.UserProgramEnrolment | Table | Stores each user's enrolment record for a programme, including opt-in/opt-out status and timestamps. |
| Dictionary.UserProgramEnrolmentStatus | Table | Sibling dictionary: records whether the user is opted in, opted out, or in no status for each programme. |
| Dictionary.AppropriatenessProduct | Table | FPSL (AppropriatenessProduct ID 2) corresponds to UserProgram FPSL (ID 1); appropriateness must be assessed before FPSL enrolment. |
| Apex.UserFpslEnrolment | Table | A dedicated enrolment table for the FPSL programme, supplementing the general UserProgramEnrolment record. |

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Documentation generated 2026-04-14 — USABroker · Dictionary schema*
