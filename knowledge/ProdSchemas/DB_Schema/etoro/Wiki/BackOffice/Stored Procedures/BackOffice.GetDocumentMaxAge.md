# BackOffice.GetDocumentMaxAge

> Returns the maximum acceptable age (in months) for a KYC document and the reference date type ('issuedate' or 'today') used to evaluate document freshness - drives compliance expiration checks for POI, POA, W-8BEN, and other document types.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (DocumentTypeID, DocumentClassificationID) lookup against Dictionary tables; returns one row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetDocumentMaxAge is the document expiration configuration lookup used by eToro's KYC compliance engine. Given a document type and optional sub-classification, it returns how old a document is allowed to be (`AgeInMonth`) and whether that age is measured from the document's own issue date or from today (`InitDate`).

The procedure implements a three-tier fallback for maximum age: (1) classification-specific override (e.g., Driving License used as POA = 24 months), (2) document type default (e.g., Proof of Address = 36 months), (3) system default of 12 months when neither table has a value configured.

Created February 2019 by Geri Reshef (RD-2504/3055 "US by using POI+POA option expiration logic should change") - originally built to support US-specific changes to how POI+POA combined documents (DocumentTypeID=13) determine their expiration.

**Practical document max ages from live data (2026-03-17):**

| DocumentTypeID | Document Type | MaxAgeInMonths (type level) | Notes |
|---|---|---|---|
| 1 | Proof of Address | 36 | Driving License POA (classif. 40) = 24; StateID (classif. 41) = 24 |
| 2 | Proof of Identity | NULL -> 12 (default) | Uses 'issuedate'; POI expiry from document itself |
| 4 | Authorization Form | 60 | - |
| 5 | Corporate doc | 60 | - |
| 12 | W-8BEN Form | 36 | IRS tax form; 3-year validity |
| 14 | W9 | 36 | IRS tax form; 3-year validity |
| 3,6-11,13,15-25 | Various | NULL -> 12 (default) | - |

---

## 2. Business Logic

### 2.1 Three-Tier MaxAge Fallback

**What**: The COALESCE resolves the applicable max age through three levels, prioritizing the most specific configuration.

**Columns/Parameters Involved**: `@documentType`, `@classificationType`, `ddc.MaxAgeInMonths`, `ddt.MaxAgeInMonths`

**Rules**:
- Level 1: `ddc.MaxAgeInMonths` - classification-specific age (most specific). Only two classification overrides exist: DocumentClassificationID=40 (Driving License POA) = 24 months and DocumentClassificationID=41 (StateID) = 24 months, both reducing POA from 36 to 24 months.
- Level 2: `ddt.MaxAgeInMonths` - document type default. Configured for: POA=36, Authorization Form=60, Corporate doc=60, W-8BEN=36, W9=36. NULL for POI (2), Credit Card (3), Selfie (15), and most other types.
- Level 3: 12 months hard default (COALESCE last resort). Applied to POI, Credit Card, and all types with no configured max age.
- The LEFT JOIN to DocumentClassification uses `@classificationType` - if no matching classification row exists (or @classificationType has no match), `ddc` is NULL and level 1 is skipped automatically.

**Diagram**:
```
COALESCE(ddc.MaxAgeInMonths, ddt.MaxAgeInMonths, 12)
         |                   |                   |
         Classification      Type level          Default
         override            default             12 months
         (if set)            (if set)
```

### 2.2 InitDate - Reference Point for Age Calculation

**What**: The `InitDate` column tells callers which date to use as the start point when computing document age.

**Columns/Parameters Involved**: `ddc.MaxAgeInMonths`, `InitDate`

