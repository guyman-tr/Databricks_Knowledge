# fiktivo.GetCountryIDByIP

> Scalar function that resolves an IPv4 address string to an INTEGER country identifier by converting the IP to numeric form via IPAddressToIPNum and performing a range lookup in the CountryIP geolocation table.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns INTEGER |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetCountryIDByIP performs identical logic to GetActualCountryIDByIP - converting an IP string to numeric form and looking up the country via the CountryIP table. The key difference is this function returns a proper INTEGER type instead of VARCHAR(100), making it the preferred version for use in queries that need to JOIN or compare the result with integer CountryID columns.

This function provides the same two-step IP geolocation pipeline: (1) IPAddressToIPNum converts the dotted-decimal IP to BIGINT, (2) BETWEEN lookup on CountryIP returns the matching CountryID. Returns 0 when no matching IP range is found.

The existence of two nearly identical functions (this one and GetActualCountryIDByIP) suggests they were created at different times to serve different callers with different type requirements.

---

## 2. Business Logic

### 2.1 IP-to-Country Resolution Pipeline

**What**: Two-step resolution from IP string to integer country identifier.

**Columns/Parameters Involved**: `@IP`

**Rules**:
- Identical logic to GetActualCountryIDByIP
- Step 1: Convert @IP to numeric BIGINT via `fiktivo.IPAddressToIPNum(@IP)`
- Step 2: SELECT CountryID FROM fiktivo.CountryIP WHERE @IPNum BETWEEN IPFrom AND IPTo
- Default: Returns 0 (INTEGER) if no matching IP range is found
- Returns INTEGER (preferred for JOINs) vs GetActualCountryIDByIP which returns VARCHAR(100)

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IP | VARCHAR(15) (IN) | NO | - | CODE-BACKED | Dotted-decimal IPv4 address to resolve (e.g., '85.102.241.26'). Passed to IPAddressToIPNum for numeric conversion. |
| 2 | RETURN | INTEGER | - | - | CODE-BACKED | CountryID as an integer. Returns 0 when no matching IP range is found. Valid country IDs range from 1 to 244. Preferred over GetActualCountryIDByIP for type-safe operations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @IP | fiktivo.IPAddressToIPNum | Function call | Converts IP string to numeric BIGINT |
| @IPNum | fiktivo.CountryIP | SELECT lookup | BETWEEN range lookup for country resolution |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Likely called from application code for IP geolocation where an integer return type is needed.

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

### 8.1 Resolve an IP to integer country ID
```sql
SELECT fiktivo.GetCountryIDByIP('85.102.241.26') AS CountryID
```

### 8.2 Use in a JOIN with country names
```sql
SELECT lp.Lead_ID, lp.IP,
       fiktivo.GetCountryIDByIP(RTRIM(lp.IP)) AS CountryID
FROM fiktivo.etoro_LeadPixel lp WITH (NOLOCK)
WHERE lp.IP IS NOT NULL
  AND RTRIM(lp.IP) <> ''
```

### 8.3 Count leads by resolved country
```sql
SELECT fiktivo.GetCountryIDByIP(RTRIM(IP)) AS CountryID,
       COUNT(*) AS LeadCount
FROM fiktivo.etoro_LeadPixel WITH (NOLOCK)
WHERE IP IS NOT NULL AND RTRIM(IP) <> ''
GROUP BY fiktivo.GetCountryIDByIP(RTRIM(IP))
ORDER BY COUNT(*) DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.GetCountryIDByIP | Type: Scalar Function | Source: fiktivo/fiktivo/Functions/fiktivo.GetCountryIDByIP.sql*
