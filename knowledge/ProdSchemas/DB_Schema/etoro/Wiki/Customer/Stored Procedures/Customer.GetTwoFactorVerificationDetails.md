# Customer.GetTwoFactorVerificationDetails

> Retrieves a specific 2FA challenge record by customer GCID and application session reference ID, with a computed flag indicating whether this challenge is the customer's most recent.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid + @referenceId -> point lookup on Customer.TwoFactorVerificationDetails |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetTwoFactorVerificationDetails retrieves the details of a specific two-factor authentication challenge from Customer.TwoFactorVerificationDetails. The caller supplies the customer's GCID and the application-generated ReferenceID (session GUID) that was passed to InsertTwoFactorVerificationDetails when the code was originally dispatched. The procedure returns all stored fields for the matching row, enriched with a computed IsLatest flag that tells the caller whether this challenge is still the most recent one for that customer.

This procedure exists to support the verification step in the 2FA login and sensitive-action flow. After a customer enters an OTP code, the application needs to look up the original challenge to compare the entered code, check whether it has been superseded, and determine current attempt counts. Without this procedure, the application would need to reconstruct query logic for this lookup inline.

Data flows: InsertTwoFactorVerificationDetails creates the row. The application retains the ReferenceID and later calls this procedure to retrieve the challenge. If the customer requests a new code, a second row is inserted - at that point, IsLatest for the original row becomes 0. UpdateTwoFactorVerificationTries increments VerificationTries on each wrong attempt; UpdateTwoFactorVerificationDetails sets Success=1 on correct entry.

---

## 2. Business Logic

### 2.1 IsLatest Computed Flag

**What**: Determines in real time whether this challenge is the most recent one for the given customer, without storing that state in the table.

**Columns/Parameters Involved**: `IsLatest` (computed output), `GCID`, `VerificationDate`

**Rules**:
- IsLatest is NOT a stored column. It is computed per-row in the SELECT via: `CASE WHEN EXISTS(SELECT 1 FROM Customer.TwoFactorVerificationDetails WHERE GCID = tf.GCID AND VerificationDate > tf.VerificationDate) THEN 0 ELSE 1 END`
- IsLatest = 1: no other row for this GCID has a later VerificationDate - this is the current active challenge
- IsLatest = 0: at least one newer challenge has been issued for this customer (e.g., customer clicked "resend code") - this challenge is superseded
- The application uses IsLatest to decide whether to accept a valid code: a correct code from a superseded challenge (IsLatest=0) should be rejected even if Success is still 0

