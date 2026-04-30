# BackOffice.UpdateDocumentClassifications_JUNKYulia0325

> DEPRECATED (March 2025) - Original TVP-based bulk document classification update procedure that adds, changes, and deletes classification records for a document in one transaction.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @documentId - targets BackOffice.CustomerDocumentToDocumentType by DocumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**STATUS: DEPRECATED** - The `_JUNKYulia0325` suffix marks this as deprecated in March 2025. Per the in-code comment: "The Update is not practically used now." The procedure is preserved in the schema for reference but is no longer called in production. The active replacement is `BackOffice.UpdateDocumentClassification` (single-row, @classificationID-based update).

`BackOffice.UpdateDocumentClassifications_JUNKYulia0325` was the original bulk document classification manager: given a DocumentID and a table-valued parameter of `BackOffice.DocumentClassification` rows, it would atomically sync the full set of classification records for that document - deleting classifications removed from the TVP, keeping those included, and inserting new ones. All this ran inside a transaction with rollback on failure.

The procedure was complex enough to require 7 change tickets over 5 years (2017-2022), and the accumulated complexity likely drove the decision to deprecate it in favor of the simpler single-record `UpdateDocumentClassification`.

---

## 2. Business Logic

### 2.1 Delete-Then-Insert Sync Pattern (Deprecated)

**What**: Full sync of classification records for a document: remove records not in the TVP, insert records not yet in the DB.

**Columns/Parameters Involved**: `@documentId`, `@classifications` TVP

**Rules**:
- Runs in a TRY/CATCH transaction with ROLLBACK on error.
- DELETE logic (when @Remove=1):
  - Condition 1: TVP has more than 1 record AND fewer-or-equal records than currently stored for the document.
  - Condition 2: TVP has exactly 1 record AND `DocumentClassificationTypeID <> 0` (not a new row marker).
  - When removing: deletes from `BackOffice.CustomerTranslationDetails` first (cascaded), then from `BackOffice.CustomerDocumentToDocumentType`.
- INSERT logic: inserts TVP rows where `DocumentClassificationTypeID IS NULL OR = 0` (new records to add), grouped by key fields using MAX aggregation for agent/comment/rejection fields.
- Returns: `SELECT TOP 1 @id AS ClassificationId, DocumentAddDate, SuggestedDocumentTypeID, ApplicationIdentifier` from CustomerDocument + StorageDocuments join.

### 2.2 DEPRECATED - Do Not Call

**Rules**:
- This procedure is tagged JUNK and should not be called from new code.
- Use `BackOffice.UpdateDocumentClassification` for individual classification updates.
- Use `BackOffice.AddDocumentClassification` (TVP-based) for new bulk inserts.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @documentId | int | NO | - | CODE-BACKED | DocumentID of the document whose classifications are being synced. Maps to BackOffice.CustomerDocument.DocumentID and BackOffice.CustomerDocumentToDocumentType.DocumentID. |
| 2 | @classifications | BackOffice.DocumentClassification (TVP) | NO | - | CODE-BACKED | READONLY table-valued parameter carrying the full desired set of classification records. Rows with DocumentClassificationTypeID=NULL or 0 are new inserts; rows with DocumentClassificationTypeID > 0 are existing records to keep. Existing records not present in this TVP are deleted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @documentId | BackOffice.CustomerDocumentToDocumentType | DELETE + INSERT target | Syncs classification records for the document |
| @documentId | BackOffice.CustomerTranslationDetails | DELETE (cascade) | Removes translation records for deleted classifications |
| @documentId | BackOffice.CustomerDocument | SELECT | Returns document metadata in result set |
| - | dbo.StorageDocuments | SELECT (LEFT JOIN) | Returns ApplicationIdentifier from storage system |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DEPRECATED - no active callers. | - | - | Was the primary document classification sync procedure before 2025. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.UpdateDocumentClassifications_JUNKYulia0325 (procedure) [DEPRECATED]
+-- BackOffice.CustomerDocumentToDocumentType (table) [DELETE + INSERT target]
+-- BackOffice.CustomerTranslationDetails (table) [DELETE - cascade]
+-- BackOffice.CustomerDocument (table) [SELECT - return result]
+-- dbo.StorageDocuments (table) [SELECT LEFT JOIN - ApplicationIdentifier]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [BackOffice.CustomerDocumentToDocumentType](../Tables/BackOffice.CustomerDocumentToDocumentType.md) | Table | DELETE (removed rows) + INSERT (new rows) |
| BackOffice.CustomerTranslationDetails | Table | DELETE (cascade before classification delete) |
| BackOffice.CustomerDocument | Table | SELECT in return result set |
| dbo.StorageDocuments | Table | LEFT JOIN for ApplicationIdentifier in return result set |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DEPRECATED - no active dependents. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Uses TRY/CATCH with ROLLBACK for transactional safety.

---

## 8. Sample Queries

### 8.1 This procedure is deprecated - use the active replacement

```sql
-- DO NOT USE - DEPRECATED as of March 2025.
-- Use BackOffice.UpdateDocumentClassification for single-record updates:
EXEC BackOffice.UpdateDocumentClassification
    @classificationID = 1234567,
    @expiryDate = '2030-01-01';

-- Use BackOffice.AddDocumentClassification for bulk inserts.
```

### 8.2 Check current active classifications for a document

```sql
SELECT DocumentToDocumentTypeID, DocumentTypeID, IssueDate, ExpiryDate, ManagerID
FROM BackOffice.CustomerDocumentToDocumentType WITH (NOLOCK)
WHERE DocumentID = @documentId
ORDER BY Occurred DESC;
```

### 8.3 Verify no active callers in BackOffice SP schema

```sql
-- No known active callers as of 2025-03 deprecation.
SELECT name FROM sys.procedures WHERE name LIKE 'UpdateDocumentClassifications%' AND schema_id = SCHEMA_ID('BackOffice');
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| COMOP-508/509 | Jira | Added SideID for POI front/back tracking - 2020-06-11 |
| COMOP-1795/1925 | Jira | Update to classification SP - 2020-12-07 |
| COMOP-1682/2019 | Jira | Allow removing document definitions - 2020-12-29 |
| COMOP-4557 | Jira | Added VisaTypeID - 2022-05-10 |
| RD-17538 | Jira | Bug fix in classification procedure - 2019-12-10 |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Dependency Inheritance, Caller Scan, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 5 Jira (from DDL comments) | Procedures: 0 callers analyzed | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.UpdateDocumentClassifications_JUNKYulia0325 | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.UpdateDocumentClassifications_JUNKYulia0325.sql*
