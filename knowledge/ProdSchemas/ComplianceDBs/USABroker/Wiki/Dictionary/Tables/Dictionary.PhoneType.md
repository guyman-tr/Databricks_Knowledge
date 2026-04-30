# Dictionary.PhoneType

**Schema:** Dictionary
**Table:** PhoneType
**Database:** USABroker
**Last Reviewed:** 2026-04-14

---

## 1. Business Meaning

`Dictionary.PhoneType` is a static reference table that classifies the category of a telephone number provided by a user during account registration or update. Capturing phone type allows the platform to understand the intended use of each number — for example, distinguishing a reachable mobile number (preferred for two-factor authentication and urgent contact) from a work number or fax line.

This classification is used in two contexts: `Apex.UserData` stores the primary phone number type for the account holder, and `Apex.UserDataTrustedContact` stores the phone type for the user's designated trusted contact person, a regulatory requirement under FINRA Rule 4512.

The five types cover the standard categories offered by US broker-dealers: Home, Work, Mobile, Fax, and Other.

---

## 2. Table Elements

| Column | Data Type | Nullable | PK | Description |
|---|---|---|---|---|
| PhoneTypeID | int | NOT NULL | Yes | Stable numeric identifier for the phone number category. |
| Name | varchar(150) | NOT NULL | No | Human-readable label for the phone category; notably wide at 150 characters to accommodate future descriptive labels. |

**Constraints:**
- `PK_PhoneType` — clustered primary key on `PhoneTypeID`

---

## 3. Data Overview

5 rows as of 2026-04-14.

| PhoneTypeID | Name | Meaning |
|---|---|---|
| 1 | Home | A residential landline number associated with the user's home address; typically not portable. |
| 2 | Work | A telephone number at the user's place of employment; may be a direct line or a switchboard extension. |
| 3 | Mobile | A cellular phone number; the preferred type for SMS-based authentication and urgent compliance contact. |
| 4 | Fax | A fax machine number; retained for legacy compatibility with customers who submit documents by fax. |
| 5 | Other | Any phone number that does not fit the Home, Work, Mobile, or Fax categories. |

---

## 4. Relationships

### Referenced by (Foreign Keys into this table)

| Referencing Table | Referencing Column | Notes |
|---|---|---|
| Apex.UserData | PhoneNumberTypeID | Classifies the primary phone number stored on the user's account record. |
| Apex.UserDataTrustedContact | PhoneNumberTypeID | Classifies the phone number provided for the user's trusted contact person (FINRA Rule 4512 requirement). |

### References to other tables

This table has no foreign key dependencies; it is a terminal reference (lookup-only) table.

---

## 5. Common Query Patterns

```sql
-- Distribution of primary phone types across all user accounts
SELECT pt.Name AS PhoneType,
       COUNT(*) AS UserCount
FROM   Apex.UserData ud WITH (NOLOCK)
JOIN   Dictionary.PhoneType pt WITH (NOLOCK)
       ON ud.PhoneNumberTypeID = pt.PhoneTypeID
GROUP  BY pt.Name
ORDER  BY UserCount DESC;
```

```sql
-- Find trusted contacts where a mobile number was provided
SELECT tc.*
FROM   Apex.UserDataTrustedContact tc WITH (NOLOCK)
WHERE  tc.PhoneNumberTypeID = 3; -- Mobile
```

---

## 6. Data Quality Notes

- `varchar(150)` for `Name` is much wider than needed for the five current short labels; this was likely sized to match `ApexValidationError.Name` or defensively for future verbose descriptions.
- IDs are non-sequential in meaning: mobile (ID 3) is often the most operationally significant but has no special ordering treatment.
- The `Fax` type (ID 4) is functionally obsolete for most users but retained for backward compatibility and legacy submissions.
- Neither `UserData` nor `UserDataTrustedContact` enforces a `NOT NULL` on `PhoneNumberTypeID` at the dictionary level; application validation must ensure a valid type is always supplied.

---

## 7. Change History

| Date | Change |
|---|---|
| 2026-04-14 | Initial documentation created; 5 rows verified against live data. |

---

## 8. Related Objects

| Object | Type | Relationship |
|---|---|---|
| Apex.UserData | Table | Stores the primary contact phone number and its type for each user account. |
| Apex.UserDataTrustedContact | Table | Stores the trusted contact's phone number and its type, required under FINRA Rule 4512. |
| Dictionary.CustomerType | Table | The customer type may influence which phone type is most relevant (e.g., custodian accounts). |

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Documentation generated 2026-04-14 — USABroker · Dictionary schema*
