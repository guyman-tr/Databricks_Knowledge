# BackOffice.CustomerIsPhoneVerified_JunkNoga240325

> Checks whether a customer has completed phone verification by querying Customer.PhoneVerificationDetails for verified status records. Returns result via OUTPUT parameter. Marked JUNK by Noga (March 2025).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure determines whether a customer has verified their phone number by checking `Customer.PhoneVerificationDetails` for records with `PhoneVerifiedID IN (1, 2)`.

Phone verification is a key step in the customer onboarding and KYC workflow. Customers who have verified their phone number have a higher trust level and may access certain trading features or bypass additional identity checks. BackOffice agents and automated processes query this SP to branch logic based on phone verification state.

`PhoneVerifiedID IN (1, 2)` captures both verification methods: value 1 and 2 represent the verified states for phone (likely 1=verified via SMS code, 2=verified via voice call, or both being "active/confirmed" states as opposed to pending/expired states in the PhoneVerificationDetails lookup).

The `_JunkNoga240325` suffix indicates this procedure was marked for deprecation by Noga in March 2025. The modern pipeline likely queries `Customer.PhoneVerificationDetails` directly or uses a different SP.

---

## 2. Business Logic

### 2.1 Phone Verification Check via EXISTS

**What**: Returns 1 if any active verified record exists for the customer, 0 otherwise.

**Rules**:
- IF EXISTS (SELECT 1 FROM Customer.PhoneVerificationDetails WITH(NOLOCK) WHERE CID=@CID AND PhoneVerifiedID IN (1,2)): @IsVerified = 1
- ELSE: @IsVerified = 0
- WITH(NOLOCK): non-blocking read for status check
- No exception raised if CID not found - returns @IsVerified=0 (treated as not verified)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Queried against Customer.PhoneVerificationDetails. If no rows exist for this CID: @IsVerified=0. |

**Output Parameters:**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 2 | @IsVerified | BIT OUT | NO | CODE-BACKED | Phone verification result. 1=customer has a PhoneVerifiedID IN (1,2) record (phone is verified). 0=no such record found (not verified or CID not found). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.PhoneVerificationDetails | SELECT (NOLOCK) | Checks for verified phone records (PhoneVerifiedID IN (1,2)) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice KYC and onboarding workflows | External | Direct call | Check phone verification state before gating features |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerIsPhoneVerified_JunkNoga240325 (procedure)
|- Customer.PhoneVerificationDetails (table) [SELECT NOLOCK: phone verification check]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.PhoneVerificationDetails | Table | SELECT: EXISTS check for PhoneVerifiedID IN (1,2) for the given CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice onboarding workflows | External | Phone verification gate |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PhoneVerifiedID IN (1,2) | Business rule | Both value 1 and 2 count as "verified" - captures all verified states |
| WITH(NOLOCK) | Concurrency | Dirty reads allowed - acceptable for status check |
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| JUNK designation | Lifecycle | Marked for deprecation by Noga March 2025 |
| @VerifiedID unused | Code quality | DECLARE @VerifiedID INT present but never assigned or used |

---

## 8. Sample Queries

### 8.1 Check if a customer has verified their phone

```sql
DECLARE @IsVerified BIT;
EXEC BackOffice.CustomerIsPhoneVerified_JunkNoga240325
    @CID = 12345,
    @IsVerified = @IsVerified OUTPUT;
SELECT @IsVerified AS IsPhoneVerified;
-- 1 = verified, 0 = not verified or not found
```

### 8.2 Direct query equivalent

```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM Customer.PhoneVerificationDetails WITH(NOLOCK)
    WHERE CID = 12345 AND PhoneVerifiedID IN (1,2)
) THEN 1 ELSE 0 END AS IsPhoneVerified;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.CustomerIsPhoneVerified_JunkNoga240325 | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerIsPhoneVerified_JunkNoga240325.sql*
