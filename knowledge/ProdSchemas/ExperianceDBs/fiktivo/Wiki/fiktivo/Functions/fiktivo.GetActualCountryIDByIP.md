# fiktivo.GetActualCountryIDByIP

> Resolves an IPv4 address string to a country ID by converting it to numeric form and performing a range lookup against the CountryIP table. Returns VARCHAR(100).

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns VARCHAR(100) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This function performs IP-to-country geo-resolution. Given a dotted-quad IP address string (e.g., '203.0.113.50'), it converts the IP to a numeric value using `fiktivo.IPAddressToIPNum`, then looks up the corresponding country in `fiktivo.CountryIP` using a BETWEEN range query. The function returns the CountryID as a VARCHAR(100) string.

This is functionally identical to `fiktivo.GetCountryIDByIP` except for the return type: this function returns VARCHAR(100) while GetCountryIDByIP returns INTEGER. The VARCHAR return type may have been created for use in contexts requiring string concatenation or dynamic SQL where an integer return type would need explicit casting.

The function is used by stored procedures that need country attribution for affiliate events - determining which country a customer is in based on their IP address, which then drives country-specific affiliate grouping and commission plans.

---

## 2. Business Logic

### 2.1 IP Geo-Resolution Pipeline

**What**: Two-step IP-to-country resolution: convert IP string to number, then range lookup.

**Columns/Parameters Involved**: `@IP` (input), VARCHAR(100) (return)

**Rules**:
- Step 1: Convert @IP to @IPNum via fiktivo.IPAddressToIPNum(@IP)
- Step 2: SELECT CountryID FROM fiktivo.CountryIP WHERE @IPNum BETWEEN IPFrom AND IPTo
- If no range matches, returns 0 (default - "Not available" country)
- @CountryID is initialized to 0 before the lookup as a safe default

**Diagram**:
```
Input: @IP = '203.0.113.50'
       |
       v
fiktivo.IPAddressToIPNum('203.0.113.50') --> 3405803826
       |
       v
SELECT CountryID FROM fiktivo.CountryIP
WHERE 3405803826 BETWEEN IPFrom AND IPTo
       |
       v
Output: '12' (VARCHAR - Australia)
```

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IP (parameter) | VARCHAR(15) | NO | - | CODE-BACKED | Input IPv4 address in dotted-quad format (e.g., '203.0.113.50'). Passed to IPAddressToIPNum for numeric conversion. |
| 2 | (return value) | VARCHAR(100) | NO | - | CODE-BACKED | Country ID as a string. Returns '0' if no matching IP range found (unknown country). References dbo.tblaff_Country.CountryID for country name resolution. VARCHAR(100) return type allows direct use in string concatenation contexts. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (function call) | [fiktivo.IPAddressToIPNum](../Functions/fiktivo.IPAddressToIPNum.md) | Function dependency | Converts @IP to numeric BIGINT for range lookup. |
| (SELECT) | [fiktivo.CountryIP](../Tables/fiktivo.CountryIP.md) | Table access | BETWEEN lookup on IPFrom/IPTo to find matching country. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Likely used by the same stored procedures as GetCountryIDByIP (sp_UpdateSales, sp_UpdateCopyTraders, etc.).

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
| fiktivo.CountryIP | Table | BETWEEN lookup on IPFrom/IPTo for country resolution |

### 6.2 Objects That Depend On This

No dependents found in the fiktivo schema SSDT files.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function.

---

## 8. Sample Queries

### 8.1 Resolve an IP to country ID (string)
```sql
SELECT fiktivo.GetActualCountryIDByIP('8.8.8.8') AS CountryID
```

### 8.2 Resolve and get country name
```sql
SELECT c.Name
FROM dbo.tblaff_Country c WITH (NOLOCK)
WHERE c.CountryID = CAST(fiktivo.GetActualCountryIDByIP('8.8.8.8') AS INT)
```

### 8.3 Compare with GetCountryIDByIP
```sql
SELECT fiktivo.GetActualCountryIDByIP('8.8.8.8') AS ActualResult_VARCHAR,
       fiktivo.GetCountryIDByIP('8.8.8.8') AS Result_INT
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.GetActualCountryIDByIP | Type: Scalar Function | Source: fiktivo/fiktivo/Functions/fiktivo.GetActualCountryIDByIP.sql*
