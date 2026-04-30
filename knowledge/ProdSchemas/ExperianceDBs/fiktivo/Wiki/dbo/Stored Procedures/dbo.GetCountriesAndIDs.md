# dbo.GetCountriesAndIDs

> Returns CountryID and Name for every row in tblaff_Country with no filtering, providing a minimal ID-to-name lookup list.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Unknown |
| **Created** | Unknown |

---

## 1. Business Meaning

Several parts of the affiliate platform need a lightweight country ID-to-name mapping for display purposes (e.g., populating a label next to a stored CountryID, or building a simple lookup dictionary). This procedure returns the minimum required columns -- CountryID and Name -- for every row in the country table, including rows that may lack an ISO abbreviation code.

Unlike dbo.GetCountries, which filters to rows with valid abbreviation codes and returns additional segmentation columns, this procedure performs no filtering and returns only the two core identification columns. It is suited to scenarios where the caller needs a comprehensive ID-to-name index rather than a validated, attribute-rich country list.

---

## 2. Business Logic

### 2.1 Unfiltered Country ID-to-Name Map

**What**: Returns CountryID and Name for all rows in tblaff_Country.

**Columns/Parameters Involved**: `CountryID`, `Name`

**Rules**:
- No WHERE clause; all rows including those without abbreviation codes are returned
- No parameters; the result is always the full table
- Duplicate names or NULL names are possible if the underlying table contains them; callers must handle this

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure accepts no parameters.

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| - | (none) | - | - | - | No parameters; always returns all rows. |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_Country | SELECT | Full table scan; no filter applied |

### 5.3 Result Set

| Column | Source | Description |
|--------|--------|-------------|
| CountryID | tblaff_Country | Primary key of the country record |
| Name | tblaff_Country | Full country name |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetCountriesAndIDs (stored procedure)
+-- dbo.tblaff_Country (table) [SELECT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Country | Table | Sole data source |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Country ID resolution layer | Application | Calls this procedure to build an ID-to-name lookup dictionary |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- WITH (NOLOCK) hint is applied; consistent with the read-only reference table pattern
- No SET NOCOUNT ON; callers may receive rowcount messages
- No abbreviation code filter -- includes incomplete/placeholder country rows unlike dbo.GetCountries
- For validated, attribute-rich country data, prefer dbo.GetCountries

---

## 8. Sample Queries

### 8.1 Return all country IDs and names

```sql
EXEC dbo.GetCountriesAndIDs;
```

### 8.2 Look up a country name by ID

```sql
SELECT Name
FROM dbo.tblaff_Country WITH (NOLOCK)
WHERE CountryID = 50;
```

### 8.3 Compare coverage against the filtered list

```sql
SELECT COUNT(*) AS AllRows FROM dbo.tblaff_Country WITH (NOLOCK);

SELECT COUNT(*) AS ValidRows
FROM dbo.tblaff_Country WITH (NOLOCK)
WHERE Abbreviation IS NOT NULL AND RTRIM(Abbreviation) <> '';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10*
*Object: dbo.GetCountriesAndIDs | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetCountriesAndIDs.sql*
