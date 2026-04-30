# Customer.GetLatestTwoFactorVerificationDetails

> Retrieves the N most recent 2FA OTP entries for a customer within a rolling expiration window; used by the authentication layer to validate or audit recent verification attempts.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid + @expirationIntervalMinutes (time-windowed lookup) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetLatestTwoFactorVerificationDetails retrieves the most recent N two-factor authentication OTP records for a customer, scoped to a caller-defined expiration window. It is the runtime lookup used by the authentication layer when a customer submits a 2FA code: the caller fetches the recent codes, compares against what the customer entered, and acts on Success/VerificationTries to determine whether to accept or reject the attempt.

The three parameters work together to define a time-bounded, size-capped result:
- @gcid: identifies the customer (GCID, not CID - 2FA is cross-environment)
- @expirationIntervalMinutes: defines how far back (in UTC minutes) to look - codes older than this are expired and excluded
- @numOfCodes: limits how many codes to return (TOP N) - only the N most recent within the window

The procedure maps onto Customer.TwoFactorVerificationDetails, which has a clustered index on (GCID, VerificationDate DESC), making this lookup extremely efficient: the WHERE on GCID uses the leading key and the VerificationDate filter uses the second key in the index direction matching the ORDER BY DESC.

This is the read-side of a two-table lifecycle: records are written on OTP send (Success=0, VerificationTries=0), wrong attempts increment VerificationTries, and a correct match updates Success=1 and VerifySuccessDate. This procedure reads at any point in that lifecycle.

---

## 2. Business Logic

### 2.1 Time-Windowed Recent Code Retrieval

**What**: Returns the N most recent OTP records for a GCID within a rolling UTC expiration window.

**Columns/Parameters Involved**: `@gcid`, `@numOfCodes`, `@expirationIntervalMinutes`, `GCID`, `VerificationDate`, `Success`, `VerificationTries`

**Rules**:
- WHERE GCID = @gcid: targets a single customer by GCID
- AND VerificationDate > DATEADD(minute, -@expirationIntervalMinutes, GETUTCDATE()): excludes codes older than the expiration window (UTC-based)
- TOP (@numOfCodes) ORDER BY VerificationDate DESC: returns the N most recent qualifying records
- WITH NOLOCK: read uncommitted, consistent with high-frequency 2FA workload
- SET NOCOUNT ON: suppresses row count messages for calling application compatibility

### 2.2 OTP Lifecycle Context

The caller uses the returned rows to:
1. Check VerificationCode against what the customer submitted
2. Check Success=1 to detect already-used codes (replay prevention)
3. Check VerificationTries to enforce lockout thresholds
4. Check VerificationDate to confirm the code has not expired (belt-and-suspenders vs the WHERE clause)

ReferenceID is a correlation key linking the OTP send event to this verification record - used for audit tracing.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | INT | NO | - | CODE-BACKED | Global Customer ID whose 2FA records to retrieve. Matches TwoFactorVerificationDetails.GCID. Used as the leading clustered index key for efficient lookup. |
| 2 | @numOfCodes | INT | NO | - | CODE-BACKED | Maximum number of records to return (TOP N). Controls how many recent OTP attempts the caller evaluates. Typical values: 1 (latest only) or small integers (3-5 for retry window). |
| 3 | @expirationIntervalMinutes | INT | NO | - | CODE-BACKED | Rolling expiration window in minutes (applied backward from GETUTCDATE()). OTP entries with VerificationDate older than this cutoff are excluded. Standard OTP expiry: 5-10 minutes. |

**Output result set:**

| Column | Source | Business Meaning |
|--------|--------|-----------------|
| GCID | Customer.TwoFactorVerificationDetails.GCID | Global Customer ID - echoed back for caller correlation. |
| ReferenceID | Customer.TwoFactorVerificationDetails.ReferenceID | Correlation key linking the OTP send event to this record. Used for audit tracing and matching verification to the original send. |
| VerificationCode | Customer.TwoFactorVerificationDetails.VerificationCode | The OTP code that was generated and sent to the customer. The caller compares this to what the customer submitted. |
| VerificationDate | Customer.TwoFactorVerificationDetails.VerificationDate | UTC datetime when this OTP record was created. Used to confirm freshness (belt-and-suspenders to the WHERE clause). Clustered index second key (DESC order) - drives the TOP N selection. |
| Success | Customer.TwoFactorVerificationDetails.Success | 0 = pending/not yet verified; 1 = successfully verified. Callers check this to prevent replay attacks (already-used codes must not be accepted again). |
| VerificationTries | Customer.TwoFactorVerificationDetails.VerificationTries | Number of incorrect attempts against this OTP entry. Callers use this to enforce lockout thresholds (e.g., 3 wrong tries -> block). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID | Customer.TwoFactorVerificationDetails | Read (clustered index scan) | Source of all returned columns; WHERE on GCID + VerificationDate matches clustered index |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase (called by authentication/session management services).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetLatestTwoFactorVerificationDetails (procedure)
└── Customer.TwoFactorVerificationDetails (table)
      └── Clustered index on (GCID, VerificationDate DESC)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.TwoFactorVerificationDetails | Table | Source of OTP records; WHERE on GCID + VerificationDate expiry window; TOP N ORDER BY VerificationDate DESC |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TOP (@numOfCodes) | Row cap | Limits result to N most recent records; prevents returning entire history |
| VerificationDate > DATEADD(minute, -@expirationIntervalMinutes, GETUTCDATE()) | Time filter | UTC-based rolling expiration window; codes outside window are excluded |
| ORDER BY VerificationDate DESC | Sort | Most recent codes returned first; aligns with clustered index direction for efficiency |
| WITH NOLOCK | Isolation | Read uncommitted; appropriate for high-frequency 2FA lookups where dirty reads are acceptable |

---

## 8. Sample Queries

### 8.1 Get the latest 2FA code for a customer (5-minute window)

```sql
EXEC Customer.GetLatestTwoFactorVerificationDetails
    @gcid = 9876543,
    @numOfCodes = 1,
    @expirationIntervalMinutes = 5
-- Returns most recent OTP sent in last 5 minutes; Success=0 means still pending
```

### 8.2 Get last 3 attempts for lockout check

```sql
EXEC Customer.GetLatestTwoFactorVerificationDetails
    @gcid = 9876543,
    @numOfCodes = 3,
    @expirationIntervalMinutes = 10
-- Caller checks VerificationTries across rows to evaluate lockout threshold
```

### 8.3 Direct query equivalent

```sql
SELECT TOP 5 GCID, ReferenceID, VerificationCode, VerificationDate, Success, VerificationTries
FROM Customer.TwoFactorVerificationDetails WITH (NOLOCK)
WHERE GCID = 9876543
AND VerificationDate > DATEADD(minute, -5, GETUTCDATE())
ORDER BY VerificationDate DESC
```

### 8.4 Check if a customer has any active unverified codes

```sql
CREATE TABLE #Codes (GCID INT, ReferenceID INT, VerificationCode VARCHAR(10), VerificationDate DATETIME, Success BIT, VerificationTries INT)
INSERT INTO #Codes EXEC Customer.GetLatestTwoFactorVerificationDetails @gcid = 9876543, @numOfCodes = 1, @expirationIntervalMinutes = 10
SELECT CASE WHEN COUNT(*) > 0 AND MAX(CAST(Success AS INT)) = 0 THEN 'Active OTP pending' ELSE 'No active OTP' END AS Status FROM #Codes
DROP TABLE #Codes
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetLatestTwoFactorVerificationDetails | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetLatestTwoFactorVerificationDetails.sql*
