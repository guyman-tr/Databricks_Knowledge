# Customer.GetOTPAbusers

> DISABLED (returns empty result set): Originally designed as a multi-signal OTP/SMS 2FA abuse detector, the procedure was deactivated by inserting a RETURN after a dummy SELECT, leaving all complex detection logic as dead code.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | 6 rate-limit parameters; dead code - always returns empty result |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetOTPAbusers was designed to identify customers abusing the SMS One-Time-Password (OTP) two-factor authentication system. The procedure was created by Ran Ovadia on 13/07/23 to feed the "STS OTP SMS Abuser Service" with a list of GCIDs to block, along with a human-readable BlockReason.

**IMPORTANT: This procedure is effectively disabled.** On line 14-15 of the DDL, a dummy SELECT (`SELECT -999 AS GCID, 'Dummy' AS BlockReason FROM Customer.Customer WHERE 1 = 0`) followed by `RETURN` causes the procedure to exit immediately with an empty result set. All complex detection logic (400+ lines) that follows is never executed.

The developer comment `-- Ran Ovadia, 04/07/23` appears directly before the RETURN pattern, suggesting this was a deliberate decision to disable the SQL-based detection while keeping the code for reference. The active OTP abuse detection is now handled differently (likely in application code or a separate service reading from STS_Audit).

The original dead code detected three categories of abusers:
1. Customers with 2 consecutive suspicious days of 2FA attempts (rate-limit based)
2. Customers with heavy 4-hour bucket concentrations of 2FA attempts
3. Customers with suspicious IP/country/VPN patterns from STS_Audit

---

## 2. Business Logic

### 2.1 DISABLED - Always Returns Empty (RETURN Guard)

**What**: The procedure always exits immediately with an empty result set.

**Columns/Parameters Involved**: All parameters (effectively ignored)

**Rules**:
- `SELECT -999 AS GCID, 'Dummy' AS BlockReason FROM Customer.Customer WHERE 1 = 0` runs but produces 0 rows (WHERE 1=0 is always false)
- `RETURN` immediately exits the procedure
- All subsequent logic (temp tables, CTEs, rate-limit calculations, STS_Audit queries) is NEVER EXECUTED
- Any caller will receive an empty result set regardless of parameter values

### 2.2 Original Detection Logic (Dead Code - For Reference Only)

**What**: Three-signal OTP abuse detection that was designed but is now dormant.

**Columns/Parameters Involved**: All 6 rate-limit parameters, GCID, BlockReason

