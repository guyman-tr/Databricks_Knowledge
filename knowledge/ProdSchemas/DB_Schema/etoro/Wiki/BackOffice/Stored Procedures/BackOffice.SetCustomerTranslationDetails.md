# BackOffice.SetCustomerTranslationDetails

> Upserts translation records for non-English KYC document fields - updating existing translations or inserting new ones - using a table-valued parameter containing all field values for one agent translation session.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @TRANSLATIONDETAILS TVP keyed on (CID, DocumentToDocumentTypeID, FieldNameID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.SetCustomerTranslationDetails is the write procedure for the KYC document translation workflow. When a customer submits identity documents written in a non-Latin script (Arabic, Chinese, Russian, etc.), BackOffice agents read the document and record both the original-language text and English translation for each structured field (name, address, date of birth, etc.). This procedure accepts all field translations for a given document in one call and upserts them into BackOffice.CustomerTranslationDetails.

The procedure was introduced in July 2017 (OPS0244: "Translation and Update of Verification Info") to support BackOffice compliance workflows for non-English-speaking customers. Without it, agents would have no structured way to record what foreign-language documents actually say, making KYC review impossible for those documents.

The TVP design allows the BackOffice UI to submit all field translations for a document in one database round-trip, and the UPSERT pattern means agents can update partial translations without losing previously entered values.

---

## 2. Business Logic

### 2.1 UPSERT Pattern - Update Existing, Insert New

**What**: The procedure handles both first-time translation entry and updates to previously recorded values.

**Columns/Parameters Involved**: `@TRANSLATIONDETAILS.CID`, `@TRANSLATIONDETAILS.DocumentToDocumentTypeID`, `@TRANSLATIONDETAILS.FieldNameID`, `OriginalValue`, `TranslatedValue`, `LastModified`

**Rules**:
- Step 1 (UPDATE): JOIN @TRANSLATIONDETAILS to BackOffice.CustomerTranslationDetails on (CID, DocumentToDocumentTypeID, FieldNameID). For matching rows, set OriginalValue, TranslatedValue, LastModified from the TVP values.
- Step 2 (INSERT): Select rows from @TRANSLATIONDETAILS where no matching row exists in CustomerTranslationDetails (NOT EXISTS anti-join on all 3 key columns). Insert CID, DocumentToDocumentTypeID, FieldNameID, OriginalValue, TranslatedValue, LastModified.
- @UPDATED OUTPUT set to 1 on success.
- Wrapped in BEGIN TRAN/COMMIT with CATCH ROLLBACK + THROW. Partial upserts are not possible - all rows succeed or none.

**Diagram**:
```
Agent records translation for document fields
    |
    v
@TRANSLATIONDETAILS TVP (one row per field)
    |
    +--> UPDATE matching rows in CustomerTranslationDetails
    |        (CID + DocumentToDocumentTypeID + FieldNameID match)
    |        SET OriginalValue, TranslatedValue, LastModified
    |
    +--> INSERT rows with no match (new fields)
    |
    v
@UPDATED = 1 (success)
```

### 2.2 TranslationDetails TVP Structure

**What**: The `TranslationDetails` User Defined Table Type defines the shape of the input.

**Rules**:
- The TVP must contain columns: CID, DocumentToDocumentTypeID, FieldNameID, OriginalValue, TranslatedValue, LastModified (matching BackOffice.CustomerTranslationDetails columns)
- Caller fills the TVP with all fields for the document(s) being translated in one session
- TVP is READONLY - the procedure cannot modify the input

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TRANSLATIONDETAILS | TranslationDetails (TVP) | NO | - | VERIFIED | Table-valued parameter containing one row per document field to upsert. Each row must supply: CID (customer), DocumentToDocumentTypeID (document classification record), FieldNameID (which field - FK to BackOffice.TranslationDetailsFieldName: First Name, Last Name, Address, City, etc.), OriginalValue (text in original language), TranslatedValue (English translation), LastModified (timestamp). The TVP is READONLY. |
| 2 | @UPDATED | BIT | - | 0 | CODE-BACKED | OUTPUT parameter. Set to 1 on successful completion of the TRY block (no exception). Returns to caller confirming the upsert completed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TRANSLATIONDETAILS | BackOffice.CustomerTranslationDetails | MODIFIER (UPDATE + INSERT) | Upserts translation records keyed on (CID, DocumentToDocumentTypeID, FieldNameID) |
| TranslationDetails type | TranslationDetails (UDT) | Type reference | TVP type defined as a User Defined Table Type in BackOffice schema |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice Document Verification UI | - | Caller | Called by agents recording translations for non-English KYC documents |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.SetCustomerTranslationDetails (procedure)
├── BackOffice.CustomerTranslationDetails (table)
└── TranslationDetails (user defined table type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerTranslationDetails | Table | UPSERT target: UPDATE existing + INSERT new rows |
| TranslationDetails | User Defined Type | TVP parameter type definition |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice Document Verification UI | External | Calls to record translations for non-English KYC documents |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Change History

- **OPS0244** (Jul 2017, Geri Reshef): Initial implementation - "Translation and Update of Verification Info - DB Changes"

---

## 8. Sample Queries

### 8.1 View translations recorded for a customer's document
```sql
SELECT
    ctd.CID,
    ctd.DocumentToDocumentTypeID,
    tdfn.FieldName,
    ctd.OriginalValue,
    ctd.TranslatedValue,
    ctd.LastModified
FROM BackOffice.CustomerTranslationDetails ctd WITH (NOLOCK)
JOIN BackOffice.TranslationDetailsFieldName tdfn WITH (NOLOCK)
    ON tdfn.FieldNameID = ctd.FieldNameID
WHERE ctd.CID = 12345678
ORDER BY ctd.DocumentToDocumentTypeID, tdfn.FieldName
```

### 8.2 Find customers with translation records (non-English KYC)
```sql
SELECT CID, COUNT(*) AS FieldCount
FROM BackOffice.CustomerTranslationDetails WITH (NOLOCK)
GROUP BY CID
ORDER BY FieldCount DESC
```

### 8.3 Check most recently translated documents
```sql
SELECT TOP 20
    ctd.CID,
    ctd.DocumentToDocumentTypeID,
    tdfn.FieldName,
    ctd.OriginalValue,
    ctd.TranslatedValue,
    ctd.LastModified
FROM BackOffice.CustomerTranslationDetails ctd WITH (NOLOCK)
JOIN BackOffice.TranslationDetailsFieldName tdfn WITH (NOLOCK)
    ON tdfn.FieldNameID = ctd.FieldNameID
ORDER BY ctd.LastModified DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.SetCustomerTranslationDetails | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.SetCustomerTranslationDetails.sql*
