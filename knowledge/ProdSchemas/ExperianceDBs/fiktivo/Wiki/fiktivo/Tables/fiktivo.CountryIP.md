# fiktivo.CountryIP

> IP address range-to-country mapping table used for geo-resolving visitor and affiliate IP addresses to their country of origin.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Table |
| **Key Identifier** | CountryID + IPFrom + IPTo (composite PK, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 4 active (1 clustered PK + 3 nonclustered) |

---

## 1. Business Meaning

This table stores a comprehensive mapping of IP address numeric ranges to country identifiers. Each row represents a contiguous block of IP addresses that belong to a specific country. The IP addresses are stored as BIGINT numeric values (converted from dotted-quad format using the formula A*256^3 + B*256^2 + C*256 + D), enabling efficient range lookups via BETWEEN queries.

Without this table, the affiliate platform could not determine where website visitors or affiliates are located based on their IP address. Country-level geo-resolution is critical for affiliate tracking (assigning visitors to the correct country-based affiliate group), commission calculations (country-specific commission plans), and regulatory compliance (blocking or routing traffic by jurisdiction).

Data is consumed exclusively through two scalar functions - `fiktivo.GetCountryIDByIP` and `fiktivo.GetActualCountryIDByIP` - which convert a dotted-quad IP string to a numeric value via `fiktivo.IPAddressToIPNum`, then perform a BETWEEN lookup on this table. Several stored procedures (`fiktivo.sp_UpdateSales`, `fiktivo.sp_UpdateCopyTraders`, `fiktivo.sp_UpdateFirstPositions`, `fiktivo.sp_InsertSocialMessage`) use CountryID resolved through these functions.

---

## 2. Business Logic

### 2.1 IP Range Geo-Resolution

**What**: Maps numeric IP ranges to countries for visitor geo-location.

**Columns/Parameters Involved**: `CountryID`, `IPFrom`, `IPTo`

**Rules**:
- Each row defines a contiguous IP range [IPFrom, IPTo] belonging to one country
- A single country has many non-contiguous ranges (e.g., US has ~3M rows covering different IP blocks)
- Lookup is performed via `WHERE @IPNum BETWEEN IPFrom AND IPTo`
- IP addresses are converted to numeric form: A*256^3 + B*256^2 + C*256 + D
- The table covers 244 distinct countries across 6.4M IP ranges
- If no range matches, the calling functions return CountryID = 0 (unknown/not available)

**Diagram**:
```
IP "203.0.113.50"
       |
       v
[IPAddressToIPNum] --> 3405803826 (BIGINT)
       |
       v
CountryIP lookup: WHERE 3405803826 BETWEEN IPFrom AND IPTo
       |
       v
CountryID = 12 --> dbo.tblaff_Country.Name = "Australia"
```

---

## 3. Data Overview

| CountryID | IPFrom | IPTo | Meaning |
|-----------|--------|------|---------|
| 219 (US) | 1036527872 | 1036529151 | One of ~3M US IP blocks. The US has by far the largest IP allocation, reflecting its dominant share of IPv4 address space. |
| 218 (GB) | (varies) | (varies) | UK IP block. Second-largest allocation with ~710K ranges, consistent with the platform's strong UK affiliate presence. |
| 74 (FR) | (varies) | (varies) | France IP block. ~389K ranges. Third-largest, reflecting European market focus. |
| 0 (N/A) | (if present) | (if present) | Sentinel country for unresolvable or private IP addresses. Maps to "Not available" in dbo.tblaff_Country. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | INT | NO | - | CODE-BACKED | Country identifier. References dbo.tblaff_Country (0=Not available, 1=Afghanistan, 2=Albania, ..., 218=United Kingdom, 219=United States). 244 distinct countries represented. Used by GetCountryIDByIP/GetActualCountryIDByIP to return the resolved country after IP range lookup. |
| 2 | IPFrom | BIGINT | NO | - | CODE-BACKED | Start of the IP address range (inclusive), stored as a numeric value computed by IPAddressToIPNum: A*256^3 + B*256^2 + C*256 + D. Combined with IPTo in a BETWEEN clause for geo-resolution. Part of composite PK. |
| 3 | IPTo | BIGINT | NO | - | CODE-BACKED | End of the IP address range (inclusive), stored as numeric. When a visitor's IP numeric value falls between IPFrom and IPTo, that visitor is attributed to the row's CountryID. Part of composite PK. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | dbo.tblaff_Country | Implicit FK / Lookup | Maps IP ranges to countries. CountryID values match dbo.tblaff_Country.CountryID for country name resolution. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.GetCountryIDByIP | (table reference) | FROM / BETWEEN lookup | Scalar function performs BETWEEN lookup on IPFrom/IPTo to resolve an IP to a country. Returns INTEGER CountryID. |
| fiktivo.GetActualCountryIDByIP | (table reference) | FROM / BETWEEN lookup | Scalar function performs the same BETWEEN lookup but returns VARCHAR(100). Identical logic to GetCountryIDByIP with different return type. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.GetCountryIDByIP | Function | BETWEEN lookup on IPFrom/IPTo to resolve IP to CountryID |
| fiktivo.GetActualCountryIDByIP | Function | BETWEEN lookup on IPFrom/IPTo to resolve IP to CountryID |
| fiktivo.sp_UpdateSales | Stored Procedure | Uses CountryID (via function) for sales country attribution |
| fiktivo.sp_UpdateCopyTraders | Stored Procedure | Uses CountryID (via function) for copy trader country attribution |
| fiktivo.sp_UpdateFirstPositions | Stored Procedure | Uses CountryID (via function) for first position country attribution |
| fiktivo.sp_InsertSocialMessage | Stored Procedure | Uses CountryID (via function) for social message country context |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CountryIP | CLUSTERED PK | CountryID ASC, IPFrom ASC, IPTo ASC | - | - | Active (FILLFACTOR=90, PAGE compression) |
| DIPC_COUNTRY | NC | CountryID ASC | - | - | Active (FILLFACTOR=90, PAGE compression) |
| DIPC_IPRANGE1 | NC | IPFrom ASC, IPTo ASC | CountryID | - | Active (FILLFACTOR=90, PAGE compression) - optimized for forward range scan |
| DIPC_IPRANGE2 | NC | IPTo ASC, IPFrom ASC | CountryID | - | Active (FILLFACTOR=90, PAGE compression) - optimized for reverse range scan |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Resolve an IP address to a country name
```sql
DECLARE @IPNum BIGINT = fiktivo.IPAddressToIPNum('203.0.113.50')
SELECT c.CountryID, c.Name, c.Abbreviation
FROM fiktivo.CountryIP ip WITH (NOLOCK)
JOIN dbo.tblaff_Country c WITH (NOLOCK) ON ip.CountryID = c.CountryID
WHERE @IPNum BETWEEN ip.IPFrom AND ip.IPTo
```

### 8.2 Count IP ranges per country (top 10)
```sql
SELECT TOP 10 ip.CountryID, c.Name, COUNT(*) AS RangeCount
FROM fiktivo.CountryIP ip WITH (NOLOCK)
JOIN dbo.tblaff_Country c WITH (NOLOCK) ON ip.CountryID = c.CountryID
GROUP BY ip.CountryID, c.Name
ORDER BY RangeCount DESC
```

### 8.3 Using the helper function for geo-resolution
```sql
SELECT fiktivo.GetCountryIDByIP('8.8.8.8') AS CountryID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.7/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.CountryIP | Type: Table | Source: fiktivo/fiktivo/Tables/fiktivo.CountryIP.sql*
