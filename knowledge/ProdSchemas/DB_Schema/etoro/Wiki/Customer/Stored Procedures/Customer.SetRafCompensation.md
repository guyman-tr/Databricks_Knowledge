# Customer.SetRafCompensation

> Executes a Refer-A-Friend (RAF) compensation payout to both the referring and referred customer, with referral-pair validation, concurrency locking, per-referrer cap enforcement, and idempotent failure tracking.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ReferringCID + @ReferredCID - the RAF pair to compensate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.SetRafCompensation processes a Refer-A-Friend bonus payout for a confirmed referring/referred customer pair. When a referred customer meets the program conditions (defined externally), this procedure: validates the referral relationship, prevents concurrent double-processing, checks the referrer has not hit their compensation cap, credits both customers via SetBalanceCompensation, and records the completed event in Customer.RAFGiven.

The procedure exists to be the single, safe, atomic compensation processor. It handles the full lifecycle of a RAF payout - from validation through credit to ledger entry - in a way that is safe for concurrent calls (the RafCIDInProcess lock) and auditable (FailedRAFCompensation on failures).

Data flow: called from the RAF batch processing job (Customer.RAFCompensationProcess_NogaJunk210725 or external RAF scheduler). Each call represents one referral pair being rewarded. The procedure calls Customer.SetBalanceCompensation for each party (BonusTypeID=53 for referrer, 54 for referred), records the paid-out amounts in Customer.RAFGiven, and uses Customer.RafCIDInProcess as a temporary advisory lock for the referring CID. On failure, records to Customer.FailedRAFCompensation for retry.

History: Original SP (2023-05-xx, Noga Rozen). Updated 2023-06-18 to set status on RafEligibleCustomers. Updated 2025-07-16 to remove RafEligibleCustomers update (no longer in use in new RAF compensation); added FailureDate to FailedRAFCompensation.

---

## 2. Business Logic

### 2.1 Referral Pair Validation

**What**: Confirms that @ReferredCID actually signed up via @ReferringCID before any money moves.

**Columns/Parameters Involved**: `@ReferringCID`, `@ReferredCID`, Customer.Customer.ReferralID

**Rules**:
- SELECT from Customer.Customer WHERE CID=@ReferredCID AND ReferralID=@ReferringCID
- If the referred customer has @ReferringCID in their ReferralID column -> pair is valid, proceed
- If no row found -> RETURN 4 ("Not Valid") - compensation is refused entirely
- This prevents compensating for referrals where the ReferralID linkage was never recorded (e.g., direct registrations, or referrals to a different referring CID)

### 2.2 Concurrency Lock (RafCIDInProcess)

**What**: Prevents the same referring CID from being processed by two concurrent RAF jobs simultaneously.

**Columns/Parameters Involved**: `@ReferringCID`, Customer.RafCIDInProcess

**Rules**:
- INSERT INTO RafCIDInProcess(CID) VALUES (@ReferringCID) - the PK on this table makes the INSERT fail if already present
- If INSERT fails with ERROR_NUMBER()=2627 (PK violation): wait 500ms and retry up to 6 times total
- After 6 failed attempts: DELETE is NOT called (lock is still held); RETURN 1 ("Busy - try again")
- On success: @TotalWaitAttempts is set to 7 to break the WHILE loop
- The lock is released (DELETE RafCIDInProcess) in all exit paths: after success, after cap check, and in the CATCH block

**Diagram**:
```
WHILE @TotalWaitAttempts <= 6:
  TRY INSERT RafCIDInProcess(CID=@ReferringCID)
    -> SUCCESS: set attempts=7, break loop
    -> PK violation (2627): wait 500ms, increment attempts
       attempts >= 6? -> RETURN 1 (Busy)
```

### 2.3 Per-Referrer Compensation Cap

**What**: Limits how many successful RAF payouts a single referring customer can earn.

**Columns/Parameters Involved**: `@ReferringCID`, `@MaxNumberOfCompensations`, Customer.RAFGiven.ReferringCID

**Rules**:
- COUNT(*) FROM RAFGiven WHERE ReferringCID=@ReferringCID
- If count >= @MaxNumberOfCompensations: DELETE lock from RafCIDInProcess, RETURN 2 ("Limit reached")
- @MaxNumberOfCompensations is passed by the caller (defined in RAF program configuration), not hardcoded in this procedure

### 2.4 Dual-Party Compensation Payout

**What**: Credits both the referring and referred customer, but only if their respective amounts are greater than zero.

**Columns/Parameters Involved**: `@ReferringCID`, `@ReferredCID`, `@ReferringCompensationInCents`, `@ReferredCompensationInCents`

**Rules**:
- Amounts are passed in CENTS; SetBalanceCompensation receives them in cents
- RAFGiven stores amounts in DOLLARS (ReferringCompensationAmount = @ReferringCompensationInCents/100)
- IF @ReferringCompensationInCents > 0: EXEC Customer.SetBalanceCompensation @ReferringCID, @ReferringCompensationInCents, 'RAF - Referring {ReferredCID}', NULL, 53 (BonusTypeID=53)
- IF @ReferredCompensationInCents > 0: EXEC Customer.SetBalanceCompensation @ReferredCID, @ReferredCompensationInCents, 'RAF - Referred by {ReferringCID}', NULL, 54 (BonusTypeID=54)
- Either compensation can be zero (the respective credit is skipped); both can be non-zero