**Rules**:
- `InitDate = 'issuedate'` when `ddc.MaxAgeInMonths IS NULL` (no classification-level override): Age is measured from the document's own stated issue date (`BackOffice.CustomerDocumentToDocumentType.IssueDate`). Used for POI, POA at type level, and most documents. Meaning: document is invalid if `IssueDate + MaxAgeInMonths < today`.
- `InitDate = 'today'` when `ddc.MaxAgeInMonths IS NOT NULL` (classification-level override exists, e.g., Driving License POA = 24 months): Age is measured backward from today. Meaning: document is invalid if `IssueDate < today - MaxAgeInMonths`.
- The two calculations are mathematically equivalent but differ in which date serves as the anchor. Callers (DocAPI, compliance checks) use this flag to select which date comparison to perform.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @documentType | INT | NO | - | CODE-BACKED | Document type identifier. FK to Dictionary.DocumentType. Values: 1=POA, 2=POI, 4=Authorization Form, 5=Corporate doc, 12=W-8BEN, 14=W9. Drives the type-level MaxAgeInMonths lookup. |
| 2 | @classificationType | INT | NO | - | CODE-BACKED | Document sub-classification identifier. FK to Dictionary.DocumentClassification. Used in LEFT JOIN to check for classification-level age override. If no match exists, classification level is skipped silently. Pass 0 or any non-matching value to skip classification override. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | AgeInMonth | int | NO | - | VERIFIED | Maximum acceptable age of the document in months. Resolved via COALESCE: classification override -> type default -> 12. Examples: POA (no classification) = 36; Driving License POA = 24; POI = 12; Authorization Form = 60; W-8BEN = 36. |
| R2 | InitDate | varchar | NO | - | VERIFIED | Reference date for age calculation. 'issuedate' = measure age from the document's IssueDate field. 'today' = measure age backward from today. Value is 'today' only when a classification-level MaxAgeInMonths override exists. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ddt | Dictionary.DocumentType | SELECT | Type-level MaxAgeInMonths configuration |
| ddc | Dictionary.DocumentClassification | LEFT JOIN | Classification-level MaxAgeInMonths override; joined on (DocumentTypeID, DocumentClassificationID) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from DocAPI compliance engine and BackOffice document validation workflows to determine whether a KYC document has expired.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetDocumentMaxAge (procedure)
├── Dictionary.DocumentType (table - cross-schema)
└── Dictionary.DocumentClassification (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.DocumentType | Table | Primary source; filtered to DocumentTypeID = @documentType; provides type-level MaxAgeInMonths |
| Dictionary.DocumentClassification | Table | LEFT JOIN on (DocumentTypeID = @documentType AND DocumentClassificationID = @classificationType); provides classification-level MaxAgeInMonths override |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DocAPI service | External | READER - calls to determine document expiration threshold before classifying or flagging documents |
| BackOffice compliance engine | External | READER - drives expired document detection and re-upload prompts |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. The LEFT JOIN condition includes both `DocumentTypeID` and `DocumentClassificationID` filters, ensuring the classification override only applies when the classification belongs to the correct document type. COALESCE guarantees a non-NULL result always (12 month floor).

---

## 8. Sample Queries

### 8.1 Get max age for Proof of Identity (no classification)
```sql
EXEC BackOffice.GetDocumentMaxAge @documentType = 2, @classificationType = 0
-- Returns: AgeInMonth=12, InitDate='issuedate'
-- (POI has NULL type-level MaxAgeInMonths -> falls to 12 month default)
```

### 8.2 Get max age for Proof of Address - Driving License (classification override)
```sql
EXEC BackOffice.GetDocumentMaxAge @documentType = 1, @classificationType = 40
-- Returns: AgeInMonth=24, InitDate='today'
-- (Classification 40 = Driving License POA overrides POA type default of 36 months)
```

### 8.3 Get max age for generic POA (no classification override)
```sql
EXEC BackOffice.GetDocumentMaxAge @documentType = 1, @classificationType = 0
-- Returns: AgeInMonth=36, InitDate='issuedate'
-- (Type-level default = 36 months; no classification row matched)
```

### 8.4 Ad-hoc equivalent showing all document type max ages
```sql
SELECT
    ddt.DocumentTypeID,
    ddt.Name AS DocumentType,
    ddt.MaxAgeInMonths AS TypeMaxAge,
    ddc.DocumentClassificationID,
    ddc.Name AS Classification,
    ddc.MaxAgeInMonths AS ClassificationMaxAge,
    COALESCE(ddc.MaxAgeInMonths, ddt.MaxAgeInMonths, 12) AS EffectiveMaxAge,
    IIF(ddc.MaxAgeInMonths IS NULL, 'issuedate', 'today') AS InitDate
FROM Dictionary.DocumentType ddt WITH (NOLOCK)
LEFT JOIN Dictionary.DocumentClassification ddc WITH (NOLOCK)
    ON ddc.DocumentTypeID = ddt.DocumentTypeID
ORDER BY ddt.DocumentTypeID, ddc.DocumentClassificationID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Created February 2019 (RD-2504/3055): "US by using POI+POA option expiration logic should change" by Geri Reshef.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.3/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: SKIPPED | Corrections: 0 applied*
*Object: BackOffice.GetDocumentMaxAge | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetDocumentMaxAge.sql*
