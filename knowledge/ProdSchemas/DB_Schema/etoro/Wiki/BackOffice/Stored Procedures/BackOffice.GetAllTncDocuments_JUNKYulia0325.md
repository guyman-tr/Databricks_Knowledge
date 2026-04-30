# BackOffice.GetAllTncDocuments_JUNKYulia0325

> DEPRECATED/JUNK: Returns all enabled T&C documents for a specific regulation (including inactive versions), with the adding manager's login. Marked for removal by Yulia, March 2025.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @regulationId - filters by regulation; returns all enabled TncDocument rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

> **DEPRECATED**: This procedure is tagged JUNK (suffix `_JUNKYulia0325`) indicating it was marked for decommissioning by Yulia in March 2025. It should not be used in new code. The recommended replacement is `BackOffice.GetAllLatestTncDocuments` (documented separately), which returns only the current active T&C document per regulation slot rather than all historical versions.

`BackOffice.GetAllTncDocuments_JUNKYulia0325` returns all T&C documents for a given regulation where `Enabled=1`, joining to `BackOffice.Manager` to surface the login of the back-office manager who added each document. Unlike `GetAllLatestTncDocuments`, it does NOT filter by `IsActive` and does NOT group to return only the latest per type/country - it returns every enabled version across all TncDocTypeID and CountryID combinations.

The procedure has a long history (originally created July 2016 for StorageAPI schema build, updated June 2018 for TncDocType support, and August 2018 for additional columns) and predates the IsActive dual-flag lifecycle system. The absence of an IsActive filter means it returns both current and superseded document versions.

---

## 2. Business Logic

### 2.1 All-Versions vs Latest-Only

**What**: This procedure returns all enabled (Enabled=1) versions of T&C documents for a regulation, not just the current active one.

**Columns/Parameters Involved**: `Enabled`, `IsActive`, `@regulationId`

**Rules**:
- Filters only by `Enabled=1` - explicitly NOT filtered by `IsActive`.
- Multiple versions (old + new) of T&C for the same regulation are all returned if Enabled=1.
- Contrast with `GetAllLatestTncDocuments`: that procedure uses `IsActive=1 AND Enabled=1` and returns only MAX(DocumentID) per group.
- For current active-document queries, use `GetAllLatestTncDocuments` instead.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @regulationId | INT | NO | - | CODE-BACKED | Regulatory jurisdiction ID. Filters BackOffice.TncDocument.RegulationID to return only T&C documents for this regulation. |
| 2 | DocumentID | INT | NO | - | CODE-BACKED | Primary key of the BackOffice.TncDocument record. |
| 3 | RegulationID | INT | NO | - | CODE-BACKED | Regulatory jurisdiction (same as @regulationId filter). |
| 4 | AddedBy | VARCHAR | YES | - | CODE-BACKED | Login (username) of the BackOffice.Manager who uploaded this document. NULL if ManagerID has no matching Manager record (LEFT JOIN). |
| 5 | DisplayName | NVARCHAR | YES | - | CODE-BACKED | Human-readable name shown to customers for this T&C document. |
| 6 | ComputerName | VARCHAR | YES | - | CODE-BACKED | Server hostname from which the T&C file was uploaded. Historical tracking only. |
| 7 | FileName | NVARCHAR | NO | - | CODE-BACKED | File path/name of the T&C PDF in the storage system. Format: {RegulationID}-{timestamp}-{original_name}.pdf. |
| 8 | DateAdded | DATETIME | NO | - | CODE-BACKED | UTC timestamp when this document was uploaded to BackOffice.TncDocument. |
| 9 | StorageID | INT | YES | - | CODE-BACKED | Reference to the external storage system where the PDF is physically stored. |
| 10 | TncDocTypeID | INT | NO | - | CODE-BACKED | T&C document sub-type within the regulation (1=main T&C; other values for product-specific addenda). Added June 2018 (ticket 51772). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @regulationId / DocumentID | BackOffice.TncDocument | Primary source | All enabled T&C documents for the regulation. |
| ManagerID | BackOffice.Manager | Lookup (LEFT JOIN) | Resolves manager ID to Login for AddedBy column. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. JUNK-tagged - not expected to have active callers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetAllTncDocuments_JUNKYulia0325 (procedure)
├── BackOffice.TncDocument (table)
└── BackOffice.Manager (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.TncDocument | Table | Main data source filtered by RegulationID and Enabled=1. |
| BackOffice.Manager | Table | LEFT JOIN on ManagerID to get Login for AddedBy. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | JUNK-tagged procedure not expected to be actively called. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

No SET NOCOUNT ON. NOLOCK on both tables. No IsActive filter (key difference from GetAllLatestTncDocuments).

---

## 8. Sample Queries

### 8.1 Get all enabled T&C documents for a regulation (use only for debugging/audit)
```sql
-- DEPRECATED: Use GetAllLatestTncDocuments for production queries
EXEC BackOffice.GetAllTncDocuments_JUNKYulia0325 @regulationId = 1;
```

### 8.2 Production equivalent (recommended replacement)
```sql
-- Use this instead - returns only current active document per slot
EXEC BackOffice.GetAllLatestTncDocuments @countryId = NULL;
```

### 8.3 Inline query showing full version history including inactive
```sql
SELECT td.DocumentID, td.RegulationID, td.TncDocTypeID,
    td.CountryID, m.Login AS AddedBy, td.DisplayName,
    td.Enabled, td.IsActive, td.DateAdded
FROM BackOffice.TncDocument td WITH (NOLOCK)
LEFT JOIN BackOffice.Manager m WITH (NOLOCK) ON m.ManagerID = td.ManagerID
WHERE td.RegulationID = 1
ORDER BY td.TncDocTypeID, td.DocumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetAllTncDocuments_JUNKYulia0325 | Type: Stored Procedure (DEPRECATED/JUNK) | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetAllTncDocuments_JUNKYulia0325.sql*
