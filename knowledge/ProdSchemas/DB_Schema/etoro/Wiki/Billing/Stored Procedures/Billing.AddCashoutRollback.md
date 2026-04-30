# Billing.AddCashoutRollback

> Top-level cashout rollback orchestrator that atomically executes a 4-step reversal workflow: update the cashout payment leg (UpdateWithdraw2Funding), upsert the withdrawal record (UpsertWithdraw), create the rollback audit trail (AddCashoutRollbackTrackingRecord), and credit the customer's balance via Customer.SetBalance with CreditTypeID=33 (Cashout Rollback).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No return value (RETURN implicit 0); raises on error; all 4 steps in a single atomic transaction |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.AddCashoutRollback` is the top-level entry point for processing a cashout reversal. When a withdrawal that was previously sent to a payment provider is reversed - either by the provider (chargeback), by the operations team (error correction), or by the risk team (fraud prevention) - this procedure coordinates all the database updates required to record and complete the reversal.

The procedure accepts two table-valued parameters (`@Widraw2F` of type `Billing.TBL_Withdraw2Funding` and `@Withdraw` of type `Billing.TBL_Withdraw`) that carry the updated state of the cashout payment leg and withdrawal record. This TVP pattern allows the caller to prepare the full desired state and pass it in a single call.

The 4-step workflow runs within a single `BEGIN TRAN` / `COMMIT TRAN` block:
1. **Update the payment leg**: Sets the new CashoutStatusID and other state on the WithdrawToFunding record.
2. **Upsert the withdrawal**: Updates or inserts the Withdraw record with the latest state.
3. **Create the audit record**: Inserts into CashoutRollbackTracking with all rollback amounts, exchange rates, and metadata.
4. **Credit the customer**: Calls Customer.SetBalance with CreditTypeID=33 (Cashout Rollback) to return the money to the customer's account.

Two additional steps that were previously called (`Trade.UpdateCustomerMoneyCashoutRollback` and `History.ActiveCredit_CashoutRollbackSet`) are commented out - their functionality was moved to another mechanism (likely the Customer.SetBalance call or event-driven processing).

---

## 2. Business Logic

### 2.1 TVP Parameter Extraction

**What**: Extracts the WithdrawToFundingID and WithdrawID from the TVP parameters at the start of execution.

**Parameters/Columns Involved**: `@Widraw2F`, `@Withdraw`, `@WithdrawToFundingID`, `@WithdrawID`

**Rules**:
- `SELECT @WithdrawToFundingID = [ID] FROM @Widraw2F` - the payment processing leg ID.
- `SELECT @WithdrawID = WithdrawID FROM @Withdraw` - the withdrawal request ID.
- These IDs are then used throughout the remaining 4 steps as linkage keys.
- Both TVPs are `READONLY` (cannot be modified within the procedure).

### 2.2 Step 1: Update the Cashout Payment Leg

**What**: Applies the caller-supplied state changes to the WithdrawToFunding record.

**Parameters/Columns Involved**: `@Widraw2F`, `Billing.WithdrawToFunding`

**Rules**:
- `EXEC Billing.UpdateWithdraw2Funding @Widraw2F`.
- The TVP carries the target state (CashoutStatusID, amounts, etc.) for the payment leg.
- This typically moves the payment leg to the "Reversed" or "Partially Reversed" status.

### 2.3 Step 2: Upsert the Withdrawal Record

**What**: Updates or inserts the Withdraw record with the current state.

**Parameters/Columns Involved**: `@Withdraw`, `@ExTransactionID`, `@WithdrawTypeID`, `@FlowID`, `Billing.Withdraw`

**Rules**:
- `EXEC Billing.UpsertWithdraw @Withdraw, @ExTransactionID, @WithdrawTypeID, @FlowID`.
- @ExTransactionID, @WithdrawTypeID, @FlowID are passed through as additional context for the upsert.

### 2.4 Step 3: Create the Rollback Audit Record

**What**: Inserts a detailed record into CashoutRollbackTracking for the reversal event.

**Parameters/Columns Involved**: All rollback amount/rate/metadata params, `Billing.CashoutRollbackTracking`, `@RollbackID OUTPUT`

**Rules**:
- `EXEC Billing.AddCashoutRollbackTrackingRecord ... @RollbackID = @RollbackID OUTPUT`.
- All rollback financial details are passed: @RollbackAmountInUSD, @RollbackAmountInCurrency, @TotalRollbackAmountInUSD, @TotalRollbackAmountInCurrency, @CurrencyID, @RollbackType, @ExchangeRate, @ReferenceNumber, @Comments, @RollbackDate, @ManagerID.
- @RollbackID is retrieved as OUTPUT - the new audit record's primary key is needed for step 4.

