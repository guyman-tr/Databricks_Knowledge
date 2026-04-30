# BackOffice.SetFundingAsVerified

> Marks a specific customer-funding link as verified (IsVerified=1) in Billing.CustomerToFunding, confirming that the BackOffice team has validated this customer's ownership of the payment method.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (@FundingID, @CID) - the customer-funding link to verify |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.SetFundingAsVerified is used by BackOffice compliance agents to flag a customer's payment instrument as verified. "Verified" in this context means the BackOffice team has confirmed that the customer is the legitimate owner of the payment method (credit card, bank account, etc.) - typically as part of a funding verification workflow before approving a withdrawal.

The procedure unconditionally sets IsVerified=1 for the specific (CID, FundingID) pair. It is a "mark as verified" action only - it does not conditionally check the current state or perform any other updates. The narrower sibling procedure, BackOffice.SetFundingVerification, accepts an @IsVerified parameter and can both set and clear verification status.

This procedure is called when agents confirm funding ownership - for example after reviewing a bank statement scan, matching card details, or completing a call verification. Without this step, certain withdrawal routes may not be available to the customer.

---

## 2. Business Logic

### 2.1 Unconditional Verification Stamp

**What**: Always sets IsVerified=1 regardless of current state.

**Columns/Parameters Involved**: `@FundingID`, `@CID`

**Rules**:
- UPDATE Billing.CustomerToFunding SET IsVerified=1 WHERE CID=@CID AND FundingID=@FundingID
- No return value - procedure has no RETURN statement (implicit NULL/0)
- No transaction, no error handling - SQL engine default behavior applies
- If (CID, FundingID) combination not found: 0 rows affected, no error raised
- Contrast with BackOffice.SetFundingVerification which accepts @IsVerified parameter (can set to 0 or 1)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingID | INTEGER | NO | - | VERIFIED | The payment instrument to mark as verified. Part of the composite PK (CID, FundingID) in Billing.CustomerToFunding. Must be a valid FundingID linked to the specified @CID. |
| 2 | @CID | INTEGER | NO | - | VERIFIED | The customer account. Together with @FundingID, uniquely identifies the customer-funding link in Billing.CustomerToFunding. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (@CID, @FundingID) | Billing.CustomerToFunding | MODIFIER (UPDATE IsVerified=1) | Sets the verification flag for this customer's payment method |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice Funding Verification Workflow | - | Caller | Called by agents when confirming a customer's ownership of a payment instrument |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.SetFundingAsVerified (procedure)
└── Billing.CustomerToFunding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | UPDATE: SET IsVerified=1 WHERE CID=@CID AND FundingID=@FundingID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice Funding Verification | External | Marks payment methods as verified after agent review |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Mark a customer's funding as verified
```sql
EXEC BackOffice.SetFundingAsVerified
    @FundingID = 7654321,
    @CID       = 12345678
```

### 8.2 Check current verification status of a funding link
```sql
SELECT CID, FundingID, IsVerified
FROM Billing.CustomerToFunding WITH (NOLOCK)
WHERE CID = 12345678
  AND FundingID = 7654321
```

### 8.3 Find all verified funding links for a customer
```sql
SELECT
    ctf.FundingID,
    ctf.IsVerified,
    ctf.CreationDate,
    ctf.LastUsedDate
FROM Billing.CustomerToFunding ctf WITH (NOLOCK)
WHERE ctf.CID = 12345678
  AND ctf.IsVerified = 1
ORDER BY ctf.LastUsedDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.SetFundingAsVerified | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.SetFundingAsVerified.sql*
