# Dictionary.DocumentClassification

> Lookup table defining 73 specific document sub-classifications within each KYC document type — mapping granular document names (Passport, Utility Bill, Bank Statement, etc.) to their parent document types with optional age limits.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | DocumentClassificationID (PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

The KYC document management system needs to classify uploaded documents at a granular level beyond just the broad document type (POI, POA, etc.). This table provides 73 specific classifications — for example, within POI (DocumentTypeID=2), documents can be classified as Passport, ID, Driving License, Electoral Card, Residence Permit, SSN Card, or US Visa. Within POA (DocumentTypeID=1), they can be Utility Bill, Bank Statement, Phone Bill, Internet Bill, Government Issued, etc.

Without this table, the system could only identify documents by their broad type. The granular classification enables document-specific validation rules (e.g., driving licenses used as POA must be ≤24 months old per MaxAgeInMonths), automated document routing to appropriate review queues, and compliance reporting that distinguishes between document sub-types.

The table is extensively referenced by BackOffice document management procedures: `BackOffice.AddDocumentClassification`, `BackOffice.UpdateDocumentClassification`, `BackOffice.RemoveDocumentClassification`, `BackOffice.GetDocumentClassifications`, `BackOffice.GetAllDocumentClassifications`, `BackOffice.GetDocumentMaxAge`, and related mass verification procedures.

---

## 2. Business Logic

### 2.1 Document Type Hierarchy

**What**: Each classification belongs to exactly one parent document type, forming a two-level hierarchy.

**Columns/Parameters Involved**: `DocumentClassificationID`, `Name`, `DocumentTypeID`, `MaxAgeInMonths`

**Rules**:
- DocumentTypeID links to Dictionary.DocumentType — grouping classifications under POI (2), POA (1), Corporate (5), Source of Funds (7), Bank Details (8), Compliance (9), Financial Reference (10), Marriage/Relation (11), T&C versions (12, 14), etc.
- MaxAgeInMonths applies only to specific classifications — e.g., Driving License POA (40) and StateID (41) have MaxAgeInMonths=24, meaning documents older than 24 months are automatically rejected
- Most classifications have NULL MaxAgeInMonths, meaning no document age restriction applies

### 2.2 KYC Document Sub-Type Groupings

**What**: Classifications group into functional categories serving different compliance needs.

**Columns/Parameters Involved**: `DocumentClassificationID`, `DocumentTypeID`

**Rules**:
- **Identity (DocumentTypeID=2)**: Passport, ID, Driving License, Electoral Card, Other Gov Issued, Residence Permit, SSN Card, US Visa (IDs 1-5, 46, 64-65)
- **Address (DocumentTypeID=1)**: Utility Bill, Bank Statement, Phone Bill, Driving License POA, StateID, Internet Bill, Gov Issued, ID POA, Residence Permit POA, Title Deed, Tenancy Contract (IDs 6-9, 40-41, 51-52, 66-67, 69-70)
- **Corporate (DocumentTypeID=5)**: Legal, Financials, Translation, Corporate Approval (IDs 14-17, 56)
- **Compliance (DocumentTypeID=9)**: Joint Account, Power of Attorney, APU, PEP, Ex Pep, Waiver, FTF Form, Corporate Questionnaire, Affiliate Questionnaire, Screening Evidence, AML Approval, etc. (IDs 18-27, 47-48, 53-55)

---

## 3. Data Overview

| DocumentClassificationID | Name | DocumentTypeID | MaxAgeInMonths | Meaning |
|---|---|---|---|---|
| 1 | Passport | 2 | NULL | Government-issued passport submitted as Proof of Identity — the most universally accepted POI document for KYC verification worldwide |
| 6 | Utility Bill | 1 | NULL | Gas, electric, or water bill submitted as Proof of Address — must show the customer's full name and residential address, typically within 3 months |
| 40 | Driving License POA | 1 | 24 | Driving license submitted as Proof of Address (not POI) — accepted in some jurisdictions where the license shows the residential address. Limited to 24 months old |
| 22 | PEP | 9 | NULL | Politically Exposed Person compliance document — uploaded when enhanced due diligence identifies the customer as a current or former PEP, requiring additional documentation |
| 71 | DA | 25 | NULL | Document classification under type 25 — appears to be a newer classification category added to support additional document workflows |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DocumentClassificationID | int | NO | - | VERIFIED | Primary key identifying the specific document classification. 73 values from 1 (Passport) to 73. Referenced by BackOffice.CustomerDocumentToDocumentType.DocumentClassificationID and multiple BackOffice procedures. |
| 2 | Name | varchar(50) | YES | - | VERIFIED | Human-readable document sub-type name (Passport, Utility Bill, Bank Statement, etc.). Displayed in the BackOffice document review UI. Nullable but all rows have values. |
| 3 | DocumentTypeID | int | YES | - | VERIFIED | FK to Dictionary.DocumentType — the parent document type this classification belongs to. Groups classifications into POI (2), POA (1), Corporate (5), Source of Funds (7), Bank Details (8), Compliance (9), etc. See [Document Type](Dictionary.DocumentType.md). |
| 4 | MaxAgeInMonths | int | YES | - | CODE-BACKED | Maximum age in months for this document to be accepted. NULL = no age limit. Only Driving License POA (40) and StateID (41) have values (24 months). Used by BackOffice.GetDocumentMaxAge to enforce document freshness rules. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DocumentTypeID | Dictionary.DocumentType | FK | Links to the parent document type (POI, POA, Corporate, etc.) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CustomerDocumentToDocumentType | DocumentClassificationID | Implicit | Stores the classification assigned to each uploaded customer document |
| BackOffice.AddDocumentClassification | @DocumentClassificationID | Implicit | Adds a new classification to a customer's document |
| BackOffice.UpdateDocumentClassification | @DocumentClassificationID | Implicit | Updates a document's classification |
| BackOffice.RemoveDocumentClassification | @DocumentClassificationID | Implicit | Removes a classification from a document |
| BackOffice.GetDocumentClassifications | DocumentClassificationID | JOIN | Returns classifications for a specific document type |
| BackOffice.GetAllDocumentClassifications | DocumentClassificationID | JOIN | Returns all classifications |
| BackOffice.GetDocumentMaxAge | MaxAgeInMonths | JOIN | Returns the max age for a specific classification |
| BackOffice.GetAllUserDocumentClassifications | DocumentClassificationID | JOIN | Returns all classifications for a user's documents |
| BackOffice.UpdateDocumentClassificationsExpiryDate | DocumentClassificationID | JOIN | Updates expiry dates based on classification age limits |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.DocumentClassification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.DocumentType | Table | FK target — parent document type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocumentToDocumentType | Table | References — per-document classification |
| BackOffice.AddDocumentClassification | Procedure | Writer — assigns classifications |
| BackOffice.UpdateDocumentClassification | Procedure | Writer — updates classifications |
| BackOffice.GetDocumentClassifications | Procedure | Reader — retrieves classifications |
| BackOffice.GetAllDocumentClassifications | Procedure | Reader — all classifications |
| BackOffice.GetDocumentMaxAge | Procedure | Reader — age limit lookup |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_DocumentClassification | CLUSTERED | DocumentClassificationID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_Dictionary_DocumentClassification_DocumentTypeID | FK | DocumentTypeID → Dictionary.DocumentType.DocumentTypeID — ensures each classification maps to a valid parent document type |

---

## 8. Sample Queries

### 8.1 List all classifications grouped by document type
```sql
SELECT  dt.DocumentTypeName,
        dc.DocumentClassificationID,
        dc.Name AS Classification,
        dc.MaxAgeInMonths
FROM    Dictionary.DocumentClassification dc WITH (NOLOCK)
        JOIN Dictionary.DocumentType dt WITH (NOLOCK) ON dc.DocumentTypeID = dt.DocumentTypeID
ORDER BY dt.DocumentTypeID, dc.DocumentClassificationID
```

### 8.2 Find classifications with age limits
```sql
SELECT  dc.DocumentClassificationID,
        dc.Name,
        dc.MaxAgeInMonths
FROM    Dictionary.DocumentClassification dc WITH (NOLOCK)
WHERE   dc.MaxAgeInMonths IS NOT NULL
ORDER BY dc.MaxAgeInMonths
```

### 8.3 Show document sub-types for POI
```sql
SELECT  dc.DocumentClassificationID,
        dc.Name AS POI_SubType
FROM    Dictionary.DocumentClassification dc WITH (NOLOCK)
WHERE   dc.DocumentTypeID = 2  -- POI
ORDER BY dc.DocumentClassificationID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 9 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.DocumentClassification | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.DocumentClassification.sql*
