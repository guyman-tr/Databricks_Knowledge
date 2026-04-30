# Dictionary.KYPDocType

> Lookup table defining the types of documents collected during Know Your Partner (KYP) verification for affiliate onboarding.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | DocTypeID (int, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.KYPDocType defines the seven types of identity and verification documents collected during the KYP (Know Your Partner) onboarding process. When a company or individual registers as an affiliate, they must submit specific documents to satisfy regulatory compliance requirements. Each document type has distinct validation rules and acceptance criteria.

Without this table, the compliance system could not classify uploaded documents or enforce which document types are required for different jurisdictions and affiliate categories. Document completeness checks depend on knowing which types have been submitted.

This is static reference data used by the KYP subsystem. The KYP.AffiliateKYPDocs table stores DocTypeID for each document submitted by an affiliate.

---

## 2. Business Logic

### 2.1 KYP Document Classification

**What**: Seven document types organized into identity verification, tax compliance, and business verification categories.

**Columns/Parameters Involved**: `DocTypeID`, `DocTypeName`

**Rules**:
- Identity documents (IDs 1-3): ID_Front, ID_Back, and Passport - standard government-issued identity verification
- Tax documents (IDs 4, 7): Tax Form and 147C IRS Letter - tax identification verification, with the IRS letter specific to US-based affiliates
- Business verification (IDs 5-6): Wallet Screenshot for crypto/payment wallet verification, Company Proof Of Address for corporate affiliates

---

## 3. Data Overview

| DocTypeID | DocTypeName | Meaning |
|---|---|---|
| 1 | ID_Front | Front side of a government-issued identity document (national ID card, driver's license). Required for all individual affiliates regardless of jurisdiction |
| 2 | ID_Back | Back side of the same identity document. Required alongside ID_Front to capture full document details including machine-readable zone |
| 3 | Passport | Full passport document scan. Alternative to ID_Front/ID_Back for international affiliates - accepted in all jurisdictions |
| 4 | Tax Form | Tax registration or identification document (W-8BEN, W-9, local equivalent). Required for tax withholding compliance |
| 5 | Wallet Screenshot | Screenshot of crypto or payment wallet. Used to verify payout destination for affiliates receiving commissions via digital wallets |
| 6 | Company Proof Of Address | Corporate registered address documentation (utility bill, bank statement, or official registration document). Required for corporate affiliates during KYP |
| 7 | 147C IRS Letter | US IRS employer identification verification letter (Form 147C). Required specifically for US-based corporate affiliates to confirm their EIN |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DocTypeID | int | NO | - | VERIFIED | Primary key identifying the KYP document type. Values: 1=ID_Front, 2=ID_Back, 3=Passport, 4=Tax Form, 5=Wallet Screenshot, 6=Company Proof Of Address, 7=147C IRS Letter. See [KYP Doc Type](../../_glossary.md#kyp-doc-type) for full definitions. |
| 2 | DocTypeName | nvarchar(25) | NO | - | VERIFIED | Human-readable label for the document type. Used in KYP admin screens and document upload interfaces. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYP.AffiliateKYPDocs | DocTypeID | Implicit FK | Stores each submitted document with its type classification |
| History.KYPAffiliateKYPDocs | DocTypeID | Implicit FK | Historical snapshot of submitted documents |
| KYP.GetAffiliateData | JOIN | Lookup | Returns document details including type names |
| KYP.UpdateAffiliateData | Parameter | Lookup | Updates document records during KYP review |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYP.AffiliateKYPDocs | Table | Stores DocTypeID for each submitted document |
| History.KYPAffiliateKYPDocs | Table | Historical document records |
| KYP.GetAffiliateData | Stored Procedure | READER - returns KYP document data |
| KYP.UpdateAffiliateData | Stored Procedure | MODIFIER - manages KYP documents |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryKYPDocType | CLUSTERED PK | DocTypeID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all document types
```sql
SELECT DocTypeID, DocTypeName
FROM Dictionary.KYPDocType WITH (NOLOCK)
ORDER BY DocTypeID
```

### 8.2 Check document submission completeness for an affiliate
```sql
SELECT dt.DocTypeID, dt.DocTypeName,
    CASE WHEN d.DocTypeID IS NOT NULL THEN 'Submitted' ELSE 'Missing' END AS Status
FROM Dictionary.KYPDocType dt WITH (NOLOCK)
LEFT JOIN KYP.AffiliateKYPDocs d WITH (NOLOCK) ON dt.DocTypeID = d.DocTypeID AND d.AffiliateID = @AffiliateID
```

### 8.3 Count submitted documents by type across all affiliates
```sql
SELECT dt.DocTypeID, dt.DocTypeName, COUNT(d.DocTypeID) AS SubmissionCount
FROM Dictionary.KYPDocType dt WITH (NOLOCK)
LEFT JOIN KYP.AffiliateKYPDocs d WITH (NOLOCK) ON dt.DocTypeID = d.DocTypeID
GROUP BY dt.DocTypeID, dt.DocTypeName
ORDER BY SubmissionCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.KYPDocType | Type: Table | Source: fiktivo/Dictionary/Tables/Dictionary.KYPDocType.sql*
