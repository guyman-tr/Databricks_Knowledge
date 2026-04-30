# Internal.IPAddressToIPNum

> Scalar function that converts a dotted-decimal IPv4 string into its BIGINT numeric representation for range-based IP lookups.

| Property | Value |
|----------|-------|
| **Schema** | Internal |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns BIGINT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Internal.IPAddressToIPNum converts a standard IPv4 address (e.g., `192.168.1.100`) into a BIGINT using the standard formula: A×256³ + B×256² + C×256 + D, where A–D are the four octets extracted via PARSENAME.

This numeric form is required for range-based lookups against Dictionary.CountryIP, which stores IP ranges as bigint pairs (IPFrom, IPTo). The conversion is deterministic and pure — it accesses no tables and has no side effects. It is the low-level building block called by Internal.GetRegionIDByIP.

---

## 2. Business Logic

### 2.1 IPv4 to BIGINT Conversion

**What**: Converts a dotted-decimal IPv4 string to its numeric equivalent.

**Columns/Parameters Involved**: `@IPAddress` (input), return value

**Rules**:
- Uses PARSENAME to split on dots: PARSENAME returns parts in reverse order (part 1 = rightmost)
- Formula: PARSENAME(@IPAddress,4) × 16777216 + PARSENAME(@IPAddress,3) × 65536 + PARSENAME(@IPAddress,2) × 256 + PARSENAME(@IPAddress,1)
- Equivalent to: A×256³ + B×256² + C×256 + D
- No input validation in this function — caller is responsible for valid IPv4 format
- Result is deterministic: same input always yields same BIGINT

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IPAddress | varchar(15) | NO (param) | - | CODE-BACKED | Input: dotted-decimal IPv4 string, e.g. '192.168.1.1'. No format validation performed. |
| 2 | RETURN | bigint | NO | - | CODE-BACKED | Output: numeric IPv4 value. Used to query IPFrom/IPTo ranges in Dictionary.CountryIP. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (pure computation, no table access).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Internal.GetRegionIDByIP | @IPAddress | Function call | Calls this to convert IP before range lookup |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetRegionIDByIP | Scalar Function | Calls to convert IP string to BIGINT |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Convert a single IP address
```sql
SELECT Internal.IPAddressToIPNum('192.168.1.100') AS IPNum
-- Returns: 3232235876
```

### 8.2 Verify the formula manually
```sql
-- 192*16777216 + 168*65536 + 1*256 + 100
SELECT (192*16777216) + (168*65536) + (1*256) + 100 AS Expected,
       Internal.IPAddressToIPNum('192.168.1.100') AS Actual
```

### 8.3 Convert and look up in CountryIP
```sql
DECLARE @IP BIGINT = Internal.IPAddressToIPNum('195.85.200.1')
SELECT CountryID, RegionID FROM Dictionary.CountryIP WITH (NOLOCK)
WHERE @IP BETWEEN IPFrom AND IPTo
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Object: Internal.IPAddressToIPNum | Type: Scalar Function | Source: UserApiDB/UserApiDB/Internal/Functions/Internal.IPAddressToIPNum.sql*