**Diagram**:
```
Customer requests 2FA code:
  Row A: GCID=100, ReferenceID=A, VerificationDate=10:00 -> IsLatest=1

Customer clicks "resend code":
  Row B: GCID=100, ReferenceID=B, VerificationDate=10:05 -> IsLatest=1
  Row A: now IsLatest=0 (row B exists with later VerificationDate)

Application checks Row A -> IsLatest=0 -> reject (superseded)
Application checks Row B -> IsLatest=1 -> accept if code matches
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | VERIFIED | Group Customer ID identifying the customer whose 2FA challenge is being retrieved. Used as the WHERE GCID = @gcid filter - matches the clustered index leading key of Customer.TwoFactorVerificationDetails for an efficient seek. |
| 2 | @referenceId | uniqueidentifier | NO | - | VERIFIED | Application-generated GUID that uniquely identifies the specific 2FA challenge session. Used as the WHERE ReferenceID = @referenceId filter - matches the NONCLUSTERED PK of Customer.TwoFactorVerificationDetails. Together with @gcid, this narrows the query to exactly one row. |

**Output columns** (SELECT result set):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | VERIFIED | Group Customer ID - echoed from the matching row. Confirms which customer this challenge belongs to. See Customer.TwoFactorVerificationDetails.GCID. |
| 2 | ReferenceID | uniqueidentifier | NO | - | VERIFIED | Application session GUID - echoed from the matching row. See Customer.TwoFactorVerificationDetails.ReferenceID. |
| 3 | VerificationCode | varchar(32) | NO | - | CODE-BACKED | The OTP code that was dispatched to the customer via SMS or voice call. The application compares the customer's entered value against this stored code to determine correctness. Security-sensitive: should not be logged or displayed in UIs. See Customer.TwoFactorVerificationDetails.VerificationCode. |
| 4 | VerificationDate | datetime | NO | - | VERIFIED | UTC timestamp when the challenge was created and the code dispatched. Used by the application to determine whether the code is within the expiration window. See Customer.TwoFactorVerificationDetails.VerificationDate. |
| 5 | Success | bit | NO | - | VERIFIED | Whether this OTP was already successfully verified: 1=customer entered correct code previously, 0=still open or failed. If Success=1, the challenge is already consumed and the application should reject re-use. See Customer.TwoFactorVerificationDetails.Success. |
| 6 | IsLatest | bit (computed) | NO | - | VERIFIED | Computed flag indicating whether this is the customer's most recent challenge: 1=no newer challenge exists for this GCID (this code is still current), 0=a newer challenge has been issued (this code is superseded). Derived via EXISTS subquery on Customer.TwoFactorVerificationDetails WHERE GCID=same AND VerificationDate > this row's date. The application should reject codes from superseded challenges even if the code value is correct. |
| 7 | VerificationTries | int | NO | - | VERIFIED | Count of incorrect entry attempts so far. Each call to Customer.UpdateTwoFactorVerificationTries increments this. Combined with application-side max-tries enforcement, a high value indicates brute-force activity. See Customer.TwoFactorVerificationDetails.VerificationTries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid, @referenceId | Customer.TwoFactorVerificationDetails | Reader (SELECT) | Point lookup by GCID + ReferenceID to retrieve a specific 2FA challenge |

### 5.2 Referenced By (other objects point to this)

No callers found in the codebase. Called externally by application services (not via EXEC in other SPs).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetTwoFactorVerificationDetails (procedure)
└── Customer.TwoFactorVerificationDetails (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.TwoFactorVerificationDetails | Table | SELECT source - filters by GCID and ReferenceID; also used in EXISTS subquery to compute IsLatest |

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

### 8.1 Retrieve a specific 2FA challenge by session reference
```sql
EXEC Customer.GetTwoFactorVerificationDetails
    @gcid = 12345678,
    @referenceId = 'A3F8D1C2-1234-5678-ABCD-9E0F12345678';
```

### 8.2 Verify the code and check if it is still the latest (application verification pattern)
```sql
-- Application pattern: call the proc, then evaluate in application code:
-- IF Success=0 AND IsLatest=1 AND VerificationDate > DATEADD(min,-10,GETUTCDATE())
--   THEN compare entered code vs VerificationCode
-- ELSE reject as expired, superseded, or already used

EXEC Customer.GetTwoFactorVerificationDetails
    @gcid = 12345678,
    @referenceId = 'A3F8D1C2-1234-5678-ABCD-9E0F12345678';
```

### 8.3 Direct table equivalent (what the proc executes, for debugging)
```sql
SELECT
    tf.GCID,
    tf.ReferenceID,
    tf.VerificationCode,
    tf.VerificationDate,
    tf.Success,
    CASE WHEN EXISTS (
        SELECT 1 FROM Customer.TwoFactorVerificationDetails WITH (NOLOCK)
        WHERE GCID = tf.GCID AND VerificationDate > tf.VerificationDate
    ) THEN 0 ELSE 1 END AS IsLatest,
    tf.VerificationTries
FROM Customer.TwoFactorVerificationDetails tf WITH (NOLOCK)
WHERE tf.GCID = 12345678
  AND tf.ReferenceID = 'A3F8D1C2-1234-5678-ABCD-9E0F12345678';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetTwoFactorVerificationDetails | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetTwoFactorVerificationDetails.sql*
