# Billing.PayoutProcess_UpdateStatus

> Updates the status of a payout process record with the provider's response, setting the final status, external reference codes, reason codes, and releasing the InProcess claim.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawToFundingID - identifies the payout record to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PayoutProcess_UpdateStatus` is the status-writing procedure for `Billing.PayoutProcess`. After the payout service submits a cashout request to the payment provider and receives a response, this procedure records the outcome: the provider's status, external reference codes, and reason code are written, the status change timestamp is set, and the InProcess claim flag is released.

This procedure is the lowest-level status update primitive for the payout pipeline. It is called either directly by the PayoutUser role (payout service) and SQL_SecurePay (SecurePay integration), or via the composite wrapper `Billing.PayoutProcess_Update` which also calls `Billing.WithdrawToFundingChangePaymentStatus` in the same transaction to keep `Billing.WithdrawToFunding` in sync.

The ISNULL pattern on ExtReferenceCode and ExtReferenceCode2 is non-destructive: if the caller passes NULL, the existing value is preserved. This allows partial updates where only the status changes without overwriting a previously-stored reference code.

Created January 2017 by Geri Reshef (ticket 43131). Ticket 51612 is also referenced in the code (Ran Ovadia, May 2018).

---

## 2. Business Logic

### 2.1 Non-Destructive Reference Code Update

**What**: Preserves existing ExtReferenceCode values when NULL is passed, preventing accidental overwrite.

**Columns Involved**: `ExtReferenceCode`, `ExtReferenceCode2`

**Rules**:
- `ExtReferenceCode = ISNULL(@ExtReferenceCode, ExtReferenceCode)`: if @ExtReferenceCode is NULL, the column retains its current value.
- `ExtReferenceCode2 = ISNULL(@ExtReferenceCode2, ExtReferenceCode2)`: same pattern for the secondary code.
- This allows the payout service to update status without always having both reference codes ready.

### 2.2 InProcess Release

**What**: Releases the worker's claim on the payout record as part of the status update.

**Columns Involved**: `InProcess`, `PayoutProcessStatusDate`

**Rules**:
- InProcess is always SET to 0 on this procedure - every call to UpdateStatus releases the claim.
- PayoutProcessStatusDate is set to GETUTCDATE() on every call, recording when the status changed.
- Callers should not need to separately reset InProcess after calling this procedure.

### 2.3 Provider Response Recording

**What**: Records the provider's outcome including reason codes for rejected/failed payouts.

**Columns Involved**: `CashoutStatusID`, `ProviderReasonCode`, `PayoutProcessReasonID`

**Rules**:
- CashoutStatusID is set to the final status value from the provider (e.g., 3=Processed, 8=RejectedByProvider, 13=Failed, 9=PendingByProvider, 10=SentToProvider).
- ProviderReasonCode: numeric code from the provider explaining rejection or failure. 0 or NULL for successful payouts.
- PayoutProcessReasonID: internal reason classification. 0 = no specific reason (default, 82% of rows). Non-zero values are used for specific categorized outcomes.
- The commented-out @ProviderResponseCode parameter suggests there was a plan for a separate response code that was not implemented.

