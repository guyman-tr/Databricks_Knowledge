# Dictionary.ModifyType

**Schema:** Dictionary
**Table:** ModifyType
**Database:** USABroker
**Last Reviewed:** 2026-04-14

---

## 1. Business Meaning

`Dictionary.ModifyType` is a static reference table that classifies the nature of an operation recorded in the `Apex.RequestLog`. Every request sent to the Apex broker-dealer platform on behalf of a user falls into one of three lifecycle categories: creating a new account (`Create`), modifying an existing account (`Update`), or closing an account (`Close`).

This classification is fundamental to audit trail integrity. Compliance and operations teams rely on `ModifyType` to filter the request log to a specific operation class — for example, to count all account closures in a period, or to investigate whether an update request preceded a compliance flag. The three values map directly to the three request types supported by the Apex API.

---

## 2. Table Elements

| Column | Data Type | Nullable | PK | Description |
|---|---|---|---|---|
| ModifyTypeID | int | NOT NULL | Yes | Numeric identifier for the operation type. |
| Name | varchar(128) | NOT NULL | No | Human-readable label for the operation class; wider than most Dictionary name columns to accommodate future verbose values. |

**Constraints:**
- `PK_ModifyType` — clustered primary key on `ModifyTypeID`

---

## 3. Data Overview

3 rows as of 2026-04-14.

| ModifyTypeID | Name | Meaning |
|---|---|---|
| 1 | Create | An account creation request was submitted to the Apex platform on behalf of a new user; represents the initial onboarding step. |
| 2 | Update | An account update request was submitted to modify one or more fields on an existing Apex account (e.g., address change, name correction). |
| 3 | Close | An account closure request was submitted to terminate the user's brokerage account with Apex. |

---

## 4. Relationships

### Referenced by (Foreign Keys into this table)

| Referencing Table | Referencing Column | Notes |
|---|---|---|
| Apex.RequestLog | ModifyTypeID | Every outbound Apex API request is logged with the operation type, enabling filtering by Create / Update / Close. |

### References to other tables

This table has no foreign key dependencies; it is a terminal reference (lookup-only) table.

---

## 5. Common Query Patterns

```sql
-- Count requests by operation type over the last 7 days
SELECT mt.Name AS OperationType,
       COUNT(*) AS RequestCount
FROM   Apex.RequestLog rl WITH (NOLOCK)
JOIN   Dictionary.ModifyType mt WITH (NOLOCK)
       ON rl.ModifyTypeID = mt.ModifyTypeID
WHERE  rl.CreatedAt >= DATEADD(DAY, -7, GETUTCDATE())
GROUP  BY mt.Name
ORDER  BY RequestCount DESC;
```

```sql
-- Retrieve all account closure requests for compliance review
SELECT rl.*
FROM   Apex.RequestLog rl WITH (NOLOCK)
WHERE  rl.ModifyTypeID = 3; -- Close
```

---

## 6. Data Quality Notes

- The three values are exhaustive for the current Apex API integration; a fourth type would require changes to both this table and the Apex request-construction logic.
- `varchar(128)` is notably wider than needed for the three current short values; this may have been sized defensively for future descriptive names.
- No `IsActive` column exists; if a modify type became obsolete it would need to be documented here rather than soft-deleted.
- The log table `Apex.RequestLog` also stores `UpdateEventMask` (an implicit reference to `Dictionary.UserDataUpdatesMask`), providing complementary granularity for Update-type requests.

---

## 7. Change History

| Date | Change |
|---|---|
| 2026-04-14 | Initial documentation created; 3 rows verified against live data. |

---

## 8. Related Objects

| Object | Type | Relationship |
|---|---|---|
| Apex.RequestLog | Table | The primary audit log of all Apex API requests; each row references ModifyType. |
| Dictionary.UserDataUpdatesMask | Table | For `Update` (ID 2) requests, the UpdateEventMask in RequestLog provides field-level granularity via this bitmask dictionary. |
| Dictionary.State | Table | The State machine table tracks the workflow state that follows each Apex request. |

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Documentation generated 2026-04-14 — USABroker · Dictionary schema*
