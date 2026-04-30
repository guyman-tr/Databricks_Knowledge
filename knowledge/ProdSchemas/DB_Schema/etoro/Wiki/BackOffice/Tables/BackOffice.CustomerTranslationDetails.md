# BackOffice.CustomerTranslationDetails

> Storage for original and translated field values extracted from non-English KYC documents, enabling BackOffice agents to record what a foreign-language document says field by field.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | TranslationID (BIGINT IDENTITY, NC PK) |
| **Partition** | No (stored ON [PRIMARY] filegroup) |
| **Indexes** | 2 active (1 NC PK on TranslationID + 1 UNIQUE CLUSTERED on CID, DocumentToDocumentTypeID, FieldNameID) |

---

## 1. Business Meaning

BackOffice.CustomerTranslationDetails stores the extracted and translated field values for KYC documents that are written in a non-English language. When a customer submits a passport, utility bill, or other identity document in Arabic, Chinese, Russian, or another non-Latin script, BackOffice agents read the document and record both the original (native-language) value and the English translation for each structured field.

The table is tightly scoped: one row per customer (CID) + document classification record (DocumentToDocumentTypeID) + field type (FieldNameID). The 11 field types are defined in BackOffice.TranslationDetailsFieldName and cover addresses (Address, Building Number, City), identity fields (First Name, Last Name, Middle Name), and universal fields (Comment, Country, Date of Birth, Expiry Date, Issue Date). The UNIQUE CLUSTERED INDEX on (CID, DocumentToDocumentTypeID, FieldNameID) enforces this one-row-per-field constraint and is the physical storage order.

The feature was introduced in 2017 (OPS0244 - Translation and Update of Verification Info). As of 2026-03-17 only 87 rows exist across 24 customer accounts, indicating this is a lightly used workflow, likely applied to a small fraction of cases where document translation is required before KYC approval. The companion column `Translated` on BackOffice.CustomerDocumentToDocumentType marks when translations have been recorded for a given classification record.

---

## 2. Business Logic

### 2.1 Upsert Pattern for Translation Recording

**What**: SetCustomerTranslationDetails uses an UPSERT (UPDATE + INSERT) pattern to record translations for all fields in a single call.

**Columns Involved**: `CID`, `DocumentToDocumentTypeID`, `FieldNameID`, `OriginalValue`, `TranslatedValue`, `LastModified`

**Rules**:
- Accepts a `TranslationDetails` TVP (User Defined Table Type) containing one row per field to record.
- For each input row: UPDATE the existing CustomerTranslationDetails row if (CID, DocumentToDocumentTypeID, FieldNameID) already exists - sets OriginalValue, TranslatedValue, LastModified.
- INSERT rows that do not yet exist (anti-join NOT EXISTS check on all 3 key columns).
- OUTPUT parameter @UPDATED is set to 1 on success.
- Wrapped in BEGIN TRAN / COMMIT with THROW error propagation. No partial updates: all rows succeed or the transaction rolls back.

**Diagram**:
```
Agent records translation for document fields
    |
    v
SetCustomerTranslationDetails(@TRANSLATIONDETAILS TVP)
    |
    +--> UPDATE existing rows (CID + DocToDocType + FieldName match)
    |        SET OriginalValue, TranslatedValue, LastModified
    |
    +--> INSERT new rows (no match found)
    |
    v
@UPDATED = 1 (output)
```

### 2.2 Cascaded Deletion on Document Removal

**What**: CustomerTranslationDetails rows are deleted as part of the document deletion cascade.

**Columns Involved**: `DocumentToDocumentTypeID`, `CID`

**Rules**:
- DeleteUserDocument (GDPR right-to-erasure): deletes ALL translation rows for a document in a transaction. First deletes DocumentVendors, then CustomerTranslationDetails (via subquery on DocumentToDocumentTypeID), then CustomerDocumentToDocumentType, then CustomerDocument.
- RemoveDocumentClassification (single classification removal): deletes translation rows for a specific (documentId, classificationId) combination before deleting the classification record itself.
- Both procedures use explicit DELETE (not cascade FK) because the FK from CustomerTranslationDetails to CustomerDocumentToDocumentType is WITH CHECK but has no ON DELETE CASCADE clause in DDL.

---

## 3. Data Overview

| TranslationID | CID | DocumentToDocumentTypeID | FieldNameID | OriginalValue (sample) | TranslatedValue (sample) | Meaning |
|--------------|-----|--------------------------|-------------|------------------------|--------------------------|---------|
| 2 | 16500496 | 960377 | 1 (Address) | "string10000" | "string10000" | Test data - BackOffice test account. Address field. |
| 3 | 16500496 | 960377 | 2 (Building Number) | "125" | "asd" | Building number extracted from POA document. |
| 4 | 16500496 | 960377 | 3 (City) | "Amsterdam" | "asd" | City name from POA document (Amsterdam visible as production-like value). |
| 5 | 16500496 | 960377 | 4 (First Name) | "tes" | "asda" | First name from POI document - test data. |
| 6 | 16500496 | 960377 | 5 (Last Name) | "tes" | "asd" | Last name from POI document - test data. |

