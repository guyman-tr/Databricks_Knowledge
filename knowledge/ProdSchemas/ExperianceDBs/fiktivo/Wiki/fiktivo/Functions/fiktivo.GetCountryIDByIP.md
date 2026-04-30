# fiktivo.GetCountryIDByIP

> Resolves an IPv4 address string to a country ID by converting it to numeric form and performing a range lookup against the CountryIP table. Returns INTEGER.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns INTEGER |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This function performs IP-to-country geo-resolution. Given a dotted-quad IP address string (e.g., '203.0.113.50'), it converts the IP to a numeric value using `fiktivo.IPAddressToIPNum`, then looks up the corresponding country in `fiktivo.CountryIP` using a BETWEEN range query. The function returns the CountryID as an INTEGER.

This is functionally identical to `fiktivo.GetActualCountryIDByIP` except for the return type: this function returns INTEGER while GetActualCountryIDByIP returns VARCHAR(100). The INTEGER return type is preferred for most use cases where the CountryID will be used in JOINs or comparisons with other integer columns.

The function is used by stored procedures that need country attribution for affiliate events - determining which country a customer is in based on their IP address, which drives country-specific commission plans and affiliate routing.

---

## 2. Business Logic

### 2.1 IP Geo-Resolution Pipeline

**What**: Two-step IP-to-country resolution: convert IP string to number, then range lookup.

**Columns/Parameters Involved**: `@IP` (input), INTEGER (return)

**Rules**:
- Step 1: Convert @IP to @IPNum via fiktivo.IPAddressToIPNum(@IP)
- Step 2: SELECT CountryID FROM fiktivo.CountryIP WHERE @IPNum BETWEEN IPFrom AND IPTo
- If no range matches, returns 0 (default - "Not available" country in dbo.tblaff_Country)
- @CountryID is initialized to 0 before the lookup as a safe default

**Diagram**:
```
Input: @IP = '8.8.8.8'
       |
       v
fiktivo.IPAddressToIPNum('8.8.8.8') --> 134744072
       |
       v
SELECT CountryID FROM fiktivo.CountryIP
WHERE 134744072 BETWEEN IPFrom AND IPTo
       |
       v
Output: 219 (INTEGER - United States)
```

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IP (parameter) | VARCHAR(15) | NO | - | CODE-BACKED | Input IPv4 address in dotted-quad format (e.g., '8.8.8.8'). Passed to IPAddressToIPNum for numeric conversion. |
| 2 | (return value) | INTEGER | NO | - | CODE-BACKED | Country ID as integer. Returns 0 if no matching IP range found (unknown country). Directly usable in JOINs to dbo.tblaff_Country.CountryID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (function call) | [fiktivo.IPAddressToIPNum](../Functions/fiktivo.IPAddressToIPNum.md) | Function dependency | Converts @IP to numeric BIGINT for range lookup. |
| (SELECT) | [fiktivo.CountryIP](../Tables/fiktivo.CountryIP.md) | Table access | BETWEEN lookup on IPFrom/IPTo to find matching country. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.sp_UpdateSales | (function call) | Function consumer | Resolves customer IP to country for sales commission attribution. |
| fiktivo.sp_UpdateCopyTraders | (function call) | Function consumer | Resolves IP to country for copy trader commission attribution. |
| fiktivo.sp_UpdateFirstPositions | (function call) | Function consumer | Resolves IP to country for first position commission attribution. |
| fiktivo.sp_InsertSocialMessage | (function call) | Function consumer | Resolves IP to country for social message context. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.GetCountryIDByIP (function)
    ├── fiktivo.IPAddressToIPNum (function)
    └── fiktivo.CountryIP (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.IPAddressToIPNum | Function | Called to convert IP string to numeric BIGINT |
| fiktivo.CountryIP | Table | BETWEEN lookup on IPFrom/IPTo for country resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.sp_UpdateSales | Stored Procedure | Calls GetCountryIDByIP for country attribution |
| fiktivo.sp_UpdateCopyTraders | Stored Procedure | Calls GetCountryIDByIP for country attribution |
| fiktivo.sp_UpdateFirstPositions | Stored Procedure | Calls GetCountryIDByIP for country attribution |
| fiktivo.sp_InsertSocialMessage | Stored Procedure | Calls GetCountryIDByIP for country context |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function.

---

## 8. Sample Queries

### 8.1 Resolve an IP to country ID
```sql
SELECT fiktivo.GetCountryIDByIP('8.8.8.8') AS CountryID
-- Returns: 219 (United States)
```

### 8.2 Resolve and get country name in one query
```sql
SELECT c.CountryID, c.Name, c.Abbreviation
FROM dbo.tblaff_Country c WITH (NOLOCK)
WHERE c.CountryID = fiktivo.GetCountryIDByIP('185.73.98.1')
```

### 8.3 Test multiple IPs
```sql
SELECT fiktivo.GetCountryIDByIP('8.8.8.8') AS Google_US,
       fiktivo.GetCountryIDByIP('1.1.1.1') AS Cloudflare,
       fiktivo.GetCountryIDByIP('0.0.0.0') AS Unknown
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.GetCountryIDByIP | Type: Scalar Function | Source: fiktivo/fiktivo/Functions/fiktivo.GetCountryIDByIP.sql*
