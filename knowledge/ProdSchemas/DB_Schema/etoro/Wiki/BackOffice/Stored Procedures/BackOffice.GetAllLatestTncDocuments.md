# BackOffice.GetAllLatestTncDocuments

> Returns the most recent active Terms & Conditions document per regulatory jurisdiction and document type, optionally filtered by country.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @countryId - optional country filter; returns one row per (RegulationID, TncDocTypeID, CountryID) group |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetAllLatestTncDocuments` answers the question: "Which T&C document should each regulatory jurisdiction currently display to customers?" For every active (Enabled=1, IsActive=1) T&C document in `BackOffice.TncDocument`, it returns only the highest DocumentID per (RegulationID, TncDocTypeID, CountryID) combination - since DocumentID is an IDENTITY column, the maximum ID is always the most recently uploaded version.

eToro operates under multiple regulatory frameworks (CySEC, FCA, ASIC, BVI, etc.) and serves customers across many countries. Different regulations require different Terms & Conditions documents, and within a regulation, country-specific addenda may override the standard version. This procedure provides DocAPI (SQL_UserDocAPI service account) with the current authoritative T&C set for presentation and signing workflows.

The @countryId NULL vs. non-NULL distinction is critical: passing NULL returns only regulation-level global documents (CountryID IS NULL); passing a specific country ID returns only country-targeted documents for that country. These two modes are used separately - global T&Cs for most customers, country-specific for jurisdictions requiring local variants (added per COAKVU-3182 to extend T&C signing to support both Regulation and Country dimensions).

---

## 2. Business Logic

### 2.1 Latest Document Selection via MAX(DocumentID)

**What**: Among multiple versions of T&C documents for the same regulatory slot, only the most recently uploaded document is returned.

**Columns/Parameters Involved**: `DocumentID`, `RegulationID`, `TncDocTypeID`, `CountryID`

**Rules**:
- GROUP BY (RegulationID, TncDocTypeID, CountryID) collapses all versions for the same regulatory slot.
- MAX(DocumentID) selects the highest IDENTITY value = most recently inserted row = latest uploaded version.
- Only rows with Enabled=1 AND IsActive=1 are eligible. Superseded documents are excluded by IsActive=0; temporarily suppressed documents by Enabled=0.
- One row per regulatory slot is returned, regardless of how many historical versions exist.

**Diagram**:
```
BackOffice.TncDocument (all versions for CySEC, type 1, global):
  DocumentID=5  (IsActive=0, Enabled=1) -- old version, deactivated
  DocumentID=12 (IsActive=1, Enabled=1) -- current
  DocumentID=18 (IsActive=1, Enabled=0) -- new version, not yet enabled

Result: DocumentID=12 (max of eligible rows)
```

### 2.2 Global vs. Country-Specific T&C Routing

**What**: @countryId NULL and non-NULL are mutually exclusive modes, each returning a different tier of T&C documents.

**Columns/Parameters Involved**: `@countryId`, `CountryID`

**Rules**:
- `@countryId IS NULL AND CountryID IS NULL`: Returns regulation-level documents that apply globally across all countries in that regulation. Used for the majority of customers.
- `@countryId IS NOT NULL AND CountryID = @countryId`: Returns documents targeted specifically to one country. Used for jurisdictions that require a local T&C variant on top of the regulation-level document.
- A single call cannot return both tiers simultaneously; callers must make two separate calls if both are needed.

**Diagram**:
```
@countryId = NULL  -> Global T&Cs (CountryID IS NULL in TncDocument)
@countryId = 123   -> Country-specific T&Cs for country 123 only
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @countryId | INT | YES | NULL | CODE-BACKED | Optional country filter. NULL = return only global regulation-level T&Cs (BackOffice.TncDocument.CountryID IS NULL). Non-null = return only T&Cs targeting that specific country. The two modes are not combined in a single call. |
| 2 | DocumentID | INT | NO | - | CODE-BACKED | MAX(DocumentID) within the group - the most recently uploaded T&C document for this regulatory slot. IDENTITY PK of BackOffice.TncDocument; higher value always means newer version. |
| 3 | RegulationID | INT | NO | - | CODE-BACKED | Regulatory jurisdiction this T&C document belongs to. FK to Dictionary or configuration table. Groups results and determines which regulatory framework (CySEC, FCA, ASIC, BVI, etc.) each document applies to. Results are ORDER BY RegulationID ASC. |
| 4 | TncDocTypeID | INT | NO | - | CODE-BACKED | Type of T&C document within a regulation. Groups documents by sub-type (e.g., main T&C, product addendum, risk warning). FK to a T&C document type lookup. Default type is 1 (main T&C). |
| 5 | CountryID | INT | YES | - | CODE-BACKED | Country this document targets, or NULL for regulation-wide global documents. Matches the @countryId filter applied in the WHERE clause. Part of the GROUP BY key. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DocumentID / RegulationID / TncDocTypeID / CountryID | BackOffice.TncDocument | Primary source | Aggregates over active T&C document records. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by SQL_UserDocAPI service account (external DocAPI layer). No SQL procedure callers found in repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetAllLatestTncDocuments (procedure)
└── BackOffice.TncDocument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.TncDocument | Table | Aggregated with MAX(DocumentID) GROUP BY to find latest active T&C per regulatory slot. Filtered: Enabled=1 AND IsActive=1. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called externally by the DocAPI service (SQL_UserDocAPI). No SQL procedure callers in repository. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

SET NOCOUNT ON. NOLOCK on BackOffice.TncDocument. Aggregation via MAX/GROUP BY. Results ordered by RegulationID ASC.

---

## 8. Sample Queries

### 8.1 Get all latest global T&C documents (across all regulations)
```sql
-- Returns one row per (RegulationID, TncDocTypeID) for global T&Cs
EXEC BackOffice.GetAllLatestTncDocuments @countryId = NULL;
```

### 8.2 Get latest T&C documents for a specific country
```sql
-- Returns country-specific T&C documents for CountryID=78 (example)
EXEC BackOffice.GetAllLatestTncDocuments @countryId = 78;
```

### 8.3 Inline query to see all active T&C documents with full details
```sql
SELECT
    td.DocumentID,
    td.RegulationID,
    td.TncDocTypeID,
    td.CountryID,
    td.DisplayName,
    td.FileName,
    td.Enabled,
    td.IsActive,
    td.ManagerID,
    td.CreatedDate
FROM BackOffice.TncDocument td WITH (NOLOCK)
WHERE td.Enabled = 1
  AND td.IsActive = 1
  AND td.CountryID IS NULL   -- global T&Cs
ORDER BY td.RegulationID, td.TncDocTypeID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HLD COAKVU-3182: Extend sign T&C logic to support Regulation and Country](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/12420907116) | Confluence | Describes the architecture extending T&C signing to support both Regulation and Country dimensions - context for the @countryId parameter and the two-tier T&C routing model. |
| [Doc Api DB Migration Mapping](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/1782906896) | Confluence | DocAPI DB migration mapping - confirms GetAllLatestTncDocuments is part of the DocAPI layer that replaced direct SQL access from BackOffice. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetAllLatestTncDocuments | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetAllLatestTncDocuments.sql*
