# fiktivo.IPAddressToIPNum

> Scalar function that converts a dotted-decimal IPv4 address string (e.g., '192.168.1.1') into its numeric BIGINT representation for use in IP range lookups against the CountryIP geolocation table.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns BIGINT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

IPAddressToIPNum is a utility function that converts a human-readable IPv4 address (like '192.168.1.1') into its numeric equivalent (3232235777). This numeric form is required for performing range-based lookups in the CountryIP geolocation table, which stores IP ranges as numeric BIGINT values.

This function is the critical first step in the IP-to-country resolution pipeline. Without it, the system would need to parse IP address octets inline in every geolocation query. It is called by both `GetActualCountryIDByIP` and `GetCountryIDByIP` as their first operation before querying CountryIP.

The conversion formula is: A * 256^3 + B * 256^2 + C * 256 + D, where A.B.C.D is the IP address. The function uses SQL Server's PARSENAME function (designed for parsing four-part object names) to extract each octet efficiently.

---

## 2. Business Logic

### 2.1 IP Address to Numeric Conversion

**What**: Converts a dotted-decimal IPv4 address to a single BIGINT number suitable for BETWEEN range comparisons.

**Columns/Parameters Involved**: `@IP`

**Rules**:
- Formula: A * 256^3 + B * 256^2 + C * 256 + D
- Uses PARSENAME(@IP, N) where N=4 is the first octet (A), N=3 is second (B), N=2 is third (C), N=1 is fourth (D)
- PARSENAME naturally handles the dotted notation since it was designed for four-part SQL Server object names
- The CONVERT(BIGINT, ...) ensures the first octet multiplication doesn't overflow INT range
- Example: '192.168.1.1' = 192*16777216 + 168*65536 + 1*256 + 1 = 3232235777

**Diagram**:
```
Input: '192.168.1.1'
         |
PARSENAME(@IP, 4) = 192  * 256*256*256 = 3221225472
PARSENAME(@IP, 3) = 168  * 256*256     =   11010048
PARSENAME(@IP, 2) = 1    * 256         =        256
PARSENAME(@IP, 1) = 1                  =          1
                                        -----------
Result: 3232235777 (BIGINT)
```

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IP | VARCHAR(15) (IN) | NO | - | CODE-BACKED | Dotted-decimal IPv4 address string (e.g., '192.168.1.1'). Maximum 15 characters to accommodate the longest possible IPv4 address ('255.255.255.255'). |
| 2 | RETURN | BIGINT | - | - | CODE-BACKED | Numeric IP representation. Range: 0 (0.0.0.0) to 4,294,967,295 (255.255.255.255). Used for BETWEEN range comparisons against CountryIP.IPFrom and CountryIP.IPTo. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It is a pure computation function with no table dependencies.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.GetActualCountryIDByIP | @IPNum variable | Function call | Calls IPAddressToIPNum to convert IP before CountryIP lookup; returns VARCHAR(100) |
| fiktivo.GetCountryIDByIP | @IPNum variable | Function call | Calls IPAddressToIPNum to convert IP before CountryIP lookup; returns INTEGER |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.GetActualCountryIDByIP | Function | Calls this function to convert IP string to numeric |
| fiktivo.GetCountryIDByIP | Function | Calls this function to convert IP string to numeric |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

N/A for function.

---

## 8. Sample Queries

### 8.1 Convert a specific IP address
```sql
SELECT fiktivo.IPAddressToIPNum('192.168.1.1') AS NumericIP
-- Returns: 3232235777
```

### 8.2 Convert and look up country in one query
```sql
DECLARE @IPNum BIGINT = fiktivo.IPAddressToIPNum('85.102.241.26')
SELECT CountryID
FROM fiktivo.CountryIP WITH (NOLOCK)
WHERE @IPNum BETWEEN IPFrom AND IPTo
```

### 8.3 Verify boundary IPs
```sql
SELECT fiktivo.IPAddressToIPNum('0.0.0.0') AS MinIP,
       fiktivo.IPAddressToIPNum('255.255.255.255') AS MaxIP
-- Returns: 0, 4294967295
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.IPAddressToIPNum | Type: Scalar Function | Source: fiktivo/fiktivo/Functions/fiktivo.IPAddressToIPNum.sql*
