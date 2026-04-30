# Dictionary.SubRegion

> Reference table defining sub-divisions within IP-derived regions for granular geographic targeting. Contains 107 sub-regions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | SubRegionID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.SubRegion provides an additional geographic granularity level below regions for targeted geo-operations. Each sub-region belongs to both a country and a region within that country. The table has 107 entries covering specific areas that require sub-regional targeting, such as distinct metropolitan areas or administrative zones within a state/province.

---

## 2. Business Logic

No complex multi-column business logic patterns detected.

---

## 3. Data Overview

107 rows. Sub-divisions within IP-derived regions.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SubRegionID | int (IDENTITY) | NO | - | CODE-BACKED | Primary key. Auto-incrementing sub-region identifier. |
| 2 | CountryID | int | NO | - | CODE-BACKED | FK to Dictionary.Country. The country this sub-region belongs to. |
| 3 | RegionID | int | NO | - | CODE-BACKED | FK to Dictionary.RegionByIP. The parent region within the country. |
| 4 | ShortName | nvarchar(100) | NO | - | CODE-BACKED | Abbreviated sub-region name for compact display and API responses. |
| 5 | Name | nvarchar(255) | YES | - | CODE-BACKED | Full sub-region name. NULL when ShortName is sufficient. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Explicit FK | Country this sub-region belongs to |
| RegionID | Dictionary.RegionByIP | Explicit FK | Parent region within the country |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.SubRegion (table)
  +-- Dictionary.Country (table)
  +-- Dictionary.RegionByIP (table)
        +-- Dictionary.Country (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | FK: CountryID |
| Dictionary.RegionByIP | Table | FK: RegionID -> RegionByIP_ID |

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SubRegion | CLUSTERED PK | SubRegionID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_SubRegion_Country | FOREIGN KEY | CountryID -> Dictionary.Country(CountryID) |
| FK_SubRegion_Region | FOREIGN KEY | RegionID -> Dictionary.RegionByIP(RegionByIP_ID) |

---

## 8. Sample Queries

### 8.1 List sub-regions with hierarchy
```sql
SELECT sr.ShortName, sr.Name, r.Name AS Region, c.Name AS Country
FROM Dictionary.SubRegion sr WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON sr.CountryID = c.CountryID
JOIN Dictionary.RegionByIP r WITH (NOLOCK) ON sr.RegionID = r.RegionByIP_ID ORDER BY c.Name, r.Name, sr.ShortName
```

### 8.2 Count sub-regions per country
```sql
SELECT c.Name, COUNT(*) AS SubRegionCount FROM Dictionary.SubRegion sr WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON sr.CountryID = c.CountryID GROUP BY c.Name ORDER BY SubRegionCount DESC
```

### 8.3 Find sub-regions for a region
```sql
SELECT sr.SubRegionID, sr.ShortName, sr.Name FROM Dictionary.SubRegion sr WITH (NOLOCK)
WHERE sr.RegionID = @RegionID ORDER BY sr.ShortName
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Dictionary.SubRegion | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.SubRegion.sql*
