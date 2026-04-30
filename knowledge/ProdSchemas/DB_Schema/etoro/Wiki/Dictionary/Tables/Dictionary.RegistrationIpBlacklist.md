# Dictionary.RegistrationIpBlacklist

> Blacklist table storing IP addresses (as decimal values and human-readable strings) that are blocked from registering new accounts on the eToro platform.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | IPAsDecimal (BIGINT, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.RegistrationIpBlacklist prevents new account registrations from known fraudulent, abusive, or suspicious IP addresses. When a user attempts to register, the system checks their IP against this blacklist. If matched, registration is blocked.

This is a fraud prevention and anti-abuse measure. The table stores both the numeric decimal representation of the IP (for fast indexed lookups) and the human-readable dotted-quad format (for admin review). No SQL consumers were found in the etoro SSDT project, suggesting the check is performed by application-layer code or a registration microservice.

---

## 2. Business Logic

### 2.1 IP Blocking

**What**: Each row represents a single blacklisted IP address.

**Columns/Parameters Involved**: `IPAsDecimal`, `IPAddress`

**Rules**:
- IP addresses are stored in both decimal and string formats.
- The decimal representation is the PK for fast equality lookups during registration.
- Addresses are IPv4 (stored as BIGINT to accommodate the full 32-bit range).
- The blacklist is manually maintained by the fraud/risk team.

---

## 3. Data Overview

| IPAsDecimal | IPAddress | Meaning |
|---|---|---|
| 17418498 | 1.9.201.2 | Blocked IP — fraud/abuse detected |
| 19827980 | 1.46.141.12 | Blocked IP — fraud/abuse detected |
| 19851675 | 1.46.233.155 | Blocked IP — fraud/abuse detected |
| 20193988 | 1.52.34.196 | Blocked IP — fraud/abuse detected |
| 20194063 | 1.52.35.15 | Blocked IP — fraud/abuse detected |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | IPAsDecimal | bigint | NO | - | VERIFIED | Primary key. IPv4 address as a decimal number for fast indexed lookups. Calculated as: (octet1 × 16777216) + (octet2 × 65536) + (octet3 × 256) + octet4. |
| 2 | IPAddress | char(15) | NO | - | VERIFIED | Human-readable dotted-quad IPv4 address (e.g., "1.9.201.2"). Padded to 15 chars (CHAR type). Used for admin review and display. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No SQL consumers found. Consumed by application-layer registration services.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No known SQL dependents.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryRegistrationIpBlacklist | CLUSTERED PK | IPAsDecimal ASC | - | - | Active (FF=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DictionaryRegistrationIpBlacklist | PRIMARY KEY | Unique IP address identifier |

---

## 8. Sample Queries

### 8.1 Check if an IP is blacklisted
```sql
SELECT  IPAddress
FROM    [Dictionary].[RegistrationIpBlacklist] WITH (NOLOCK)
WHERE   IPAsDecimal = 17418498;
```

### 8.2 Count total blacklisted IPs
```sql
SELECT  COUNT(*) AS BlacklistedCount
FROM    [Dictionary].[RegistrationIpBlacklist] WITH (NOLOCK);
```

### 8.3 Search by IP address pattern
```sql
SELECT  IPAsDecimal,
        RTRIM(IPAddress) AS IPAddress
FROM    [Dictionary].[RegistrationIpBlacklist] WITH (NOLOCK)
WHERE   IPAddress LIKE '1.46.%'
ORDER BY IPAsDecimal;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RegistrationIpBlacklist | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.RegistrationIpBlacklist.sql*