**Diagram**:
```
Provider sends response:
  - Status: Processed / RejectedByProvider / Failed / ...
  - ExtReferenceCode: provider's transaction reference
  - ProviderReasonCode: why rejected (if applicable)
            |
  PayoutProcess_UpdateStatus(@WithdrawToFundingID, @CashoutStatusID,
      @PayoutProcessReasonID, @ExtReferenceCode, @ExtReferenceCode2, @ProviderReasonCode)
            |
  UPDATE Billing.PayoutProcess SET
    CashoutStatusID = @CashoutStatusID,
    ExtReferenceCode = ISNULL(@ExtReferenceCode, ExtReferenceCode),
    ExtReferenceCode2 = ISNULL(@ExtReferenceCode2, ExtReferenceCode2),
    ProviderReasonCode = @ProviderReasonCode,
    PayoutProcessStatusDate = GETUTCDATE(),
    PayoutProcessReasonID = @PayoutProcessReasonID,
    InProcess = 0
  WHERE WithdrawToFundingID = @WithdrawToFundingID
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawToFundingID | int | NO | - | CODE-BACKED | The payout record to update. Matched against `Billing.PayoutProcess.WithdrawToFundingID` (UNIQUE NC index - single seek). |
| 2 | @CashoutStatusID | int | NO | - | CODE-BACKED | The new status to set. Common values: 3=Processed (success), 8=RejectedByProvider, 13=Failed, 9=PendingByProvider, 10=SentToProvider. Set directly from the provider's response. See Dictionary.CashoutStatus for all values. |
| 3 | @PayoutProcessReasonID | int | NO | - | CODE-BACKED | Internal reason classification for this status update. 0=no specific reason (most common - 82% of PayoutProcess rows). Non-zero values indicate specific categorized outcomes (reason IDs 1-6 observed in live data, not in a discovered dictionary table). |
| 4 | @ExtReferenceCode | varchar(50) | YES | - | VERIFIED | Primary external provider reference code. ISNULL-protected: if NULL is passed, the existing value is preserved (`ISNULL(@ExtReferenceCode, ExtReferenceCode)`). Used for provider reconciliation and dispute resolution. |
| 5 | @ExtReferenceCode2 | varchar(50) | YES | - | VERIFIED | Secondary external provider reference code. ISNULL-protected same as @ExtReferenceCode. Some providers return two reference codes; others only use one. |
| 6 | @ProviderReasonCode | int | NO | - | CODE-BACKED | Numeric reason code from the payment provider explaining why a payout was rejected or failed. 0 for successful payouts. Stored as `Billing.PayoutProcess.ProviderReasonCode`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawToFundingID | [Billing.PayoutProcess](../Tables/Billing.PayoutProcess.md) | Write (UPDATE) | Updates 7 columns on the payout record: CashoutStatusID, ExtReferenceCode (ISNULL), ExtReferenceCode2 (ISNULL), ProviderReasonCode, PayoutProcessStatusDate, PayoutProcessReasonID, InProcess. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| [Billing.PayoutProcess_Update](Billing.PayoutProcess_Update.md) | @WithdrawToFundingID | EXEC (caller) | Composite wrapper that calls this plus WithdrawToFundingChangePaymentStatus in one transaction. |
| PayoutUser (db role) | - | EXEC | Payout service calls this directly on provider callback |
| SQL_SecurePay (db role) | - | EXEC | SecurePay integration calls this on payout response |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayoutProcess_UpdateStatus (procedure)
└── Billing.PayoutProcess (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.PayoutProcess](../Tables/Billing.PayoutProcess.md) | Table | UPDATE - writes status, reference codes, reason codes, InProcess=0, timestamp. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| [Billing.PayoutProcess_Update](Billing.PayoutProcess_Update.md) | Stored Procedure | Calls this as part of the atomic two-table update wrapper (Batch 28, #25). |
| PayoutUser / SQL_SecurePay | Application | Direct callers from payout and SecurePay services. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

The UPDATE targets `WHERE WithdrawToFundingID = @WithdrawToFundingID` - this uses the UNIQUE NC index `IX_BillingPayoutProcess_WithdrawToFundingID` on PayoutProcess for a single-seek update. No full scan occurs.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Record a successful payout from provider

```sql
EXEC Billing.PayoutProcess_UpdateStatus
    @WithdrawToFundingID  = 12345678,
    @CashoutStatusID      = 3,   -- Processed
    @PayoutProcessReasonID = 0,
    @ExtReferenceCode     = 'PROVREF-SUCCESS123',
    @ExtReferenceCode2    = NULL,
    @ProviderReasonCode   = 0;
```

### 8.2 Record a provider rejection

```sql
EXEC Billing.PayoutProcess_UpdateStatus
    @WithdrawToFundingID  = 12345678,
    @CashoutStatusID      = 8,   -- RejectedByProvider
    @PayoutProcessReasonID = 6,
    @ExtReferenceCode     = 'PROVREF-REJECT456',
    @ExtReferenceCode2    = 'PROVREF-SUB789',
    @ProviderReasonCode   = 4501;  -- provider-specific rejection code
```

### 8.3 Check recent status updates to PayoutProcess

```sql
SELECT
    pp.ProcessID,
    pp.WithdrawToFundingID,
    pp.CashoutStatusID,
    cs.Name AS StatusName,
    pp.PayoutProcessStatusDate,
    pp.ProviderReasonCode,
    pp.PayoutProcessReasonID,
    pp.ExtReferenceCode
FROM Billing.PayoutProcess pp WITH (NOLOCK)
JOIN Dictionary.CashoutStatus cs WITH (NOLOCK) ON cs.CashoutStatusID = pp.CashoutStatusID
WHERE pp.PayoutProcessStatusDate >= DATEADD(HOUR, -1, GETUTCDATE())
ORDER BY pp.PayoutProcessStatusDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 SQL caller (PayoutProcess_Update) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PayoutProcess_UpdateStatus | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PayoutProcess_UpdateStatus.sql*
