# fiktivo.CountryIP

> IP address range-to-country mapping table used for geolocation of affiliate traffic by converting IP addresses to country identifiers.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Table |
| **Key Identifier** | CountryID + IPFrom + IPTo (composite PK) |
| **Partition** | No |
| **Indexes** | 3 active (1 clustered PK + 2 nonclustered) |

---

## 1. Business Meaning

CountryIP is the geolocation backbone of the affiliate system. It stores IP address ranges mapped to country identifiers, enabling the platform to determine which country a user is connecting from based on their IP address. This is essential for affiliate attribution, regional commission structures, and compliance with geographic restrictions.

Without this table, the system would have no way to resolve an IP address to a country. Affiliate tracking pixels, download tracking, and lead tracking all rely on IP-based geolocation to assign traffic to the correct geographic region.

Data in this table is a reference dataset of IP-to-country mappings (6.4M+ ranges covering 244 countries). It is consumed by two scalar functions - `fiktivo.GetActualCountryIDByIP` and `fiktivo.GetCountryIDByIP` - which convert a dotted-decimal IP address string into a numeric IP and then perform a BETWEEN lookup against this table to return the matching CountryID.

---

## 2. Business Logic

### 2.1 IP Range Lookup

**What**: Each row defines a contiguous range of numeric IP addresses that belong to a single country.

**Columns/Parameters Involved**: `CountryID`, `IPFrom`, `IPTo`

**Rules**:
- An IP address is first converted to a numeric value using the formula: A * 256^3 + B * 256^2 + C * 256 + D (implemented by `fiktivo.IPAddressToIPNum`)
- The numeric IP is then matched using `WHERE @IPNum BETWEEN IPFrom AND IPTo`
- A single CountryID can have millions of non-contiguous IP ranges (e.g., CountryID 219 has 3M+ ranges)
- Ranges do not overlap - each numeric IP maps to exactly one country

**Diagram**:
```
User IP (string)
    |
    v
IPAddressToIPNum() --> numeric IP
    |
    v
CountryIP lookup: WHERE @IPNum BETWEEN IPFrom AND IPTo
    |
    v
CountryID (integer)
```

---

## 3. Data Overview

| CountryID | IPFrom | IPTo | Meaning |
|---|---|---|---|
| 1 | 84572036 | 84572043 | A small 8-address IP block assigned to country 1. Demonstrates how granular the IP allocation data can be - single subnets are tracked individually. |
| 1 | 92539136 | 92539391 | A 256-address block (typical /24 subnet) for country 1. Shows the standard subnet-level granularity of most entries. |
| 219 | - | - | Country 219 holds the most IP ranges (3M+ entries), indicating it is likely the United States - the country with the largest IPv4 allocation. |
| 74 | - | - | Country 74 has 388K ranges, suggesting a major European or Asian nation with significant IP allocation. |
| 38 | - | - | Country 38 has 173K ranges, representing a mid-tier IP allocation country. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | CODE-BACKED | Numeric identifier for a country. Used as the return value by `GetActualCountryIDByIP` and `GetCountryIDByIP` functions. References an external country lookup table (not in the fiktivo schema). 244 distinct countries represented in the dataset. |
| 2 | IPFrom | bigint | NO | - | CODE-BACKED | Start of a contiguous IP address range, stored as a numeric value computed from the dotted-decimal IP using the formula A*256^3 + B*256^2 + C*256 + D. Used in BETWEEN comparisons for geolocation lookups. Minimum value in dataset: 7,602,176. |
| 3 | IPTo | bigint | NO | - | CODE-BACKED | End of a contiguous IP address range, stored as a numeric value. Paired with IPFrom to define the full range. Used in BETWEEN comparisons: `WHERE @IPNum BETWEEN IPFrom AND IPTo`. Maximum value in dataset: 3,758,096,383 (covers the full IPv4 address space). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | External Country lookup (not in fiktivo schema) | Implicit | Maps IP ranges to country identifiers. The referenced country table likely resides in a shared/dbo schema with country names and ISO codes. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.GetActualCountryIDByIP | CountryID (return) | SELECT lookup | Scalar function that converts an IP string to a CountryID by calling IPAddressToIPNum then querying this table with BETWEEN |
| fiktivo.GetCountryIDByIP | CountryID (return) | SELECT lookup | Scalar function identical in logic to GetActualCountryIDByIP but returns INTEGER instead of VARCHAR(100) |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.GetActualCountryIDByIP | Function | Reads CountryID via BETWEEN lookup on IPFrom/IPTo |
| fiktivo.GetCountryIDByIP | Function | Reads CountryID via BETWEEN lookup on IPFrom/IPTo |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CountryIP | CLUSTERED PK | CountryID ASC, IPFrom ASC, IPTo ASC | - | - | Active |
| DIPC_COUNTRY | NONCLUSTERED | CountryID ASC | - | - | Active |
| DIPC_IPRANGE1 | NONCLUSTERED | IPFrom ASC, IPTo ASC | CountryID | - | Active |
| DIPC_IPRANGE2 | NONCLUSTERED | IPTo ASC, IPFrom ASC | CountryID | - | Active |

All indexes use FILLFACTOR=90 and DATA_COMPRESSION=PAGE, optimized for read-heavy geolocation lookups.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CountryIP | PRIMARY KEY | Composite key on (CountryID, IPFrom, IPTo) - ensures no duplicate IP range entries per country |

---

## 8. Sample Queries

### 8.1 Look up country for a specific IP address
```sql
DECLARE @IPNum BIGINT = 92539200  -- Pre-computed numeric IP
SELECT CountryID
FROM fiktivo.CountryIP WITH (NOLOCK)
WHERE @IPNum BETWEEN IPFrom AND IPTo
```

### 8.2 Count IP ranges per country (top 10)
```sql
SELECT TOP 10 CountryID, COUNT(*) AS RangeCount
FROM fiktivo.CountryIP WITH (NOLOCK)
GROUP BY CountryID
ORDER BY COUNT(*) DESC
```

### 8.3 Find all IP ranges for a specific country
```sql
SELECT IPFrom, IPTo, (IPTo - IPFrom + 1) AS AddressCount
FROM fiktivo.CountryIP WITH (NOLOCK)
WHERE CountryID = 1
ORDER BY IPFrom
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.CountryIP | Type: Table | Source: fiktivo/fiktivo/Tables/fiktivo.CountryIP.sql*
