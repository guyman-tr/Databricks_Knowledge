# Customer.GetTwoFactorVerificationFailedRequestCount

> Returns the count of failed (Success=0) 2FA OTP attempts for a customer since a given datetime, used for per-user rate limiting and brute-force detection.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid + @dateFrom -> COUNT(*) from Customer.TwoFactorVerificationDetails |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetTwoFactorVerificationFailedRequestCount queries Customer.TwoFactorVerificationDetails and returns a scalar count of rows where the customer's 2FA challenges failed (Success=0) within the time window starting at @dateFrom. The caller passes a lookback window start (e.g., DATEADD(hour, -1, GETUTCDATE())) to enforce rate limits: if the returned count exceeds a configured threshold, the application blocks further OTP requests or login attempts for that customer.

This procedure exists to implement the server-side OTP brute-force protection layer. Without it, a bad actor could repeatedly request new codes or attempt verification codes indefinitely. As documented in Customer.TwoFactorVerificationDetails Business Logic section 2.2, GetOTPAbusers uses a more comprehensive multi-window pipeline for systematic abuse detection, while this procedure handles the simpler per-user time-window rate limiting check.

Data flows: InsertTwoFactorVerificationDetails creates rows (Success=0 default). UpdateTwoFactorVerificationDetails sets Success=1 on correct entry. The count returned by this procedure grows until either the customer succeeds (UpdateTwoFactorVerificationDetails flips rows to Success=1) or the time window rolls forward past old failures.

---

## 2. Business Logic

### 2.1 Rate-Limiting Window Query

**What**: Counts failed OTP events for a single customer within a caller-defined time window, feeding application-layer rate limiting.

**Columns/Parameters Involved**: `@gcid`, `@dateFrom`, `Success`, `VerificationDate`

**Rules**:
- Filters WHERE GCID = @gcid AND VerificationDate >= @dateFrom AND Success = CAST(0 AS BIT)
- Only unverified/failed rows are counted: rows where the customer never entered the correct code since @dateFrom
- The caller controls the window size via @dateFrom; common patterns: last hour, last N minutes, last 24 hours
- A returned count >= threshold -> caller blocks the customer from requesting more codes or attempting more entries
- Does NOT count tries (VerificationTries) per challenge - it counts challenge-level failures; even a challenge with 0 tries but no success counts as 1 failure

**Diagram**:
```
Caller sets @dateFrom = DATEADD(hour,-1, GETUTCDATE())
Caller sets threshold = 5

GetTwoFactorVerificationFailedRequestCount(@gcid, @dateFrom)
  -> COUNT(*) WHERE GCID=@gcid
                AND VerificationDate >= @dateFrom
                AND Success = 0

Result >= 5 -> block customer
Result < 5  -> allow next attempt
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | VERIFIED | Group Customer ID identifying the customer to check. Applied as WHERE GCID = @gcid - matches the clustered index leading key of Customer.TwoFactorVerificationDetails for an efficient range seek. |
| 2 | @dateFrom | datetime | NO | - | VERIFIED | Start of the lookback window. Only 2FA challenges created at or after this datetime are counted. The caller determines the window size: e.g., DATEADD(hour,-1,GETUTCDATE()) for an hourly rate limit. Applied as WHERE VerificationDate >= @dateFrom. |

**Output** (scalar result set):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (unnamed COUNT) | int | NO | - | VERIFIED | Count of failed 2FA challenge rows for @gcid since @dateFrom where Success=0. Returned as a single-row, single-column scalar result set. The application reads this value and compares against its configured threshold to decide whether to allow further OTP activity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid, @dateFrom | Customer.TwoFactorVerificationDetails | Reader (SELECT COUNT) | Counts failed OTP rows within the given time window |

### 5.2 Referenced By (other objects point to this)

No callers found in the codebase. Called externally by application services enforcing OTP rate limits.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetTwoFactorVerificationFailedRequestCount (procedure)
└── Customer.TwoFactorVerificationDetails (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.TwoFactorVerificationDetails | Table | SELECT COUNT(*) source - filtered by GCID, VerificationDate >= @dateFrom, Success=0 |

### 6.2 Objects That Depend On This

No dependents found in the codebase. Called externally by application.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Count failed OTP attempts for a customer in the last hour
```sql
DECLARE @oneHourAgo DATETIME = DATEADD(hour, -1, GETUTCDATE());
EXEC Customer.GetTwoFactorVerificationFailedRequestCount
    @gcid = 12345678,
    @dateFrom = @oneHourAgo;
```

### 8.2 Count failed attempts in the last 24 hours (daily rate limit check)
```sql
DECLARE @yesterday DATETIME = DATEADD(day, -1, GETUTCDATE());
EXEC Customer.GetTwoFactorVerificationFailedRequestCount
    @gcid = 12345678,
    @dateFrom = @yesterday;
```

### 8.3 Direct equivalent query for debugging
```sql
SELECT COUNT(*) AS FailedCount
FROM Customer.TwoFactorVerificationDetails WITH (NOLOCK)
WHERE GCID = 12345678
  AND VerificationDate >= DATEADD(hour, -1, GETUTCDATE())
  AND Success = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 8/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetTwoFactorVerificationFailedRequestCount | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetTwoFactorVerificationFailedRequestCount.sql*
