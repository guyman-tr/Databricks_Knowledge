# Dictionary.IdentificationType

> Lookup table defining the types of government-issued identification documents accepted for affiliate KYC (Know Your Customer) verification.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | IdentificationTypeID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK) |

---

## 1. Business Meaning

This table enumerates the types of official identification documents that affiliates can submit for identity verification during onboarding or compliance reviews. Each entry represents a nationally or internationally recognized form of ID.

The identification type system supports regulatory KYC requirements - affiliate platforms must verify the identity of their partners to comply with anti-money laundering (AML) and financial regulations. Without this table, there would be no standardized classification of document types.

Rows are static reference data. The `IdentificationTypeID` is referenced by `dbo.tblaff_Affiliates.IdentificationTypeID` via an explicit foreign key, paired with `IdentificationNumber` to store the actual document number.

---

## 2. Business Logic

### 2.1 Regional Document Types

**What**: Different identification types correspond to region-specific government documents.

**Columns/Parameters Involved**: `IdentificationTypeID`, `IdentificationTypeName`

**Rules**:
- IDs 1-2 (Passport, ID Card) are universally accepted across all jurisdictions
- IDs 3-8 are country-specific: Codice Fiscale (Italy), Det Centrale Personregister (Denmark), Social Insurance Number (Canada), Medicare Number (Australia), Social Security Number (US)
- The affiliate's country of residence determines which identification types are valid for their account

---

## 3. Data Overview

| IdentificationTypeID | IdentificationTypeName | Meaning |
|---|---|---|
| 1 | Passport | International travel document - universally accepted for KYC across all jurisdictions. Most common choice for non-domestic affiliates |
| 2 | ID Card | Government-issued national identity card - accepted in jurisdictions where national ID cards are standard (EU, many Asian countries) |
| 3 | National Insurance Number | UK National Insurance Number (NINO) - used for UK-based affiliates as a supplementary verification alongside passport/ID |
| 4 | Codice Fiscale | Italian fiscal code - a unique alphanumeric identifier assigned to all Italian residents for tax purposes |
| 5 | Det Centrale Personregister | Danish Central Person Register (CPR) number - the civil registration number used in Denmark |
| 6 | Social Insurance Number | Canadian Social Insurance Number (SIN) - used for Canadian affiliates for tax reporting purposes |
| 7 | Medicare Number | Australian Medicare card number - used as a supplementary form of ID for Australian affiliates |
| 8 | Social Security Number | US Social Security Number (SSN) - required for US-based affiliates for IRS tax reporting (W-9) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | IdentificationTypeID | int | NO | - | VERIFIED | Primary key identifying the document type. Static enumeration: 1=Passport, 2=ID Card, 3=National Insurance Number (UK), 4=Codice Fiscale (Italy), 5=Det Centrale Personregister (Denmark), 6=Social Insurance Number (Canada), 7=Medicare Number (Australia), 8=Social Security Number (US). Referenced by dbo.tblaff_Affiliates.IdentificationTypeID via explicit FK. |
| 2 | IdentificationTypeName | nvarchar(50) | NO | - | VERIFIED | Human-readable name of the identification document type. Displayed in affiliate profile forms and compliance review screens. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_Affiliates | IdentificationTypeID | FK | Classifies which type of government ID the affiliate submitted for KYC verification |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table | FK constraint on IdentificationTypeID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED PK | IdentificationTypeID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all identification types
```sql
SELECT IdentificationTypeID, IdentificationTypeName
FROM Dictionary.IdentificationType WITH (NOLOCK)
ORDER BY IdentificationTypeID
```

### 8.2 Find affiliates with their ID type
```sql
SELECT a.AffiliateID, a.LoginName, it.IdentificationTypeName, a.IdentificationNumber
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
LEFT JOIN Dictionary.IdentificationType it WITH (NOLOCK) ON a.IdentificationTypeID = it.IdentificationTypeID
WHERE a.IdentificationTypeID IS NOT NULL
```

### 8.3 Count affiliates per identification type
```sql
SELECT it.IdentificationTypeName, COUNT(*) AS AffiliateCount
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
JOIN Dictionary.IdentificationType it WITH (NOLOCK) ON a.IdentificationTypeID = it.IdentificationTypeID
GROUP BY it.IdentificationTypeName
ORDER BY AffiliateCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.IdentificationType | Type: Table | Source: fiktivo/Dictionary/Tables/Dictionary.IdentificationType.sql*
