# Dictionary.DocumentType

**Schema:** Dictionary
**Table:** DocumentType
**Database:** USABroker
**Last Reviewed:** 2026-04-14

---

## 1. Business Meaning

`Dictionary.DocumentType` is a static reference table that enumerates the categories of identity and compliance documents that can be submitted as part of a CIP (Customer Identification Program) investigation for a brokerage account. These document types reflect the identity-verification requirements imposed by US anti-money-laundering (AML) and KYC regulations, particularly FinCEN's CIP rules under the Bank Secrecy Act.

When a user's identity cannot be verified automatically through the Sketch CIP pipeline, a manual investigation is opened and one or more supporting documents must be collected. The `DocumentType` code recorded in `Apex.InvestigationDocument` tells compliance reviewers what kind of document was uploaded so they can assess its validity for CIP purposes.

The table includes primary identity documents (driver's licence, passport, state ID, military ID), Social Security Number evidence documents (SSN card, SSA letter, IRS ITIN letter), and broader compliance document categories (CDD document, all passing CIP results).

---

## 2. Table Elements

| Column | Data Type | Nullable | PK | Description |
|---|---|---|---|---|
| DocumentTypeID | int | NOT NULL | Yes | Stable numeric identifier for the document category. |
| Name | varchar(50) | NOT NULL | No | Uppercase underscore-delimited code that identifies the document class in application logic and reporting. |

**Constraints:**
- `PK_DocumentType` — clustered primary key on `DocumentTypeID`

---

## 3. Data Overview

10 rows as of 2026-04-14.

| DocumentTypeID | Name | Meaning |
|---|---|---|
| 1 | DRIVERS_LICENSE | A government-issued driver's licence — a primary photo ID accepted for identity verification. |
| 2 | STATE_ID_CARD | A state-issued non-driver identification card — an alternative government-issued photo ID. |
| 3 | PASSPORT | A valid passport (domestic or foreign) providing government-verified identity and nationality information. |
| 4 | MILITARY_ID | A US military identification card issued to active-duty or reserve service members. |
| 5 | SSN_CARD | The physical Social Security card issued by the SSA, used to verify the user's SSN. |
| 6 | SSA_LETTER | An official letter from the Social Security Administration confirming the user's SSN and identity. |
| 7 | IRS_ITIN_LETTER | An IRS-issued letter confirming assignment of an Individual Taxpayer Identification Number (ITIN) for non-SSN holders. |
| 8 | OTHER_GOVERNMENT_ID | Any other government-issued identification document not covered by the specific categories above. |
| 9 | CDD_DOCUMENT | A Customer Due Diligence document collected as part of enhanced due diligence (EDD) procedures. |
| 10 | ALL_PASSING_CIP_RESULTS | A compiled record of all CIP checks that passed for the user, used as a consolidated evidence artefact. |

---

## 4. Relationships

### Referenced by (Foreign Keys into this table)

| Referencing Table | Referencing Column | Notes |
|---|---|---|
| Apex.InvestigationDocument | DocumentTypeID | Each document uploaded as part of a CIP investigation references a type from this table. |

### References to other tables

This table has no foreign key dependencies; it is a terminal reference (lookup-only) table.

---

## 5. Common Query Patterns

```sql
-- Count investigation documents submitted by type
SELECT dt.Name AS DocumentType,
       COUNT(*) AS DocumentCount
FROM   Apex.InvestigationDocument id WITH (NOLOCK)
JOIN   Dictionary.DocumentType dt WITH (NOLOCK)
       ON id.DocumentTypeID = dt.DocumentTypeID
GROUP  BY dt.Name
ORDER  BY DocumentCount DESC;
```

```sql
-- Find all investigations where a passport was submitted
SELECT id.*
FROM   Apex.InvestigationDocument id WITH (NOLOCK)
WHERE  id.DocumentTypeID = 3; -- PASSPORT
```

---

## 6. Data Quality Notes

- Name values are UPPERCASE with underscores, matching the Apex API document-type codes; do not normalise the case.
- IDs 5–7 (SSN_CARD, SSA_LETTER, IRS_ITIN_LETTER) are specifically for SSN/ITIN verification evidence; they complement rather than replace photo ID.
- ID 9 (CDD_DOCUMENT) is used in enhanced due diligence flows that go beyond standard CIP.
- ID 10 (ALL_PASSING_CIP_RESULTS) is a synthetic document type used when a bundle of results is stored together.
- `varchar(50)` is sufficient for all current names; all are ASCII.

---

## 7. Change History

| Date | Change |
|---|---|
| 2026-04-14 | Initial documentation created; 10 rows verified against live data. |

---

## 8. Related Objects

| Object | Type | Relationship |
|---|---|---|
| Apex.InvestigationDocument | Table | Stores the actual document records for CIP investigations, keyed to this dictionary. |
| Dictionary.UserDocumentType | Table | Related but distinct: classifies documents uploaded by users to their profile (signatures, ID images) rather than CIP-specific investigation documents. |
| Dictionary.CustomerType | Table | The customer type may influence which document types are required for CIP. |

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Documentation generated 2026-04-14 — USABroker · Dictionary schema*