87 total rows as of 2026-03-17. All 11 FieldNameIDs appear in the data.

**FieldNameID distribution** (87 rows):

| FieldNameID | FieldName | DocumentTypeID scope | Rows | Pct |
|-------------|-----------|---------------------|------|-----|
| 4 | First Name | POI (2) | 20 | 23.0% |
| 1 | Address | POA (1) | 9 | 10.3% |
| 5 | Last Name | POI (2) | 9 | 10.3% |
| 7 | Country | NULL (universal) | 9 | 10.3% |
| 8 | Date Of Birth | NULL (universal) | 7 | 8.0% |
| 9 | Expiry Date | NULL (universal) | 7 | 8.0% |
| 2 | Building Number | POA (1) | 6 | 6.9% |
| 10 | Issue Date | NULL (universal) | 6 | 6.9% |
| 6 | Comment | NULL (universal) | 5 | 5.7% |
| 11 | Middle Name | POI (2) | 5 | 5.7% |
| 3 | City | POA (1) | 4 | 4.6% |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TranslationID | bigint IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-incrementing surrogate PK. NOT CLUSTERED - the NC PK allows physical storage to be controlled by the separate UNIQUE CLUSTERED INDEX. Range: 2-88 (87 rows; TranslationID=1 is absent, deleted or skipped). BIGINT chosen for future volume growth despite current small size. |
| 2 | CID | int | YES | - | VERIFIED | Customer whose document is being translated. FK (WITH CHECK) to Customer.CustomerStatic(CID). Part of the UNIQUE CLUSTERED INDEX. NULL allowed in DDL but functionally required - all 87 rows have a CID value. 24 distinct customers as of 2026-03-17. |
| 3 | DocumentToDocumentTypeID | int | YES | - | VERIFIED | The specific classification record being translated. FK (WITH CHECK) to BackOffice.CustomerDocumentToDocumentType(DocumentToDocumentTypeID). Part of the UNIQUE CLUSTERED INDEX. Links the translation to the document type context (e.g., a specific POA classification record). 30 distinct values in 87 rows. NULL allowed in DDL but functionally required. |
| 4 | FieldNameID | int | YES | - | VERIFIED | The field within the document being translated. FK (WITH CHECK) to BackOffice.TranslationDetailsFieldName(FieldNameID). Part of the UNIQUE CLUSTERED INDEX. Values 1-11 all appear in data: 1=Address, 2=Building Number, 3=City (POA fields); 4=First Name, 5=Last Name, 11=Middle Name (POI fields); 6=Comment, 7=Country, 8=Date Of Birth, 9=Expiry Date, 10=Issue Date (universal fields). NULL allowed in DDL but functionally required. |
| 5 | OriginalValue | nvarchar(max) | YES | - | VERIFIED | The text as it appears on the physical document in its original language. For non-Latin scripts, this would be the native characters (Arabic, Chinese, Hebrew, etc.) or the transliterated/romanized form as printed. NULL for 14 of 87 rows (16.1%) - cases where the agent recorded a translation but left the original blank. |
| 6 | TranslatedValue | nvarchar(max) | YES | - | VERIFIED | The English translation or normalized form of the OriginalValue. For name fields, the English spelling of a non-Latin name. For address fields, the English address as it appears in the document. For Date of Birth/Issue/Expiry Date fields, the date value in standard format. NULL allowed; no NULL rows observed in current data. |
| 7 | LastModified | datetime | YES | - | CODE-BACKED | Timestamp of the last update to this row, set by the calling application/procedure. No DEFAULT constraint - must be supplied by the caller. SetCustomerTranslationDetails explicitly passes LastModified from the TVP input. Range: 2024-09-04 to 2026-03-04. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (WITH CHECK) | Parent customer account |
| DocumentToDocumentTypeID | BackOffice.CustomerDocumentToDocumentType | FK (WITH CHECK) | The classification record being translated |
| FieldNameID | BackOffice.TranslationDetailsFieldName | FK (WITH CHECK) | The field being translated (controlled vocabulary) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.SetCustomerTranslationDetails | CID, DocumentToDocumentTypeID, FieldNameID | WRITER (upsert) | Primary writer - UPSERT via TranslationDetails TVP |
| BackOffice.GetCustomerTranslationDetails | CID, DocumentToDocumentTypeID | READER | Returns all translation rows for a given document classification |
| BackOffice.DeleteUserDocument | DocumentToDocumentTypeID | DELETER (cascade) | GDPR document erasure - deletes all translations for a document |
| BackOffice.RemoveDocumentClassification | DocumentToDocumentTypeID | DELETER (cascade) | Removes translations when a classification record is deleted |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerTranslationDetails (table)
- FK targets:
  |- Customer.CustomerStatic (table) - customer account
  |- BackOffice.CustomerDocumentToDocumentType (table) - classification record
  |- BackOffice.TranslationDetailsFieldName (table) - field vocabulary
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK on CID |
| BackOffice.CustomerDocumentToDocumentType | Table | FK on DocumentToDocumentTypeID |
| BackOffice.TranslationDetailsFieldName | Table | FK on FieldNameID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.SetCustomerTranslationDetails | Procedure | WRITER - upsert via TVP |
| BackOffice.GetCustomerTranslationDetails | Procedure | READER - retrieves translations for BackOffice UI |
| BackOffice.DeleteUserDocument | Procedure | DELETER - GDPR erasure cascade |
| BackOffice.RemoveDocumentClassification | Procedure | DELETER - cascade on classification removal |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BackOffice_CustomerTranslationDetails | NC PK | TranslationID ASC | - | - | Active (FILLFACTOR=95, DATA_COMPRESSION=PAGE) |
| Idx_BackOffice_CustomerTranslationDetails | UNIQUE CLUSTERED | CID ASC, DocumentToDocumentTypeID ASC, FieldNameID ASC | - | - | Active (FILLFACTOR=95, DATA_COMPRESSION=PAGE) |

