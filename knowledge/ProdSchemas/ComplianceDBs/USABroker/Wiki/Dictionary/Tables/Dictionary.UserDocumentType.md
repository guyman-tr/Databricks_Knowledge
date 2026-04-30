# Dictionary.UserDocumentType

**Schema:** Dictionary
**Table:** UserDocumentType
**Database:** USABroker
**Last Reviewed:** 2026-04-14

---

## 1. Business Meaning

`Dictionary.UserDocumentType` is a static reference table that classifies the category of documents that users upload and associate with their brokerage account profile. These are user-facing document uploads managed at the account level, distinct from `Dictionary.DocumentType` which classifies documents submitted specifically as part of a CIP investigation.

The six types span the range of documents a broker-dealer typically collects: the account holder's signature image (required for agreement execution), government-issued identity documents (stored for KYC records), IRA-specific deposit slips, account transfer forms (ACATS-related), affiliated-entity approval letters, and a catch-all for other supporting documents.

`Apex.UserDocument` stores each uploaded file with a `UserDocumentTypeID`, allowing compliance and operations teams to filter, audit, and retrieve specific document categories efficiently.

---

## 2. Table Elements

| Column | Data Type | Nullable | PK | Description |
|---|---|---|---|---|
| UserDocumentTypeID | int | NOT NULL | Yes | Stable numeric identifier for the user document category. |
| Name | varchar(50) | NOT NULL | No | Uppercase underscore-delimited code that identifies the document class in application logic and reporting. |

**Constraints:**
- `PK_UserDocumentType` — clustered primary key on `UserDocumentTypeID`

---

## 3. Data Overview

6 rows as of 2026-04-14.

| UserDocumentTypeID | Name | Meaning |
|---|---|---|
| 1 | SIGNATURE_IMAGE | A scanned or photographed image of the user's handwritten signature, collected for agreement execution and audit purposes. |
| 2 | ID_DOCUMENT | A government-issued identity document (e.g., passport, driver's licence) stored against the user's profile for KYC record-keeping. |
| 3 | IRA_DEPOSIT_SLIP | A deposit slip or transfer confirmation associated with a contribution into the user's Individual Retirement Account. |
| 4 | ACCOUNT_TRANSFER_FORM | An ACATS (Automated Customer Account Transfer Service) or similar form initiating the transfer of assets from another broker. |
| 5 | AFFILIATED_APPROVAL | An approval letter or consent form from a broker-dealer, exchange, or employer where the user is affiliated, required under FINRA conflict-of-interest rules. |
| 6 | OTHER | A catch-all category for any supporting document that does not fit the specific categories above. |

---

## 4. Relationships

### Referenced by (Foreign Keys into this table)

| Referencing Table | Referencing Column | Notes |
|---|---|---|
| Apex.UserDocument | UserDocumentTypeID | Each document file stored against a user's account references the document category from this table. |

### References to other tables

This table has no foreign key dependencies; it is a terminal reference (lookup-only) table.

---

## 5. Common Query Patterns

```sql
-- Count uploaded documents by type across all users
SELECT udt.Name AS DocumentType,
       COUNT(*) AS DocumentCount
FROM   Apex.UserDocument ud WITH (NOLOCK)
JOIN   Dictionary.UserDocumentType udt WITH (NOLOCK)
       ON ud.UserDocumentTypeID = udt.UserDocumentTypeID
GROUP  BY udt.Name
ORDER  BY DocumentCount DESC;
```

```sql
-- Find all affiliated approval documents pending review
SELECT ud.*
FROM   Apex.UserDocument ud WITH (NOLOCK)
WHERE  ud.UserDocumentTypeID = 5; -- AFFILIATED_APPROVAL
```

---

## 6. Data Quality Notes

- Name values are UPPERCASE with underscores, consistent with `Dictionary.DocumentType`; do not normalise case.
- `ID_DOCUMENT` (ID 2) stores the KYC photo ID at the profile level, while `Dictionary.DocumentType` classifies the same types of documents when submitted as part of a formal CIP investigation — two different storage locations for related but distinct purposes.
- `AFFILIATED_APPROVAL` (ID 5) relates to the `AffiliatedApprovalRequired` error (ApexValidationError ID 38) and state (State ID 36–37); these documents are collected specifically for affiliated-person compliance.
- `OTHER` (ID 6) should be monitored; high volume in this category may indicate a need for a new specific type.
- `varchar(50)` is used; all values are ASCII-safe.

---

## 7. Change History

| Date | Change |
|---|---|
| 2026-04-14 | Initial documentation created; 6 rows verified against live data. |

---

## 8. Related Objects

| Object | Type | Relationship |
|---|---|---|
| Apex.UserDocument | Table | Stores each uploaded document file with its type, keyed to this dictionary. |
| Dictionary.DocumentType | Table | Related but distinct: classifies documents submitted specifically as part of CIP investigations rather than general user profile documents. |
| Dictionary.CustomerType | Table | The customer type (e.g., IRA) may mandate specific document types such as IRA_DEPOSIT_SLIP. |

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Documentation generated 2026-04-14 — USABroker · Dictionary schema*