### 2.5 Return Code Protocol

**What**: Structured return codes allow callers to respond appropriately without catching exceptions.

**Rules**:
```
0 = Done (success - both parties credited, RAFGiven inserted)
1 = Busy - try again (RafCIDInProcess lock held after 6 retries)
2 = Limit reached (referring CID has hit @MaxNumberOfCompensations)
3 = Compensation already given (CATCH path: SetBalanceCompensation likely raised a duplicate error)
4 = Not valid (ReferralID mismatch - wrong pair)
5 = Failed to give RAF (CATCH path: @ErrOut indicates SetBalanceCompensation returned an error)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ReferringCID | bigint | NO | - | CODE-BACKED | The customer who made the referral (the "referrer"). Validated via Customer.Customer.ReferralID of the referred customer. Used as the lock key in RafCIDInProcess, the count key in RAFGiven, and the compensation target for BonusTypeID=53. |
| 2 | @ReferringCompensationInCents | int | NO | - | CODE-BACKED | The amount to credit to the referring customer, in cents. Passed directly to Customer.SetBalanceCompensation. Stored in RAFGiven as dollars (value/100). If 0, the referring customer receives no credit this call. |
| 3 | @ReferredCID | bigint | NO | - | CODE-BACKED | The customer who was referred (the "referee"). Their ReferralID must equal @ReferringCID for the validation check to pass. The compensation target for BonusTypeID=54. |
| 4 | @ReferredCompensationInCents | int | NO | - | CODE-BACKED | The amount to credit to the referred customer, in cents. Passed directly to Customer.SetBalanceCompensation. Stored in RAFGiven as dollars (value/100). If 0, the referred customer receives no credit this call. |
| 5 | @MaxNumberOfCompensations | int | NO | - | CODE-BACKED | Program-defined cap on how many successful referrals a single referring CID can earn. Compared against COUNT(*) in RAFGiven for the referring CID. Passed by caller from program configuration - not stored in DB. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ReferredCID | Customer.Customer | Reader (validation) | Checks ReferralID = @ReferringCID to validate the referral pair |
| @ReferringCID | Customer.RafCIDInProcess | Writer + Deleter | INSERT for concurrency lock; DELETE after processing |
| @ReferringCID | Customer.RAFGiven | Reader + Writer | COUNT to enforce cap; INSERT on success |
| @ReferringCID, @ReferredCID | Customer.FailedRAFCompensation | Writer | INSERT on CATCH failure with IsFixed=0, FailureDate=GETUTCDATE() |
| @ReferringCID, @ReferredCID | Customer.SetBalanceCompensation | EXEC (callee) | Credits balance for both parties (BonusTypeID 53 and 54) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external RAF scheduler / batch) | - | - | No intra-DB callers found; called from the RAF processing batch job |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetRafCompensation (procedure)
├── Customer.Customer (view - referral pair validation)
├── Customer.RafCIDInProcess (table - concurrency lock)
├── Customer.RAFGiven (table - cap check + success ledger)
├── Customer.FailedRAFCompensation (table - failure log)
└── Customer.SetBalanceCompensation (procedure - balance credits)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | SELECT to validate ReferralID linkage between referred and referring CID |
| Customer.RafCIDInProcess | Table | Concurrency lock: INSERT to acquire, DELETE to release |
| Customer.RAFGiven | Table | COUNT to check cap; INSERT to record completed compensation |
| Customer.FailedRAFCompensation | Table | INSERT on failure to track unprocessed compensations |
| Customer.SetBalanceCompensation | Stored Procedure | Credits balance for @ReferringCID (BonusTypeID=53) and @ReferredCID (BonusTypeID=54) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No intra-DB callers found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Explicit transaction | Atomicity | BEGIN TRANSACTION wraps SetBalanceCompensation calls + RAFGiven INSERT; ROLLBACK on any failure |
| Retry loop | Concurrency | Up to 6 retries with 500ms delay on RafCIDInProcess PK violation |
| RETURN codes | Protocol | Callers must check return value: 0=success, 1=retry, 2=cap, 3=dup, 4=invalid, 5=error |
| THROW in CATCH | Error propagation | After logging to FailedRAFCompensation, re-throws the original exception |

---

## 8. Sample Queries

### 8.1 Execute RAF compensation for a validated pair
```sql
DECLARE @Result INT;
EXEC @Result = Customer.SetRafCompensation
    @ReferringCID = 100001,
    @ReferringCompensationInCents = 5000,   -- $50
    @ReferredCID = 200002,
    @ReferredCompensationInCents = 2500,    -- $25
    @MaxNumberOfCompensations = 5;
SELECT @Result AS ReturnStatus;
-- 0=done, 1=busy, 2=limit, 3=already given, 4=invalid, 5=failed
```

### 8.2 Check if a referring CID has reached their cap
```sql
SELECT COUNT(*) AS GivenCount
FROM Customer.RAFGiven WITH (NOLOCK)
WHERE ReferringCID = 100001;
```

### 8.3 Review failed RAF compensations pending retry
```sql
SELECT fc.ReferringCID, fc.ReferredCID, fc.FailueDate, fc.IsFixed
FROM Customer.FailedRAFCompensation fc WITH (NOLOCK)
WHERE fc.IsFixed = 0
ORDER BY fc.FailueDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (SetBalanceCompensation) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetRafCompensation | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetRafCompensation.sql*
