# Internal.GetRegionIDByIP

> Scalar function that validates an IPv4 string, converts it to BIGINT via IPAddressToIPNum, and returns the RegionID from Dictionary.CountryIP. Returns 0 if no match is found.

| Property | Value |
|----------|-------|
| **Schema** | Internal |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Internal.GetRegionIDByIP is the primary entry point for IP-based geographic region resolution. Given an IPv4 address string, it validates the format, converts the IP to a BIGINT using Internal.IPAddressToIPNum, then queries Dictionary.CountryIP to find the RegionID for the matching IP range.

This function is used during user registration and login to determine the user's sub-country region from their IP address. RegionID drives regulatory routing, access control, and geo-restriction checks. If no range match exists (unrecognized or private IP), the function returns 0.

---

## 2. Business Logic

### 2.1 IP Format Validation

**What**: Guards against invalid inputs before the expensive range lookup.

**Columns/Parameters Involved**: `@IPAddress`

**Rules**:
- Checks that the IP string contains exactly 3 dots (CHARINDEX / LEN validation)
- If format is invalid, returns 0 immediately without querying the table
- Private/loopback ranges may match or not match depending on CountryIP data

### 2.2 Region Resolution

**What**: Matches numeric IP against pre-loaded range table.

**Columns/Parameters Involved**: `@IPAddress`, `IPFrom`, `IPTo`, `RegionID`

**Rules**:
- Calls Internal.IPAddressToIPNum to convert input to BIGINT
- Queries Dictionary.CountryIP WHERE @IPNum BETWEEN IPFrom AND IPTo
- Returns RegionID from the matching row (TOP 1 with NOLOCK)
- Returns 0 if no row found (ISNULL or ELSE branch)

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IPAddress | varchar(15) | NO (param) | - | CODE-BACKED | Input: dotted-decimal IPv4 string. Validated for format before processing. |
| 2 | RETURN | int | NO | - | CODE-BACKED | Output: RegionID from Dictionary.CountryIP for the matching range. Returns 0 if format invalid or no range match found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @IPAddress | Internal.IPAddressToIPNum | Function call | Converts IP string to BIGINT for range comparison |
| IPFrom/IPTo/RegionID | Dictionary.CountryIP | SELECT FROM | IP range table queried for region resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Registration procedures | @IPAddress | Function call | Called to determine user region at signup |
| Customer data SPs | @IPAddress | Function call | Used for geo-detection during login/access checks |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Internal.GetRegionIDByIP (function)
  +-- Internal.IPAddressToIPNum (function)
  +-- Dictionary.CountryIP (table)
        +-- Dictionary.Country (table)
        +-- Dictionary.RegionByIP (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.IPAddressToIPNum | Scalar Function | Converts IP string to BIGINT |
| Dictionary.CountryIP | Table | Range lookup: IPFrom <= @IPNum <= IPTo |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Registration.InsertRealCustomer (and similar) | Stored Procedure | Calls to populate RegionByIP_ID at user creation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get region for a known IP
```sql
SELECT Internal.GetRegionIDByIP('195.85.200.1') AS RegionID
```

### 8.2 Handle unknown or private IP
```sql
SELECT Internal.GetRegionIDByIP('127.0.0.1') AS RegionID  -- likely returns 0
SELECT Internal.GetRegionIDByIP('not-an-ip') AS RegionID  -- returns 0 (invalid format)
```

### 8.3 Join region name for display
```sql
DECLARE @RegionID INT = Internal.GetRegionIDByIP('195.85.200.1')
SELECT r.Name AS RegionName FROM Dictionary.RegionByIP r WITH (NOLOCK)
WHERE r.RegionByIP_ID = @RegionID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Object: Internal.GetRegionIDByIP | Type: Scalar Function | Source: UserApiDB/UserApiDB/Internal/Functions/Internal.GetRegionIDByIP.sql*
