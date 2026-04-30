# Billing.BlockAllPaymentMethodsForCID

> Risk Rule Engine procedure (Phase 1) that blocks ALL funding instruments (payment methods) associated with a customer by setting IsBlocked=1 on every Billing.Funding record linked to any of the customer's deposits.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No return value; side effect is IsBlocked=1 on all CID-linked Billing.Funding records |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.BlockAllPaymentMethodsForCID` is a risk enforcement procedure that blocks all payment methods (funding instruments) linked to a specific customer. It is part of the "Risk Rule Engine Phase 1" - an automated risk response system that can freeze a customer's payment capabilities.

When a customer is flagged for suspicious activity, the risk engine can call this procedure to prevent any further deposits using any of the payment methods they have previously used. The block is applied to the `Billing.Funding` table entry (the shared payment instrument record), meaning the block affects the instrument globally - not just this customer's access to it.

Unlike `Billing.BlockAllRelatedMeansOfPayment` (which supports both block and unblock, tracks manager, and also updates CustomerToFunding), this procedure is a simpler hard-block: it only sets IsBlocked=1 and does not record who performed the block or why.

---

## 2. Business Logic

### 2.1 Block All Deposit-Linked Funding Instruments

**What**: Sets IsBlocked=1 on all Billing.Funding records that are linked to any of the customer's deposits.

**Parameters/Columns Involved**: `@CID`, `Billing.Funding.IsBlocked`, `Billing.Deposit.CID`

**Rules**:
- `UPDATE Billing.Funding SET IsBlocked = 1 FROM Billing.Funding BFUN JOIN Billing.Deposit BDEP ON BFUN.FundingID = BDEP.FundingID WHERE BDEP.CID = @CID`.
- All FundingIDs that appear in any Billing.Deposit record for @CID are blocked, regardless of FundingType.
- No funding type exclusions (unlike BlockAllRelatedMeansOfPayment which excludes FundingTypeID=17 and IsSingleFunding types).
- No unblock capability - this procedure only sets IsBlocked=1. Use BlockAllRelatedMeansOfPayment @IsBlocked=0 to unblock.
- No manager/audit metadata recorded (ManagerID, BlockedAt, BlockedDescription are not updated).

### 2.2 Transaction and Error Handling

**Rules**:
- `BEGIN TRAN / COMMIT TRAN` wraps the UPDATE.
- `CATCH`: if `XACT_STATE() <> 0` -> `ROLLBACK TRAN` (handles both active and doomed transactions).
- Error re-raised as RAISERROR with ErrorNumber, error_procedure(), error_line(), error_message() context.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | VERIFIED | Customer ID whose payment methods are to be blocked. All Billing.Funding records linked to this customer's deposits will have IsBlocked set to 1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.Deposit | READER (JOIN) | Identifies all FundingIDs linked to this customer's deposits. |
| BDEP.FundingID | Billing.Funding | WRITER (UPDATE) | Sets IsBlocked=1 on all matching funding instruments. |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called from the Risk Rule Engine (Phase 1) automation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BlockAllPaymentMethodsForCID (procedure)
|- Billing.Deposit (table)   [JOIN - find FundingIDs for the customer]
+- Billing.Funding (table)   [UPDATE - set IsBlocked=1]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | JOIN to identify all FundingIDs used by @CID in deposits |
| Billing.Funding | Table | UPDATE IsBlocked=1 on all matched instruments |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files. Called from Risk Rule Engine.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **No audit trail**: Unlike `Billing.BlockAllRelatedMeansOfPayment`, this procedure does not record ManagerID, BlockedAt, or BlockedDescription. Blocked instruments have no metadata about when or why they were blocked.
- **Global instrument block**: Billing.Funding records can be shared across customers (e.g., same card used by family members). Setting IsBlocked=1 on the FundingID blocks the instrument globally, not just for @CID.
- **No funding type filter**: All instrument types are blocked, including those excluded by BlockAllRelatedMeansOfPayment (FundingTypeID=17, IsSingleFunding types).

---

## 8. Sample Queries

### 8.1 Block all payment methods for a customer
```sql
EXEC Billing.BlockAllPaymentMethodsForCID @CID = 12345;
```

### 8.2 Verify the block was applied
```sql
SELECT  BF.FundingID,
        BF.FundingTypeID,
        BF.IsBlocked,
        BF.BlockedAt,
        BF.BlockedDescription
FROM    Billing.Funding BF WITH (NOLOCK)
JOIN    Billing.Deposit BD WITH (NOLOCK) ON BD.FundingID = BF.FundingID
WHERE   BD.CID = 12345;
-- IsBlocked = 1, BlockedAt = NULL (no timestamp recorded by this proc)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.BlockAllPaymentMethodsForCID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.BlockAllPaymentMethodsForCID.sql*
