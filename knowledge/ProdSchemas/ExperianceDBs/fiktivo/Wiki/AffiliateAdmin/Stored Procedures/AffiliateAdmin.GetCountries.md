# AffiliateAdmin.GetCountries

> Returns countries with their affiliate group assignments, supporting optional search filtering by country name.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | CountryID, Name, AffiliatesGroupsID, Abbreviation, AffiliatesGroupsName |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** GetCountries retrieves the list of countries along with their affiliate group assignments. Each country row includes the country's ID, name, abbreviation, and the affiliate group it belongs to (if any). An optional search word parameter allows filtering by country name.

**WHY:** Countries play an important role in the affiliate management platform for geographic segmentation. Affiliates are organized into groups, and countries are mapped to these groups to define geographic territories. The admin interface uses this procedure to display the country-to-group mapping, enabling administrators to understand and manage geographic assignments for affiliate operations.

**HOW:** The procedure performs a LEFT JOIN between `tblaff_Country` and `AffiliateAdmin.AffiliatesGroups` on AffiliatesGroupsID. The LEFT JOIN ensures countries without group assignments are still returned. When @SearchWord is provided, a LIKE filter is applied to the country name. The result includes CountryID, Name, AffiliatesGroupsID, Abbreviation, and AffiliatesGroupsName.

---

## 2. Business Logic

### 2.1 Country-Group Mapping
The LEFT JOIN with `AffiliateAdmin.AffiliatesGroups` retrieves the affiliate group name for each country. Countries not assigned to any group will have NULL values for AffiliatesGroupsID and AffiliatesGroupsName, making it easy to identify unassigned countries.

### 2.2 Optional Search Filtering
When @SearchWord is provided, the procedure filters countries by name using a LIKE comparison. This supports partial matching for type-ahead search in the admin interface. When NULL, all countries are returned.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SearchWord | NVARCHAR(50) | Yes | NULL | CODE-BACKED | Optional partial name filter for country search; NULL returns all countries |

**Result Set:** CountryID (INT), Name (NVARCHAR), AffiliatesGroupsID (INT, nullable), Abbreviation (NVARCHAR), AffiliatesGroupsName (NVARCHAR, nullable) (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Country` | Table | SELECT country details |
| `AffiliateAdmin.AffiliatesGroups` | Table | LEFT JOIN for affiliate group name resolution |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Country management screen | Application | Displays countries with group assignments |
| Geographic configuration | Application | Country-to-group mapping administration |

---

## 6. Dependencies

### 6.0 Chain
`GetCountries` -> `tblaff_Country` + `AffiliateAdmin.AffiliatesGroups`

### 6.1 Depends On
- `dbo.tblaff_Country` - Source table for country data
- `AffiliateAdmin.AffiliatesGroups` - Affiliate group definitions for name resolution

### 6.2 Depend On This
No known database dependencies. Called from application layer.

---

## 7. Technical Details

### 7.1 Indexes
N/A

### 7.2 Constraints
N/A

---

## 8. Sample Queries

```sql
-- 1. Get all countries with their group assignments
EXEC AffiliateAdmin.GetCountries;
```

```sql
-- 2. Search countries by partial name
EXEC AffiliateAdmin.GetCountries @SearchWord = N'United';
```

```sql
-- 3. Find unassigned countries (check results for NULL AffiliatesGroupsID)
EXEC AffiliateAdmin.GetCountries;
-- Filter application-side for rows where AffiliatesGroupsID IS NULL
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL references: PART-3577, PART-5531.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetCountries | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetCountries.sql*
