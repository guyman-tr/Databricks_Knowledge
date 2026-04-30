# BackOffice.TncDocument

> Registry of Terms & Conditions documents uploaded by back-office managers, organized by regulatory jurisdiction and country, with active/enabled flags controlling customer visibility.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | PK_TNC: DocumentID IDENTITY (CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

`BackOffice.TncDocument` is the registry of Terms & Conditions (T&C) PDF documents that eToro presents to customers. As a multi-regulated broker, eToro operates under different legal frameworks (CySEC, FCA, ASIC, BVI, etc.) and different jurisdictions require different T&C documents. Back-office managers upload T&C PDFs via the admin interface; this table records the metadata for each uploaded document.

Each row represents one T&C document: which regulation it applies to, what country it targets (`CountryID`), the display name shown to customers, the physical file path (`FileName`), the storage backend identifier (`StorageID`), and two control flags (`Enabled`, `IsActive`). The dual-flag system allows granular lifecycle management - a document can be `Enabled=0` (suppressed without deletion) or `IsActive=0` (formally superseded by a newer version) independently.

Live data shows documents dating from 2015 onward. The file naming convention is `{RegulationID}-{timestamp}-{original_name}.pdf`, enabling the back office to track multiple versions of the same regulatory T&C document over time.

SPs: `InsertTncDocument` (creates records), `TncDocumentUpdateIsActive` (deactivates), `GetTncDocument` (fetches one), `GetAllLatestTncDocuments` (fetches the current active set for all regulations).

---

## 2. Business Logic

### 2.1 Regulation-Jurisdiction T&C Routing

**What**: Customers are served the T&C document matching their regulatory jurisdiction and, where applicable, their country.

**Columns/Parameters Involved**: `RegulationID`, `CountryID`, `TncDocTypeID`, `Enabled`, `IsActive`

**Rules**:
- A customer's regulation (from their customer record) and country determine which T&C document they see.
- `GetAllLatestTncDocuments` queries for the most recent document per (regulation, country, type) combination.
- `CountryID` is optional (NULL) - regulation-level T&Cs apply to all countries in that regulation; country-specific T&Cs override the regulation-level one.
- `TncDocTypeID` defaults to 1 (main T&C). Other types may cover specific products or jurisdictional addenda.
- Only documents with `Enabled=1 AND IsActive=1` are served to customers.

### 2.2 Document Lifecycle (Enable/Disable/Deactivate)

**What**: Two-flag system for document lifecycle management.

**Columns/Parameters Involved**: `Enabled`, `IsActive`

**Rules**:
- `Enabled=1` + `IsActive=1`: Document is live and displayed to customers.
- `Enabled=0`: Document is temporarily suppressed (e.g., pending legal review). Can be re-enabled.
- `IsActive=0`: Document has been formally superseded. `TncDocumentUpdateIsActive` sets this to 0 when a new version is uploaded.
- When a new document is uploaded for a regulation, the previous document(s) should be deactivated via `TncDocumentUpdateIsActive`.

**Diagram**:
```
Upload new T&C for CySEC:
  -> InsertTncDocument (new row, Enabled=1, IsActive=1)
  -> TncDocumentUpdateIsActive (deactivates old rows for same regulation)

GetAllLatestTncDocuments:
  -> Returns rows WHERE IsActive=1 AND Enabled=1 per regulation
```

### 2.3 File Storage

**What**: Documents are stored in an external storage system; this table stores only the metadata pointer.

**Columns/Parameters Involved**: `FileName`, `ComputerName`, `StorageID`

**Rules**:
- `FileName` stores the path/filename in the format `{RegulationID}-{timestamp}-{original_name}.pdf`.
- `ComputerName` records the server from which the file was uploaded.
- `StorageID` is an integer reference to an external storage system (blob storage or file share).

---

## 3. Data Overview

| Column | Observed Values |
|--------|----------------|
| Earliest DocumentID | 1 (2015-05-03) |
| Regulations covered | 1 (CySEC), 2 (FCA), 4 (ASIC), 5 (BVI), 6 (eToroUS), others |
| File naming | `{RegID}-{timestamp}-{name}.pdf` (e.g., `1-20150503120000-TermsAndConditions.pdf`) |
| TncDocTypeID | Default=1 (main T&C) |
| Enabled/IsActive | Dual-flag lifecycle management |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DocumentID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate PK. Auto-incremented. NOT FOR REPLICATION. Uniquely identifies each T&C document entry. Referenced by BackOffice.ZendeskDocuments. |
| 2 | RegulationID | int | YES | - | CODE-BACKED | The regulatory jurisdiction this document applies to. Maps to Dictionary.Regulation.ID values (1=CySEC, 2=FCA, 4=ASIC, 5=BVI, 6=eToroUS, etc.). Customers are shown the document matching their regulation. |
| 3 | ManagerID | int | YES | - | CODE-BACKED | The back-office manager who uploaded this document. Audit trail reference to BackOffice.Manager.ManagerID. |
| 4 | DisplayName | varchar(100) | YES | - | CODE-BACKED | Human-readable name shown to customers in the T&C acceptance UI (e.g., "Terms and Conditions - CySEC"). |
| 5 | ComputerName | varchar(100) | YES | - | CODE-BACKED | Hostname of the machine from which the document was uploaded. Used for upload audit trail. |
| 6 | FileName | varchar(200) | YES | - | CODE-BACKED | Physical filename/path of the PDF in storage. Format: `{RegulationID}-{timestamp}-{original_name}.pdf`. Used by StorageID to locate the file. |
| 7 | DateAdded | datetime | YES | - | CODE-BACKED | Timestamp when this document was uploaded/registered. Earliest records from 2015-05-03. |
| 8 | StorageID | int | YES | - | CODE-BACKED | Reference to the external storage system record (blob store or file share). Used with FileName to retrieve the actual PDF. |
| 9 | TncDocTypeID | int | NO | 1 | CODE-BACKED | FK to Dictionary.TncDocType. Classifies the document type. Default=1 (main Terms & Conditions). Other values may represent product-specific or jurisdictional addenda. |
| 10 | Enabled | bit | NO | 1 | CODE-BACKED | 1=Document is active and visible to customers. 0=Document is suppressed/hidden without deletion. Can be toggled independently of IsActive. |
| 11 | IsActive | bit | NO | 1 | CODE-BACKED | 1=Document is the current valid version. 0=Document has been superseded by a newer version (set by TncDocumentUpdateIsActive). Used with Enabled to determine if document is served to customers. |
| 12 | CountryID | int | YES | - | CODE-BACKED | FK to Dictionary.Country. If non-NULL, this document applies only to customers in the specified country within the regulation. NULL=applies to all countries in the regulation. Enables country-specific T&C overrides. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TncDocTypeID | Dictionary.TncDocType.TncDocTypeID | FK | Document type classification |
| CountryID | Dictionary.Country.CountryID | FK | Country-specific targeting |
| RegulationID | Dictionary.Regulation.ID | Implicit | Jurisdiction this document covers |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.InsertTncDocument | INSERT | Writer | Creates new document records |
| BackOffice.TncDocumentUpdateIsActive | UPDATE | Writer | Deactivates superseded documents |
| BackOffice.GetTncDocument | SELECT | Reader | Retrieves single document by ID |
| BackOffice.GetAllLatestTncDocuments | SELECT | Reader | Returns current active documents per regulation |
| BackOffice.ZendeskDocuments | DocumentID | FK (logical) | Links Zendesk tickets to T&C documents |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.TncDocument (table)
+-- Dictionary.TncDocType (table) [FK: TncDocTypeID]
+-- Dictionary.Country (table) [FK: CountryID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.TncDocType | Table | FK: TncDocTypeID must be a valid document type |
| Dictionary.Country | Table | FK: CountryID must be a valid country |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.InsertTncDocument | Stored Procedure | Inserts new T&C document records |
| BackOffice.TncDocumentUpdateIsActive | Stored Procedure | Deactivates old document versions |
| BackOffice.GetTncDocument | Stored Procedure | Retrieves a specific T&C document |
| BackOffice.GetAllLatestTncDocuments | Stored Procedure | Gets all current active T&C docs |
| BackOffice.ZendeskDocuments | Table | DocumentID links Zendesk tickets to T&C documents |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TNC | CLUSTERED PK | DocumentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK (TncDocTypeID) | FK | TncDocTypeID -> Dictionary.TncDocType |
| FK (CountryID) | FK | CountryID -> Dictionary.Country |
| DEFAULT Enabled=1 | DEFAULT | New documents are enabled by default |
| DEFAULT IsActive=1 | DEFAULT | New documents are active by default |
| DEFAULT TncDocTypeID=1 | DEFAULT | New documents default to main T&C type |

---

## 8. Sample Queries

### 8.1 Get all active T&C documents per regulation

```sql
SELECT
    d.DocumentID, d.RegulationID, d.DisplayName, d.FileName,
    d.DateAdded, d.TncDocTypeID, d.CountryID
FROM BackOffice.TncDocument d WITH (NOLOCK)
WHERE d.IsActive = 1 AND d.Enabled = 1
ORDER BY d.RegulationID, d.TncDocTypeID, d.CountryID;
```

### 8.2 Get T&C history for a regulation (all versions)

```sql
SELECT
    d.DocumentID, d.DisplayName, d.FileName, d.DateAdded,
    d.IsActive, d.Enabled
FROM BackOffice.TncDocument d WITH (NOLOCK)
WHERE d.RegulationID = 1  -- CySEC
ORDER BY d.DateAdded DESC;
```

### 8.3 Deactivate old document when uploading new version (via SP)

```sql
EXEC BackOffice.TncDocumentUpdateIsActive @RegulationID = 1, @TncDocTypeID = 1;
EXEC BackOffice.InsertTncDocument
    @RegulationID = 1,
    @ManagerID = 701,
    @DisplayName = 'CySEC Terms and Conditions 2026',
    @ComputerName = 'BACKOFFICE-01',
    @FileName = '1-20260101120000-TnC_CySEC_2026.pdf',
    @StorageID = 5001,
    @TncDocTypeID = 1,
    @CountryID = NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Live Data, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.TncDocument | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.TncDocument.sql*
