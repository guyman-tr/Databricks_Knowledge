# BackOffice.GetTncDocument

> Returns metadata for a single Terms and Conditions document by ID - used by Back Office to retrieve TnC document details for display or management.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @documentId (required); returns BackOffice.TncDocument row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetTncDocument` retrieves the metadata record for a specific Terms and Conditions document from `BackOffice.TncDocument`. TnC documents are regulatory compliance documents (terms of service, risk disclosures, legal agreements) assigned to specific regulations and/or countries. This procedure is a simple lookup by document ID, optionally filtering on active/inactive state. It is used by BO compliance or legal teams to inspect or manage specific TnC documents.

---

## 2. Business Logic

### 2.1 Active/Inactive Filter

**What**: Controls whether to return active or inactive TnC documents.

**Columns/Parameters Involved**: `@isActive`, `BackOffice.TncDocument.IsActive`

**Rules**:
- Default: `@isActive = 1` (active documents only)
- Pass `@isActive = 0` to retrieve deactivated/historical documents
- Both @documentId AND @isActive must match for a row to be returned

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @documentId | INT | NO | - | CODE-BACKED | Primary key of the TnC document to retrieve (BackOffice.TncDocument.DocumentID). Required. |
| 2 | @isActive | BIT | YES | 1 | CODE-BACKED | Whether to return active (1) or inactive (0) documents. Default=1 returns only active documents. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DocumentID | INT | NO | - | CODE-BACKED | Primary key of the TnC document (BackOffice.TncDocument.DocumentID). |
| 2 | RegulationID | INT | YES | - | CODE-BACKED | Regulatory jurisdiction this document applies to (BackOffice.TncDocument.RegulationID). Links to Dictionary.Regulation. NULL if regulation-agnostic. |
| 3 | DateAdded | DATETIME | NO | - | CODE-BACKED | Timestamp when the document was created/uploaded (BackOffice.TncDocument.DateAdded). |
| 4 | DisplayName | NVARCHAR | NO | - | CODE-BACKED | Human-readable name of the TnC document shown in BO interface (BackOffice.TncDocument.DisplayName). |
| 5 | FileName | NVARCHAR | YES | - | CODE-BACKED | Filename of the document in storage (BackOffice.TncDocument.FileName). Used to retrieve the actual document from cloud/blob storage. |
| 6 | AddedBy | NVARCHAR | YES | - | CODE-BACKED | Login/username of the BackOffice manager who uploaded this document (BackOffice.Manager.Login aliased as AddedBy). NULL if manager record not found. |
| 7 | StorageID | NVARCHAR | YES | - | CODE-BACKED | Storage system identifier for the document binary (BackOffice.TncDocument.StorageID). Used to locate the file in blob/document storage. |
| 8 | TncDocTypeID | INT | YES | - | CODE-BACKED | Type classification of this TnC document (BackOffice.TncDocument.TncDocTypeID). Lookup table not joined - raw ID returned. |
| 9 | CountryID | INT | YES | - | CODE-BACKED | Country this document is specific to (BackOffice.TncDocument.CountryID). NULL if applicable to all countries in the regulation. Links to Dictionary.Country. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| td.DocumentID = @documentId | BackOffice.TncDocument | Read (WHERE filter) | Primary data source |
| td.ManagerID | BackOffice.Manager | LEFT JOIN | Manager login (AddedBy) |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (BO TnC management screen) | @documentId | Application | Called by BO legal/compliance document management interface |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetTncDocument (procedure)
├── BackOffice.TncDocument (table) - primary data source
└── BackOffice.Manager (table) - AddedBy login
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.TncDocument | Table | Primary data source - WHERE DocumentID = @documentId AND IsActive = @isActive |
| BackOffice.Manager | Table | LEFT JOIN - manager login for AddedBy |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called by BO application layer. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Single row expected | Semantic | @documentId is a PK lookup - should return 0 or 1 rows. Combined with @isActive filter, returns 0 if document is in opposite active state. |
| NoLock on both tables | Implementation | Both BackOffice.TncDocument and BackOffice.Manager use WITH(NOLOCK) - dirty reads acceptable for document metadata. |

---

## 8. Sample Queries

### 8.1 Get active document by ID
```sql
EXEC [BackOffice].[GetTncDocument] @documentId = 42, @isActive = 1
```

### 8.2 Get inactive/archived document
```sql
EXEC [BackOffice].[GetTncDocument] @documentId = 42, @isActive = 0
```

### 8.3 List all active TnC documents for a regulation
```sql
SELECT DocumentID, RegulationID, DisplayName, TncDocTypeID, CountryID, DateAdded
FROM BackOffice.TncDocument WITH (NOLOCK)
WHERE IsActive = 1
  AND RegulationID = 1  -- e.g., CySEC
ORDER BY DateAdded DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 8.5/10, Logic: 7.5/10, Relationships: 8.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 5/5 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetTncDocument | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetTncDocument.sql*
