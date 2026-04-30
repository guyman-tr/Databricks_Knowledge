# Trade.GetCountryIDsWithName

> Returns all country IDs with their lowercase names from the Dictionary.Country lookup table, ordered alphabetically for display in selection lists.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns CountryID and CountryName from Dictionary.Country |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides the complete list of countries with their IDs and names for use in UI selection lists, report filters, and country-based processing. The names are returned in lowercase for consistent display and comparison. It reads from the Dictionary.Country reference table which is the authoritative source for country data across the platform.

Data flow: API/UI service calls this procedure -> receives all countries ordered alphabetically -> populates country dropdowns or filters.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple lookup table reader with lowercase name transformation.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

None.

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | INT | NO | - | CODE-BACKED | Unique identifier for the country. PK of Dictionary.Country. |
| 2 | CountryName | VARCHAR | NO | - | CODE-BACKED | Country name in lowercase. Computed: LOWER(Name) from Dictionary.Country. Used for case-insensitive display and comparison. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Dictionary.Country | Read | Reads all country records |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| API/UI Services | EXEC | Caller | Country list for selection and filtering |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCountryIDsWithName (procedure)
└── Dictionary.Country (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | Source of all country records |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| UI/API | External | Country selection lists |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- SET NOCOUNT ON for performance
- Results ordered by CountryName (column 2)

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Trade.GetCountryIDsWithName;
```

### 8.2 Query countries directly

```sql
SELECT CountryID, LOWER(Name) AS CountryName
FROM Dictionary.Country WITH (NOLOCK)
ORDER BY Name;
```

### 8.3 Find country by name pattern

```sql
SELECT CountryID, Name
FROM Dictionary.Country WITH (NOLOCK)
WHERE Name LIKE '%united%'
ORDER BY Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCountryIDsWithName | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCountryIDsWithName.sql*
