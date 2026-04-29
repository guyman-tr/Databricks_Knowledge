# DWH_dbo.Dim_ContactType

> Dormant dimension table with 0 rows. Defines contact type classifications with a DWH surrogate key pattern. No writer stored procedure, no generic pipeline mapping, and no upstream production source could be identified. Table exists in DDL but has never been populated in the current Synapse environment.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown (dormant — no writer SP, no generic pipeline entry) |
| **Refresh** | None (table is empty, no ETL process identified) |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (ContactTypeID ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | None |
| **UC Table Type** | — |

---

## 1. Business Meaning

Dim_ContactType is a dimension table intended to classify types of customer contacts (e.g., phone, email, chat). The table has **0 rows** and appears to have never been populated in the Synapse DWH. No stored procedure writes to this table, and it does not appear in the generic pipeline mapping that governs Bronze/Gold data exports.

The table follows the standard DWH dimension pattern with a source key (`ContactTypeID`), a DWH surrogate key (`DWHContactTypeID`), a descriptive label (`Name`), ETL audit timestamps (`InsertDate`, `UpdateDate`), and an active/inactive flag (`StatusID`). Despite this well-formed structure, the table is effectively orphaned — no downstream views, SPs, or BI_DB objects reference it.

A BI_DB stored procedure (`SP_NewContactActivityPerRep`) uses the string `ContactType` as a column alias for Salesforce `ActionName`, but this is unrelated to this table.

---

## 2. Business Logic

### 2.1 Surrogate Key Pattern

**What**: The table uses a dual-key pattern common in DWH dimensions.
**Columns Involved**: ContactTypeID, DWHContactTypeID
**Rules**:
- `ContactTypeID` is the natural/source key (clustered index).
- `DWHContactTypeID` is the DWH-assigned surrogate key.
- Both are `int NOT NULL`, suggesting they were designed as mandatory identifiers.

### 2.2 Status Flag

**What**: Standard soft-delete / active-inactive pattern.
**Columns Involved**: StatusID
**Rules**:
- `StatusID` is `bit NULL` — expected values would be 1 (active) and 0 (inactive).
- NULL status is possible, which may indicate unknown or uninitialized state.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: REPLICATE — full copy on every compute node. Appropriate for a small dimension table.
- **Index**: CLUSTERED INDEX on `ContactTypeID` — supports efficient point lookups by contact type ID.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What contact types exist? | `SELECT * FROM DWH_dbo.Dim_ContactType WHERE StatusID = 1` (currently returns 0 rows) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| (none identified) | — | No downstream consumers found |

### 3.4 Gotchas

- **Table is empty**: Any JOIN to this table will produce no matches. Fact tables referencing a ContactTypeID FK will lose rows in an INNER JOIN.
- **No writer SP**: There is no ETL process to populate this table. If data is needed, a manual load or new SP must be created.
- **StatusID is nullable**: Unlike most dimension status flags, this allows NULL, which could cause unexpected behavior in `WHERE StatusID = 1` filters.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream production wiki — verbatim quote |
| Tier 2 | Derived from stored procedure / ETL logic |
| Tier 3 | Inferred from DDL structure, naming conventions, and data patterns |
| Tier 4 | Inferred from column name only — no corroborating evidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ContactTypeID | int | NO | Natural/source key identifying the contact type. Clustered index key. No writer SP or upstream source found to confirm origin. (Tier 3 — DDL structure, no upstream) |
| 2 | Name | varchar(20) | YES | Human-readable label for the contact type (e.g., expected values like phone, email, chat). Max 20 characters. No data available to confirm actual values. (Tier 3 — DDL structure, no upstream) |
| 3 | DWHContactTypeID | int | NO | DWH-assigned surrogate key for the contact type dimension. Follows the standard `DWH{Entity}ID` naming pattern used across DWH dimension tables. (Tier 3 — DDL structure, no upstream) |
| 4 | UpdateDate | datetime | YES | Timestamp of the last ETL update to this row. Standard DWH audit column. NULL if the row has never been updated after initial insert. (Tier 3 — DDL structure, no upstream) |
| 5 | InsertDate | datetime | YES | Timestamp of the initial ETL insert of this row. Standard DWH audit column. NULL handling is unusual — most DWH tables enforce NOT NULL on InsertDate. (Tier 3 — DDL structure, no upstream) |
| 6 | StatusID | bit | YES | Active/inactive flag. Expected: 1 = active, 0 = inactive. NULL may indicate uninitialized state. Standard DWH dimension soft-delete pattern. (Tier 3 — DDL structure, no upstream) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| ContactTypeID | Unknown | Unknown | Unknown — no writer SP or pipeline mapping found |
| Name | Unknown | Unknown | Unknown |
| DWHContactTypeID | Unknown | Unknown | Unknown — DWH surrogate key, likely auto-assigned |
| UpdateDate | Unknown | Unknown | Unknown — standard ETL audit |
| InsertDate | Unknown | Unknown | Unknown — standard ETL audit |
| StatusID | Unknown | Unknown | Unknown — standard soft-delete flag |

### 5.2 ETL Pipeline

```
(Unknown production source)
  |-- (no generic pipeline mapping found) --|
  v
(no staging table identified)
  |-- (no writer SP found) --|
  v
DWH_dbo.Dim_ContactType (0 rows — dormant)
  |-- (not in generic pipeline — no UC target) --|
  v
_Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| (none identified) | — | No FK relationships found in DDL or SP code |

### 6.2 Referenced By (other objects point to this)

| Element | Referencing Object | Description |
|---------|-------------------|-------------|
| (none identified) | — | No SPs, views, or tables reference Dim_ContactType |

---

## 7. Sample Queries

### 7.1 List All Contact Types

```sql
SELECT ContactTypeID, Name, DWHContactTypeID, StatusID
FROM DWH_dbo.Dim_ContactType
WHERE StatusID = 1
ORDER BY ContactTypeID;
```

### 7.2 Check Table Population Status

```sql
SELECT COUNT(*) AS TotalRows,
       SUM(CASE WHEN StatusID = 1 THEN 1 ELSE 0 END) AS ActiveRows,
       MIN(InsertDate) AS EarliestInsert,
       MAX(UpdateDate) AS LatestUpdate
FROM DWH_dbo.Dim_ContactType;
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources found for this dormant table.

---

*Generated: 2026-04-27 | Quality: 5/10 | Phases: 11/14*
*Tiers: 0 T1, 0 T2, 6 T3, 0 T4, 0 T5 | Elements: 6/6, Logic: 3/10, Lineage: 2/10*
*Object: DWH_dbo.Dim_ContactType | Type: Table | Production Source: Unknown (dormant)*
