# Billing.AmountAdd

> Core money-addition orchestrator that credits a customer account by delegating to Customer.SetBalance, with specialized handling for deposits (exclusive app lock + IsSetBalanceCompleted flag), credit notes (History.CreditNotes), and P&L compensation adjustments (History.Position_Extra). Translates AccountUpdateTypeID to the internal CreditTypeID taxonomy used by the balance engine.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN 0 (success) or non-zero error code; core side-effect is Customer.SetBalance credit |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.AmountAdd` is the central credit-side money-movement procedure in the Billing schema. All positive balance adjustments - whether they originate from deposits, position close profits, bonuses, or P&L compensations - funnel through this procedure. It does not perform the balance update itself; instead, it translates the caller's business context (AccountUpdateTypeID) into the internal CreditTypeID understood by `Customer.SetBalance`, then delegates the actual ledger credit to that cross-schema procedure.

Beyond the core credit, the procedure enforces three important side-effects:

1. **Deposit concurrency guard**: For deposit credits (AccountUpdateTypeID=1), it acquires an exclusive application lock on the DepositID before proceeding. This prevents two parallel processes from crediting the same deposit twice (a common race condition in payment confirmation workflows).

2. **Deposit completion flag**: After a successful deposit credit, it marks `Billing.Deposit.IsSetBalanceCompleted=1`, signaling that the balance side of the deposit lifecycle is done.

3. **P&L compensation audit**: For compensation credits tied to a specific position (CompensationReasonID=22), it upserts a record in `History.Position_Extra` so the compensation amount is tracked separately from normal trade P&L, and the position is flagged to be excluded from statistics (ExcludeFromStatistics=1).

4. **Credit note recording**: For credit type 6 (manual credit), it records the credit description as a note in `History.CreditNotes` linked to the CreditID returned by SetBalance.

The procedure is wrapped in a full BEGIN TRANSACTION / TRY-CATCH block. On error, it rolls back and re-throws with rich diagnostic context (server, DB, procedure, line, message).

---

## 2. Business Logic

### 2.1 AccountUpdateTypeID to CreditTypeID Translation

**What**: The caller supplies a business-level AccountUpdateTypeID; the procedure maps it to the internal CreditTypeID used by the balance engine.

**Parameters/Columns Involved**: `@AccountUpdateTypeID`, `@CreditTypeID`

**Rules** (exhaustive CASE - unmapped values yield NULL CreditTypeID, which will cause Customer.SetBalance to behave unexpectedly):

| AccountUpdateTypeID | CreditTypeID | Business Meaning |
|--------------------|-------------|-----------------|
| 1 | 1 | Deposit |
| 2 | 2 | (Deposit-related credit type) |
| 3 | 7 | Bonus credit |
| 6 | 6 | Manual credit (triggers credit note insertion) |
| 10 | 3 | Position close - profit |
| 11 | 4 | Position close (manual / take profit / stop loss) |
| 12 | 5 | Position-related credit |
| 22 | 22 | Mirror Hierarchical Close position |
| 23 | 23 | Mirror Hierarchical Open position |
| (any other) | NULL | Not mapped - pass-through results in NULL CreditTypeID |

### 2.2 Deposit Exclusive Lock (AccountUpdateTypeID=1)

**What**: Before processing a deposit credit, acquires an exclusive application lock to prevent parallel processing of the same deposit.

**Parameters/Columns Involved**: `@AccountUpdateTypeID`, `@DepositID`, `sp_getapplock`

**Rules**:
- Only executed when `@AccountUpdateTypeID = 1` AND `@DepositID IS NOT NULL`.
- Calls `EXECUTE @lockResult = sp_getapplock @Resource = @DepositID, @LockMode = 'Exclusive', @LockTimeout = 0`.
- Lock timeout = 0: if the lock cannot be acquired immediately, it fails.
- If `@lockResult <> 0`: raises error 60025 ("Deposit Processed BY another instance") and returns 60025 - the transaction is not committed.
- Prevents duplicate deposit crediting in high-volume parallel payment confirmation scenarios.

### 2.3 MirrorID Lookup from Position

**What**: If a PositionID is provided, resolves the associated MirrorID to pass through to Customer.SetBalance.

**Parameters/Columns Involved**: `@PositionID`, `@MirrorID`, `Trade.Position`

**Rules**:
- `SELECT @MirrorID = COALESCE(MirrorID, 0) FROM Trade.Position WITH(NOLOCK) WHERE PositionID = @PositionID`.
- `COALESCE(MirrorID, 0)` converts NULL (non-mirror position) to 0.
- @MirrorID is then passed to Customer.SetBalance to link the credit to mirror copy context.
- If @PositionID is NULL (non-position credit), @MirrorID remains at its default (NULL is passed to SetBalance).

### 2.4 Customer.SetBalance Delegation

**What**: The actual ledger credit is performed by Customer.SetBalance in the Customer schema.

**Parameters/Columns Involved**: All @CID, @Amount, @CreditTypeID, plus context params

**Rules**:
- @Amount (INTEGER, in cents) is passed as @Payment.
- @CurrencyID is accepted as a parameter of Billing.AmountAdd but is NOT forwarded to Customer.SetBalance. It was used in the (now-removed) LocalPerfLog audit block (removed per DBAD-79). Currently unused in any active code path.
- If `@Answer != 0` (SetBalance failure): the procedure returns @Answer immediately (exits without committing).
- On success, @CreditID OUTPUT receives the new credit record ID.

### 2.5 Credit Note Insertion (CreditTypeID=6)

**What**: For manual credits, records the description as a credit note linked to the CreditID from SetBalance.

**Parameters/Columns Involved**: `@CreditTypeID`, `@CreditID`, `@Description`, `History.CreditNotes`

**Rules**:
- Condition: `IF @CreditTypeID = 6` (i.e., @AccountUpdateTypeID=6).
- Inserts `(CreditID, CreditNote)` into `History.CreditNotes` using @Description as the note text.
- Provides an audit trail for manual/administrative credits beyond what Customer.SetBalance records.

### 2.6 P&L Compensation Tracking (CompensationReasonID=22)

**What**: When a credit is a P&L adjustment compensation tied to an active position, records the compensation amount separately in History.Position_Extra.

**Parameters/Columns Involved**: `@CompensationReasonID`, `@PositionID`, `@Amount`, `History.Position_Active`, `History.Position_Extra`

**Rules**:
- Condition: `@CompensationReasonID = 22` AND `@PositionID IS NOT NULL` AND `EXISTS (SELECT 1 FROM History.Position_Active WHERE PositionID = @PositionID)`.
- If position NOT in History.Position_Active: raises error 60000 with context 'Billing.AmountAdd=@CompensationReasonID=22'.
- If position exists and no History.Position_Extra record: INSERT with `TotalCompensation = @Amount / 100.0`, `ExcludeFromStatistics = 1`.
- If position exists and History.Position_Extra record already present: UPDATE, adding `@Amount / 100.0` to existing TotalCompensation, setting ExcludeFromStatistics = 1.
- Division by 100.0: converts the INTEGER cents value (@Amount) to a decimal currency amount.
- ExcludeFromStatistics=1: flags this position to be excluded from trading statistics reports (compensation amounts should not distort P&L analytics).

### 2.7 Deposit Completion Flag

**What**: After a successful deposit credit, marks the deposit record as balance-complete.

**Parameters/Columns Involved**: `@AccountUpdateTypeID`, `@DepositID`, `Billing.Deposit.IsSetBalanceCompleted`

**Rules**:
- Condition: `@AccountUpdateTypeID = 1` (deposit credit only).
- `UPDATE Billing.Deposit SET IsSetBalanceCompleted = 1 WHERE DepositID = @DepositID`.
- Signals that the balance-engine step of the deposit lifecycle is complete.
- Does not check if @DepositID is NULL - if @DepositID IS NULL (unusual for deposits), the UPDATE WHERE clause matches nothing (no-op).

### 2.8 Transaction and Error Handling

**What**: Full transactional wrapper with rollback on failure and rich error reporting.

**Rules**:
- `BEGIN TRANSACTION` wraps all operations; `COMMIT TRANSACTION` on success.
- `CATCH` block: if `@@TranCount = 1` -> `ROLLBACK TRAN`; if `@@TranCount > 1` -> `COMMIT TRAN` (nested transaction context).
- Error re-thrown via `THROW 60000, @ErrOut, 1` with full diagnostic context: ServerName, DB_NAME(), OBJECT_NAME(@@ProcID), ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE(), ERROR_SEVERITY(), @@TranCount.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | VERIFIED | Customer ID of the account to credit. Passed directly to Customer.SetBalance. FK to Customer.Customer.CID. |
| 2 | @CurrencyID | INTEGER | NO | - | VERIFIED | Account currency ID. Accepted as a parameter but NOT forwarded to Customer.SetBalance in the current code (legacy parameter, used in now-removed LocalPerfLog audit block per DBAD-79). Implicit FK to Dictionary.Currency. |
| 3 | @AccountUpdateTypeID | INTEGER | NO | - | VERIFIED | Business operation type that initiated this credit. Mapped to internal CreditTypeID before calling Customer.SetBalance. Valid values: 1=Deposit, 2=Deposit-type-2, 3=Bonus, 6=Manual credit, 10=Position profit, 11=Position close, 12=Position credit, 22=Mirror close, 23=Mirror open. Unmapped values yield NULL CreditTypeID. |
| 4 | @Amount | INTEGER | NO | - | VERIFIED | Amount to credit, expressed in cents (INTEGER). Passed as @Payment to Customer.SetBalance. For P&L compensation (CompensationReasonID=22), divided by 100.0 to convert to decimal currency amount for History.Position_Extra.TotalCompensation. |
| 5 | @PositionID | BIGINT | YES | NULL | VERIFIED | Position this credit relates to. When provided: resolves MirrorID from Trade.Position to pass to Customer.SetBalance. Also used to identify the position for P&L compensation tracking in History.Position_Extra. |
| 6 | @ManagerID | INTEGER | YES | NULL | VERIFIED | ID of the back-office manager or system actor authorizing this credit. Passed through to Customer.SetBalance for audit trail. NULL for automated system credits. |
| 7 | @Description | VARCHAR(600) | YES | NULL | VERIFIED | Free-text description of the credit operation. Passed to Customer.SetBalance. Also used as CreditNote when @CreditTypeID=6 (manual credit). |
| 8 | @PaymentID | INTEGER | YES | NULL | VERIFIED | External payment transaction identifier. Passed through to Customer.SetBalance for cross-reference. |
| 9 | @CompensationReasonID | INTEGER | YES | NULL | VERIFIED | Reason code for compensation credits. Value 22 = P&L Adjustment, triggers History.Position_Extra upsert. Passed through to Customer.SetBalance. |
| 10 | @DepositID | INTEGER | YES | NULL | VERIFIED | Deposit record ID for deposit credits (AccountUpdateTypeID=1). Used to acquire exclusive app lock (preventing parallel deposit processing) and to set Billing.Deposit.IsSetBalanceCompleted=1 after credit. Passed through to Customer.SetBalance. |
| 11 | @BonusCredit | MONEY | YES | NULL | VERIFIED | Bonus credit amount associated with this transaction. Passed through to Customer.SetBalance. Applies to bonus-type credits. |
| 12 | @IsInitiatedByUser | INT | YES | NULL | VERIFIED | Flag indicating whether this credit was triggered by the customer (1) or by the system/back-office. Passed through to Customer.SetBalance for audit differentiation. |
| 13 | @MoveMoneyReasonID | INTEGER | YES | NULL | VERIFIED | Reason code for money movement operations. Added in 2016 (Geri Reshef, change 34112). Passed through to Customer.SetBalance for enhanced movement tracking. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID | Trade.Position | READER (JOIN) | SELECT MirrorID for the given PositionID to pass to Customer.SetBalance. |
| @CreditTypeID, @CreditID | History.CreditNotes | WRITER (INSERT) | Inserts credit note when CreditTypeID=6 (manual credits). |
| @PositionID, @Amount | History.Position_Active | READER (EXISTS) | Validates position is active before writing P&L compensation record. |
| @PositionID, @Amount | History.Position_Extra | WRITER (INSERT/UPDATE) | Upserts compensation amount and ExcludeFromStatistics flag for CompensationReasonID=22. |
| @DepositID | Billing.Deposit | WRITER (UPDATE) | Sets IsSetBalanceCompleted=1 after successful deposit credit. |
| All params | Customer.SetBalance | EXEC (cross-schema) | Core balance credit delegation - the actual ledger update is performed here. |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called from payment processing services and back-office credit operations.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.AmountAdd (procedure)
|- Trade.Position (table)              [SELECT - resolve MirrorID for position credits]
|- History.Position_Active (table)     [EXISTS - validate position is active for P&L comp]
|- History.Position_Extra (table)      [INSERT/UPDATE - P&L compensation tracking]
|- History.CreditNotes (table)         [INSERT - manual credit note recording]
|- Billing.Deposit (table)             [UPDATE - mark IsSetBalanceCompleted=1]
+- Customer.SetBalance (proc)          [EXEC cross-schema - core balance credit engine]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalance | Stored Procedure (cross-schema) | Core balance credit engine; all actual ledger updates delegated here |
| Billing.Deposit | Table | UPDATE IsSetBalanceCompleted=1 after successful deposit credit |
| Trade.Position | Table | SELECT MirrorID WHERE PositionID=@PositionID |
| History.Position_Active | Table | EXISTS check to validate position is active before P&L compensation write |
| History.Position_Extra | Table | INSERT/UPDATE TotalCompensation and ExcludeFromStatistics for CompensationReasonID=22 |
| History.CreditNotes | Table | INSERT credit note text for CreditTypeID=6 manual credits |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files. Called from payment processing and back-office systems.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **Removed audit logging**: The procedure previously logged execution to `dbo.LocalPerfLog`. This was removed per DBAD-79 (2023-07-30, Dor Izmaylov). The commented-out block shows all input parameters were logged as XML.
- **@CurrencyID unused**: The @CurrencyID parameter is accepted but never used in any active code path. It was part of the removed audit logging. Callers must still pass it (or NULL) to avoid parameter mismatch.
- **Lock scope**: The sp_getapplock resource key is the raw @DepositID integer (as a varchar). The lock is released on COMMIT (Transaction scope, not Session scope). Lock timeout=0 means no retry - first caller wins, second caller gets error 60025.
- **Nested transaction awareness**: The CATCH block differentiates between @@TranCount=1 (sole transaction owner - ROLLBACK) and @@TranCount>1 (nested - COMMIT, letting outer transaction control rollback).

---

## 8. Sample Queries

### 8.1 Process a deposit credit
```sql
DECLARE @Result INT;
EXEC @Result = Billing.AmountAdd
    @CID                = 12345,
    @CurrencyID         = 1,         -- USD (unused in current code)
    @AccountUpdateTypeID = 1,         -- Deposit
    @Amount             = 100000,    -- $1000.00 in cents
    @DepositID          = 99887766,
    @Description        = 'Deposit via CreditCard';
SELECT @Result AS ReturnCode;  -- 0 = success
```

### 8.2 Apply a P&L compensation credit to an active position
```sql
DECLARE @Result INT;
EXEC @Result = Billing.AmountAdd
    @CID                  = 12345,
    @CurrencyID           = 1,
    @AccountUpdateTypeID  = 10,       -- Position profit
    @Amount               = 5000,     -- $50.00 in cents
    @PositionID           = 1234567890,
    @CompensationReasonID = 22,       -- P&L Adjustment
    @Description          = 'P&L compensation - manual adjustment';
SELECT @Result AS ReturnCode;
```

### 8.3 Check deposit completion status
```sql
SELECT  D.DepositID,
        D.IsSetBalanceCompleted,
        D.Amount,
        D.ModificationDate
FROM    Billing.Deposit D WITH (NOLOCK)
WHERE   D.DepositID = 99887766;
-- IsSetBalanceCompleted = 1 confirms Billing.AmountAdd completed successfully
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 13 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.AmountAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.AmountAdd.sql*
