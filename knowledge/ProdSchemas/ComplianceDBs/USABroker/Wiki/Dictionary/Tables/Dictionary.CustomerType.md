# Dictionary.CustomerType

**Schema:** Dictionary
**Table:** CustomerType
**Database:** USABroker
**Last Reviewed:** 2026-04-14

---

## 1. Business Meaning

`Dictionary.CustomerType` is a static reference table that classifies the legal structure of a brokerage account held by a user. The account type governs a wide range of downstream rules: which agreements must be signed, which tax forms are required, who is authorised to transact, and which regulatory disclosures apply.

The four types reflect the US broker-dealer product catalogue. `INDIVIDUAL` accounts are standard retail accounts held in a single person's name. `IRA` (Individual Retirement Account) accounts carry specific tax-advantaged rules, mandatory IRA adoption agreements, and contribution limits. `JOINT` accounts are held by two or more individuals and require a joint account agreement. `CUSTODIAN` accounts are managed by an adult on behalf of a minor under UGMA/UTMA statutes.

`Apex.UserData` stores the `CustomerTypeID` against each user's profile, making this the primary branching point for account-type-specific validation, document requirements, and regulatory treatment throughout the USABroker workflow engine.

---

## 2. Table Elements

| Column | Data Type | Nullable | PK | Description |
|---|---|---|---|---|
| CustomerTypeID | int | NOT NULL | Yes | Stable numeric identifier for the account/customer type. |
| Name | varchar(50) | NOT NULL | No | Uppercase string code used throughout the application layer to identify the account structure. |

**Constraints:**
- `PK_CustomerType` — clustered primary key on `CustomerTypeID`

---

## 3. Data Overview

4 rows as of 2026-04-14.

| CustomerTypeID | Name | Meaning |
|---|---|---|
| 1 | INDIVIDUAL | A standard retail brokerage account held solely by one natural person; the most common account type. |
| 2 | IRA | An Individual Retirement Account — tax-advantaged account subject to IRS contribution limits, requiring an IRA adoption agreement and specific annual tax reporting. |
| 3 | JOINT | An account co-owned by two or more individuals; requires a joint account agreement and both parties' identity verification. |
| 4 | CUSTODIAN | A custodial account (UGMA/UTMA) managed by an adult custodian on behalf of a minor beneficiary; custodian retains control until the minor reaches the age of majority. |

---

## 4. Relationships

### Referenced by (Foreign Keys into this table)

| Referencing Table | Referencing Column | Notes |
|---|---|---|
| Apex.UserData | CustomerTypeID | Stores the account type for each user record; drives agreement requirements, tax-form selection, and validation rules. |

### References to other tables

This table has no foreign key dependencies; it is a terminal reference (lookup-only) table.

---

## 5. Common Query Patterns

```sql
-- Distribution of users by account type
SELECT ct.Name AS CustomerType,
       COUNT(*) AS UserCount
FROM   Apex.UserData ud WITH (NOLOCK)
JOIN   Dictionary.CustomerType ct WITH (NOLOCK)
       ON ud.CustomerTypeID = ct.CustomerTypeID
GROUP  BY ct.Name
ORDER  BY UserCount DESC;
```

```sql
-- Find all IRA accounts for tax reporting purposes
SELECT ud.*
FROM   Apex.UserData ud WITH (NOLOCK)
WHERE  ud.CustomerTypeID = 2; -- IRA
```

---

## 6. Data Quality Notes

- Names are stored in UPPERCASE, consistent with the Apex API convention; application code should not normalise them to mixed-case.
- The `JOINT` type (ID 3) is cross-referenced by the `ApexValidationError` codes 14 and 18, which enforce joint-agreement document rules.
- The `IRA` type (ID 2) is cross-referenced by `ApexValidationError` codes 16 and 17, which enforce IRA adoption agreement rules.
- `varchar(50)` is adequate for all current values; all names are ASCII.
- Adding a new customer type requires coordinated changes to agreement configuration, validation rules, and Apex API mappings.

---

## 7. Change History

| Date | Change |
|---|---|
| 2026-04-14 | Initial documentation created; 4 rows verified against live data. |

---

## 8. Related Objects

| Object | Type | Relationship |
|---|---|---|
| Apex.UserData | Table | Stores the customer type for each user; primary consumer of this dictionary. |
| Dictionary.DocumentType | Table | Sibling dictionary: the document types required may vary by customer type. |
| Dictionary.UserDocumentType | Table | Sibling dictionary: user document categories uploaded as part of account opening. |

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Documentation generated 2026-04-14 — USABroker · Dictionary schema*
