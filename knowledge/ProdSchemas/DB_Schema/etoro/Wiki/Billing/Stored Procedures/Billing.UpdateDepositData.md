# Billing.UpdateDepositData

> Patch-updates selected fields on a Billing.Deposit record using the ISNULL pattern - only provided (non-NULL) parameters overwrite the existing value, making it safe for partial updates by the deposit service.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositID - targets Billing.Deposit |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpdateDepositData` is the deposit service's general-purpose patch-update procedure for supplementary deposit fields that may not be available at the time of initial deposit creation. Payment processors return transaction IDs asynchronously, clearing houses provide settlement dates after processing, and operations managers may need to correct or enrich deposit records - all of these are handled through this procedure.

The ISNULL pattern (`SET column = ISNULL(@param, column)`) means the caller only needs to supply the fields it wants to change; all other fields retain their current values. This is a safe multi-field UPDATE with no risk of accidentally NULLing out fields that were intentionally set.

The procedure has been incrementally extended:
- **Oct 2022** (Elrom B.): Added `@FundingID` to support updating the payment instrument reference
- **Oct 2025** (Elrom B.): Added `@StatusID` to allow updating `PaymentStatusID` directly
- **Jan 2026** (Denys O.): Added `@FunnelID` for marketing funnel updates

Called exclusively by the DepositUser role (the Deposit microservice).

---

## 2. Business Logic

### 2.1 ISNULL Patch-Update Pattern

**What**: Only parameters with non-NULL values are applied. Parameters left as NULL (the default for all optional params) leave the corresponding column unchanged - safe for any caller that only knows a subset of fields.

**Columns/Parameters Involved**: All parameters mapped to their target columns in `Billing.Deposit`

**Rules**:
- Single UPDATE statement with no transaction guard or concurrency check
- The WHERE clause is only `DepositID = @DepositID` - no state validation before update
- If `@DepositID` does not exist, the UPDATE silently affects 0 rows (no error raised)
- For columns the caller wants to explicitly NULL out (e.g., clear ExTransactionID), the ISNULL pattern prevents this - it can only set values, not clear them
- `@Approved` (BIT) is a legacy field largely superseded by `PaymentStatusID`; setting it has limited effect on modern workflows
- `@StatusID` -> `PaymentStatusID`: this is a direct status override bypassing the `Dictionary.PaymentStatusStateMachine` validation used by `Billing.DepositProcess`. Caller is responsible for transition validity

**Column mapping**:

| Parameter | Target Column | Notes |
|-----------|--------------|-------|
| @ExTransactionID | ExTransactionID | External provider transaction ID. Indexed (BDEP_ExTransactionID) |
| @RefundVerificationCode | RefundVerificationCode | Provider-side refund confirmation code |
| @ProcessorValueDate | ProcessorValueDate | Processor credit date; mandatory for wire/ACH deposits |
| @ClearingHouseEffectiveDate | ClearingHouseEffectiveDate | Clearing house settlement date (wires/ACH) |
| @ManagerID | ManagerID | Operations manager; 0=automated, non-zero=human operator (FK BackOffice.Manager) |
| @Approved | Approved | Legacy BIT flag; superseded by PaymentStatusID=2 |
| @Commission | Commission | Deposit commission charged; defaults to 0 |
| @FundingID | FundingID | Payment instrument (FK Billing.Funding); added Oct 2022 |
| @StatusID | PaymentStatusID | Current payment state (FK Dictionary.PaymentStatus); added Oct 2025 - bypasses state machine validation |
| @FunnelID | FunnelID | Marketing funnel (FK Dictionary.Funnel); added Jan 2026 |

**Diagram**:
```
Deposit service receives async provider callback:
  -> ExTransactionID now known, ProcessorValueDate provided
  -> EXEC UpdateDepositData @DepositID=X,
       @ExTransactionID='PROV-TXN-999',
       @ProcessorValueDate='2026-01-15 14:00:00'
  -> UPDATE Billing.Deposit SET
       ExTransactionID='PROV-TXN-999',
       RefundVerificationCode=RefundVerificationCode, -- unchanged (ISNULL)
       ProcessorValueDate='2026-01-15 14:00:00',
       ClearingHouseEffectiveDate=ClearingHouseEffectiveDate, -- unchanged
       ...
     WHERE DepositID=X
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INTEGER | NO | - | CODE-BACKED | Primary key of the deposit to update. Maps to `Billing.Deposit.DepositID`. If DepositID does not exist, the UPDATE silently affects 0 rows. |
| 2 | @ExTransactionID | VARCHAR(50) | YES | NULL | CODE-BACKED | External (provider) transaction ID returned by the payment processor. Written to `Billing.Deposit.ExTransactionID`. NULL = leave unchanged. Used for provider-side reconciliation and dispute resolution. |
| 3 | @RefundVerificationCode | VARCHAR(50) | YES | NULL | CODE-BACKED | Verification code associated with a refund operation. Written to `Billing.Deposit.RefundVerificationCode`. NULL = leave unchanged. Used to correlate refund requests with provider confirmations. |
| 4 | @ProcessorValueDate | DATETIME | YES | NULL | CODE-BACKED | Processor credit date - when the payment processor considers funds credited. Written to `Billing.Deposit.ProcessorValueDate`. NULL = leave unchanged. Mandatory for wire/ACH deposits (offline funding types). |
| 5 | @ClearingHouseEffectiveDate | DATETIME | YES | NULL | CODE-BACKED | Settlement date provided by the clearing house. Written to `Billing.Deposit.ClearingHouseEffectiveDate`. NULL = leave unchanged. Used in conversion rate management for wire processing. |
| 6 | @ManagerID | INTEGER | YES | NULL | CODE-BACKED | Operations manager who processed or enriched this deposit. Written to `Billing.Deposit.ManagerID`. NULL = leave unchanged. 0=automated/system, non-zero=human operator (FK to BackOffice.Manager). |
| 7 | @Approved | BIT | YES | NULL | CODE-BACKED | Legacy approval flag. Written to `Billing.Deposit.Approved`. NULL = leave unchanged. Largely superseded by PaymentStatusID=2 (Approved) in modern workflows. Retained for backward compatibility. |
| 8 | @Commission | MONEY | YES | NULL | CODE-BACKED | Commission amount charged on this deposit. Written to `Billing.Deposit.Commission`. NULL = leave unchanged. Column defaults to 0; only set for commission-based deposit flows. |
| 9 | @FundingID | INTEGER | YES | NULL | CODE-BACKED | Payment instrument identifier. Written to `Billing.Deposit.FundingID` (FK Billing.Funding). NULL = leave unchanged. Added Oct 2022 to support post-creation funding instrument corrections. |
| 10 | @StatusID | INTEGER | YES | NULL | CODE-BACKED | Payment processing status override. Written to `Billing.Deposit.PaymentStatusID` (FK Dictionary.PaymentStatus). NULL = leave unchanged. Added Oct 2025. Bypasses PaymentStatusStateMachine validation used by Billing.DepositProcess - caller is responsible for valid transitions. |
| 11 | @FunnelID | INTEGER | YES | NULL | CODE-BACKED | Marketing funnel identifier. Written to `Billing.Deposit.FunnelID` (FK Dictionary.Funnel). NULL = leave unchanged. Added Jan 2026 to support funnel attribution corrections. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WHERE DepositID | Billing.Deposit | UPDATE | Patch-updates multiple supplementary fields on the target deposit record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Deposit service | @DepositID + selective params | EXEC (DepositUser role) | Called when supplementary deposit data arrives asynchronously (provider callbacks, wire settlement dates, manager corrections) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateDepositData (procedure)
`- Billing.Deposit (table) - UPDATE (patch)
   |- Billing.Funding (FK on FundingID)
   |- Dictionary.PaymentStatus (FK on PaymentStatusID)
   |- Dictionary.Funnel (FK on FunnelID)
   `- BackOffice.Manager (FK on ManagerID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | UPDATE - patch-updates 10 fields via ISNULL pattern WHERE DepositID=@DepositID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found in SSDT. | - | Called externally by Deposit service (DepositUser role) for async field enrichment. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Target table `Billing.Deposit` has indexes relevant to the updated columns: `BDEP_ExTransactionID` (NC on ExTransactionID), `BDEP_FUNDING` (NC on FundingID), `IX_BillingDeposit_PaymentStatusID` and related indexes on PaymentStatusID. The UPDATE statement itself hits the clustered PK (`PK_BDEP` on DepositID).

### 7.2 Constraints

N/A for stored procedure. Note: `@StatusID` updates `PaymentStatusID` directly without going through `Dictionary.PaymentStatusStateMachine` validation. The FK constraint `FK_DPMS_BDEP` on `Billing.Deposit.PaymentStatusID -> Dictionary.PaymentStatus` is still enforced at the table level - invalid PaymentStatusID values will fail. However, invalid STATE TRANSITIONS (e.g., Approved -> Pending) are not prevented by this procedure. Use `Billing.DepositProcess` for validated status transitions.

---

## 8. Sample Queries

### 8.1 Set the external provider transaction ID after async callback
```sql
-- Record the provider's transaction ID after receiving their callback
EXEC Billing.UpdateDepositData
    @DepositID = 10780413,
    @ExTransactionID = 'PROV-TXN-7823456';
```

### 8.2 Set wire/ACH settlement dates
```sql
-- Update processor and clearing house dates for a wire deposit
EXEC Billing.UpdateDepositData
    @DepositID = 10780413,
    @ProcessorValueDate = '2026-03-18 12:00:00',
    @ClearingHouseEffectiveDate = '2026-03-20 00:00:00';
```

### 8.3 Update the payment instrument and commission together
```sql
-- Correct the funding instrument and record commission
EXEC Billing.UpdateDepositData
    @DepositID = 10780413,
    @FundingID = 5001234,
    @Commission = 2.50;
```

### 8.4 Override payment status (use with care - bypasses state machine)
```sql
-- Direct status override (caller must validate transition is valid)
EXEC Billing.UpdateDepositData
    @DepositID = 10780413,
    @StatusID = 2; -- 2=Approved
```

### 8.5 Verify the update was applied
```sql
SELECT DepositID, ExTransactionID, ProcessorValueDate, ClearingHouseEffectiveDate,
       ManagerID, Approved, Commission, FundingID, PaymentStatusID, FunnelID
FROM Billing.Deposit WITH (NOLOCK)
WHERE DepositID = 10780413;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UpdateDepositData | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateDepositData.sql*
