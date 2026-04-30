# Billing.GetCustomersWithSameRegistrationIp

> Fraud detection probe: returns CIDs of other customers who registered from the same IP address AND made their very first deposit within a recent time window (@CheckPeriod hours), identifying suspicious multi-account first-deposit patterns from a single IP.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @IpAddress + @CheckPeriod (hours) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCustomersWithSameRegistrationIp` is a fraud detection check that finds accounts registered from the same IP address that are making their FIRST deposit within a recent time window. The combination of two signals - same registration IP AND first-ever deposit within @CheckPeriod hours - strongly indicates multi-account abuse:

- A fraudster may register multiple accounts from the same IP or proxy.
- The first deposit from each account is the highest-risk moment (e.g., to claim new-account bonuses multiple times, or to establish multiple accounts for market manipulation).
- By focusing on RowNumber=1 (the first deposit per CID), the procedure filters out accounts that have been depositing normally for a long time.

The procedure queries `Customer.CustomerStatic.IP` (the registration IP) - not the deposit IP. This is intentional: the registration IP is more stable and harder to change after the fact than a deposit-time IP.

No explicit EXECUTE grant found in UsersPermissions - called by application services via their own DB user.

---

## 2. Business Logic

### 2.1 First-Deposit-Within-Window Pattern Detection

**What**: Two-step filter: first find CIDs with the same registration IP (excluding self), then of those, find ones whose first deposit is within the @CheckPeriod.

**Columns/Parameters Involved**: `@IpAddress`, `@CID`, `@CheckPeriod`, `Customer.CustomerStatic.IP`, `ROW_NUMBER()`, `PaymentDate`

**Rules**:
- Inner query - IP match: `SELECT CID FROM Customer.CustomerStatic WHERE IP = @IpAddress AND CID <> @CID`. Finds all CIDs registered from the same IP, excluding the requesting CID.
- Middle query - first deposit per CID: `SELECT CID, PaymentDate, ROW_NUMBER() OVER (PARTITION BY CID ORDER BY PaymentDate) AS RowNumber FROM Billing.Deposit WHERE CID IN (...)`. Assigns row number 1 to each customer's earliest deposit.
- Outer filter: `WHERE RowNumber = 1 AND PaymentDate >= DATEADD(HOUR, @CheckPeriod * (-1), GETUTCDATE())`. Returns only customers whose FIRST deposit happened within the last @CheckPeriod hours.
- No PaymentStatusID filter: counts ANY deposit (approved, declined, pending) as the "first". A declined first deposit still triggers the flag.
- `@CheckPeriod * (-1)` in DATEADD: subtracts @CheckPeriod hours from current UTC time to define the window start. @CheckPeriod=24 means "last 24 hours".

**Diagram**:
```
@IpAddress + @CID
     |
Customer.CustomerStatic WHERE IP = @IpAddress AND CID <> @CID
     -> Set of CIDs registered from same IP
          |
          v
Billing.Deposit WHERE CID IN (above set)
  + ROW_NUMBER() OVER (PARTITION BY CID ORDER BY PaymentDate)
  -> All deposits with row number (1=first deposit per CID)
          |
          v
Filter: RowNumber = 1 AND PaymentDate >= NOW() - @CheckPeriod hours
  -> CIDs whose first-ever deposit is within the time window
          |
          v
SELECT CID (list of suspicious same-IP first-depositors)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | The customer to perform the check FOR. This customer is excluded from the results. |
| 2 | @IpAddress | VARCHAR(15) | NO | - | CODE-BACKED | The registration IP address to check for shared registrations. Matched against Customer.CustomerStatic.IP. IPv4 format (max 15 chars: 255.255.255.255). |
| 3 | @CheckPeriod | INT | NO | - | CODE-BACKED | Time window in HOURS to look back from now (GETUTCDATE()). @CheckPeriod=24 means "find first deposits in the last 24 hours". @CheckPeriod=0 would return no results (window collapses to current instant). |

**Returns**:

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | CID | INT | NO | CODE-BACKED | Customer ID of a potentially suspicious account - registered from the same IP as @CID AND made their first-ever deposit within the last @CheckPeriod hours. Returns 0 rows if no matches. Returns multiple rows if multiple suspicious accounts found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| IP, CID | Customer.CustomerStatic | Subquery (inner filter) | Source of registration IP addresses; identifies same-IP accounts |
| CID, PaymentDate | Billing.Deposit | Subquery (ROW_NUMBER + date filter) | Source of deposit history; identifies first-deposit timing |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | EXECUTE (implicit) | Runtime caller | No explicit EXECUTE grant found in UsersPermissions; called via service DB user |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCustomersWithSameRegistrationIp (procedure)
├── Customer.CustomerStatic (table - registration IP lookup, cross-schema)
└── Billing.Deposit (table - first deposit timing)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table (cross-schema) | Subquery: find CIDs registered from @IpAddress excluding @CID |
| Billing.Deposit | Table | ROW_NUMBER to find first deposit per CID; date filter for recent first deposits |

### 6.2 Objects That Depend On This

No stored procedures found calling this in the SSDT repo. Called by application services via their own DB users.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Feature | Details |
|---------|---------|
| No status filter on deposits | ROW_NUMBER counts any deposit status (including declined) as the first deposit event. |
| No NOLOCK hints | Neither Customer.CustomerStatic nor Billing.Deposit uses NOLOCK - consistent reads for fraud decisions. |
| IPv4 only | @IpAddress is VARCHAR(15) - supports IPv4 only (max 15 chars: 255.255.255.255). No IPv6 support. |
| @CheckPeriod in hours | DATEADD(HOUR, @CheckPeriod * -1, GETUTCDATE()) - the multiplier by -1 converts to negative hours. |
| Cross-schema dependency | References Customer.CustomerStatic (Customer schema). Requires cross-schema access. |

---

## 8. Sample Queries

### 8.1 Check for multi-account first deposits in last 24 hours

```sql
-- Find other accounts from same IP with first deposits in last 24 hours
EXEC [Billing].[GetCustomersWithSameRegistrationIp]
    @CID = 1234567,
    @IpAddress = '192.168.1.100',
    @CheckPeriod = 24
-- Returns: CIDs of suspicious same-IP first-depositors within 24 hours
```

### 8.2 Extend the window for wider fraud investigation

```sql
-- Check last 72 hours (3 days) for broader multi-account detection
EXEC [Billing].[GetCustomersWithSameRegistrationIp]
    @CID = 1234567,
    @IpAddress = '192.168.1.100',
    @CheckPeriod = 72
```

### 8.3 Verify first deposit timing directly

```sql
-- See all first deposits from same-IP accounts and their timing:
SELECT CS.CID, MIN(D.PaymentDate) AS FirstDepositDate,
    DATEDIFF(HOUR, MIN(D.PaymentDate), GETUTCDATE()) AS HoursAgo
FROM Customer.CustomerStatic CS
JOIN Billing.Deposit D ON D.CID = CS.CID
WHERE CS.IP = '192.168.1.100' AND CS.CID <> 1234567
GROUP BY CS.CID
HAVING MIN(D.PaymentDate) >= DATEADD(HOUR, -24, GETUTCDATE())
ORDER BY FirstDepositDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped; 11 complete)*
*Sources: Atlassian: 0 Confluence + 0 Jira | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCustomersWithSameRegistrationIp | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCustomersWithSameRegistrationIp.sql*
