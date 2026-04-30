# Customer.UpdateTwoFactorVerificationTries

> Increments the wrong-attempt counter on a 2FA challenge row when a customer enters an incorrect OTP code, enabling brute-force detection and rate limiting.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates Customer.TwoFactorVerificationDetails by ReferenceID + GCID; returns @@ROWCOUNT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateTwoFactorVerificationTries is called every time a customer submits an incorrect OTP code. It atomically increments VerificationTries by 1 on the specific challenge row identified by both the session GUID (ReferenceID) and the customer identity (GCID). This counter is the raw signal for brute-force detection: GetTwoFactorVerificationFailedRequestCount queries Success=0 rows to count failures within a time window, and GetOTPAbusers uses multi-day Success=0 patterns for systematic abuse detection.

Without this procedure, the system would have no record of how many wrong attempts were made on any given challenge. A high VerificationTries value (e.g., 5+) combined with Success=0 is a strong indicator that either a brute-force attempt was made or the customer was unable to access their phone. This counter is purely additive - it is never decremented or reset; a new challenge (via InsertTwoFactorVerificationDetails) starts a fresh row with Tries=0.

Data flows: Customer.InsertTwoFactorVerificationDetails creates the row with VerificationTries=0. This procedure is called on each wrong entry. Customer.UpdateTwoFactorVerificationDetails is called on the correct entry (sets Success=1, does NOT touch VerificationTries).

---

## 2. Business Logic

### 2.1 Atomic Counter Increment

**What**: The increment is performed as a single SQL UPDATE (VerificationTries = VerificationTries + 1), making it safe under concurrent access without requiring application-side read-modify-write.

**Columns/Parameters Involved**: `@gcid`, `@referenceID`, VerificationTries (on TwoFactorVerificationDetails)

**Rules**:
- UPDATE is atomic: no risk of lost updates under concurrent wrong-entry submissions
- WHERE clause: ReferenceID = @referenceID AND GCID = @gcid - same dual-key targeting as UpdateTwoFactorVerificationDetails to prevent cross-customer modification
- Returns @@ROWCOUNT: 1 = row found and incremented; 0 = challenge not found (expired/deleted or wrong parameters)
- VerificationTries is NOT reset when a new challenge is created for the same customer - each row tracks its own attempt count independently
- There is no maximum enforcement in SQL (no CHECK constraint on VerificationTries); application logic determines when to lock out or expire the challenge

**Diagram**:
```
Customer enters wrong code
         |
         v
EXEC Customer.UpdateTwoFactorVerificationTries @gcid, @referenceID
         |
         v
UPDATE TwoFactorVerificationDetails
   SET VerificationTries = VerificationTries + 1
 WHERE ReferenceID = @referenceID AND GCID = @gcid
         |
    +---------+
    |         |
   1 row    0 rows
    |         |
Return 1   Return 0  (challenge not found)
    |
VerificationTries++ (e.g., 0->1->2->3...)
Application checks count; may expire or lock out after threshold
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | INT | NO | - | VERIFIED | Group Customer ID of the customer who entered the wrong OTP code. Used in WHERE clause alongside @referenceID to target the correct challenge row. Prevents modifying another customer's attempt counter. |
| 2 | @referenceID | UNIQUEIDENTIFIER | NO | - | VERIFIED | Application-generated GUID identifying the specific OTP challenge session. Paired with @gcid in the WHERE clause. Matches TwoFactorVerificationDetails.ReferenceID. The application retains this GUID throughout the active challenge session. |
| 3 | Return: @@ROWCOUNT | INT | - | - | VERIFIED | Number of rows updated (0 or 1). 1 = challenge found and tries counter incremented. 0 = challenge not found (wrong parameters or challenge row does not exist). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid + @referenceID | Customer.TwoFactorVerificationDetails | MODIFIER | Increments VerificationTries by 1 on the matching challenge row |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (application layer) | - | Caller | Called by verification service each time a customer submits a wrong OTP code |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateTwoFactorVerificationTries (procedure)
└── Customer.TwoFactorVerificationDetails (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.TwoFactorVerificationDetails | Table | UPDATE target - increments VerificationTries by 1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (external application - verification service) | Application | Calls this procedure after each wrong OTP submission |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Record a wrong OTP attempt

```sql
DECLARE @rowsAffected INT;
EXEC Customer.UpdateTwoFactorVerificationTries
    @gcid = 12345678,
    @referenceID = 'A3F8B2C1-1234-5678-9ABC-DEF012345678';
-- Returns 1 if found, 0 if not found
```

### 8.2 Check current attempt count for an active challenge

```sql
SELECT
    tf.ReferenceID,
    tf.GCID,
    tf.Success,
    tf.VerificationTries,
    tf.VerificationDate,
    DATEDIFF(minute, tf.VerificationDate, GETUTCDATE()) AS AgeMinutes
FROM Customer.TwoFactorVerificationDetails tf WITH (NOLOCK)
WHERE tf.GCID = 12345678
  AND tf.ReferenceID = 'A3F8B2C1-1234-5678-9ABC-DEF012345678';
```

### 8.3 Find high-attempt failed challenges (potential brute force) in last 24 hours

```sql
SELECT
    tf.GCID,
    tf.ReferenceID,
    tf.VerificationTries,
    tf.Success,
    tf.VerificationDate,
    tf.VerificationSendMethodTypeID
FROM Customer.TwoFactorVerificationDetails tf WITH (NOLOCK)
WHERE tf.VerificationDate >= DATEADD(hour, -24, GETUTCDATE())
  AND tf.Success = 0
  AND tf.VerificationTries >= 3
ORDER BY tf.VerificationTries DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.UpdateTwoFactorVerificationTries | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.UpdateTwoFactorVerificationTries.sql*
