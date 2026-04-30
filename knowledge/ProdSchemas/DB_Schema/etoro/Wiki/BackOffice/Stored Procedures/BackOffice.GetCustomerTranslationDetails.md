# BackOffice.GetCustomerTranslationDetails

> Returns all translation detail records for a specific customer document classification, providing the original and translated field values recorded by BackOffice agents for non-English KYC documents.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all rows from BackOffice.CustomerTranslationDetails for (CID, DocumentToDocumentTypeID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetCustomerTranslationDetails retrieves the translation records that BackOffice agents have entered for a specific customer's document classification. Given a CID and a DocumentToDocumentTypeID, it returns all field-level translation rows from `BackOffice.CustomerTranslationDetails` - one row per field type (address, name, dates, etc.) that has been recorded. This data represents the agent's manual translation of a non-English KYC document into English-readable structured fields.

The procedure was introduced in 2017 as part of OPS0244 ("Translation and Update of Verification Info") - a feature enabling BackOffice agents to process KYC documents in non-Latin scripts (Arabic, Chinese, Russian, etc.) by recording both the original native-language value and its English translation field by field. Without this, foreign-language documents could not be structured into the eToro KYC system.

Called from the BackOffice application when an agent opens the translation view for a specific document classification record. The companion write procedure is `BackOffice.SetCustomerTranslationDetails` (UPSERT pattern). The `Translated` bit on `BackOffice.CustomerDocumentToDocumentType` marks when translation details have been recorded.

---

## 2. Business Logic

### 2.1 Document-Scoped Field Retrieval

**What**: Returns all translation fields for one specific document classification record, not all documents for a customer.

**Columns/Parameters Involved**: `@CID`, `@DocumentToDocumentTypeID`, `CustomerTranslationDetails.FieldNameID`

**Rules**:
- Filter is (CID = @CID AND DocumentToDocumentTypeID = @DocumentToDocumentTypeID) - targets one document classification record
- Returns ALL fields recorded for that document (up to 11 field types: Address, Building Number, City, Comment, Country, Date of Birth, Expiry Date, First Name, Issue Date, Last Name, Middle Name)
- Row count per call: 0-11 rows depending on which fields have been recorded
- Empty result = no translations have been entered for this document classification yet

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer account ID. Identifies whose document translation records to retrieve. Used with @DocumentToDocumentTypeID to uniquely scope the result to a single document classification. |
| 2 | @DocumentToDocumentTypeID | INT | NO | - | CODE-BACKED | The ID of the specific document-to-document-type classification record. FK to BackOffice.CustomerDocumentToDocumentType. Each classification record represents one document (e.g., a specific passport submission) associated with one document type. |

**Return Columns (SELECT * from BackOffice.CustomerTranslationDetails):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | TranslationID | bigint | NO | - | CODE-BACKED | Surrogate PK. Non-clustered identity - not meaningful for business logic. |
| R2 | CID | int | NO | - | CODE-BACKED | Customer account ID. Matches @CID filter parameter. |
| R3 | DocumentToDocumentTypeID | int | NO | - | CODE-BACKED | Document classification record ID. Matches @DocumentToDocumentTypeID filter parameter. |
| R4 | FieldNameID | int | NO | - | VERIFIED | The type of document field recorded. FK to BackOffice.TranslationDetailsFieldName. 11 field types: Address, Building Number, City, Comment, Country, Date of Birth, Expiry Date, First Name, Issue Date, Last Name, Middle Name. One row per field per document. |
| R5 | OriginalValue | nvarchar | YES | - | VERIFIED | The field value as it appears in the original non-English document (native script - Arabic, Chinese, Cyrillic, etc.). NULL if the agent only recorded the translation without the original. |
| R6 | TranslatedValue | nvarchar | YES | - | VERIFIED | The English translation of the field value entered by the BackOffice agent reviewing the non-English document. NULL if translation has not yet been provided for this field. |
| R7 | LastModified | datetime | YES | - | CODE-BACKED | Timestamp of the most recent update to this translation row. Set by SetCustomerTranslationDetails on UPSERT. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CTD | BackOffice.CustomerTranslationDetails | SELECT | Primary source - all translation field rows for the given (CID, DocumentToDocumentTypeID) pair |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from the BackOffice application document translation view. No stored procedure callers found in BackOffice schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerTranslationDetails (procedure)
└── BackOffice.CustomerTranslationDetails (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerTranslationDetails | Table | SELECT * filtered by CID and DocumentToDocumentTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (document translation view) | External | READER - loads translation fields for agent review/editing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. The underlying table has a UNIQUE CLUSTERED INDEX on (CID, DocumentToDocumentTypeID, FieldNameID) ensuring at most one row per field per document classification record.

---

## 8. Sample Queries

### 8.1 Retrieve all translation fields for a specific document
```sql
EXEC BackOffice.GetCustomerTranslationDetails
    @CID = 12345,
    @DocumentToDocumentTypeID = 67890
```

### 8.2 Equivalent ad-hoc query with field name resolution
```sql
SELECT
    ctd.FieldNameID,
    tfn.FieldName,
    ctd.OriginalValue,
    ctd.TranslatedValue,
    ctd.LastModified
FROM BackOffice.CustomerTranslationDetails ctd WITH (NOLOCK)
JOIN BackOffice.TranslationDetailsFieldName tfn WITH (NOLOCK)
    ON tfn.FieldNameID = ctd.FieldNameID
WHERE ctd.CID = 12345
  AND ctd.DocumentToDocumentTypeID = 67890
ORDER BY ctd.FieldNameID
```

### 8.3 Find all customers with any recorded translations
```sql
SELECT DISTINCT CID, COUNT(*) AS FieldsRecorded
FROM BackOffice.CustomerTranslationDetails WITH (NOLOCK)
GROUP BY CID
ORDER BY FieldsRecorded DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Feature introduced in 2017 per DDL comment: OPS0244 - Translation and Update of Verification Info.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: SKIPPED (no BackOffice repos) | Corrections: 0 applied*
*Object: BackOffice.GetCustomerTranslationDetails | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomerTranslationDetails.sql*
