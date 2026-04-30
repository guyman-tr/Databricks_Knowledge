# BackOffice.InsertTncDocument

> Inserts a new Terms and Conditions (TnC) document record for a specific regulation (and optionally a country) into BackOffice.TncDocument, returning the new DocumentID.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @regulationId + @storageId; returns DocumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`InsertTncDocument` creates a new Terms and Conditions document record in `BackOffice.TncDocument`. Unlike `InsertDocument` (which stores documents per customer), TnC documents are regulation-level or country-level - they apply to all customers under a specific regulatory framework (CySEC, ASIC, FCA, etc.) and optionally to a specific country.

This SP is used when a new version of Terms and Conditions, a regulatory disclosure, or a compliance document is uploaded and needs to be made available to customers in a specific regulatory region. The `@tncDocTypeId` (default 1) and `@isActive` (default 1) parameters allow different document types and activation states.

Called by `SQL_UserDocAPI` and `PROD_SQL_DocAPI_2` (the same document upload services as `InsertDocument`) and by `PROD_BIadmins`.

---

## 2. Business Logic

### 2.1 Regulation-Level Document with Optional Country Override

**What**: TnC documents scope at regulation level, with optional country-specific overrides.

**Columns/Parameters Involved**: `@regulationId`, `@countryId`, `@tncDocTypeId`, `@isActive`

**Rules**:
- `@regulationId` (required): The regulatory region this document applies to (e.g. CySEC = 1, ASIC = 2). All customers under this regulation may be presented this document.
- `@countryId` (optional, NULL): If set, the document is specific to customers in a particular country within the regulation. Used for country-specific TnC variants.
- `@tncDocTypeId` (default 1): Type of TnC document (e.g. 1 = standard TnC, other values = specific document types).
- `@isActive` (default 1): Whether the document is immediately active. 0 = uploaded but not yet active (staged deployment).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @regulationId | INT | NO | - | CODE-BACKED | Regulatory region ID. TnC document applies to all customers under this regulation. FK to `Dictionary.Regulation`. |
| 2 | @addedBy | VARCHAR(50) | NO | - | CODE-BACKED | Manager username. Resolved to ManagerID via `BackOffice.GetManagerID(@addedBy)`. Stored in `TncDocument.ManagerID`. |
| 3 | @displayName | VARCHAR(250) | NO | - | CODE-BACKED | Human-readable document title shown in the Back Office TnC management interface. |
| 4 | @computerName | VARCHAR(50) | NO | - | CODE-BACKED | Workstation from which the document was uploaded. Audit trail. |
| 5 | @fileName | VARCHAR(255) | NO | - | CODE-BACKED | Storage filename used to retrieve the document. |
| 6 | @dateAdded | DATETIME | NO | - | CODE-BACKED | Upload timestamp. |
| 7 | @storageId | INT | NO | - | CODE-BACKED | Required link to the storage system record where the file is physically stored. Unlike CustomerDocument, StorageID is not optional for TnC documents. |
| 8 | @tncDocTypeId | INT | YES | 1 | CODE-BACKED | Type of TnC document. Default 1 = standard Terms and Conditions. Other values represent specific document types (regulatory disclosures, etc.). |
| 9 | @isActive | BIT | YES | 1 | CODE-BACKED | Activation state. 1 = active and available to customers in the regulation. 0 = staged/inactive. Default 1 (active on upload). |
| 10 | @countryId | INT | YES | NULL | CODE-BACKED | Optional country ID for country-specific TnC variants. NULL = applies to all countries under the regulation. |

**Output (result set):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DocumentID | INT | NO | - | CODE-BACKED | Identity value of the newly inserted `BackOffice.TncDocument` row (`SCOPE_IDENTITY()`). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @regulationId | Dictionary.Regulation | Lookup | TnC document scoped to this regulation |
| @addedBy | BackOffice.GetManagerID | Function call | Resolves manager username to ManagerID |
| (INSERT) | BackOffice.TncDocument | Writer | Creates new TnC document record |
| @countryId | Dictionary.Country | Lookup (implicit) | Optional country-specific scope |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_UserDocAPI service | params | Caller | Document upload API |
| PROD_SQL_DocAPI_2 service | params | Caller | Document upload API |
| PROD_BIadmins | params | Caller | BI admin access |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.InsertTncDocument (procedure)
├── BackOffice.TncDocument (table) [INSERT]
└── BackOffice.GetManagerID (function) [resolves @addedBy to ManagerID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.TncDocument | Table | INSERT target for new TnC document |
| BackOffice.GetManagerID | Function | Resolves manager username to ManagerID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_UserDocAPI / PROD_SQL_DocAPI_2 | External services | TnC document upload |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row-count messages |
| TRY/CATCH + THROW | Error handling | Full diagnostic print + re-throw |
| @storageId required | Design | StorageID has no NULL default (required for TnC docs, unlike customer docs where it is optional) |

---

## 8. Sample Queries

### 8.1 Insert a new TnC document for a regulation

```sql
EXEC [BackOffice].[InsertTncDocument]
    @regulationId = 1,
    @addedBy = 'compliance.officer',
    @displayName = 'CySEC Terms and Conditions v3.2',
    @computerName = 'BO-COMPLIANCE-01',
    @fileName = 'tnc_cysec_v3.2_2026.pdf',
    @dateAdded = '2026-03-18 09:00:00',
    @storageId = 4567,
    @tncDocTypeId = 1,
    @isActive = 1;
```

### 8.2 Check current TnC documents for a regulation

```sql
SELECT
    TncDocumentID,
    RegulationID,
    DisplayName,
    TncDocTypeID,
    IsActive,
    DateAdded,
    CountryID
FROM BackOffice.TncDocument WITH (NOLOCK)
WHERE RegulationID = 1
ORDER BY DateAdded DESC;
```

### 8.3 Find active TnC documents by type

```sql
SELECT
    td.TncDocumentID,
    r.Name AS Regulation,
    td.DisplayName,
    td.TncDocTypeID,
    td.DateAdded
FROM BackOffice.TncDocument WITH (NOLOCK) td
JOIN Dictionary.Regulation WITH (NOLOCK) r ON r.ID = td.RegulationID
WHERE td.IsActive = 1
ORDER BY td.RegulationID, td.DateAdded DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 9.0/10, Logic: 7.5/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: SQL_UserDocAPI + PROD_SQL_DocAPI_2 callers | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.InsertTncDocument | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.InsertTncDocument.sql*