The unusual combination of a NON-CLUSTERED PK and a separate UNIQUE CLUSTERED INDEX is intentional: physical storage is ordered by (CID, DocumentToDocumentTypeID, FieldNameID) for efficient per-customer, per-document lookups (the dominant query pattern in GetCustomerTranslationDetails), while the IDENTITY-based PK provides a synthetic row identifier. Both indexes use DATA_COMPRESSION=PAGE, appropriate for the nvarchar(max) columns.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BackOffice_CustomerTranslationDetails | PK | TranslationID uniqueness |
| Idx_BackOffice_CustomerTranslationDetails | UNIQUE | One translation per (CID, DocumentToDocumentTypeID, FieldNameID) - no duplicate field translations for the same document |
| FK on DocumentToDocumentTypeID | FK (WITH CHECK) | References BackOffice.CustomerDocumentToDocumentType |
| FK on FieldNameID | FK (WITH CHECK) | References BackOffice.TranslationDetailsFieldName |
| FK on CID | FK (WITH CHECK) | References Customer.CustomerStatic |

### 7.3 Table-Valued Parameter

SetCustomerTranslationDetails accepts `@TRANSLATIONDETAILS As TranslationDetails ReadOnly` - a UDT defined as a table type (not found in the BackOffice schema SSDT files; likely defined in dbo or a shared schema). The TVP mirrors the table structure: CID, DocumentToDocumentTypeID, FieldNameID, OriginalValue, TranslatedValue, LastModified.

---

## 8. Sample Queries

### 8.1 Get all translations for a customer's document classification
```sql
SELECT
    ctd.TranslationID,
    ctd.FieldNameID,
    fn.FieldName,
    fn.DocumentTypeID AS FieldScope,
    ctd.OriginalValue,
    ctd.TranslatedValue,
    ctd.LastModified
FROM BackOffice.CustomerTranslationDetails ctd WITH (NOLOCK)
JOIN BackOffice.TranslationDetailsFieldName fn WITH (NOLOCK) ON fn.FieldNameID = ctd.FieldNameID
WHERE ctd.CID = @CID
  AND ctd.DocumentToDocumentTypeID = @DocumentToDocumentTypeID
ORDER BY fn.DocumentTypeID, fn.FieldName
```

### 8.2 Find customers with translation records (have non-English documents)
```sql
SELECT ctd.CID, COUNT(DISTINCT ctd.DocumentToDocumentTypeID) AS TranslatedDocuments,
       MAX(ctd.LastModified) AS LatestTranslation
FROM BackOffice.CustomerTranslationDetails ctd WITH (NOLOCK)
GROUP BY ctd.CID
ORDER BY LatestTranslation DESC
```

### 8.3 Get full document context with translations
```sql
SELECT
    c2dt.DocumentToDocumentTypeID,
    cd.DisplayName,
    dt.Name AS DocumentType,
    fn.FieldName,
    ctd.OriginalValue,
    ctd.TranslatedValue,
    ctd.LastModified
FROM BackOffice.CustomerTranslationDetails ctd WITH (NOLOCK)
JOIN BackOffice.CustomerDocumentToDocumentType c2dt WITH (NOLOCK)
    ON c2dt.DocumentToDocumentTypeID = ctd.DocumentToDocumentTypeID
JOIN BackOffice.CustomerDocument cd WITH (NOLOCK) ON cd.DocumentID = c2dt.DocumentID
JOIN Dictionary.DocumentType dt WITH (NOLOCK) ON dt.DocumentTypeID = c2dt.DocumentTypeID
JOIN BackOffice.TranslationDetailsFieldName fn WITH (NOLOCK) ON fn.FieldNameID = ctd.FieldNameID
WHERE ctd.CID = @CID
ORDER BY ctd.DocumentToDocumentTypeID, fn.FieldName
```

---

## 9. Atlassian Knowledge Sources

No direct Atlassian matches found. Procedure comment cites OPS0244 (2017) "Translation and Update of Verification Info - DB Changes" as the origin ticket, and COMOP-2095/2097 (2021) as the classification CRUD changes that added the cascaded delete in RemoveDocumentClassification.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerTranslationDetails | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.CustomerTranslationDetails.sql*
