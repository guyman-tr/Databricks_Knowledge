# fiktivo.GetActualCountryIDByIP

> Scalar function that resolves an IPv4 address string to a country identifier by converting the IP to numeric form via IPAddressToIPNum and performing a range lookup in the CountryIP geolocation table.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns VARCHAR(100) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetActualCountryIDByIP is a convenience function that encapsulates the full IP-to-country resolution pipeline in a single call. Given a dotted-decimal IP address string, it returns the corresponding CountryID by: (1) converting the IP to a numeric BIGINT using IPAddressToIPNum, and (2) performing a BETWEEN range lookup against the CountryIP geolocation table.

This function exists to provide a simple, reusable interface for IP geolocation throughout the affiliate system. Any query or procedure that needs to determine a user's country from their IP address can call this function instead of implementing the conversion and lookup inline.

Note: Despite the return type being VARCHAR(100), the function actually returns an INTEGER CountryID. The VARCHAR return type appears to be a design inconsistency - its sibling function GetCountryIDByIP returns INTEGER for the same logic. This function defaults to returning CountryID=0 when no matching IP range is found.

---

## 2. Business Logic

### 2.1 IP-to-Country Resolution Pipeline

**What**: Two-step resolution from IP string to country identifier.

**Columns/Parameters Involved**: `@IP`

**Rules**:
- Step 1: Convert @IP to numeric BIGINT via `fiktivo.IPAddressToIPNum(@IP)` (formula: A*256^3 + B*256^2 + C*256 + D)
- Step 2: SELECT CountryID FROM fiktivo.CountryIP WHERE @IPNum BETWEEN IPFrom AND IPTo
- Default: Returns 0 if no matching IP range is found (initialized before the SELECT)
- The CountryIP table contains 6.4M+ ranges covering 244 countries

**Diagram**:
```
@IP (VARCHAR)
    |
    v
IPAddressToIPNum(@IP) --> @IPNum (BIGINT)
    |
    v
CountryIP: WHERE @IPNum BETWEEN IPFrom AND IPTo
    |
    v
CountryID (returned as VARCHAR(100), actually integer)
```

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IP | VARCHAR(15) (IN) | NO | - | CODE-BACKED | Dotted-decimal IPv4 address to resolve (e.g., '85.102.241.26'). Passed directly to IPAddressToIPNum for numeric conversion. |
| 2 | RETURN | VARCHAR(100) | - | - | CODE-BACKED | CountryID as a string. Returns '0' when no matching IP range is found. Despite the VARCHAR(100) return type, the value is always an integer CountryID (1-244 for valid matches, 0 for no match). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @IP | fiktivo.IPAddressToIPNum | Function call | Converts IP string to numeric BIGINT for range comparison |
| @IPNum | fiktivo.CountryIP | SELECT lookup | BETWEEN lookup on IPFrom/IPTo to find matching country |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Likely called from application code or external procedures for IP geolocation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.GetActualCountryIDByIP (function)
├── fiktivo.IPAddressToIPNum (function)
└── fiktivo.CountryIP (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.IPAddressToIPNum | Function | Called to convert IP string to numeric BIGINT |
| fiktivo.CountryIP | Table | BETWEEN range lookup for country resolution |

### 6.2 Objects That Depend On This

No dependents found in the fiktivo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

N/A for function.

---

## 8. Sample Queries

### 8.1 Resolve a specific IP to country
```sql
SELECT fiktivo.GetActualCountryIDByIP('85.102.241.26') AS CountryID
```

### 8.2 Resolve multiple IPs from lead data
```sql
SELECT TOP 10 Lead_ID, IP,
       fiktivo.GetActualCountryIDByIP(RTRIM(IP)) AS CountryID
FROM fiktivo.etoro_LeadPixel WITH (NOLOCK)
WHERE IP IS NOT NULL AND RTRIM(IP) <> ''
```

### 8.3 Compare with sibling function
```sql
SELECT fiktivo.GetActualCountryIDByIP('85.102.241.26') AS VarcharResult,
       fiktivo.GetCountryIDByIP('85.102.241.26') AS IntegerResult
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.GetActualCountryIDByIP | Type: Scalar Function | Source: fiktivo/fiktivo/Functions/fiktivo.GetActualCountryIDByIP.sql*
