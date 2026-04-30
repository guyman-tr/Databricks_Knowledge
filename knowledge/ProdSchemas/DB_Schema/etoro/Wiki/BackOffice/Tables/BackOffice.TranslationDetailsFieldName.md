# BackOffice.TranslationDetailsFieldName

> Registry of field names that can be extracted from customer identity documents during KYC data translation, scoped by document type.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | FieldNameID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (1 clustered PK) |

---

## 1. Business Meaning

BackOffice.TranslationDetailsFieldName defines the schema of extractable data fields from KYC documents. It acts as a controlled vocabulary for BackOffice.CustomerTranslationDetails, specifying which named fields (Address, First Name, Date of Birth, etc.) can be recorded when BackOffice agents or automated systems extract data from scanned identity documents.

Without this table, the CustomerTranslationDetails extraction system would lack a standardized field registry, making it impossible to consistently capture and compare document data (e.g., confirming the address on a Proof of Address document matches the customer's registered address). The table links fields to specific document types (DocumentTypeID) or leaves them unscoped (NULL = applicable to any document type).

This is a static configuration table with 11 rows representing the complete set of extractable fields. No dedicated management procedures exist for it - rows are managed via direct DML or deployment scripts.

---

## 2. Business Logic

### 2.1 Document-Scoped vs. Universal Fields

**What**: Each field is either specific to one document type or applicable across all document types.

**Columns Involved**: `FieldName`, `DocumentTypeID`

**Rules**:
- DocumentTypeID=1 (Proof of Address): Address, Building Number, City - address-specific fields extracted from utility bills, bank statements
- DocumentTypeID=2 (Proof of Identity): First Name, Last Name, Middle Name - identity-specific fields from passports and national IDs
- DocumentTypeID=NULL: Comment, Country, Date of Birth, Expiry Date, Issue Date - common fields applicable to any document type

---

## 3. Data Overview

| FieldNameID | FieldName | DocumentTypeID | Meaning |
|-------------|-----------|----------------|---------|
| 1 | Address | 1 (Proof of Address) | Street address line extracted from POA document - used to verify customer's registered address against submitted document |
| 4 | First Name | 2 (Proof of Identity) | First name from passport/ID - verified against customer registration data |
| 6 | Comment | NULL | Free-text comment applicable to any document type - BackOffice agent notes on the extraction |
| 9 | Date Of Birth | NULL | DOB extracted from any identity document - cross-checked against customer's registration DOB |
| 10 | Expiry Date | NULL | Document expiry date - triggers re-verification workflow when document expires |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FieldNameID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-generated identifier for the field. PK referenced by BackOffice.CustomerTranslationDetails.FieldNameID. 11 rows (complete set). |
| 2 | FieldName | varchar(255) | NO | - | CODE-BACKED | Human-readable field label displayed in the BackOffice UI document translation section. Values: Address, Building Number, City, First Name, Last Name, Middle Name, Comment, Country, Date Of Birth, Expiry Date, Issue Date. |
| 3 | DocumentTypeID | int | YES | - | VERIFIED | FK to Dictionary.DocumentType. When set, restricts this field to documents of that type only. NULL = universal field applicable to any document type. 1=Proof of Address (address fields), 2=Proof of Identity (name fields). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DocumentTypeID | Dictionary.DocumentType | FK (WITH CHECK) | Scopes the field to a specific document category |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CustomerTranslationDetails | FieldNameID | FK | Each extracted data point references its field definition here |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.TranslationDetailsFieldName (table)
- FK target: Dictionary.DocumentType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.DocumentType | Table | FK constraint on DocumentTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerTranslationDetails | Table | FieldNameID FK - stores extracted field values |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BackOffice_TranslationDetailsFieldName | CLUSTERED PK | FieldNameID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (unnamed FK) | FK | DocumentTypeID -> Dictionary.DocumentType(DocumentTypeID) |

---

## 8. Sample Queries

### 8.1 Get all fields with their document type names
```sql
SELECT
    tdfn.FieldNameID,
    tdfn.FieldName,
    ISNULL(dt.Name, 'Universal (any doc type)') AS DocumentType
FROM BackOffice.TranslationDetailsFieldName tdfn WITH (NOLOCK)
LEFT JOIN Dictionary.DocumentType dt WITH (NOLOCK) ON dt.DocumentTypeID = tdfn.DocumentTypeID
ORDER BY tdfn.DocumentTypeID, tdfn.FieldName
```

### 8.2 Get extracted data for a specific customer's documents
```sql
SELECT
    cd.DocumentID,
    cd.DisplayName AS DocumentName,
    tdfn.FieldName,
    ctd.FieldValue
FROM BackOffice.CustomerTranslationDetails ctd WITH (NOLOCK)
JOIN BackOffice.TranslationDetailsFieldName tdfn WITH (NOLOCK) ON tdfn.FieldNameID = ctd.FieldNameID
JOIN BackOffice.CustomerDocumentToDocumentType cdd WITH (NOLOCK) ON cdd.DocToDocTypeID = ctd.DocToDocTypeID
JOIN BackOffice.CustomerDocument cd WITH (NOLOCK) ON cd.DocumentID = cdd.DocumentID
WHERE cd.CID = 12345  -- replace with target CID
ORDER BY cd.DateAdded DESC, tdfn.FieldName
```

### 8.3 Get all POI name fields extracted for a customer
```sql
SELECT
    cd.DisplayName AS DocumentName,
    tdfn.FieldName,
    ctd.FieldValue,
    cd.DateAdded
FROM BackOffice.CustomerTranslationDetails ctd WITH (NOLOCK)
JOIN BackOffice.TranslationDetailsFieldName tdfn WITH (NOLOCK) ON tdfn.FieldNameID = ctd.FieldNameID
JOIN BackOffice.CustomerDocumentToDocumentType cdd WITH (NOLOCK) ON cdd.DocToDocTypeID = ctd.DocToDocTypeID
JOIN BackOffice.CustomerDocument cd WITH (NOLOCK) ON cd.DocumentID = cdd.DocumentID
WHERE cd.CID = 12345
  AND tdfn.DocumentTypeID = 2  -- Proof of Identity
ORDER BY cd.DateAdded DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.9/10 (Elements: 10.0/10, Logic: 8.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.TranslationDetailsFieldName | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.TranslationDetailsFieldName.sql*
