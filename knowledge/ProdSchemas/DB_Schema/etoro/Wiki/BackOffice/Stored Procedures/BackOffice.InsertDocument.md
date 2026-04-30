# BackOffice.InsertDocument

> Inserts a new document record into BackOffice.CustomerDocument by resolving both CID (from GCID via CustomerStatic) and ManagerID (from username via GetManagerID), then returns the new DocumentID.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid (customer GCID) + @addedBy (manager username); returns DocumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`InsertDocument` is the primary document upload entry point used by the `SQL_UserDocAPI` and `PROD_SQL_DocAPI_2` services to create customer document records in `BackOffice.CustomerDocument`. It is similar to `InsertCustomerDocument` but resolves the manager ID internally from a username string (`@addedBy`) rather than accepting a numeric ManagerID directly.

This design allows callers (document APIs) to pass the manager's login name without needing to look up their numeric ID - the SP calls `BackOffice.GetManagerID(@addedBy)` to perform that resolution. Both CID and ManagerID are resolved internally, making this the more self-contained document insert entry point.

Built in July 2016 as part of the StorageAPI schema rebuild (Geri Reshef). Updated in 2017 for OPS0342 FTD Emails docapi, 2018 for NOLOCK hint, and 2020 (COMOP-511/605) for POI validation support.

---

## 2. Business Logic

### 2.1 Dual Internal Resolution

**What**: Both customer identity and manager identity are resolved inside the procedure from external identifiers.

**Columns/Parameters Involved**: `@gcid`, `@addedBy`, `CID`, `ManagerID`

**Rules**:
- `ManagerID` resolved via `SELECT @managerId = BackOffice.GetManagerID(@addedBy)` - converts the manager's username to their numeric ID
- `CID` resolved via `SELECT CID FROM Customer.CustomerStatic WITH (NOLOCK) WHERE GCID = @gcid` - converts GCID to internal CID
- If GCID not found: no row inserted, DocumentID = NULL
- If `@addedBy` not found by GetManagerID: ManagerID may be NULL (depends on GetManagerID behavior), potentially violating a NOT NULL constraint

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | INT | NO | - | CODE-BACKED | Global Customer ID. Used to resolve the internal CID via `Customer.CustomerStatic.GCID`. Also stored in `BackOffice.CustomerDocument.GCID`. |
| 2 | @addedBy | VARCHAR(50) | NO | - | CODE-BACKED | Manager's login name/username. Passed to `BackOffice.GetManagerID(@addedBy)` to resolve the numeric ManagerID stored in `BackOffice.CustomerDocument.ManagerID`. |
| 3 | @displayName | NVARCHAR(250) | NO | - | CODE-BACKED | Human-readable document label shown in the Back Office UI. |
| 4 | @computerName | VARCHAR(50) | NO | - | CODE-BACKED | Workstation name from which the document was uploaded. Audit trail. |
| 5 | @fileName | NVARCHAR(255) | NO | - | CODE-BACKED | Storage filename used to retrieve the document from the document storage system. |
| 6 | @dateAdded | DATETIME | NO | - | CODE-BACKED | Upload timestamp. |
| 7 | @accounting | BIT | NO | - | CODE-BACKED | 1 = document is relevant to accounting/financial processing. |
| 8 | @obsolete | BIT | NO | - | CODE-BACKED | 1 = document is obsolete/superseded. Typically 0 on first insert. |
| 9 | @comment | VARCHAR(255) | YES | - | CODE-BACKED | Optional free-text comment about the document. |
| 10 | @documentSizeActionTypeId | INT | NO | - | CODE-BACKED | Document type/action category for sizing and processing rules. |
| 11 | @storageId | INT | YES | NULL | CODE-BACKED | Optional link to an external storage system record. |
| 12 | @SuggestedDocumentTypeID | INT | YES | NULL | CODE-BACKED | Optional document type suggestion (e.g. passport, utility bill). |
| 13 | @SessionID | VARCHAR(255) | YES | NULL | CODE-BACKED | Optional upload session identifier for grouping related uploads. |
| 14 | @SuggestedDocumentSubTypeID | INT | YES | NULL | CODE-BACKED | Optional document sub-type classification. |

**Output (result set):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DocumentID | INT | YES | - | CODE-BACKED | Identity value of the newly inserted `BackOffice.CustomerDocument` row (`SCOPE_IDENTITY()`). NULL if no row was inserted (GCID not found). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.CustomerStatic | Lookup | Resolves CID from GCID |
| @addedBy | BackOffice.GetManagerID | Function call | Resolves ManagerID from username |
| (INSERT) | BackOffice.CustomerDocument | Writer | Creates new document record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_UserDocAPI service | @gcid + @addedBy | Caller | Primary document upload service |
| PROD_SQL_DocAPI_2 service | @gcid + @addedBy | Caller | Secondary document upload service |
| PROD_BIadmins | @gcid + @addedBy | Caller | BI admin access |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.InsertDocument (procedure)
├── Customer.CustomerStatic (table) [SELECT - GCID lookup]
├── BackOffice.CustomerDocument (table) [INSERT]
└── BackOffice.GetManagerID (function) [resolves @addedBy to ManagerID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | SELECT to resolve CID from GCID |
| BackOffice.CustomerDocument | Table | INSERT target |
| BackOffice.GetManagerID | Function | Resolves manager username to numeric ManagerID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_UserDocAPI service | External service | Primary document upload endpoint |
| PROD_SQL_DocAPI_2 service | External service | Secondary document upload endpoint |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row-count messages |
| WITH (NOLOCK) | Query hint | CustomerStatic lookup uses NOLOCK |
| TRY/CATCH + THROW | Error handling | Errors printed with full diagnostic detail and re-thrown |

---

## 8. Sample Queries

### 8.1 Insert a document via username

```sql
EXEC [BackOffice].[InsertDocument]
    @gcid = 12345678,
    @addedBy = 'john.smith',
    @displayName = N'ID Document',
    @computerName = 'BO-SERVER-01',
    @fileName = N'id_12345678.pdf',
    @dateAdded = '2026-03-18 10:00:00',
    @accounting = 0,
    @obsolete = 0,
    @comment = 'KYC upload',
    @documentSizeActionTypeId = 1,
    @storageId = 555;
```

### 8.2 Check documents uploaded by a specific manager

```sql
SELECT
    cd.DocumentID,
    cd.GCID,
    cd.DisplayName,
    cd.DateAdded,
    bm.FirstName + ' ' + bm.LastName AS UploadedBy
FROM BackOffice.CustomerDocument WITH (NOLOCK) cd
JOIN BackOffice.Manager WITH (NOLOCK) bm ON bm.ManagerID = cd.ManagerID
WHERE bm.UserName = 'john.smith'
ORDER BY cd.DateAdded DESC;
```

### 8.3 Resolve GetManagerID for a given username

```sql
SELECT BackOffice.GetManagerID('john.smith') AS ManagerID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 9.0/10, Logic: 7.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: SQL_UserDocAPI + PROD_SQL_DocAPI_2 callers | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.InsertDocument | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.InsertDocument.sql*
