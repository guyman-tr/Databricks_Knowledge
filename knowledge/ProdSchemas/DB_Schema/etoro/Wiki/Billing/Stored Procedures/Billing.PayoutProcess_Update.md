# Billing.PayoutProcess_Update

> Atomic two-table payout status update: wraps PayoutProcess_UpdateStatus and WithdrawToFundingChangePaymentStatus in a single transaction to keep Billing.PayoutProcess and Billing.WithdrawToFunding synchronized on every provider callback.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawToFundingID - identifies the payout record to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PayoutProcess_Update` is the composite payout status update wrapper for the cashout pipeline. When a payment provider callback arrives reporting the outcome of a submitted cashout, the payout service or SecurePay integration calls this procedure to record the result atomically across two tables:

1. **`Billing.PayoutProcess`** (via `Billing.PayoutProcess_UpdateStatus`): records the provider's status, external reference codes, reason code, and releases the InProcess claim.
2. **`Billing.WithdrawToFunding`** (via `Billing.WithdrawToFundingChangePaymentStatus`): propagates the new status to the withdrawal-funding leg, keeping the user-visible cashout status consistent.

These two writes are wrapped in a single `BEGIN TRAN / COMMIT TRAN`, guaranteeing that both tables are always in sync. If one write fails, both are rolled back. This prevents the data integrity failure where PayoutProcess shows a final status but WithdrawToFunding still shows an in-flight status.

The extra parameters `@ManagerID`, `@Remark`, `@ProtocolMIDSettingsID`, and `@MerchantAccountID` are passed through to `WithdrawToFundingChangePaymentStatus` to support both automated (system) and manual (manager-initiated) status changes and to carry the payment provider's merchant account context.

Callers: `SQL_SecurePay` and `PayoutUser` database roles.

---

## 2. Business Logic

### 2.1 Atomic Dual-Table Status Update

**What**: Ensures PayoutProcess and WithdrawToFunding are always updated together.

**Columns Involved**: `Billing.PayoutProcess.*` (via UpdateStatus), `Billing.WithdrawToFunding.CashoutStatusID` (via ChangePaymentStatus)

**Rules**:
- BEGIN TRAN wraps both EXECs.
- EXEC Billing.PayoutProcess_UpdateStatus: writes CashoutStatusID, ExtReferenceCode (ISNULL), ExtReferenceCode2 (ISNULL), ProviderReasonCode, PayoutProcessStatusDate=GETUTCDATE(), PayoutProcessReasonID, InProcess=0.
- EXEC Billing.WithdrawToFundingChangePaymentStatus: propagates the new status to Billing.WithdrawToFunding, records ManagerID (actor), Remark, ProtocolMIDSettingsID, MerchantAccountID.
- COMMIT TRAN on success; ROLLBACK on error.
- If both inner procedures succeed, the caller sees a committed state. If either fails, both revert.

### 2.2 Actor Classification (Manager vs System)

**What**: Distinguishes automated provider callbacks from human-initiated status changes.

**Parameters Involved**: `@ManagerID`

**Rules**:
- @ManagerID = 0: automated system update (provider callback processed by payout service).
- @ManagerID > 0: human back-office manager triggered the status update.
- Passed through to WithdrawToFundingChangePaymentStatus for audit trail.

### 2.3 Merchant Account Context

**What**: Carries the MID (Merchant ID) and protocol context for the payment.

**Parameters Involved**: `@ProtocolMIDSettingsID`, `@MerchantAccountID`

**Rules**:
- Both default to 0 (not applicable / unknown).
- When non-zero, they identify which merchant account processed the payment.
- Passed to WithdrawToFundingChangePaymentStatus for reconciliation.

**Diagram**:
```
Provider callback: status + ref codes + reason codes
  |
EXEC Billing.PayoutProcess_Update(
    @WithdrawToFundingID, @CashoutStatusID, @PayoutProcessReasonID,
    @ExtReferenceCode, @ExtReferenceCode2, @ProviderReasonCode,
    @ManagerID=0, @Remark=NULL,
    @ProtocolMIDSettingsID=0, @MerchantAccountID=0)
  |
BEGIN TRAN
  |
  EXEC PayoutProcess_UpdateStatus(
      @WithdrawToFundingID, @CashoutStatusID, @PayoutProcessReasonID,
      @ExtReferenceCode, @ExtReferenceCode2, @ProviderReasonCode)
    -> UPDATE Billing.PayoutProcess:
       CashoutStatusID, ExtReferenceCode (ISNULL), ExtReferenceCode2 (ISNULL),
       ProviderReasonCode, PayoutProcessStatusDate=NOW, PayoutProcessReasonID, InProcess=0
  |
  EXEC WithdrawToFundingChangePaymentStatus(
      @WithdrawToFundingID, @CashoutStatusID, @ManagerID, @Remark,
      @ProtocolMIDSettingsID, @MerchantAccountID)
    -> UPDATE Billing.WithdrawToFunding: CashoutStatusID + audit fields
  |
