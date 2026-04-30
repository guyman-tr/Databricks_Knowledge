# Customer.GetDocumentTypes_JUNKYulia0325

> Returns a customer's KYC document status summary: classified non-expired document type IDs plus latest passport and utility document flags (presence, expiry, type); a temporary working procedure created by Yulia in March 2025.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid (global customer ID to check) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetDocumentTypes_JUNKYulia0325 is a KYC (Know Your Customer) document status inquiry procedure. Given a GCID, it returns a summary of the customer's KYC document state: which document types have been submitted and are still valid (non-expired), and whether the customer has a current passport-type document and utility bill on record.

The "JUNK" prefix and "Yulia0325" suffix indicate this is a temporary working or exploratory procedure created by Yulia in March 2025. It may have been created for a specific investigation, data migration, or feature proof-of-concept rather than as a permanent production API. However, it contains non-trivial business logic around KYC document classification that reflects the actual new-KYC document workflow.

The procedure distinguishes two document kinds:
- **Passport-type**: newkyc-passport, newkyc-ie-passport, newkyc-idCard, newkyc-ie-idCard, newkyc-visa
- **Utility**: newkyc-bill, newkyc-ie-bill (proof of address)

---

## 2. Business Logic

### 2.1 Non-Expired Document Type Aggregation

**What**: Collects all valid (non-expired) document type IDs for the customer into a comma-delimited string.

**Columns/Parameters Involved**: `@gcid`, `ClassifiedDocumentTypes`, `ExpiryDate`, `MaxAgeInMonths`, `IssueDate`

**Rules**:
- Joins BackOffice.CustomerDocument -> Customer.CustomerStatic -> BackOffice.CustomerDocumentToDocumentType -> Dictionary.DocumentType
- Validity check: ExpiryDate > GETUTCDATE() OR (ExpiryDate IS NULL AND DATEDIFF(MONTH, IssueDate, GETUTCDATE()) <= MaxAgeInMonths)
- When ExpiryDate is NULL, the document is considered valid if it was issued within MaxAgeInMonths months
- Result: comma-delimited string of DocumentTypeIDs (via STRING_AGG), or empty string if none
- Rejected documents (DocumentTypeID = 6) are not explicitly excluded here (only in the CTE below)

### 2.2 Latest Passport and Utility Document Status

**What**: Determines whether the customer has a current passport-type and utility document on file.

**Columns/Parameters Involved**: `HasUtilityDocument`, `UtilityExpired`, `UtilityDocumentTypeID`, `HasPassportDocument`, `PassportExpired`, `PassportDocumentTypeID`

**Rules**:
- CTE `LastCustomerDocument`: groups by CID + DocKind (utility or passport), takes MAX DocumentID (latest document)
- DocKind logic: if Comment = 'newkyc-bill' or 'newkyc-ie-bill' -> 'utility'; else -> 'passport'
- Only considers comments: 'newkyc-bill', 'newkyc-ie-bill', 'newkyc-passport', 'newkyc-ie-passport', 'newkyc-idCard', 'newkyc-ie-idCard', 'newkyc-visa' (new KYC workflow documents only)
- Excludes DocumentTypeID = 6 (rejected) from the CTE join condition
- Expired check: ExpiryDate < GETUTCDATE() OR (ExpiryDate IS NULL AND IssueDate is older than MaxAgeInMonths)
- OUTER APPLY: pivots the 'utility' and 'passport' rows into columns
- HasDocument: 1 if DocumentID > 0, 0 otherwise
- TOP 1 on final SELECT: returns one summary row per GCID