**Rules (DEAD CODE - never executed)**:
- Source 1: Customer.TwoFactorVerificationDetails - failed 2FA attempts (Success=0)
- Source 2: STS_Audit.StsAudit.UserOperations - OTP actions 37/38 with specific OtpTypeId
- Eligible population filter: RealizedEquity=0 AND VerificationLevelID=0 AND PlayerLevelID<>4 AND CountryID NOT IN (250=UK, 101=Cyprus) AND PlayerStatusID<>2
- Block reason 1 ('2 days'): 2+ consecutive suspicious days (hourly rate >= @HourlyRateLimit OR daily rate >= @DailyRateLimit)
- Block reason 2 ('4 hours'): 2+ four-hour buckets with > @BucketThershold 2FAs in each
- Block reason 3 ('IP/Country/VPN'): >6 distinct IPs AND (>3 proxy types OR >3 countries)
- Also includes static blacklist from Customer.OTPAbusers table
- Excludes 8 hardcoded system GCIDs from results

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DaysToCheck | INT | NO | 7 | CODE-BACKED | DEAD CODE. Originally: rolling window (days) for abuse detection. Default 7 days. |
| 2 | @HourlyRateLimit | INT | NO | 4 | CODE-BACKED | DEAD CODE. Originally: minimum 2FA attempts per hour to flag as suspicious. Default 4. |
| 3 | @DailyRateLimit | INT | NO | 7 | CODE-BACKED | DEAD CODE. Originally: minimum 2FA attempts per day to flag as suspicious. Default 7. |
| 4 | @HoursBucketSize | INT | NO | 4 | CODE-BACKED | DEAD CODE. Originally: size of the hour-bucket for concentration analysis. Default 4 (hours). |
| 5 | @BucketThershold | INT | NO | 10 | CODE-BACKED | DEAD CODE. Originally: minimum 2FA count per bucket to flag. Default 10. Note: typo in parameter name "Thershold" (should be "Threshold"). |
| 6 | @BackutDaysRateLimit | INT | NO | 2 | CODE-BACKED | DEAD CODE. Originally: minimum number of suspicious buckets to trigger a block. Default 2. Note: typo "Backut" (should be "Bucket"). |
| 7 | GCID | int (output) | - | - | CODE-BACKED | ALWAYS EMPTY. Originally: GCID of an identified OTP abuser. |
| 8 | BlockReason | varchar (output) | - | - | CODE-BACKED | ALWAYS EMPTY. Originally: human-readable block reason string (e.g., "OTP Abuser: 2 days; 4 hours"). Max length designed as 64 chars via CONCAT. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (dummy SELECT) | Customer.Customer | FROM (WHERE 1=0) | Only touched for the empty dummy SELECT - no actual data read |
| (dead code) | Customer.TwoFactorVerificationDetails | FROM (DEAD) | Source of failed 2FA attempts - never reached |
| (dead code) | STS_Audit.StsAudit.UserOperations | FROM (DEAD, cross-DB) | STS audit log - cross-database dependency - never reached |
| (dead code) | BackOffice.Customer | JOIN (DEAD) | VerificationLevelID filter - never reached |
| (dead code) | Customer.OTPAbusers | FROM (DEAD) | Static abuser blacklist table - never reached |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| STS OTP SMS Abuser Service | - | Caller | External service that calls this SP - now receives empty results |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetOTPAbusers (procedure - DISABLED)
└── Customer.Customer (table) [only via WHERE 1=0 dummy SELECT]
```

Dead code references (never executed):
- Customer.TwoFactorVerificationDetails
- STS_Audit.StsAudit.UserOperations (cross-DB)
- BackOffice.Customer
- Customer.OTPAbusers

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | Dummy SELECT only (WHERE 1=0) - zero rows returned, then RETURN |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| STS OTP SMS Abuser Service | External Service | Calls this SP for abuse list - receives empty result |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURN after dummy SELECT | Behavioral | Forces immediate exit; disables all detection logic. Created 04/07/23 per developer comment. |
| Hardcoded GCID exclusions | Data quality | 8 infrastructure/system GCIDs (14069618, 14158940, 4327001, 14753275, 36503267, 2009987, 33780430, 2110499) excluded from abuser list. |

---

## 8. Sample Queries

### 8.1 Run the procedure (returns empty)
```sql
-- Always returns 0 rows due to RETURN guard
EXEC Customer.GetOTPAbusers;
-- All parameters are irrelevant - result is always empty
```

### 8.2 Check the OTPAbusers static blacklist directly
```sql
SELECT abu.CID, cc.GCID, cc.UserName, cc.RealizedEquity, cc.PlayerStatusID
FROM Customer.OTPAbusers abu WITH (NOLOCK)
INNER JOIN Customer.Customer cc WITH (NOLOCK) ON cc.CID = abu.CID
ORDER BY abu.CID;
```

### 8.3 Check failed 2FA attempts that the original logic would have scanned
```sql
SELECT TOP 100 GCID, VerificationDate, Success
FROM Customer.TwoFactorVerificationDetails WITH (NOLOCK)
WHERE VerificationDate > DATEADD(DAY, -7, GETUTCDATE())
  AND Success = 0
ORDER BY VerificationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetOTPAbusers | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetOTPAbusers.sql*
