# Dictionary.RegionByIP

> Reference table mapping geographic regions (states/provinces) for IP-based geo-location, linked to countries. Contains 4,206 regions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RegionByIP_ID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.RegionByIP stores geographic regions (states, provinces, territories) resolved from IP address lookups. When a user connects, their IP is matched to a range in Dictionary.CountryIP, which provides both a CountryID and a RegionID pointing to this table. This enables sub-country geo-targeting for regulatory routing, content localization, and fraud detection.

This table is separate from Dictionary.State (which stores user-entered address states). RegionByIP regions are IP-derived and used for automated geo-detection, while State is user-declared and used for address verification.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

4,206 rows. Value map omitted due to size - concept entry only.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RegionByIP_ID | int (IDENTITY) | NO | - | CODE-BACKED | Primary key. Auto-incrementing region identifier. Referenced by CountryIP, RegionByIP_ISOCode, and SubRegion. |
| 2 | CountryID | int | NO | - | CODE-BACKED | Implicit FK to Dictionary.Country. The country this region belongs to. |
| 3 | Name | nvarchar(50) | YES | - | CODE-BACKED | Region name (e.g., "California", "Bavaria", "New South Wales"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Implicit FK | Region belongs to this country |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.CountryIP | RegionID | Implicit FK | IP ranges resolve to regions |
| Dictionary.RegionByIP_ISOCode | RegionByIP_ID | Implicit FK | ISO code mapping for regions |
| Dictionary.SubRegion | RegionID | Explicit FK | Sub-divisions within regions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.RegionByIP (table)
  +-- Dictionary.Country (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | Implicit FK via CountryID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CountryIP | Table | References RegionID |
| Dictionary.RegionByIP_ISOCode | Table | References RegionByIP_ID |
| Dictionary.SubRegion | Table | FK: RegionID -> RegionByIP_ID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RegionByIP | CLUSTERED PK | RegionByIP_ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Regions for a country
```sql
SELECT r.RegionByIP_ID, r.Name, c.Name AS Country FROM Dictionary.RegionByIP r WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON r.CountryID = c.CountryID WHERE c.Name = 'United States' ORDER BY r.Name
```

### 8.2 Count regions per country
```sql
SELECT c.Name, COUNT(*) AS RegionCount FROM Dictionary.RegionByIP r WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON r.CountryID = c.CountryID GROUP BY c.Name ORDER BY RegionCount DESC
```

### 8.3 Find region for an IP
```sql
SELECT c.Name AS Country, r.Name AS Region FROM Dictionary.CountryIP ip WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON ip.CountryID = c.CountryID
LEFT JOIN Dictionary.RegionByIP r WITH (NOLOCK) ON ip.RegionID = r.RegionByIP_ID
WHERE @IPAsInt BETWEEN ip.IPFrom AND ip.IPTo
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Dictionary.RegionByIP | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.RegionByIP.sql*