**Diagram**:
```
newkyc-bill / newkyc-ie-bill     -> DocKind = 'utility'
newkyc-passport / newkyc-ie-passport / newkyc-idCard / newkyc-ie-idCard / newkyc-visa -> DocKind = 'passport'

Result:
  HasUtilityDocument: 1=utility doc on file, 0=none
  UtilityExpired: 1=expired, 0/NULL=valid
  HasPassportDocument: 1=passport/ID on file, 0=none
  PassportExpired: 1=expired, 0/NULL=valid
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | INT | NO | - | CODE-BACKED | Global Customer ID. All document lookups are filtered through Customer.CustomerStatic.GCID to resolve to actual CIDs. |

**Output result set:**

| Column | Source | Business Meaning |
|--------|--------|-----------------|
| CID | LastCustomerDocument CTE | CID of the customer (resolved from GCID via CustomerStatic) |
| ClassifiedDocumentTypes | STRING_AGG(DocumentTypeID) | Comma-delimited list of non-expired DocumentTypeIDs for this customer (e.g., '1,3,7'). Empty string if no valid documents. |
| HasUtilityDocument | OUTER APPLY (utility) | 1 = customer has a utility bill (proof of address) on file; 0 = none |
| UtilityExpired | OUTER APPLY (utility) | 1 = most recent utility document is expired; NULL/0 = still valid |
| UtilityDocumentTypeID | OUTER APPLY (utility) | DocumentTypeID of the most recent utility document |
| HasPassportDocument | OUTER APPLY (passport) | 1 = customer has a passport/ID card on file; 0 = none |
| PassportExpired | OUTER APPLY (passport) | 1 = most recent passport/ID is expired; NULL/0 = still valid |
| PassportDocumentTypeID | OUTER APPLY (passport) | DocumentTypeID of the most recent passport/ID document |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.CustomerStatic | JOIN (bridge) | Resolves GCID to CID for BackOffice.CustomerDocument lookup |
| CID | BackOffice.CustomerDocument | Read | Source of KYC document submissions |
| DocumentID | BackOffice.CustomerDocumentToDocumentType | JOIN | Links documents to their type classifications |
| DocumentTypeID | Dictionary.DocumentType | JOIN (lookup) | Provides MaxAgeInMonths for expiry calculation |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase (JUNK procedure - likely called for ad-hoc analysis only).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetDocumentTypes_JUNKYulia0325 (procedure)
├── Customer.CustomerStatic (table)
├── BackOffice.CustomerDocument (table - cross-schema)
├── BackOffice.CustomerDocumentToDocumentType (table - cross-schema)
└── Dictionary.DocumentType (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Resolves GCID -> CID for filtering |
| BackOffice.CustomerDocument | Table | Source of customer KYC document submissions |
| BackOffice.CustomerDocumentToDocumentType | Table | Links documents to their DocumentTypeIDs |
| Dictionary.DocumentType | Table | Provides MaxAgeInMonths for age-based expiry calculation |

### 6.2 Objects That Depend On This

No dependents found (JUNK/temporary procedure).

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DocumentTypeID <> 6 filter | Business rule | DocumentTypeID=6 = Rejected; excluded from CTE document classification |
| New-KYC comments filter | Scope | Only 'newkyc-*' document comments are analyzed; legacy KYC documents are excluded |
| TOP 1 on final SELECT | Result cap | Returns one summary row even if GCID maps to multiple CIDs |
| SET NOCOUNT ON | Performance | Suppresses row-count messages |

---

## 8. Sample Queries

### 8.1 Get KYC document status for a customer by GCID

```sql
EXEC Customer.GetDocumentTypes_JUNKYulia0325 @gcid = 9876543
```

### 8.2 Check document validity window for document types

```sql
SELECT DocumentTypeID, Name, MaxAgeInMonths
FROM Dictionary.DocumentType WITH (NOLOCK)
ORDER BY DocumentTypeID
```

### 8.3 Check raw customer documents for a GCID

```sql
SELECT cd.DocumentID, cd.Comment, cdd.DocumentTypeID, cdd.ExpiryDate, cdd.IssueDate
FROM BackOffice.CustomerDocument cd WITH (NOLOCK)
JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cd.CID = cs.CID
LEFT JOIN BackOffice.CustomerDocumentToDocumentType cdd WITH (NOLOCK) ON cd.DocumentID = cdd.DocumentID
WHERE cs.GCID = 9876543
ORDER BY cd.DocumentID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetDocumentTypes_JUNKYulia0325 | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetDocumentTypes_JUNKYulia0325.sql*
