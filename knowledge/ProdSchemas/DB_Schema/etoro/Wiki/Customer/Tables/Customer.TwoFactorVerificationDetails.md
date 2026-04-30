# Customer.TwoFactorVerificationDetails

> Two-factor authentication audit log: records each OTP challenge sent to a customer via SMS or voice call, tracking whether the code was successfully verified and how many entry attempts were made.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | ReferenceID (GUID, NONCLUSTERED PK); GCID + VerificationDate (CLUSTERED) |
| **Partition** | No (MAIN filegroup, PAGE compression) |
| **Indexes** | 2 (NONCLUSTERED PK on ReferenceID + CLUSTERED on GCID,VerificationDate DESC) |

---

## 1. Business Meaning

Customer.TwoFactorVerificationDetails records every two-factor authentication (2FA) challenge issued to an eToro customer. Each row represents a single OTP (One-Time Password) event: the system generated a code, sent it to the customer via SMS or voice call, and then tracked whether the customer successfully entered the correct code. The composite of ReferenceID (application-side GUID) and GCID (group customer identity) links a database record to the exact application session that triggered the challenge.

This table is the operational backbone of eToro's 2FA security layer. Without it, the system cannot verify whether a code has expired, was already used, or is being brute-forced. GetTwoFactorVerificationFailedRequestCount reads failed attempts within a time window to block brute-force attacks. GetOTPAbusers uses Success=0 records over 7-day windows to identify customers systematically abusing the SMS sending infrastructure.

Data flows: Customer.InsertTwoFactorVerificationDetails creates a new row when a code is dispatched. Customer.UpdateTwoFactorVerificationTries increments VerificationTries on each wrong entry attempt. Customer.UpdateTwoFactorVerificationDetails sets Success=1 and stamps VerifySuccessDate when the customer enters the correct code. The clustered index on (GCID, VerificationDate DESC) ensures "fetch the most recent challenge for this user" is a single-range seek, which is the dominant access pattern across all reader procedures.

---

## 2. Business Logic

### 2.1 OTP Challenge Lifecycle

**What**: Each 2FA event progresses through a defined state machine from code dispatch to resolution.

**Columns/Parameters Involved**: `Success`, `VerificationTries`, `VerificationDate`, `VerifySuccessDate`

