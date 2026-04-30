# Dictionary.CountryIP

> Large reference table mapping IP address ranges to countries and regions for real-time geo-location. Contains 6.8M rows.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CountryID + IPFrom + IPTo (composite PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.CountryIP is the largest table in the Dictionary schema with 6.8 million rows, mapping IP address ranges to countries and regions. When a user connects to the platform, their IP address is looked up against this table to determine their geographic location. This drives regulatory routing, fraud detection, access control, and registration country pre-population.

IP-based geo-location is a critical first-line defense: it detects VPN usage (IP country != declared country), identifies restricted jurisdictions, and supports "country of access" audit trails required by regulators.

The table is periodically refreshed from commercial IP geolocation databases. Each row defines an IP range (IPFrom to IPTo as bigint representations) mapping to a country and optionally a region within that country.

---

## 2. Business Logic

### 2.1 IP Range Lookup

**What**: Binary search on IP ranges for real-time geo-location.

**Columns/Parameters Involved**: `CountryID`, `IPFrom`, `IPTo`, `RegionID`

**Rules**:
- IP is converted to bigint and matched: IPFrom <= IP <= IPTo
- Composite PK (CountryID, IPFrom, IPTo) ensures unique non-overlapping ranges per country
- RegionID is optional (NULL for ranges without sub-country precision)
- Multiple ranges may exist per country (IP blocks are not contiguous)

---

## 3. Data Overview

6,864,024 rows. Value map omitted due to size - reference data table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | CODE-BACKED | Part of composite PK. Implicit FK to Dictionary.Country. The country this IP range resolves to. |
| 2 | IPFrom | bigint | NO | - | CODE-BACKED | Part of composite PK. Start of the IP address range (IPv4 as bigint). |
| 3 | IPTo | bigint | NO | - | CODE-BACKED | Part of composite PK. End of the IP address range (IPv4 as bigint). |
| 4 | RegionID | int | YES | - | CODE-BACKED | Implicit FK to Dictionary.RegionByIP. Sub-country region for this IP range. NULL when region-level precision is unavailable. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Implicit FK | Country this IP range maps to |
| RegionID | Dictionary.RegionByIP | Implicit FK | Region within the country (when available) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CountryIP (table)
  +-- Dictionary.Country (table)
  +-- Dictionary.RegionByIP (table)
        +-- Dictionary.Country (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | Implicit FK via CountryID |
| Dictionary.RegionByIP | Table | Implicit FK via RegionID |

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CountryIP | CLUSTERED PK | CountryID, IPFrom, IPTo | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Look up country for an IP
```sql
DECLARE @IP BIGINT = 3232235876 -- 192.168.1.100
SELECT c.Name AS Country, r.Name AS Region FROM Dictionary.CountryIP ip WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON ip.CountryID = c.CountryID
LEFT JOIN Dictionary.RegionByIP r WITH (NOLOCK) ON ip.RegionID = r.RegionByIP_ID
WHERE @IP BETWEEN ip.IPFrom AND ip.IPTo
```

### 8.2 Count IP ranges per country (top 10)
```sql
SELECT TOP 10 c.Name, COUNT(*) AS RangeCount FROM Dictionary.CountryIP ip WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON ip.CountryID = c.CountryID GROUP BY c.Name ORDER BY RangeCount DESC
```

### 8.3 Check total IP space coverage
```sql
SELECT COUNT(*) AS TotalRanges, SUM(CAST(IPTo - IPFrom AS BIGINT)) AS TotalIPsCovered
FROM Dictionary.CountryIP WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Dictionary.CountryIP | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.CountryIP.sql*
