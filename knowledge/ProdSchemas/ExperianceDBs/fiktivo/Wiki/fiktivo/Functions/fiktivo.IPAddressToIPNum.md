# fiktivo.IPAddressToIPNum

> Converts a dotted-quad IPv4 address string (e.g., '203.0.113.50') into its numeric BIGINT representation for efficient IP range lookups.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns BIGINT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This function converts a human-readable IPv4 address (e.g., '203.0.113.50') into a single numeric BIGINT value using the standard IP-to-number formula: A * 256^3 + B * 256^2 + C * 256 + D. This numeric representation enables efficient range-based lookups against the `fiktivo.CountryIP` table, which stores IP-to-country mappings as numeric ranges.

Without this function, every IP geo-resolution query would need to inline the conversion formula, making code harder to maintain and more error-prone. It provides a single, consistent conversion point used by both `fiktivo.GetCountryIDByIP` and `fiktivo.GetActualCountryIDByIP`.

The function is called by both geo-resolution functions, which in turn are used by multiple stored procedures (sp_UpdateSales, sp_UpdateCopyTraders, sp_UpdateFirstPositions, sp_InsertSocialMessage) for country attribution of affiliate events.

---

## 2. Business Logic

### 2.1 IP-to-Number Conversion Formula

**What**: Standard IPv4 address to integer conversion.

**Columns/Parameters Involved**: `@IP` (input), BIGINT (return)

**Rules**:
- Uses SQL Server's PARSENAME function to split the dotted-quad string: PARSENAME(@IP, 4) = first octet (A), PARSENAME(@IP, 3) = second (B), PARSENAME(@IP, 2) = third (C), PARSENAME(@IP, 1) = fourth (D)
- Formula: A * 256^3 + B * 256^2 + C * 256 + D = A * 16777216 + B * 65536 + C * 256 + D
- Example: '203.0.113.50' = 203 * 16777216 + 0 * 65536 + 113 * 256 + 50 = 3405803826
- Result is always a positive BIGINT in range [0, 4294967295] (0.0.0.0 to 255.255.255.255)

**Diagram**:
```
Input: '203.0.113.50'
       |
PARSENAME splits by '.'
       |
  A=203  B=0  C=113  D=50
       |
  203 * 256*256*256 = 3,405,774,848
    + 0 * 256*256   =             0
    + 113 * 256      =        28,928
    + 50             =            50
       |
Output: 3,405,803,826 (BIGINT)
```

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IP (parameter) | VARCHAR(15) | NO | - | CODE-BACKED | Input IPv4 address in dotted-quad format (e.g., '203.0.113.50'). Maximum 15 characters covers the longest valid IPv4 string ('255.255.255.255'). |
| 2 | (return value) | BIGINT | NO | - | CODE-BACKED | Numeric representation of the IP address. Range: 0 ('0.0.0.0') to 4,294,967,295 ('255.255.255.255'). Used directly in BETWEEN queries against fiktivo.CountryIP (IPFrom/IPTo). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It is a pure computation function with no table access.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.GetCountryIDByIP | (function call) | Function dependency | Calls IPAddressToIPNum to convert IP before CountryIP lookup. Returns INTEGER. |
| fiktivo.GetActualCountryIDByIP | (function call) | Function dependency | Calls IPAddressToIPNum to convert IP before CountryIP lookup. Returns VARCHAR(100). |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.GetCountryIDByIP | Function | Calls IPAddressToIPNum(@IP) to convert IP to numeric for range lookup |
| fiktivo.GetActualCountryIDByIP | Function | Calls IPAddressToIPNum(@IP) to convert IP to numeric for range lookup |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function.

---

## 8. Sample Queries

### 8.1 Convert an IP address to numeric
```sql
SELECT fiktivo.IPAddressToIPNum('203.0.113.50') AS IPNum
-- Returns: 3405803826
```

### 8.2 Convert and lookup country in one step
```sql
DECLARE @IPNum BIGINT = fiktivo.IPAddressToIPNum('8.8.8.8')
SELECT c.Name
FROM fiktivo.CountryIP ip WITH (NOLOCK)
JOIN dbo.tblaff_Country c WITH (NOLOCK) ON ip.CountryID = c.CountryID
WHERE @IPNum BETWEEN ip.IPFrom AND ip.IPTo
```

### 8.3 Verify conversion for known IPs
```sql
SELECT fiktivo.IPAddressToIPNum('0.0.0.0') AS Min_IP,      -- 0
       fiktivo.IPAddressToIPNum('255.255.255.255') AS Max_IP, -- 4294967295
       fiktivo.IPAddressToIPNum('192.168.1.1') AS Private_IP  -- 3232235777
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.IPAddressToIPNum | Type: Scalar Function | Source: fiktivo/fiktivo/Functions/fiktivo.IPAddressToIPNum.sql*
