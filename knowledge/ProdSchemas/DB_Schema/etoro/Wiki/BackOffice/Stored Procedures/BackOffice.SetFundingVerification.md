# BackOffice.SetFundingVerification

> Sets or clears the verification flag on a specific customer-funding link in Billing.CustomerToFunding, allowing BackOffice agents to both approve and revoke payment method verification.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (@FundingID, @CID) - the customer-funding link to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.SetFundingVerification is the parameterized version of the funding verification write, allowing agents to both set (IsVerified=1) and clear (IsVerified=0) a customer's payment method verification status. While BackOffice.SetFundingAsVerified can only mark verified, this procedure supports both directions - enabling scenarios where a previously verified payment method needs to be de-verified (e.g., after fraud detection, disputed ownership, or compliance review triggers a re-verification requirement).

The procedure is typically used in BackOffice payment verification workflows where agents review and approve or reject funding instruments. When a customer's identity changes, ownership is disputed, or a new compliance check is triggered, agents may need to clear previously granted verification before re-processing.

---

## 2. Business Logic

### 2.1 Bidirectional Verification Toggle

**What**: Can both grant and revoke verification for a customer-funding link.

**Columns/Parameters Involved**: `@FundingID`, `@CID`, `@IsVerified`

**Rules**:
- UPDATE Billing.CustomerToFunding SET IsVerified=@IsVerified WHERE CID=@CID AND FundingID=@FundingID
- @IsVerified=1: grant verification (customer confirmed as legitimate owner)
- @IsVerified=0: revoke verification (re-verification required)
- No return value, no transaction wrapper, no error handling - SQL engine default behavior
- If (CID, FundingID) not found: 0 rows affected, no error raised
- Compare with BackOffice.SetFundingAsVerified which hard-codes IsVerified=1

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingID | INTEGER | NO | - | VERIFIED | The payment instrument to update. Part of the composite PK (CID, FundingID) in Billing.CustomerToFunding. |
| 2 | @CID | INTEGER | NO | - | VERIFIED | The customer account. Together with @FundingID, uniquely identifies the customer-funding link. |
| 3 | @IsVerified | BIT | NO | - | VERIFIED | Desired verification state: 1=verified (BackOffice confirmed ownership), 0=not verified (de-verified or new, pending review). Written directly to Billing.CustomerToFunding.IsVerified. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (@CID, @FundingID) | Billing.CustomerToFunding | MODIFIER (UPDATE IsVerified) | Sets or clears the verification flag for this customer's payment method |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice Funding Verification Workflow | - | Caller | Called when agents grant or revoke funding verification status |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.SetFundingVerification (procedure)
└── Billing.CustomerToFunding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | UPDATE: SET IsVerified=@IsVerified WHERE CID=@CID AND FundingID=@FundingID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice Funding Verification | External | Grants or revokes payment method verification for customers |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Verify a customer's funding method
```sql
EXEC BackOffice.SetFundingVerification
    @FundingID  = 7654321,
    @CID        = 12345678,
    @IsVerified = 1
```

### 8.2 De-verify (revoke) a funding method
```sql
EXEC BackOffice.SetFundingVerification
    @FundingID  = 7654321,
    @CID        = 12345678,
    @IsVerified = 0
```

### 8.3 Find unverified funding links requiring review
```sql
SELECT
    ctf.CID,
    ctf.FundingID,
    ctf.CreationDate,
    ctf.LastUsedDate,
    ctf.IsVerified
FROM Billing.CustomerToFunding ctf WITH (NOLOCK)
WHERE ctf.IsVerified = 0
  AND ctf.CustomerFundingStatusID = 1  -- Active
ORDER BY ctf.CreationDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9.5/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.SetFundingVerification | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.SetFundingVerification.sql*
