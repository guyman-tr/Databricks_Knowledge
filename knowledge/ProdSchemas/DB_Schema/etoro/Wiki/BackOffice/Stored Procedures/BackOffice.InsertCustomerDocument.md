# BackOffice.InsertCustomerDocument

> Inserts a new document record into BackOffice.CustomerDocument by resolving the customer CID from the provided GCID, then returns the new DocumentID.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid (customer GCID); returns DocumentID (new row identity) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`InsertCustomerDocument` creates a new document upload record in `BackOffice.CustomerDocument`. It is called by the `SQL_UserDocAPI` service when a Back Office manager uploads a document (e.g. ID scan, address proof, KYC document) for a customer.

The procedure accepts the Global Customer ID (GCID) rather than the internal CID - it resolves CID internally by looking up `Customer.CustomerStatic WHERE GCID = @gcid`. This design allows the caller to work exclusively with GCIDs (the cross-system customer identifier) without needing to resolve to internal CIDs.

If the GCID does not exist in `Customer.CustomerStatic`, no row is inserted (the INSERT...SELECT returns 0 rows) and `DocumentID` will be NULL. Errors are caught, logged to the print buffer, and re-thrown via `THROW`.

---

## 2. Business Logic

### 2.1 GCID-to-CID Resolution at Insert

**What**: The caller provides GCID; the procedure resolves the internal CID before inserting.

**Columns/Parameters Involved**: `@gcid`, `CID`

**Rules**:
- `INSERT INTO BackOffice.CustomerDocument ... SELECT CID ... FROM Customer.CustomerStatic WITH (NOLOCK) WHERE GCID = @gcid`
- If GCID matches exactly one customer, one row is inserted
- If GCID matches no customer, zero rows are inserted (no error raised)
- GCID is also stored directly in the `BackOffice.CustomerDocument.GCID` column alongside the resolved CID

### 2.2 Document Metadata

**What**: The document record stores both file identity and Back Office context.

**Columns/Parameters Involved**: `@displayName`, `@fileName`, `@computerName`, `@dateAdded`, `@managerId`, `@storageId`

**Rules**:
- `DisplayName` - human-readable label shown in Back Office UI
- `FileName` - actual storage filename (used to retrieve the file from storage)
- `ComputerName` - workstation that uploaded the file (audit trail)
- `StorageID` - optional link to a storage system record; NULL if not stored externally
- `ManagerID` - the Back Office manager performing the upload

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | INT | NO | - | CODE-BACKED | Global Customer ID. Used to resolve the internal CID via `Customer.CustomerStatic.GCID`. Also stored directly in `BackOffice.CustomerDocument.GCID`. |
| 2 | @managerId | INT | NO | - | CODE-BACKED | ID of the Back Office manager uploading the document. Stored in `BackOffice.CustomerDocument.ManagerID`. |
| 3 | @displayName | NVARCHAR(250) | NO | - | CODE-BACKED | Human-readable document name shown in the Back Office document list. |
| 4 | @computerName | VARCHAR(50) | NO | - | CODE-BACKED | Name of the workstation from which the document was uploaded. Stored for audit trail. |
| 5 | @fileName | NVARCHAR(255) | NO | - | CODE-BACKED | Storage filename or path used to retrieve the document. |
| 6 | @dateAdded | DATETIME | NO | - | CODE-BACKED | Timestamp of the document upload. Stored in `DateAdded`. |
| 7 | @accounting | BIT | NO | - | CODE-BACKED | Flags the document as relevant to accounting/financial processing. 1 = accounting-relevant. |
| 8 | @obsolete | BIT | NO | - | CODE-BACKED | Marks the document as obsolete/superseded. 1 = no longer current. Typically 0 on insert; updated later when a newer version is uploaded. |
| 9 | @comment | VARCHAR(255) | YES | - | CODE-BACKED | Optional free-text comment about the document. |
| 10 | @documentSizeActionTypeId | INT | NO | - | CODE-BACKED | Identifies the document type/action category for sizing and processing rules. |
| 11 | @storageId | INT | YES | NULL | CODE-BACKED | Optional ID linking to an external storage system record. NULL if document is stored locally. |
| 12 | @SuggestedDocumentTypeID | INT | YES | NULL | CODE-BACKED | Optional suggested document type classification (e.g. passport, utility bill). Populated when the system suggests a type for the uploaded file. |
| 13 | @SessionID | VARCHAR(255) | YES | NULL | CODE-BACKED | Optional upload session identifier for grouping related uploads. |
| 14 | @SuggestedDocumentSubTypeID | INT | YES | NULL | CODE-BACKED | Optional document sub-type classification (more specific than SuggestedDocumentTypeID). |

**Output (result set):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DocumentID | INT | YES | - | CODE-BACKED | Identity value of the newly inserted `BackOffice.CustomerDocument` row (`SCOPE_IDENTITY()`). NULL if no row was inserted (GCID not found). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.CustomerStatic | Lookup | Resolves CID from GCID before insert |
| (INSERT) | BackOffice.CustomerDocument | Writer | Creates new document record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_UserDocAPI service | @gcid + document fields | Caller | Back Office document upload service calls this SP |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.InsertCustomerDocument (procedure)
├── Customer.CustomerStatic (table) [GCID lookup - SELECT]
└── BackOffice.CustomerDocument (table) [INSERT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | SELECT to resolve CID from @gcid |
| BackOffice.CustomerDocument | Table | INSERT target for new document record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_UserDocAPI service | External service | Calls to upload new customer documents |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row-count messages |
| WITH (NOLOCK) | Query hint | CustomerStatic lookup uses NOLOCK |
| TRY/CATCH + THROW | Error handling | Errors are printed with full diagnostic detail (server, DB, procedure, line, message) and re-thrown to the caller |
| INSERT...SELECT | Atomic | If GCID not found, no row inserted and no error raised |

---

## 8. Sample Queries

### 8.1 Insert a document record for a customer

```sql
EXEC [BackOffice].[InsertCustomerDocument]
    @gcid = 12345678,
    @managerId = 101,
    @displayName = N'Passport Scan',
    @computerName = 'BO-WORKSTATION-01',
    @fileName = N'passport_12345678_20260318.pdf',
    @dateAdded = '2026-03-18 10:00:00',
    @accounting = 0,
    @obsolete = 0,
    @comment = 'Uploaded for KYC verification',
    @documentSizeActionTypeId = 1,
    @storageId = NULL,
    @SuggestedDocumentTypeID = 5;
```

### 8.2 Verify the inserted document

```sql
SELECT TOP 5
    cd.DocumentID,
    cd.CID,
    cd.GCID,
    cd.DisplayName,
    cd.DateAdded,
    cd.Obsolete
FROM BackOffice.CustomerDocument WITH (NOLOCK) cd
WHERE cd.GCID = 12345678
ORDER BY cd.DateAdded DESC;
```

### 8.3 Resolve GCID to CID (mirrors the internal lookup)

```sql
SELECT CID, GCID, UserName
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE GCID = 12345678;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 9.0/10, Logic: 7.5/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: SQL_UserDocAPI service (permissions grant) | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.InsertCustomerDocument | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.InsertCustomerDocument.sql*