COMMIT TRAN
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawToFundingID | int | NO | - | CODE-BACKED | The payout record to update. Passed to both inner procedures. Identifies the specific cashout leg being finalized. |
| 2 | @CashoutStatusID | int | NO | - | CODE-BACKED | The new status from the payment provider. Common values: 3=Processed, 8=RejectedByProvider, 9=PendingByProvider, 10=SentToProvider, 13=Failed. Passed to both PayoutProcess_UpdateStatus and WithdrawToFundingChangePaymentStatus. |
| 3 | @PayoutProcessReasonID | int | NO | - | CODE-BACKED | Internal reason classification. 0=no specific reason (most common). Passed to PayoutProcess_UpdateStatus. See `Billing.PayoutProcess_UpdateStatus` Section 4 for details. |
| 4 | @ExtReferenceCode | varchar(50) | YES | - | CODE-BACKED | Primary external provider reference code. ISNULL-protected in PayoutProcess_UpdateStatus: NULL preserves existing value. |
| 5 | @ExtReferenceCode2 | varchar(50) | YES | - | CODE-BACKED | Secondary external provider reference code. ISNULL-protected in PayoutProcess_UpdateStatus: NULL preserves existing value. |
| 6 | @ProviderReasonCode | int | NO | - | CODE-BACKED | Numeric reason code from the provider (why rejected/failed). 0 for success. Passed to PayoutProcess_UpdateStatus. |
| 7 | @ManagerID | int | NO | 0 | VERIFIED | Actor performing the update. 0=automated system (provider callback), >0=back-office manager. Passed to WithdrawToFundingChangePaymentStatus for audit. |
| 8 | @Remark | varchar(255) | YES | NULL | VERIFIED | Optional free-text remark for this status update. Passed to WithdrawToFundingChangePaymentStatus. Used when a manager manually changes the status. |
| 9 | @ProtocolMIDSettingsID | int | NO | 0 | CODE-BACKED | Merchant ID protocol settings identifier. 0=not applicable. Passed to WithdrawToFundingChangePaymentStatus for payment provider routing context. |
| 10 | @MerchantAccountID | int | NO | 0 | CODE-BACKED | Merchant account identifier. 0=not applicable. Passed to WithdrawToFundingChangePaymentStatus. Non-zero when a specific merchant account processed the payment. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawToFundingID + status fields | [Billing.PayoutProcess_UpdateStatus](Billing.PayoutProcess_UpdateStatus.md) | EXEC (callee) | Updates PayoutProcess: status, ref codes, reason, InProcess=0. |
| @WithdrawToFundingID + status + manager | Billing.WithdrawToFundingChangePaymentStatus | EXEC (callee) | Propagates status to WithdrawToFunding + audit fields. Pending documentation. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_SecurePay (db role) | - | EXEC | SecurePay integration calls this on provider callback to record the outcome. |
| PayoutUser (db role) | - | EXEC | Payout service calls this on provider response to update both tables atomically. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayoutProcess_Update (procedure)
├── Billing.PayoutProcess_UpdateStatus (procedure)
|   └── Billing.PayoutProcess (table)
└── Billing.WithdrawToFundingChangePaymentStatus (procedure)
    └── Billing.WithdrawToFunding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.PayoutProcess_UpdateStatus](Billing.PayoutProcess_UpdateStatus.md) | Stored Procedure | EXEC - updates PayoutProcess with provider response and releases InProcess. Documented Batch 28, #14. |
| Billing.WithdrawToFundingChangePaymentStatus | Stored Procedure | EXEC - propagates status to WithdrawToFunding with manager/remark/merchant context. Pending documentation (future batch). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_SecurePay application role | Application | Called on SecurePay provider callback response. |
| PayoutUser application role | Application | Called on payout service provider callback response. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

The atomic transaction guarantees the two-table update is all-or-nothing. Each inner procedure uses its own index coverage (PayoutProcess uses `IX_BillingPayoutProcess_WithdrawToFundingID`; WithdrawToFunding uses its PK).

**Why this wrapper exists**: Callers could call `PayoutProcess_UpdateStatus` and `WithdrawToFundingChangePaymentStatus` individually, but doing so outside a transaction risks a partial update if the second call fails or times out. This wrapper enforces the transactional guarantee.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Record a successful payout from provider (automated)

```sql
EXEC Billing.PayoutProcess_Update
    @WithdrawToFundingID  = 12345678,
    @CashoutStatusID      = 3,   -- Processed
    @PayoutProcessReasonID = 0,
    @ExtReferenceCode     = 'PROVREF-SUCCESS123',
    @ExtReferenceCode2    = NULL,
    @ProviderReasonCode   = 0,
    @ManagerID            = 0,
    @Remark               = NULL;
```

### 8.2 Record a rejection from provider

```sql
EXEC Billing.PayoutProcess_Update
    @WithdrawToFundingID  = 12345678,
    @CashoutStatusID      = 8,   -- RejectedByProvider
    @PayoutProcessReasonID = 6,
    @ExtReferenceCode     = 'PROVREF-REJECT456',
    @ExtReferenceCode2    = NULL,
    @ProviderReasonCode   = 4501,
    @ManagerID            = 0,
    @Remark               = NULL;
```

### 8.3 Manual manager override

```sql
EXEC Billing.PayoutProcess_Update
    @WithdrawToFundingID  = 12345678,
    @CashoutStatusID      = 3,   -- Processed
    @PayoutProcessReasonID = 0,
    @ExtReferenceCode     = 'MANUAL-REF001',
    @ExtReferenceCode2    = NULL,
    @ProviderReasonCode   = 0,
    @ManagerID            = 999,   -- back-office manager ID
    @Remark               = 'Manual approval after provider confirmation';
```

### 8.4 Verify both tables were updated atomically

```sql
-- Check PayoutProcess
SELECT pp.WithdrawToFundingID, pp.CashoutStatusID, pp.InProcess, pp.PayoutProcessStatusDate
FROM Billing.PayoutProcess pp WITH (NOLOCK)
WHERE pp.WithdrawToFundingID = 12345678;

-- Check WithdrawToFunding
SELECT wtf.ID, wtf.CashoutStatusID, wtf.ModificationDate
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
WHERE wtf.ID = 12345678;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 callees (PayoutProcess_UpdateStatus, WithdrawToFundingChangePaymentStatus) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PayoutProcess_Update | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PayoutProcess_Update.sql*
