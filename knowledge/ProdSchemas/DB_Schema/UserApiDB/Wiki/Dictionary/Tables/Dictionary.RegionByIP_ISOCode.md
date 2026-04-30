# Dictionary.RegionByIP_ISOCode

> Reference table mapping IP-derived regions to standardized ISO 3166-2 region codes. Contains 179 mappings.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RegionByIP_ID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.RegionByIP_ISOCode provides ISO 3166-2 standardized region codes for a subset of IP-derived regions. Not all 4,206 regions in Dictionary.RegionByIP have ISO codes - only 179 are mapped. These codes enable standardized regulatory region identification, particularly for jurisdictions that require ISO-standard geographic reporting.

---

## 2. Business Logic

No complex multi-column business logic patterns detected.

---

## 3. Data Overview

179 rows. Maps RegionByIP entries to ISO 3166-2 subdivision codes.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RegionByIP_ID | int | NO | - | CODE-BACKED | Primary key. Implicit FK to Dictionary.RegionByIP. The IP-derived region being mapped. |
| 2 | CountryID | int | NO | - | CODE-BACKED | Implicit FK to Dictionary.Country. Redundant with RegionByIP's CountryID for query convenience. |
| 3 | RegionISOCode | nvarchar(50) | YES | - | CODE-BACKED | ISO 3166-2 subdivision code (e.g., "US-CA" for California, "AU-NSW" for New South Wales). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RegionByIP_ID | Dictionary.RegionByIP | Implicit FK | The region this ISO code belongs to |
| CountryID | Dictionary.Country | Implicit FK | The country of this region |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.RegionByIP_ISOCode (table)
  +-- Dictionary.RegionByIP (table)
  |     +-- Dictionary.Country (table)
  +-- Dictionary.Country (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.RegionByIP | Table | Implicit FK via RegionByIP_ID |
| Dictionary.Country | Table | Implicit FK via CountryID |

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RegionByIP_ISOCode | CLUSTERED PK | RegionByIP_ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List regions with ISO codes
```sql
SELECT r.Name AS Region, c.Name AS Country, iso.RegionISOCode
FROM Dictionary.RegionByIP_ISOCode iso WITH (NOLOCK)
JOIN Dictionary.RegionByIP r WITH (NOLOCK) ON iso.RegionByIP_ID = r.RegionByIP_ID
JOIN Dictionary.Country c WITH (NOLOCK) ON iso.CountryID = c.CountryID ORDER BY c.Name, r.Name
```

### 8.2 Regions without ISO codes
```sql
SELECT r.RegionByIP_ID, r.Name, c.Name AS Country FROM Dictionary.RegionByIP r WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON r.CountryID = c.CountryID
LEFT JOIN Dictionary.RegionByIP_ISOCode iso WITH (NOLOCK) ON r.RegionByIP_ID = iso.RegionByIP_ID
WHERE iso.RegionByIP_ID IS NULL
```

### 8.3 Count ISO-mapped regions per country
```sql
SELECT c.Name, COUNT(*) AS MappedRegions FROM Dictionary.RegionByIP_ISOCode iso WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON iso.CountryID = c.CountryID GROUP BY c.Name ORDER BY MappedRegions DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Dictionary.RegionByIP_ISOCode | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.RegionByIP_ISOCode.sql*
