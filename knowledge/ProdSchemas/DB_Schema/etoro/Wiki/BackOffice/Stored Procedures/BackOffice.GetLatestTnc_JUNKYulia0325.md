# BackOffice.GetLatestTnc_JUNKYulia0325

> Returns the most recently added, enabled Terms and Conditions (TnC) document for a given regulation and TnC document type. JUNK - marked for removal March 2025.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @regulationId + @tncDocTypeId - identifies which TnC document set to query |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the latest active Terms and Conditions document for a specific regulatory framework and TnC document type. It answers: "What is the current TnC document that customers under a given regulation are required to accept?" - returning the document's storage reference, display name, and the manager who added it.

The procedure exists to support the StorageAPI flow (created 2016, per inline comments) that presents TnC documents to customers during registration or acceptance workflows. The TnC document type parameter (`@tncDocTypeId`, added in 2018) allows distinguishing between different categories of TnC documents (e.g., standard TnC vs. other agreement types) for the same regulation.

**Status: JUNK** - The `_JUNKYulia0325` suffix indicates this procedure was flagged for decommissioning in March 2025 by Yulia. It has no SQL callers in the codebase and its EXECUTE permission is not granted to any application user in the permissions files, suggesting it is already disconnected from active services.

---

## 2. Business Logic

### 2.1 Latest-Document Selection

**What**: Returns exactly one row - the most recent enabled TnC document for the given regulation and type.

**Columns/Parameters Involved**: `@regulationId`, `@tncDocTypeId`, `DocumentID`, `Enabled`

**Rules**:
- Filtered by `Enabled = 1` - only active/published TnC documents are candidates. Disabled documents (Enabled = 0) are not returned even if they are more recent.
- Ordered by `DocumentID DESC` and `TOP 1` - the document with the highest DocumentID is considered the latest for the given regulation/type combination.
- Default `@tncDocTypeId = 1` - callers that don't specify a type get TnC type 1 (the primary/standard TnC).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @regulationId | INT | NO | - | CODE-BACKED | Input parameter. The regulatory framework identifier (e.g., CySEC, FCA, FinCEN). Filters TnC documents to only those applicable to the specified regulation. References `BackOffice.TncDocument.RegulationID` / `Dictionary.Regulation`. |
| 2 | @tncDocTypeId | INT | NO | 1 | CODE-BACKED | Input parameter. The TnC document type identifier. Default = 1 (standard TnC). Added in 2018 to support multiple TnC document categories per regulation. References `BackOffice.TncDocument.TncDocTypeID`. |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DocumentID | INT | NO | - | CODE-BACKED | Primary key of the TnC document record in `BackOffice.TncDocument`. The highest DocumentID among enabled documents for the regulation/type combination. |
| 2 | RegulationID | INT | NO | - | CODE-BACKED | Regulatory framework identifier - echoes the input parameter. References `Dictionary.Regulation`. |
| 3 | AddedBy | NVARCHAR | YES | - | CODE-BACKED | Login name of the BackOffice manager who uploaded this TnC document. From `BackOffice.Manager.Login` via LEFT JOIN on `ManagerID`. NULL if no manager record found. |
| 4 | DisplayName | NVARCHAR | YES | - | CODE-BACKED | Human-readable display name of the TnC document shown to customers during the acceptance flow. From `BackOffice.TncDocument.DisplayName`. |
| 5 | ComputerName | NVARCHAR | YES | - | NAME-INFERRED | Name of the computer from which the document was uploaded. Audit/provenance field. |
| 6 | FileName | NVARCHAR | YES | - | CODE-BACKED | Original filename of the uploaded TnC document (e.g., "TnC_FCA_v3.pdf"). Used to identify the file in storage. |
| 7 | DateAdded | DATETIME | YES | - | CODE-BACKED | UTC timestamp when this TnC document was added to the system. |
| 8 | StorageID | NVARCHAR | YES | - | CODE-BACKED | Identifier used by the StorageAPI to locate and serve the document file. This is the reference callers need to retrieve the actual document content. |
| 9 | TncDocTypeID | INT | YES | - | CODE-BACKED | The TnC document type of this record - echoes the input @tncDocTypeId filter. Indicates the category of TnC (1 = standard, other values for additional agreement types added in 2018). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (internal) | BackOffice.TncDocument | Lookup (READ) | Primary source of TnC document records |
| ManagerID | BackOffice.Manager | Lookup | LEFT JOIN to resolve the uploading manager's login name |
| RegulationID | Dictionary.Regulation | Implicit | Regulation filter; the ID space is defined by Dictionary.Regulation |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No SQL callers found. No EXECUTE grants in permissions files - procedure appears disconnected from active services. JUNK status confirmed.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetLatestTnc_JUNKYulia0325 (procedure)
├── BackOffice.TncDocument (table)
└── BackOffice.Manager (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.TncDocument | Table | FROM clause; source of all TnC document records |
| BackOffice.Manager | Table | LEFT JOIN on ManagerID to resolve AddedBy (manager login) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found) | - | No SQL callers; no EXECUTE grants; JUNK as of March 2025 |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Enabled = 1 | Business filter | Only enabled/published TnC documents are candidates; draft or disabled versions are excluded |
| TOP 1 ORDER BY DocumentID DESC | Query logic | Returns only the single most recent document - the one with the highest auto-incremented DocumentID |

---

## 8. Sample Queries

### 8.1 Get the latest standard TnC for CySEC regulation

```sql
EXEC BackOffice.GetLatestTnc_JUNKYulia0325 @regulationId = 1, @tncDocTypeId = 1
```

### 8.2 Query TnC documents directly for a regulation

```sql
SELECT TOP 1
    td.DocumentID,
    td.RegulationID,
    m.Login AS AddedBy,
    td.DisplayName,
    td.FileName,
    td.DateAdded,
    td.StorageID,
    td.TncDocTypeID
FROM BackOffice.TncDocument td WITH (NOLOCK)
LEFT JOIN BackOffice.Manager m WITH (NOLOCK)
    ON m.ManagerID = td.ManagerID
WHERE td.RegulationID = 1
  AND td.TncDocTypeID = 1
  AND td.Enabled = 1
ORDER BY td.DocumentID DESC;
```

### 8.3 List all enabled TnC documents grouped by regulation and type

```sql
SELECT td.RegulationID,
       td.TncDocTypeID,
       COUNT(*) AS TotalDocuments,
       MAX(td.DocumentID) AS LatestDocumentID,
       MAX(td.DateAdded) AS LatestDateAdded
FROM BackOffice.TncDocument td WITH (NOLOCK)
WHERE td.Enabled = 1
GROUP BY td.RegulationID, td.TncDocTypeID
ORDER BY td.RegulationID, td.TncDocTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 8.9/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetLatestTnc_JUNKYulia0325 | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetLatestTnc_JUNKYulia0325.sql*
