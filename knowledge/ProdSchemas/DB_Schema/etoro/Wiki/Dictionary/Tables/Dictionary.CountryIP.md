# Dictionary.CountryIP

> Large geolocation mapping table (6.8M+ rows) that maps IP address ranges to countries and regions — used for GeoIP resolution during registration, login, and fraud detection.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CountryID + IPFrom + IPTo (composite PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 4 active (clustered composite PK + 3 NC) |

---

## 1. Business Meaning

Dictionary.CountryIP provides IP-to-country geolocation resolution for the eToro platform. Each row maps a range of IP addresses (as integer values) to a specific country and optionally a sub-national region. When a user connects to the platform, the system converts their IP address to an integer and performs a range lookup against this table to determine their geographic location.

This geolocation data drives multiple critical platform functions: during registration it auto-detects the customer's country (pre-filling the registration form and determining the applicable regulatory entity), during login it validates that the IP location matches expected patterns (fraud detection), and during transactions it provides location context for risk scoring and compliance reporting.

The table is heavily indexed with 4 indexes optimizing different lookup patterns: by CountryID (find all IPs for a country), by IP range in both directions (fast range overlap searches), and the composite PK for exact match. Multiple Internal schema functions and procedures consume this table: `Internal.GetCountryIDByIP`, `Internal.GetCountryNameByIP`, `Internal.GetRegionIDByIP` (functions), and `Internal.GetCountryToIpList`, `Internal.GetCountryNameByIp`, `Internal.LoadGeoDataFromStaticResources`, `Internal.GetCountryToIpsCount`, `Internal.GetIpRangesForCountry` (procedures). Also referenced by `dbo.GetUsaIPsList`.

---

## 2. Business Logic

### 2.1 IP Range Lookup Algorithm

**What**: IP-to-country resolution using integer range comparisons.

**Columns/Parameters Involved**: `CountryID`, `IPFrom`, `IPTo`, `RegionID`

**Rules**:
- IP addresses are stored as bigint integers (IPv4 converted: `IP = octet1*16777216 + octet2*65536 + octet3*256 + octet4`). For example, IP 5.39.217.74 = 87965770.
- Lookup: `WHERE @IPInteger BETWEEN IPFrom AND IPTo` — finds the country for a given IP.
- Ranges can be as small as a single IP (IPFrom = IPTo) or as large as /8 blocks (16M addresses).
- Multiple ranges can map to the same CountryID — a country's IP space is typically fragmented across many non-contiguous ranges.
- RegionID provides sub-national granularity (e.g., different states/provinces within a country). NULL when region is not available.
- The `Internal.LoadGeoDataFromStaticResources` procedure handles bulk updates to this table from external GeoIP databases.

---

## 3. Data Overview

| CountryID | IPFrom | IPTo | RegionID | Meaning |
|---|---|---|---|---|
| 1 | 87965673 | 87965675 | 48 | A tiny 3-IP range for country 1 in region 48 — shows the granularity of IP allocation where even 3 consecutive IPs can be assigned to a specific region. |
| 1 | 391692288 | 391700479 | 48 | A larger range (~8K IPs) for the same country — demonstrates that a single country can have many ranges of varying sizes. |
| 1 | 460601344 | 460602367 | 2305 | Same country, different region (2305 vs 48) — shows that IP ranges within a country map to different sub-national regions. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | VERIFIED | References `Dictionary.Country`. Part of the composite PK. Identifies which country owns this IP range. Used by `Internal.GetCountryIDByIP` to resolve an IP to a country. |
| 2 | IPFrom | bigint | NO | - | VERIFIED | Start of the IP address range as an integer. Part of the composite PK. IPv4 addresses are converted to integers for efficient range comparisons. Used with IPTo for `BETWEEN` lookups. |
| 3 | IPTo | bigint | NO | - | VERIFIED | End of the IP address range as an integer. Part of the composite PK. When IPFrom = IPTo, the range covers exactly one IP address. Used with IPFrom for `BETWEEN` lookups. |
| 4 | RegionID | int | YES | - | CODE-BACKED | Sub-national region within the country. References a region lookup (likely `Dictionary.Region` or similar). NULL when regional granularity is not available for the IP range. Used by `Internal.GetRegionIDByIP` for sub-country geolocation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Implicit FK | Maps each IP range to a country in the master country list |
| RegionID | Dictionary.Region (or similar) | Implicit FK | Maps to a sub-national region within the country |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Internal.GetCountryIDByIP | Function | Read | Resolves an IP integer to a CountryID |
| Internal.GetCountryNameByIP | Function | Read | Resolves an IP integer to a country name |
| Internal.GetRegionIDByIP | Function | Read | Resolves an IP integer to a RegionID |
| Internal.GetCountryToIpList | Procedure | Read | Returns IP ranges for listing/admin |
| Internal.GetCountryNameByIp | Procedure | Read | Name resolution via procedure |
| Internal.LoadGeoDataFromStaticResources | Procedure | Write | Bulk-loads updated GeoIP data from external sources |
| Internal.GetCountryToIpsCount | Procedure | Read | Counts IP ranges per country |
| Internal.GetIpRangesForCountry | Procedure | Read | Returns all IP ranges for a specific country |
| dbo.GetUsaIPsList | Procedure | Read | Returns US IP ranges for US-specific filtering |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetCountryIDByIP | Function | IP-to-country resolution |
| Internal.GetCountryNameByIP | Function | IP-to-name resolution |
| Internal.GetRegionIDByIP | Function | IP-to-region resolution |
| Internal.GetCountryToIpList | Procedure | IP range listing |
| Internal.LoadGeoDataFromStaticResources | Procedure | Bulk data loading |
| Internal.GetCountryToIpsCount | Procedure | Count ranges per country |
| Internal.GetIpRangesForCountry | Procedure | Country-specific range lookup |
| dbo.GetUsaIPsList | Procedure | US IP range extraction |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CountryIP | CLUSTERED PK | CountryID ASC, IPFrom ASC, IPTo ASC | - | - | Active |
| DIPC_COUNTRY | NC | CountryID ASC | - | - | Active |
| DIPC_IPRANGE1 | NC | IPFrom ASC, IPTo ASC | CountryID | - | Active |
| DIPC_IPRANGE2 | NC | IPTo ASC, IPFrom ASC | CountryID | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 Resolve an IP address to a country
```sql
DECLARE @IPInteger BIGINT = 87965674;  -- Example IP as integer
SELECT  CountryID,
        RegionID
FROM    Dictionary.CountryIP WITH (NOLOCK)
WHERE   @IPInteger BETWEEN IPFrom AND IPTo;
```

### 8.2 Count IP ranges per country
```sql
SELECT  CIP.CountryID,
        C.Name AS CountryName,
        COUNT(*) AS IPRangeCount
FROM    Dictionary.CountryIP CIP WITH (NOLOCK)
INNER JOIN Dictionary.Country C WITH (NOLOCK)
        ON C.CountryID = CIP.CountryID
GROUP BY CIP.CountryID, C.Name
ORDER BY IPRangeCount DESC;
```

### 8.3 Find the largest IP range blocks
```sql
SELECT  TOP 10
        CountryID,
        IPFrom,
        IPTo,
        (IPTo - IPFrom + 1) AS RangeSize
FROM    Dictionary.CountryIP WITH (NOLOCK)
ORDER BY (IPTo - IPFrom) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CountryIP | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CountryIP.sql*
