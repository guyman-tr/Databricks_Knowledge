# Dictionary.UserDataUpdatesMask

**Schema:** Dictionary
**Table:** UserDataUpdatesMask
**Database:** USABroker
**Last Reviewed:** 2026-04-14

---

## 1. Business Meaning

`Dictionary.UserDataUpdatesMask` is a static reference table that defines the individual bit flags used to represent which specific data fields were included in a user data update event. Rather than storing a separate boolean column for each updatable field, the platform encodes the set of changed fields as a single integer bitmask — a common pattern for efficient storage and flexible multi-field queries.

Each row defines one bit position and its corresponding field name. A bitmask value stored in `Apex.UserDataUpdates.UpdatesMask`, `Apex.UserParameters.UpdatesMask`, or `Apex.RequestLog.UpdateEventMask` is decoded by bitwise AND against each row in this table. For example, a mask value of `192` means both `PhoneNumber` (64) and `HomeAddress` (128) were updated in that event.

The 13 defined fields cover all the personal and compliance data points that the Apex API permits to be updated: disclosures, name components, date of birth, citizenship and birth country, SSN, phone, home address, email, permanent residency status, trusted contact, mailing address, and a special `Instructions` flag for processing directives.

---

## 2. Table Elements

| Column | Data Type | Nullable | PK | Description |
|---|---|---|---|---|
| Mask | int | NOT NULL | Yes | The power-of-two bit value representing this field in a composite bitmask integer. Used as the PK and as the operand in bitwise AND operations. |
| Name | varchar(128) | NOT NULL | No | Human-readable field name corresponding to this bit position; used in reporting and audit decoding. |

**Constraints:**
- `PK_UserDataUpdatesMask` — clustered primary key on `Mask`

---

## 3. Data Overview

13 rows as of 2026-04-14.

| Mask | Name | Meaning |
|---|---|---|
| 1 | Disclosures | The user's regulatory disclosure answers (e.g., affiliated status, political exposure) were included in the update. |
| 2 | Name | The user's legal name (first name, last name, or both) was changed or corrected in the update event. |
| 4 | DateOfBirth | The user's date of birth was included in the update, typically following a correction or identity verification. |
| 8 | CitizenshipCountry | The user's country of citizenship was updated, affecting tax and residency status determinations. |
| 16 | SocialSecurityNumber | The user's Social Security Number was included in the update, a high-sensitivity change requiring additional audit scrutiny. |
| 32 | BirthCountry | The user's country of birth was updated; relevant to FATCA and AML screening. |
| 64 | PhoneNumber | The user's primary phone number or phone type was changed. |
| 128 | HomeAddress | The user's residential home address was updated, triggering address verification checks. |
| 256 | Email | The user's email address was changed on the account. |
| 512 | PermanentResident | The user's US permanent residency status was updated, affecting eligibility and tax-form requirements. |
| 1024 | TrustedContact | The user's designated trusted contact person details (name, phone, email) were added or updated per FINRA Rule 4512. |
| 2048 | MailingAddress | The user's mailing address (if different from home) was updated. |
| 4096 | Instructions | A special processing instruction flag was set alongside the update, directing specific handling by the Apex integration layer. |

**Bitmask combination examples:**
- Mask `6` = Name (2) + DateOfBirth (4) — a name-correction event that also updated DOB.
- Mask `192` = PhoneNumber (64) + HomeAddress (128) — a contact-details update.
- Mask `3072` = TrustedContact (1024) + MailingAddress (2048) — a trusted contact and address update together.

---

## 4. Relationships

### Referenced by (Implicit bitmask references to this table)

| Referencing Table | Referencing Column | Notes |
|---|---|---|
| Apex.UserDataUpdates | UpdatesMask | Stores a bitmask indicating which fields were included in each user data update event; decoded using this table. |
| Apex.UserParameters | UpdatesMask | Stores a bitmask of user parameter fields applicable to the account configuration; decoded using this table. |
| Apex.RequestLog | UpdateEventMask | Stores a bitmask of the fields included in each outbound update request to the Apex API; decoded using this table. |

### References to other tables

This table has no foreign key dependencies; it is a terminal reference (lookup-only) table.

---

## 5. Common Query Patterns

```sql
-- Decode which fields were updated in a specific UserDataUpdates event (example mask = 192)
SELECT m.Name AS UpdatedField
FROM   Dictionary.UserDataUpdatesMask m WITH (NOLOCK)
WHERE  (192 & m.Mask) = m.Mask;
-- Returns: PhoneNumber, HomeAddress
```

```sql
-- Find all update events that included a SSN change
SELECT udu.*
FROM   Apex.UserDataUpdates udu WITH (NOLOCK)
WHERE  (udu.UpdatesMask & 16) = 16; -- SocialSecurityNumber bit
```

```sql
-- Count how often each field appears in update events (approximate, may double-count composite masks)
SELECT m.Name AS Field,
       SUM(CASE WHEN (udu.UpdatesMask & m.Mask) = m.Mask THEN 1 ELSE 0 END) AS UpdateCount
FROM   Apex.UserDataUpdates udu WITH (NOLOCK)
CROSS JOIN Dictionary.UserDataUpdatesMask m WITH (NOLOCK)
GROUP  BY m.Name
ORDER  BY UpdateCount DESC;
```

---

## 6. Data Quality Notes

- All mask values are powers of 2 (1, 2, 4, 8, … 4096); any value in referencing tables that is not decomposable into these 13 bits indicates a data integrity issue.
- The primary key is `Mask` (an integer power of two) rather than a sequential ID — this is an intentional design to make the PK directly usable in bitwise operations without a join.
- `SocialSecurityNumber` (mask 16) is a high-sensitivity field; queries filtering on this bit should be subject to data access controls and audit logging.
- `varchar(128)` for `Name` is wider than most Dictionary name columns; this matches `Dictionary.ModifyType` and accommodates the longer field names.
- There is no `IsActive` flag; retired fields should be documented here and the corresponding bit should not be reused.
- The maximum composite mask value with all 13 bits set is `1 + 2 + 4 + 8 + 16 + 32 + 64 + 128 + 256 + 512 + 1024 + 2048 + 4096 = 8191`.

---

## 7. Change History

| Date | Change |
|---|---|
| 2026-04-14 | Initial documentation created; 13 rows verified against live data. |

---

## 8. Related Objects

| Object | Type | Relationship |
|---|---|---|
| Apex.UserDataUpdates | Table | Event log of user data changes; UpdatesMask column encodes changed fields using this table's bit definitions. |
| Apex.UserParameters | Table | Stores user-level parameter configuration; UpdatesMask encoded using this table. |
| Apex.RequestLog | Table | Outbound Apex API request log; UpdateEventMask column encodes which fields were in each update request. |
| Dictionary.ModifyType | Table | The ModifyType of a RequestLog entry determines whether UpdateEventMask is relevant (only for Update type). |

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Documentation generated 2026-04-14 — USABroker · Dictionary schema*
