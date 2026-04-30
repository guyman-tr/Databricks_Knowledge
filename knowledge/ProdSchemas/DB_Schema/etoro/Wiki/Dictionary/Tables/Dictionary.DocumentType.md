# Dictionary.DocumentType

> Lookup table defining the 20 types of identity and verification documents accepted by eToro for KYC/AML compliance.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | DocumentTypeID (INT, CLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.DocumentType classifies the identity documents that users upload as part of Know Your Customer (KYC) and Anti-Money Laundering (AML) verification processes. eToro, as a regulated financial entity, is required to verify user identities before enabling trading and withdrawals.

The MaxAgeInMonths column enforces document freshness requirements — certain documents (like utility bills for proof of address) must be recent, while others (like passports) remain valid for their full term. This prevents users from submitting outdated documents that may no longer reflect their current identity or address.

DocumentTypeID is referenced by the customer document upload system and compliance verification workflows.

---

## 2. Business Logic

### 2.1 Document Freshness Enforcement

**What**: Some document types expire based on MaxAgeInMonths, requiring fresh uploads for ongoing compliance.

**Columns/Parameters Involved**: `DocumentTypeID`, `MaxAgeInMonths`

**Rules**:
- MaxAgeInMonths=NULL: Document has no freshness requirement (e.g., passport, national ID)
- MaxAgeInMonths=3: Document must be from the last 3 months (e.g., utility bills, bank statements for proof of address)
- MaxAgeInMonths=6: Document must be from the last 6 months (e.g., some official statements)
- Documents exceeding MaxAgeInMonths are rejected during compliance review, requiring the user to upload a newer copy

---

## 3. Data Overview

| DocumentTypeID | Name | MaxAgeInMonths | Meaning |
|---|---|---|---|
| 1 | Passport | NULL | Government-issued passport — primary ID document. No expiry enforcement (valid until passport expiration). Accepted globally. |
| 3 | National Identity Card | NULL | Government-issued national ID card. No expiry enforcement. May not be available in all jurisdictions (e.g., US/UK). |
| 6 | Utility Bill | 3 | Electricity, water, gas, or internet bill — proof of address. Must be from the last 3 months to ensure current address. |
| 9 | Bank Statement | 3 | Official bank statement — proof of address AND proof of funds. Must be from the last 3 months. Used when utility bills are unavailable. |
| 16 | Selfie | NULL | Photograph of the user for facial comparison against submitted ID. No age requirement. Used as an additional verification layer against identity fraud. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DocumentTypeID | int | NO | - | CODE-BACKED | Primary key identifying the document type category. Values range from 1 to 20. Each ID maps to a specific kind of identity or verification document. See [Document Type](_glossary.md#document-type). (Dictionary.DocumentType) |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Document type label. Used in the document upload UI, compliance review screens, and regulatory reports. |
| 3 | MaxAgeInMonths | int | YES | - | CODE-BACKED | Maximum permitted age of the document in months from its issue date. NULL=no freshness requirement (document valid until its own expiration). Non-NULL=document must have been issued within this many months of upload. Used by compliance validation to reject stale documents. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer document tables | DocumentTypeID | Implicit Lookup | Classifies uploaded documents |

---

## 6. Dependencies

This object has no dependencies.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DDTDTI | CLUSTERED PK | DocumentTypeID ASC | - | - | Active |

---

## 8. Sample Queries

### 8.1 List all document types with freshness requirements
```sql
SELECT DocumentTypeID, Name, MaxAgeInMonths
FROM [Dictionary].[DocumentType] WITH (NOLOCK) ORDER BY DocumentTypeID;
```

### 8.2 Find document types requiring recent uploads
```sql
SELECT Name, MaxAgeInMonths
FROM [Dictionary].[DocumentType] WITH (NOLOCK)
WHERE MaxAgeInMonths IS NOT NULL ORDER BY MaxAgeInMonths;
```

---

*Generated: 2026-03-13 | Quality: 7.8/10*
*Object: Dictionary.DocumentType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.DocumentType.sql*