**Rules**:
- INSERT: Success=0 (default), VerificationTries=0 (default), VerifySuccessDate=NULL - challenge is open
- Each wrong entry: UpdateTwoFactorVerificationTries increments VerificationTries by 1
- Correct entry: UpdateTwoFactorVerificationDetails sets Success=1, VerifySuccessDate=GETUTCDATE()
- Codes expire by application logic: GetLatestTwoFactorVerificationDetails filters WHERE VerificationDate > DATEADD(minute, -@expirationIntervalMinutes, GETUTCDATE())
- IsLatest is NOT stored - it is computed dynamically by GetTwoFactorVerificationDetails: EXISTS(SELECT 1 WHERE GCID=same AND VerificationDate > this row's date) -> 0 if superseded, 1 if latest

**Diagram**:
```
[INSERT: Success=0, Tries=0]
         |
         v
   Code sent to customer
         |
   +-----+------+
   |            |
Wrong entry   Correct entry
   |            |
UpdateTries   UpdateDetails
Tries += 1    Success=1, VerifySuccessDate=NOW
   |            |
(loop)        [RESOLVED: Success=1]
   |
[EXPIRED: VerificationDate + expiry window < now]
```

### 2.2 OTP Abuse Detection

**What**: The Success=0 rows (failed challenges) are the primary signal used by the OTP abuse detection pipeline to identify customers systematically abusing the SMS sending system.

**Columns/Parameters Involved**: `GCID`, `Success`, `VerificationDate`

**Rules**:
- GetTwoFactorVerificationFailedRequestCount: COUNT(*) WHERE GCID=@gcid AND VerificationDate >= @dateFrom AND Success=0 - used for per-user rate limiting
- GetOTPAbusers: complex multi-signal pipeline that reads Success=0 rows over @DaysToCheck (default 7) days, then applies hourly rate limits (@HourlyRateLimit=4/hr), daily rate limits (@DailyRateLimit=7/day), and 4-hour bucket thresholds (@BucketThershold=10) to identify systematic abusers; results feed into Customer.OTPAbusers table
- Only customers with RealizedEquity=0, VerificationLevelID=0, PlayerLevelID<>4 (not Partner), CountryID not in (250=virtual, 101=excluded) are in scope for abuse blocking
- Note: GetOTPAbusers starts with RETURN on line 14 (disabled shortcut) - the real logic is preserved but bypassed by a Ran Ovadia comment (04/07/23)

---

## 3. Data Overview

| ReferenceID (abbreviated) | GCID | VerificationCode | SendMethod | Success | Tries | Meaning |
|--------------------------|------|-----------------|------------|---------|-------|---------|
| a3f8...1234 | 12345678 | [6-digit OTP] | 1 (sms) | 1 | 0 | Customer entered code correctly on first try via SMS - typical successful 2FA login |
| b7c2...5678 | 12345678 | [6-digit OTP] | 1 (sms) | 0 | 3 | Customer entered wrong code 3 times; code either expired or they abandoned - failure row used by abuse detection |
| d9e1...9012 | 23456789 | [6-digit OTP] | 2 (call) | 1 | 1 | Customer chose voice call delivery, needed one retry before succeeding |
| f4a7...3456 | 34567890 | [6-digit OTP] | 1 (sms) | 0 | 0 | Code just sent, verification pending (Success=0, Tries=0 = open challenge) |
| c1b5...7890 | 23456789 | [6-digit OTP] | 1 (sms) | 0 | 0 | Second challenge for same GCID; IsLatest=1 (this row supersedes the b7c2 row above for this user) |

*VerificationCode values masked (security-sensitive OTP data). 85.3% of rows have Success=1.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReferenceID | uniqueidentifier | NO | - | VERIFIED | Application-generated GUID that uniquely identifies this 2FA challenge. NONCLUSTERED PK - used for point-lookup by the consuming application to retrieve or update a specific challenge by session ID. InsertTwoFactorVerificationDetails receives this from the caller; the application generates it before calling the SP. |
| 2 | GCID | int | NO | - | VERIFIED | Group Customer ID - the cross-product identity of the customer receiving the challenge. Part of the CLUSTERED index (GCID, VerificationDate DESC), enabling fast "get all/latest challenges for this customer" queries. Used by all reader procedures as the primary filter. |
| 3 | VerificationCode | varchar(32) | NO | - | CODE-BACKED | The OTP code sent to the customer via SMS or voice call. Typically a 6-digit numeric string. Stored here so the verification service can compare the customer's entered value against the original. InsertTwoFactorVerificationDetails receives this from the calling application. varchar(32) provides headroom for future code format changes. |
| 4 | VerificationDate | datetime | NO | getutcdate() | VERIFIED | UTC timestamp when this challenge was created and the code dispatched to the customer. Default = getutcdate() on INSERT. Functions as the clustered index leading key (after GCID) in descending order - rows are physically sorted newest-first per customer. Used by GetLatestTwoFactorVerificationDetails to filter for non-expired codes via DATEADD(minute, -@expirationIntervalMinutes, getutcdate()). |
| 5 | VerifySuccessDate | datetime | YES | - | VERIFIED | UTC timestamp set by UpdateTwoFactorVerificationDetails when Success is flipped to 1. NULL = challenge not yet verified. Non-NULL = the exact moment the customer entered the correct code. Useful for auditing how long customers take to verify and for detecting replayed/delayed codes. |
| 6 | Success | bit | NO | 0 | VERIFIED | Whether the OTP was successfully verified: 1 = customer entered correct code (UpdateTwoFactorVerificationDetails was called); 0 = challenge still open, failed, or expired. Default=0 on INSERT. GetTwoFactorVerificationFailedRequestCount counts rows WHERE Success=0 for brute-force detection. GetOTPAbusers reads Success=0 rows as the abuse signal. |
| 7 | VerificationTries | int | NO | 0 | VERIFIED | Count of incorrect entry attempts. Default=0 on INSERT. Incremented by 1 on each call to UpdateTwoFactorVerificationTries (wrong code entered). Does NOT increment on success - UpdateTwoFactorVerificationDetails sets Success=1 directly without touching VerificationTries. A high value (e.g., 3+) combined with Success=0 indicates a brute-force attempt or user error. |
| 8 | VerificationSendMethodTypeID | int | YES | - | VERIFIED | Delivery channel for the OTP code. FK to Dictionary.TwoFactorVerificationSendMethodType: 1=sms (text message), 2=call (automated voice call). NULL = delivery method not recorded (older rows predating this column). InsertTwoFactorVerificationDetails receives this from the caller - the application determines which channel based on user preference or fallback logic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| VerificationSendMethodTypeID | Dictionary.TwoFactorVerificationSendMethodType | FK (enforced) | Lookup for OTP delivery channel: 1=sms, 2=call |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.InsertTwoFactorVerificationDetails | ReferenceID, GCID | Writer | Creates new OTP challenge row when code is dispatched to customer |
| [Customer.UpdateTwoFactorVerificationDetails](../Stored%20Procedures/Customer.UpdateTwoFactorVerificationDetails.md) | ReferenceID, GCID | Modifier | Sets Success=1, VerifySuccessDate=GETUTCDATE() when code verified |
| Customer.UpdateTwoFactorVerificationTries | ReferenceID, GCID | Modifier | Increments VerificationTries by 1 on each wrong entry attempt |
| Customer.GetTwoFactorVerificationDetails | GCID, ReferenceID | Reader | Returns challenge details with computed IsLatest flag for application verification flow |
| Customer.GetLatestTwoFactorVerificationDetails | GCID | Reader | Returns TOP N most recent non-expired challenges for a customer; used to check if a valid code exists |
| Customer.GetTwoFactorLastVerificationDetails | GCID | Reader | Returns TOP 1 most recent challenge summary (no code); used to check last 2FA activity |
| Customer.GetTwoFactorVerificationFailedRequestCount | GCID | Reader | Counts Success=0 rows since @dateFrom; feeds per-user rate limiting logic |
| Customer.GetOTPAbusers | GCID | Reader | Reads Success=0 rows over 7-day window as primary signal for systematic SMS abuse detection |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.TwoFactorVerificationDetails (table)
```
Tables are leaf nodes - no code-level FROM/JOIN dependencies in CREATE TABLE.

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.TwoFactorVerificationSendMethodType | Table | FK target for VerificationSendMethodTypeID (1=sms, 2=call) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.InsertTwoFactorVerificationDetails | Stored Procedure | Writer - creates challenge row |
| Customer.UpdateTwoFactorVerificationDetails | Stored Procedure | Modifier - marks challenge as successful |
| Customer.UpdateTwoFactorVerificationTries | Stored Procedure | Modifier - increments try counter |
| Customer.GetTwoFactorVerificationDetails | Stored Procedure | Reader - point lookup by GCID+ReferenceID |
| Customer.GetLatestTwoFactorVerificationDetails | Stored Procedure | Reader - recent non-expired codes for a customer |
| Customer.GetTwoFactorLastVerificationDetails | Stored Procedure | Reader - most recent activity summary |
| Customer.GetTwoFactorVerificationFailedRequestCount | Stored Procedure | Reader - failure count for rate limiting |
| Customer.GetOTPAbusers | Stored Procedure | Reader - Success=0 rows for abuse detection pipeline |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TwoFactorVerificationDetails | NONCLUSTERED PK | ReferenceID ASC | - | - | Active (FILLFACTOR=90) |
| CLU_IX_TwoFactorVerificationDetails_GCID | CLUSTERED | GCID ASC, VerificationDate DESC | - | - | Active (FILLFACTOR=80, PAGE compressed) |

*Unusual design: the clustered index is NOT on the PK. The clustered index (GCID, VerificationDate DESC) is optimized for the dominant query pattern - "get latest N challenges for this customer". The NONCLUSTERED PK on ReferenceID supports application point-lookups by session GUID. VerificationDate DESC in the clustered key means most recent rows are physically first per GCID - Order By VerificationDate Desc queries avoid a sort.*

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_TwoFactorVerif_VerifDate | DEFAULT | VerificationDate = getutcdate() |
| DF_TwoFcatorVerif_Success | DEFAULT | Success = 0 (challenge starts as unverified) |
| DF_TwoFactorVerif_VerificationTries | DEFAULT | VerificationTries = 0 (no attempts at creation) |
| FK_Customer_TwoFactorVerificationDetails_VerificationSendMethodTypeID | FK | VerificationSendMethodTypeID -> Dictionary.TwoFactorVerificationSendMethodType(SendMethodTypeID) |

---

## 8. Sample Queries

### 8.1 Get all recent 2FA challenges for a customer (last 24 hours)
```sql
SELECT
    tf.ReferenceID,
    tf.GCID,
    tf.VerificationDate,
    tf.VerifySuccessDate,
    tf.Success,
    tf.VerificationTries,
    smt.Name AS SendMethod
FROM Customer.TwoFactorVerificationDetails tf WITH (NOLOCK)
LEFT JOIN Dictionary.TwoFactorVerificationSendMethodType smt WITH (NOLOCK)
    ON smt.SendMethodTypeID = tf.VerificationSendMethodTypeID
WHERE tf.GCID = 12345678
  AND tf.VerificationDate >= DATEADD(hour, -24, GETUTCDATE())
ORDER BY tf.VerificationDate DESC;
```

### 8.2 Count failed OTP attempts for a customer in the last hour (rate limiting check)
```sql
SELECT COUNT(*) AS FailedAttempts
FROM Customer.TwoFactorVerificationDetails WITH (NOLOCK)
WHERE GCID = 12345678
  AND VerificationDate >= DATEADD(hour, -1, GETUTCDATE())
  AND Success = 0;
```

### 8.3 Find customers with high 2FA failure rates (potential abuse signals)
```sql
SELECT
    tf.GCID,
    COUNT(*) AS TotalChallenges,
    SUM(CASE WHEN tf.Success = 1 THEN 1 ELSE 0 END) AS Successes,
    SUM(CASE WHEN tf.Success = 0 THEN 1 ELSE 0 END) AS Failures,
    AVG(CAST(tf.VerificationTries AS float)) AS AvgTries
FROM Customer.TwoFactorVerificationDetails tf WITH (NOLOCK)
WHERE tf.VerificationDate >= DATEADD(day, -7, GETUTCDATE())
GROUP BY tf.GCID
HAVING SUM(CASE WHEN tf.Success = 0 THEN 1 ELSE 0 END) >= 10
ORDER BY Failures DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.TwoFactorVerificationDetails | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.TwoFactorVerificationDetails.sql*
