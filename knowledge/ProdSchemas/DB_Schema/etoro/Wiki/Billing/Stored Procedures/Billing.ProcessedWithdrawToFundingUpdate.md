# Billing.ProcessedWithdrawToFundingUpdate

> Updates the VerificationCode and ProcessorValueDate on an already-processed (CashoutStatusID=3) WithdrawToFunding record, using non-destructive ISNULL logic to preserve existing values when NULL is passed.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawToFundingID - the processed payout record to enrich |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.ProcessedWithdrawToFundingUpdate` is a post-processing enrichment procedure for completed withdrawals. After a cashout has been finalized (CashoutStatusID=3 = Processed), the payment processor may provide additional metadata that was not available at finalization time: a VerificationCode (the processor's confirmation token) and a ProcessorValueDate (the value date for settlement/reconciliation).

This procedure safely writes these values back to `Billing.WithdrawToFunding` with two important guards:
1. **Status guard**: Raises error 60025 if the record is not in CashoutStatusID=3. This prevents accidentally enriching a record that is still in-flight.
2. **Non-destructive update**: Uses ISNULL pattern for both fields - passing NULL preserves the existing value rather than clearing it.

The procedure is used when the verification or value-date metadata arrives asynchronously after the primary finalization has already completed.

---

## 2. Business Logic

### 2.1 Status Guard

**What**: Prevents enrichment of non-finalized records.

**Columns Involved**: `Billing.WithdrawToFunding.CashoutStatusID`

**Rules**:
- Checks that WTF.CashoutStatusID = 3 (Processed) for @WithdrawToFundingID.
- If CashoutStatusID != 3: RAISERROR 60025 (custom error code indicating wrong status for this operation).
- This guard ensures the procedure only runs on records that have completed the payout pipeline.

### 2.2 Non-Destructive Field Update

**What**: Updates VerificationCode and ProcessorValueDate without overwriting existing values when NULL is passed.

**Columns Involved**: `Billing.WithdrawToFunding.VerificationCode`, `Billing.WithdrawToFunding.ProcessorValueDate`, `Billing.WithdrawToFunding.ModificationDate`

**Rules**:
- VerificationCode = ISNULL(@VerificationCode, VerificationCode): if @VerificationCode is NULL, the existing value is preserved.
- ProcessorValueDate = ISNULL(@ProcessorValueDate, ProcessorValueDate): same non-destructive pattern.
- ModificationDate = GETUTCDATE(): always updated to record when this enrichment occurred.
- This allows callers to update just one field without needing to re-provide the other.

### 2.3 Error Handling

**What**: Uses Internal.CallRaiseError on CATCH for consistent error propagation.

**Rules**:
- TRY/CATCH wraps the entire operation.
- On error in CATCH: EXEC Internal.CallRaiseError to re-raise with context.
- This ensures errors are not silently swallowed.

**Diagram**:
```
@WithdrawToFundingID + @VerificationCode (nullable) + @ProcessorValueDate (nullable)
  |
  Check: WTF.CashoutStatusID = 3?
    NO  -> RAISERROR 60025 (record not in Processed state)
    YES ->
      UPDATE Billing.WithdrawToFunding SET
        VerificationCode  = ISNULL(@VerificationCode, VerificationCode),
        ProcessorValueDate = ISNULL(@ProcessorValueDate, ProcessorValueDate),
        ModificationDate  = GETUTCDATE()
      WHERE ID = @WithdrawToFundingID
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawToFundingID | int | NO | - | CODE-BACKED | The processed withdrawal record to enrich. Maps to `Billing.WithdrawToFunding.ID`. Must have CashoutStatusID=3 or the procedure raises error 60025. |
| 2 | @VerificationCode | varchar(50) | YES | - | CODE-BACKED | Processor's verification/confirmation token. ISNULL-protected: if NULL, the existing `Billing.WithdrawToFunding.VerificationCode` is preserved. |
| 3 | @ProcessorValueDate | datetime | YES | - | CODE-BACKED | Settlement value date provided by the payment processor. ISNULL-protected: if NULL, the existing `Billing.WithdrawToFunding.ProcessorValueDate` is preserved. Used for accounting/settlement reconciliation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawToFundingID | [Billing.WithdrawToFunding](../Tables/Billing.WithdrawToFunding.md) | Read + Write | Validates CashoutStatusID=3; updates VerificationCode, ProcessorValueDate, ModificationDate. |
| CATCH handler | Internal.CallRaiseError | EXEC (error helper) | Re-raises errors on failure. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payment processor / withdrawal service (application) | - | EXEC | Called when asynchronous verification or value-date metadata arrives after finalization. No SQL-layer callers found. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ProcessedWithdrawToFundingUpdate (procedure)
├── Billing.WithdrawToFunding (table) - status check + UPDATE
└── Internal.CallRaiseError (procedure) - error handler
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.WithdrawToFunding](../Tables/Billing.WithdrawToFunding.md) | Table | SELECT to validate CashoutStatusID=3; UPDATE VerificationCode, ProcessorValueDate, ModificationDate. |
| Internal.CallRaiseError | Stored Procedure | EXEC in CATCH block for consistent error propagation. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payment processing application | Application | Post-finalization enrichment with verification code and value date. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

Both the status check and the UPDATE target `WHERE ID = @WithdrawToFundingID` (the PK of `Billing.WithdrawToFunding`) for single-row seeks.

**Error code 60025**: Custom Billing error code indicating the operation was attempted on a record in an unexpected status. Callers should check for this specific error when calling this procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Enrich a processed withdrawal with verification code

```sql
EXEC Billing.ProcessedWithdrawToFundingUpdate
    @WithdrawToFundingID = 12345678,
    @VerificationCode    = 'VERIF-XYZ789',
    @ProcessorValueDate  = NULL;
-- Preserves existing ProcessorValueDate; updates VerificationCode
```

### 8.2 Update the processor value date only

```sql
EXEC Billing.ProcessedWithdrawToFundingUpdate
    @WithdrawToFundingID = 12345678,
    @VerificationCode    = NULL,
    @ProcessorValueDate  = '2026-03-20 00:00:00';
-- Preserves existing VerificationCode; sets ProcessorValueDate
```

### 8.3 Verify the update was applied

```sql
SELECT
    ID AS WithdrawToFundingID,
    CashoutStatusID,
    VerificationCode,
    ProcessorValueDate,
    ModificationDate
FROM Billing.WithdrawToFunding WITH (NOLOCK)
WHERE ID = 12345678;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ProcessedWithdrawToFundingUpdate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.ProcessedWithdrawToFundingUpdate.sql*
