# Customer.UpdateTwoFactorVerificationDetails

> Marks a 2FA (OTP) challenge as successfully verified: sets Success=1 and stamps the verification timestamp on Customer.TwoFactorVerificationDetails when the customer enters the correct one-time code.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates Customer.TwoFactorVerificationDetails by ReferenceID + GCID; returns @@ROWCOUNT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateTwoFactorVerificationDetails is the "success" half of the 2FA verification workflow. When a customer enters the correct OTP code, the application calls this procedure to close the challenge as resolved: Success is flipped to 1 and VerifySuccessDate is set to the current UTC timestamp. The WHERE clause targets the exact challenge row using both ReferenceID (the application-side GUID generated at challenge creation) and GCID (the cross-product customer identity), ensuring only the specific session's challenge is marked as verified.

Without this procedure, successful verifications could not be recorded. Every entry in TwoFactorVerificationDetails remains in the Success=0 state until either this procedure runs (correct code) or the challenge expires. Security logic in GetTwoFactorVerificationFailedRequestCount and GetOTPAbusers relies on Success=0 as the "unresolved/failed" signal - so correctly flipping to Success=1 is critical to prevent false fraud signals for legitimate customers.

Data flows: Customer.InsertTwoFactorVerificationDetails creates the row with Success=0, VerifySuccessDate=NULL. This procedure sets Success=1 and VerifySuccessDate. The companion procedure Customer.UpdateTwoFactorVerificationTries handles wrong-code attempts (increments VerificationTries) but never sets Success.

---

## 2. Business Logic

### 2.1 Optimistic Update with Row Count Guard

**What**: The procedure returns @@ROWCOUNT to the caller so the application can verify that exactly one row was updated.

**Columns/Parameters Involved**: `@gcid`, `@referenceID`, return value (@@ROWCOUNT)

**Rules**:
- WHERE clause requires BOTH ReferenceID = @referenceID AND GCID = @gcid - dual-key targeting prevents cross-customer contamination
- If @@ROWCOUNT = 1: challenge was found and marked as verified (normal path)
- If @@ROWCOUNT = 0: challenge not found - either wrong parameters, or challenge was already updated/deleted. Application should treat this as a failure to verify.
- SET NOCOUNT ON suppresses the automatic row count message but @@ROWCOUNT is still captured and returned explicitly via SELECT @@ROWCOUNT

**Diagram**:
```
Caller provides: @gcid + @referenceID (from original InsertTwoFactorVerificationDetails call)
         |
         v
UPDATE TwoFactorVerificationDetails
   SET Success = 1
       VerifySuccessDate = GETUTCDATE()
 WHERE ReferenceID = @referenceID AND GCID = @gcid
         |
    +---------+
    |         |
   1 row    0 rows
   updated  updated
    |         |
SELECT 1   SELECT 0   <- returned to caller
(success)  (not found - wrong params or already resolved)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | INT | NO | - | VERIFIED | Group Customer ID of the customer who entered the OTP code. Used in WHERE clause alongside @referenceID to uniquely identify the challenge row. Prevents one customer from resolving another's challenge. |
| 2 | @referenceID | UNIQUEIDENTIFIER | NO | - | VERIFIED | Application-generated GUID identifying the specific OTP challenge session. Paired with @gcid in the WHERE clause. Matches TwoFactorVerificationDetails.ReferenceID (the NONCLUSTERED PK of that table). The application holds this GUID from the original InsertTwoFactorVerificationDetails call. |
| 3 | Return: @@ROWCOUNT | INT | - | - | VERIFIED | Number of rows updated (0 or 1). 1 = challenge successfully marked as verified. 0 = challenge not found (wrong ReferenceID/GCID combination, or row does not exist). The caller uses this to determine whether verification succeeded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid + @referenceID | Customer.TwoFactorVerificationDetails | MODIFIER | Updates Success=1 and VerifySuccessDate on the matching 2FA challenge row |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (application layer) | - | Caller | Called by the verification service when a customer submits the correct OTP code |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateTwoFactorVerificationDetails (procedure)
└── Customer.TwoFactorVerificationDetails (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.TwoFactorVerificationDetails | Table | UPDATE target - sets Success=1, VerifySuccessDate=GETUTCDATE() |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (external application - verification service) | Application | Calls this procedure after customer enters correct OTP code |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Mark a 2FA challenge as successfully verified

```sql
DECLARE @rowsAffected INT;
EXEC Customer.UpdateTwoFactorVerificationDetails
    @gcid = 12345678,
    @referenceID = 'A3F8B2C1-1234-5678-9ABC-DEF012345678';
-- Returns 1 if found and updated, 0 if not found
```

### 8.2 Verify the update was applied (post-call check)

```sql
SELECT
    tf.ReferenceID,
    tf.GCID,
    tf.Success,
    tf.VerifySuccessDate,
    tf.VerificationTries
FROM Customer.TwoFactorVerificationDetails tf WITH (NOLOCK)
WHERE tf.GCID = 12345678
  AND tf.ReferenceID = 'A3F8B2C1-1234-5678-9ABC-DEF012345678';
-- Should show Success=1, VerifySuccessDate=timestamp
```

### 8.3 Check verification history for a customer over the last 24 hours

```sql
SELECT
    tf.ReferenceID,
    tf.VerificationDate,
    tf.VerifySuccessDate,
    tf.Success,
    tf.VerificationTries,
    tf.VerificationSendMethodTypeID
FROM Customer.TwoFactorVerificationDetails tf WITH (NOLOCK)
WHERE tf.GCID = 12345678
  AND tf.VerificationDate >= DATEADD(hour, -24, GETUTCDATE())
ORDER BY tf.VerificationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.UpdateTwoFactorVerificationDetails | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.UpdateTwoFactorVerificationDetails.sql*
