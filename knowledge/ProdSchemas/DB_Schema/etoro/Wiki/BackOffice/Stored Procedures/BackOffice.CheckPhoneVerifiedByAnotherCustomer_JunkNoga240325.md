# BackOffice.CheckPhoneVerifiedByAnotherCustomer_JunkNoga240325

> Checks whether a phone number has been verified by a different customer account; returns the username of the most recent other verified owner of that phone number via OUTPUT parameter.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID / @Phone |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure detects phone number sharing across customer accounts - a potential fraud signal. When a BackOffice agent or compliance process needs to check whether a specific phone number is already verified on a DIFFERENT customer account, this procedure returns the username of the most recently registered customer who has that phone verified.

The `_JunkNoga240325` suffix indicates this is a deprecated or temporary procedure created by Noga around March 2025. Despite the "Junk" designation, it contains valid business logic for phone verification cross-account checking.

The core use case is KYC/fraud detection: if customer A (CID=@CID) provides a phone number that is already verified on customer B's account, this is a strong signal of account duplication, family sharing, or potentially fraudulent account creation. The OUTPUT parameter @VerifiedBy returns customer B's username; if NULL, the phone is not verified on any other account.

Results are restricted to `PhoneVerifiedID > 0` - only records with an actual phone verification event (not just submissions). The `ORDER BY Registered DESC` returns the most recently registered customer who verified that phone, relevant when multiple accounts share a number.

---

## 2. Business Logic

### 2.1 Cross-Account Phone Verification Check

**What**: Finds if any other customer (not @CID) has verified the same phone number.

**Columns/Parameters Involved**: `@Phone`, `@CID`, `Customer.PhoneVerificationDetails.PhoneNumber`, `Customer.PhoneVerificationDetails.PhoneVerifiedID`, `Customer.Customer.UserName`

**Rules**:
- Searches `Customer.PhoneVerificationDetails` for rows where PhoneNumber = @Phone
- Excludes the requesting customer's own records: `cp.CID != @CID`
- Only considers verified phones: `cp.PhoneVerifiedID > 0` (PhoneVerifiedID=0 or NULL means not yet verified)
- TOP 1 ORDER BY `Registered DESC` - returns the most recently registered customer who verified this phone
- If no other verified customer exists: @VerifiedBy remains NULL (unmodified from caller's default)
- Result returned via OUTPUT parameter - no result set

**Diagram**:
```
Customer.PhoneVerificationDetails (WHERE PhoneNumber=@Phone AND CID!=@CID AND PhoneVerifiedID>0)
    JOIN Customer.Customer (to get UserName)
    ORDER BY Registered DESC
    TOP 1 -> @VerifiedBy = UserName of other customer who verified this phone
    No rows -> @VerifiedBy = NULL (phone unique to @CID or unverified elsewhere)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | The requesting customer's ID. Used to exclude the customer's own phone verification records from the search (cp.CID != @CID). |
| 2 | @Phone | VARCHAR(24) | NO | - | CODE-BACKED | The phone number to check for cross-account verification. Compared against Customer.PhoneVerificationDetails.PhoneNumber. |

**Output Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | @VerifiedBy | VARCHAR(20) | YES | NULL | CODE-BACKED | OUTPUT. The UserName of the most recently registered customer (other than @CID) who has verified this phone number. NULL if no other verified account holds this phone. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Phone / @CID | Customer.PhoneVerificationDetails | Lookup (SELECT) | Searches for verified phone records belonging to other customers (cross-schema) |
| cp.CID | Customer.Customer | Lookup (JOIN) | Retrieves the UserName of the other customer who verified the phone |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found. Called from BackOffice fraud detection or KYC review workflows.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CheckPhoneVerifiedByAnotherCustomer_JunkNoga240325 (procedure)
|- Customer.PhoneVerificationDetails (table) [SELECT - phone verification records, cross-schema]
+-- Customer.Customer (table) [JOIN - retrieve UserName of other account, cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.PhoneVerificationDetails | Table | SELECT WHERE PhoneNumber=@Phone AND CID!=@CID AND PhoneVerifiedID>0 (cross-schema) |
| Customer.Customer | Table | INNER JOIN on CID to retrieve UserName (cross-schema) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice fraud/KYC review workflow | External | Checks if a phone number is verified on another account during compliance review |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PhoneVerifiedID > 0 | Application | Only counts verified phone records - unverified submissions (PhoneVerifiedID=0/NULL) are excluded |
| CID exclusion | Application | cp.CID != @CID - the customer's own verification records are excluded from the cross-account check |
| TOP 1 ORDER BY Registered DESC | Design | When multiple accounts share a verified phone, returns the most recently registered one |
| Junk designation | Design | _JunkNoga240325 suffix indicates temporary/deprecated status - use with caution; may be removed |
| OUTPUT default | Application | @VerifiedBy is only set if a match is found; callers must initialize to NULL before calling |

---

## 8. Sample Queries

### 8.1 Check if a phone is verified by another customer

```sql
DECLARE @VerifiedBy VARCHAR(20) = NULL
EXEC BackOffice.CheckPhoneVerifiedByAnotherCustomer_JunkNoga240325
    @CID = 12345,
    @Phone = '+1234567890',
    @VerifiedBy = @VerifiedBy OUTPUT
IF @VerifiedBy IS NOT NULL
    PRINT 'Phone verified by: ' + @VerifiedBy  -- fraud signal
ELSE
    PRINT 'Phone is unique to this customer'
```

### 8.2 Check phone verification status directly

```sql
SELECT cpd.CID, cc.UserName, cpd.PhoneNumber, cpd.PhoneVerifiedID, cc.Registered
FROM Customer.PhoneVerificationDetails cpd WITH (NOLOCK)
INNER JOIN Customer.Customer cc WITH (NOLOCK) ON cc.CID = cpd.CID
WHERE cpd.PhoneNumber = '+1234567890'
    AND cpd.CID != 12345
    AND cpd.PhoneVerifiedID > 0
ORDER BY cc.Registered DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.9/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CheckPhoneVerifiedByAnotherCustomer_JunkNoga240325 | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CheckPhoneVerifiedByAnotherCustomer_JunkNoga240325.sql*
