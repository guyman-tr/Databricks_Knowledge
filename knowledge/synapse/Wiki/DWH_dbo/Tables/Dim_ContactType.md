# DWH_dbo.Dim_ContactType

> Empty dimension table designed to classify contact types — the table has 0 rows, no active ETL, and no consuming SPs or views; purpose and production source are unknown.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown — no ETL SP, staging table, migration script, or production DB equivalent found |
| **Refresh** | None — empty table, no active ETL |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (ContactTypeID ASC) |
| | |
| **UC Target** | Not in Generic Pipeline mapping — not exported to Gold/UC |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_ContactType` is a dimension table whose purpose is to enumerate categories of "contact types" — likely customer contact methods or interaction channel types (e.g., email, phone, chat). However, the table has **0 rows** and its intended business meaning cannot be confirmed from data.

No upstream production source has been found for this table. Exhaustive searching across the Dataplatform SSDT repo found no stored procedure that writes to it, no staging table that feeds it, no DWH_Migration script that seeded it, and no entry in the Generic Pipeline mapping. The DB_Schema etoro repository has no ContactType table or wiki. This table appears to be a planned dimension that was never populated or connected to an ETL pipeline.

The presence of `DWHContactTypeID` (a standard DWH surrogate key column pattern seen on SP_Dictionaries-loaded tables) suggests this table was designed to be populated by `SP_Dictionaries_DL_To_Synapse`, but the corresponding ETL section was never implemented. This table is a candidate for removal or future ETL development.

---

## 2. Business Logic

No business logic can be documented — the table has 0 rows and no observable data patterns. The DDL structure suggests a standard DWH dimension design (natural key + DWH surrogate + status flag + ETL timestamps) but no values have ever been loaded.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on `ContactTypeID`. The design is appropriate for a small dimension table. However, since the table is empty, all queries will return 0 rows.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table is NOT in the Generic Pipeline mapping and is therefore not exported to the Gold/UC layer.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Why does this table return 0 rows? | Table has no ETL. No data has ever been loaded. |
| Should I JOIN to this table? | Not recommended — no data, no consuming objects. Consult data engineering before using. |

### 3.3 Common JOINs

No JOINs exist in the codebase. This table is not referenced by any SP, view, or downstream table.

### 3.4 Gotchas

- **Empty table**: 0 rows. Any JOIN to this table will zero out your result set.
- **No ETL**: No SP, ADF pipeline, or migration script populates this table. It is an empty shell.
- **Not in UC**: The table is not exported to the Gold lake or Unity Catalog.
- **Dead schema**: This table does not appear in any other object in the Dataplatform SSDT codebase — no SP reads from or writes to it.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| ★★ | Tier 3b | DDL structure from SSDT repo — inferred from column name and type |
| ★ | Tier 4-Inferred | Column name guessing — [UNVERIFIED] |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ContactTypeID | int | NO | Natural key identifying the contact type. 0 rows — values never loaded. Expected to match a production Dictionary.ContactType.ContactTypeID if ETL is ever implemented. (Tier 3b — SSDT DDL, DWH_dbo.Dim_ContactType) |
| 2 | Name | varchar(20) | YES | [UNVERIFIED] Short label for the contact type category (e.g., "Email", "Phone", "Chat"). No data exists to confirm actual values. (Tier 4 — inferred) |
| 3 | DWHContactTypeID | int | NO | DWH surrogate key — standard DWH pattern where DWH{X}ID mirrors the source PK. Expected to equal ContactTypeID if loaded by SP_Dictionaries pattern. 0 rows — never populated. (Tier 3b — SSDT DDL DWH design pattern) |
| 4 | UpdateDate | datetime | YES | ETL load timestamp — would record GETDATE() on each SP_Dictionaries refresh. Currently NULL (0 rows, no ETL). (Tier 3b — SSDT DDL, SP_Dictionaries pattern) |
| 5 | InsertDate | datetime | YES | ETL insert timestamp — would record GETDATE() when row first loaded. Currently NULL (0 rows, no ETL). (Tier 3b — SSDT DDL, SP_Dictionaries pattern) |
| 6 | StatusID | bit | YES | Active/inactive flag — standard SP_Dictionaries convention (1 = active). Currently NULL (0 rows, no ETL). (Tier 3b — SSDT DDL, SP_Dictionaries pattern) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| All columns | Unknown | Unknown | No ETL found |

No production source identified. Exhaustive search across SSDT repo, DB_Schema repo, NoDbObjectsScripts, and Generic Pipeline mapping returned no results.

### 5.2 ETL Pipeline

```
[Unknown production source] -> [No ETL implemented] -> DWH_dbo.Dim_ContactType (empty)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | Unknown | No matching production table found in etoro DB or any other source |
| ETL | None | No SP writes to this table. No staging table exists. No migration script found. |
| Target | DWH_dbo.Dim_ContactType | 0 rows — never populated |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| — | — | No foreign key relationships. Leaf dimension. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| — | — | No consuming SPs, views, or downstream tables reference this table. |

---

## 7. Sample Queries

### 7.1 Confirm table is empty

```sql
SELECT COUNT(*) AS RowCount FROM DWH_dbo.Dim_ContactType
-- Expected: 0
```

### 7.2 View DDL structure

```sql
-- Use SSDT repo: DWH_dbo.Dim_ContactType.sql
-- 6 columns: ContactTypeID, Name, DWHContactTypeID, UpdateDate, InsertDate, StatusID
SELECT TOP 0 * FROM DWH_dbo.Dim_ContactType
```

### 7.3 Validate no ETL has run recently

```sql
SELECT
    COUNT(*) AS TotalRows,
    MAX(UpdateDate) AS LastRefresh
FROM DWH_dbo.Dim_ContactType
-- Expected: 0 rows, NULL LastRefresh
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped — empty table with completely unknown provenance; Jira search unlikely to yield actionable results without knowing the intended source system.)

---

*Generated: 2026-03-19 | Quality: 4.5/10 (★★☆☆☆) | Phases: 11/14*
*Tiers: 0 T1, 0 T2, 0 T2b, 0 T3, 5 T3b, 1 T4 [UNVERIFIED], 0 T5 | Elements: 8.3/10, Logic: 2/10, Relationships: 2/10, Sources: 2/10*
*Object: DWH_dbo.Dim_ContactType | Type: Table | Production Source: Unknown*