### 2.5 Step 4: Credit Customer Balance

**What**: Returns the reversed amount to the customer's account balance.

**Parameters/Columns Involved**: `@CID`, `@Amount`, `@RollbackID`, `Customer.SetBalance`

**Rules**:
- `EXEC Customer.SetBalance @CID=@CID, @Payment=@Amount, @CreditTypeID=33, @WithdrawID=@WithdrawID, @ManagerID=@ManagerID, @Description=@Comments, @WithdrawProcessingID=@WithdrawToFundingID, @RollbackID=@RollbackID`.
- `@CreditTypeID=33` is the Cashout Rollback credit type.
- @RollbackID (from step 3) is passed to link the credit event to the tracking record.
- @Amount (MONEY) is the reversal credit amount (positive - this is a credit back to the customer).

### 2.6 Transaction and Error Handling

**Rules**:
- `BEGIN TRAN / COMMIT TRAN` wraps all 4 steps - all succeed together or none succeed.
- `CATCH`: ROLLBACK if @@TRANCOUNT=1; COMMIT if >1 (nested transaction handling). THROW always re-throws the original error.
- Standard THROW pattern (same as AmountAdd - re-throws without modification).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Widraw2F | Billing.TBL_Withdraw2Funding | NO | - | VERIFIED | TVP carrying the target state for the cashout payment leg (WithdrawToFunding record). Must contain exactly one row. The ID column is extracted to identify which payment leg to update. (Note: "Widraw" spelling is consistent with the UDT name.) |
| 2 | @Withdraw | Billing.TBL_Withdraw | NO | - | VERIFIED | TVP carrying the target state for the withdrawal record. Must contain exactly one row. The WithdrawID column is extracted as the withdrawal linkage key. |
| 3 | @Amount | MONEY | NO | - | VERIFIED | Amount to credit back to the customer's balance (MONEY type, positive value). Passed to Customer.SetBalance as the reversal credit. |
| 4 | @CID | INT | NO | - | VERIFIED | Customer ID receiving the rollback credit. Passed to Customer.SetBalance. |
| 5 | @ExTransactionID | VARCHAR(500) | YES | NULL | VERIFIED | External transaction reference from the payment provider for the reversal. Passed to UpsertWithdraw. |
| 6 | @WithdrawTypeID | INT | YES | NULL | VERIFIED | Type of withdrawal being rolled back. Passed to UpsertWithdraw for state classification. |
| 7 | @FlowID | INT | YES | NULL | VERIFIED | Processing flow identifier. Passed to UpsertWithdraw. |
| 8 | @CashoutStatusID | INT | NO | - | VERIFIED | Target cashout status ID for the reversal (e.g., 16=Reversed, 17=Partially Reversed). Passed to AddCashoutRollbackTrackingRecord. |
| 9 | @RollbackAmountInUSD | MONEY | YES | NULL | VERIFIED | Rollback amount denominated in USD. Passed to AddCashoutRollbackTrackingRecord for the audit trail. |
| 10 | @RollbackAmountInCurrency | MONEY | YES | NULL | VERIFIED | Rollback amount in the deposit's currency. Passed to AddCashoutRollbackTrackingRecord. |
| 11 | @TotalRollbackAmountInUSD | MONEY | YES | NULL | VERIFIED | Cumulative rollback amount in USD (for partial rollback tracking). Passed to AddCashoutRollbackTrackingRecord. |
| 12 | @TotalRollbackAmountInCurrency | MONEY | NO | - | VERIFIED | Cumulative rollback amount in deposit currency. Required. Passed to AddCashoutRollbackTrackingRecord. |
| 13 | @CurrencyID | INT | YES | NULL | VERIFIED | Currency of the rollback amounts. Passed to AddCashoutRollbackTrackingRecord. |
| 14 | @RollbackType | INT | YES | NULL | VERIFIED | Type/reason classification of the rollback. Stored as RollbackReasonID in CashoutRollbackTracking. |
| 15 | @ExchangeRate | MONEY | YES | NULL | VERIFIED | FX rate applied to the rollback amounts. Passed to AddCashoutRollbackTrackingRecord. |
| 16 | @ReferenceNumber | VARCHAR(50) | YES | NULL | VERIFIED | Provider-issued reference number for the reversal transaction. Stored in CashoutRollbackTracking.ReferenceNumber. |
| 17 | @Comments | VARCHAR(255) | YES | NULL | VERIFIED | Free-text comment describing the rollback. Used as Description in Customer.SetBalance and as Comments in AddCashoutRollbackTrackingRecord. |
| 18 | @RollbackDate | DATETIME | YES | NULL | VERIFIED | Date the rollback occurred (per the provider or operation). Passed to AddCashoutRollbackTrackingRecord. |
| 19 | @ManagerID | INT | YES | NULL | VERIFIED | ID of the manager or system actor initiating the rollback. Passed to both AddCashoutRollbackTrackingRecord and Customer.SetBalance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Widraw2F | Billing.UpdateWithdraw2Funding | EXEC | Step 1: updates the cashout payment leg via TVP. |
| @Withdraw | Billing.UpsertWithdraw | EXEC | Step 2: upserts the withdrawal record via TVP. |
| @RollbackID OUTPUT | Billing.AddCashoutRollbackTrackingRecord | EXEC | Step 3: creates the rollback audit record; returns RollbackID for step 4. |
| @RollbackID, @Amount | Customer.SetBalance | EXEC (cross-schema) | Step 4: credits the customer with CreditTypeID=33 (Cashout Rollback). |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called from cashout reversal processing services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.AddCashoutRollback (procedure)  [Level 1]
|- Billing.UpdateWithdraw2Funding (proc)               [EXEC Step 1 - payment leg update]
|   +- Billing.WithdrawToFunding (table)               [UPDATE target]
|- Billing.UpsertWithdraw (proc)                       [EXEC Step 2 - withdrawal upsert]
|   +- Billing.Withdraw (table)                        [UPDATE/INSERT target]
|- Billing.AddCashoutRollbackTrackingRecord (proc)     [EXEC Step 3 - audit trail] [documented Batch 10 #1]
|   +- Billing.CashoutRollbackTracking (table)         [INSERT target]
+- Customer.SetBalance (proc cross-schema)             [EXEC Step 4 - balance credit CreditTypeID=33]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.UpdateWithdraw2Funding | Stored Procedure | Step 1: applies TVP state to WithdrawToFunding |
| Billing.UpsertWithdraw | Stored Procedure | Step 2: applies TVP state to Withdraw |
| Billing.AddCashoutRollbackTrackingRecord | Stored Procedure | Step 3: creates rollback audit record; returns RollbackID |
| Customer.SetBalance | Stored Procedure (cross-schema) | Step 4: credits customer with CreditTypeID=33 (Cashout Rollback) |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files. Called from payment reversal services.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **TVP pattern**: Using typed TVPs (TBL_Withdraw2Funding and TBL_Withdraw) allows the caller to prepare the full new state of complex records before calling, making the interface strongly-typed and preventing parameter explosion.
- **@RollbackID output linkage**: The RollbackID from step 3 is passed to Customer.SetBalance in step 4, enabling the balance credit event to be traced back to the specific rollback audit record in CashoutRollbackTracking.
- **Commented-out steps**: Two additional steps were previously called but are now commented out - `Trade.UpdateCustomerMoneyCashoutRollback` and `History.ActiveCredit_CashoutRollbackSet`. Their functionality is now handled elsewhere (likely by Customer.SetBalance triggering downstream events).
- **Debug print artifact**: `print 'Billing.UpdateWithdraw2Funding.sql'` at the end of the file executes outside the procedure body (after GO) as a standalone batch statement - it is not part of the procedure code.
- **THROW on error**: Uses `THROW` to re-propagate errors without modification - the cleanest error handling pattern among the Billing SPs reviewed in this batch.

---

## 8. Sample Queries

### 8.1 Initiate a cashout rollback
```sql
DECLARE @WTF Billing.TBL_Withdraw2Funding;
DECLARE @W   Billing.TBL_Withdraw;

-- Populate TVPs from existing records with updated state
INSERT INTO @WTF SELECT * FROM Billing.WithdrawToFunding WHERE ID = 12345678;
UPDATE @WTF SET CashoutStatusID = 16;  -- Set to Reversed

INSERT INTO @W SELECT * FROM Billing.Withdraw WHERE WithdrawID = 99887766;

EXEC Billing.AddCashoutRollback
    @Widraw2F                      = @WTF,
    @Withdraw                      = @W,
    @Amount                        = 50.00,
    @CID                           = 12345,
    @CashoutStatusID               = 16,
    @TotalRollbackAmountInCurrency = 50.00,
    @RollbackAmountInUSD           = 50.00,
    @CurrencyID                    = 1,
    @ManagerID                     = 9999,
    @Comments                      = 'Provider reversed the cashout';
```

### 8.2 Verify the rollback was recorded
```sql
SELECT TOP 5
    CRT.RollbackID,
    CRT.WithdrawID,
    CRT.RollbackAmountInUSD,
    CRT.ModificationDate,
    CRT.Comments
FROM Billing.CashoutRollbackTracking CRT WITH (NOLOCK)
WHERE CRT.WithdrawID = 99887766
ORDER BY CRT.RollbackID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 19 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.AddCashoutRollback | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.AddCashoutRollback.sql*
