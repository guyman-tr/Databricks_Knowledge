# Billing.UpsertWithdraw

> Central UPSERT procedure for `Billing.Withdraw`; inserts a new withdrawal request or partially updates an existing one using a TVP, then always writes an audit entry to `History.WithdrawAction`.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns WithdrawID (RETURN value) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpsertWithdraw` is the single gateway for all INSERT and UPDATE operations on `Billing.Withdraw`. It was introduced as part of the DBA-648 refactoring (Shay Oren, September 2021) to eliminate 25+ individual `INSERT INTO Billing.Withdraw` and `UPDATE Billing.Withdraw` statements scattered across many procedures, replacing them with one centralized UPSERT call. This consolidation ensures that every change to a withdrawal record is always accompanied by an audit entry in `History.WithdrawAction`.

The procedure is the dependency of all withdrawal lifecycle operations: creating a new withdrawal request (`WithdrawRequestAdd`), advancing it through status stages (`CashoutRequestUpdate`, `UpdateWithdrawStatus`), processing payment legs (`WithdrawToFundingProcess`), and handling reversals and rejections. Without this procedure, each caller would need to implement its own INSERT/UPDATE and its own history logging, risking audit gaps.

Data flow: the caller populates a local `@Info [Billing].[TBL_Withdraw]` variable with only the columns it needs to set (partial update pattern - NULLs mean "preserve existing value"). It calls `Billing.UpsertWithdraw @Info`. The procedure MERGEs on `WithdrawID` (NULL = new record, non-NULL = update), captures the merged row via OUTPUT, then always inserts one row into `History.WithdrawAction`. The `WithdrawID` of the processed record is returned via RETURN for callers that need to capture the new ID.

---

## 2. Business Logic

### 2.1 MERGE-Based UPSERT with Partial Update

**What**: The procedure uses a SQL MERGE statement to insert or update `Billing.Withdraw` in a single atomic operation. On UPDATE, it applies a partial-update pattern where only non-NULL columns in the TVP overwrite the existing row.

**Parameters/Columns Involved**: `@Withdraw`, all columns of `Billing.TBL_Withdraw`

**Rules**:
- If `@Withdraw.WithdrawID` is NULL (or no matching row exists): WHEN NOT MATCHED -> INSERT all columns. `ExTransactionID`, `WithdrawTypeID`, `FlowID` come from the scalar parameters (not the TVP), as these are only relevant for new records.
- If `@Withdraw.WithdrawID` is non-NULL and a row with that ID exists: WHEN MATCHED -> UPDATE using `ISNULL(Src.Col, BW.Col)` for most columns - if the TVP column is NULL, the existing DB value is preserved.
- `ModificationDate` on UPDATE is always forced to `GETUTCDATE()` (not ISNULL) - every update advances the modification timestamp regardless.
- `AccountCurrencyID` is NOT in the UPDATE SET - it can only be set at INSERT time. Existing values are never overridden by this procedure.
- `@ExTransactionID`, `@WithdrawTypeID`, `@FlowID` are injected into the MERGE source via a SELECT wrapper on the TVP and are inserted only on WHEN NOT MATCHED (new records). On UPDATE they are NOT applied.

**Diagram**:
```
Caller declares: DECLARE @Info [Billing].[TBL_Withdraw]
  -> Populates only columns it needs to change
  -> Leaves other columns NULL (= preserve existing)

EXEC Billing.UpsertWithdraw @Withdraw=@Info, @ExTransactionID=..., ...

MERGE INTO Billing.Withdraw BW
USING (SELECT *, @ExTransactionID, @WithdrawTypeID, @FlowID FROM @Withdraw) AS Src
  ON BW.WithdrawID = Src.WithdrawID

WHEN NOT MATCHED (new):
  INSERT (CurrencyID, FundingTypeID, CID, ManagerID, CashoutStatusID,
          RequestDate, Amount, Commission, Approved, IPAddress,
          ModificationDate, Remark, Comment, Fee, FundingID,
          RequestorComments, SessionID, CashoutReasonID,
          SuggestedBonusDeductionAmount, ActualBonusDeductionAmount,
          ClientWithdrawReasonID, ClientWithdrawReasonComment,
          AccountCurrencyID, ClientWithdrawCommentID,
          ExTransactionID, WithdrawTypeID, FlowID)
  VALUES (Src.Col, ..., ISNULL(Src.RequestDate,GETUTCDATE()),
          ..., ISNULL(Src.ModificationDate,GETUTCDATE()), ...)

WHEN MATCHED (update):
  UPDATE SET
    CurrencyID = ISNULL(Src.CurrencyID, BW.CurrencyID),
    ...(ISNULL pattern for all updatable cols)...
    ModificationDate = GETUTCDATE()   -- always updated, no ISNULL
    -- AccountCurrencyID NOT UPDATED
```

### 2.2 Mandatory Audit Trail via OUTPUT Clause

**What**: Every MERGE operation (INSERT or UPDATE) writes an audit record to `History.WithdrawAction`. The OUTPUT clause captures the merged/inserted row into a local table variable `@Info [History].[TBL_WithdrawAction]`, and then an INSERT from `@Info` feeds the history table.

**Parameters Involved**: `@HistoryOnlyRemark`, all columns via OUTPUT

**Rules**:
- The OUTPUT clause captures: `WithdrawID`, `CashoutStatusID`, `ManagerID` (ISNULL(Src.WithrawActionManagerID, Inserted.ManagerID)), `Commission`, `Approved`, `ModificationDate`, `Comment`, `SessionID`, `CashoutReasonID`, `FundingID`, `FundingTypeID`, `Amount`, `CurrencyID`, `Fee`, `AccountCurrencyID`.
- `ClientPersonalID` column is captured as NULL in the OUTPUT (the column was removed from `Billing.Withdraw` but retained in the TVP for backward compatibility).
- The `Comment` field in History uses `ISNULL(@HistoryOnlyRemark, [Comment])` - if the caller passes `@HistoryOnlyRemark`, that text overrides the normal Comment in the history record (but NOT in the Withdraw table). This allows callers to log a different reason in history than what is stored in the live record.
- `@ExTransactionID`, `@WithdrawTypeID`, `@FlowID` are also inserted into History even on updates (passed directly from the scalar params).
- One history row is ALWAYS written per EXEC call - history is never optional.

**Diagram**:
```
MERGE OUTPUT -> @Info [History].[TBL_WithdrawAction]
INSERT History.WithdrawAction
  SELECT WithdrawID, CashoutStatusID, ...,
         ISNULL(@HistoryOnlyRemark, [Comment]) AS Comment,
         ..., @ExTransactionID, @WithdrawTypeID, @FlowID
  FROM @Info
```

### 2.3 Transaction Management and Error Handling

**What**: The procedure wraps all operations in a transaction with a specific pattern to support both standalone calls and calls nested within an outer transaction.

**Rules**:
- Uses `BEGIN TRY / BEGIN TRAN / ... COMMIT TRAN / END TRY / BEGIN CATCH` pattern.
- On error: if `@@TRANCOUNT = 1` (this is the outermost transaction), performs ROLLBACK.
- On error: if `@@TRANCOUNT > 1` (called from within another transaction), performs COMMIT on the savepoint and returns to the parent's transaction scope.
- `THROW` is always called after the transaction handling to re-raise the original error to the caller.
- This pattern lets callers wrap multiple `UpsertWithdraw` calls in an outer transaction without the inner procedure killing the outer transaction on error.

### 2.4 Return Value

**What**: The procedure returns the `WithdrawID` of the processed record via RETURN.

**Rules**:
- On INSERT: returns the newly assigned IDENTITY value (from `Billing.Withdraw.WithdrawID`).
- On UPDATE: returns the existing `WithdrawID`.
- Capture with: `DECLARE @NewWithdrawID INT; EXEC @NewWithdrawID = Billing.UpsertWithdraw @Info`.
- Only one row is ever in `@Info` (MERGE on PK), so `SELECT TOP (1) WithdrawID FROM @Info` is always safe.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Withdraw | [Billing].[TBL_Withdraw] READONLY | NO | - | VERIFIED | Table-valued parameter carrying the withdrawal row to insert or update. Mirrors `Billing.Withdraw` column structure. The caller populates only the columns it needs; NULL columns are treated as "preserve existing value" on UPDATE. `WithdrawID` within the TVP determines INSERT vs UPDATE: NULL = new record, non-NULL matching row = update. See [Billing.TBL_Withdraw](../User Defined Types/Billing.TBL_Withdraw.md) for full column descriptions. |
| 2 | @HistoryOnlyRemark | VARCHAR(255) | YES | NULL | CODE-BACKED | Optional override text written to `History.WithdrawAction.Comment` instead of the TVP's Comment value. Does NOT affect the Comment stored in `Billing.Withdraw` - only the history record. Used when callers want to log a different reason in audit history than the live record's comment (e.g., internal processing notes). Added by Shay O. 20/10/2021. |
| 3 | @ExTransactionID | VARCHAR(500) | YES | NULL | CODE-BACKED | External transaction identifier from the payment provider. Injected into the MERGE source via SELECT wrapper and inserted into `Billing.Withdraw.ExTransactionID` on new records ONLY (WHEN NOT MATCHED). Also written to `History.WithdrawAction.ExTransactionID`. Per code comment: "This parameter relevant for adding new withdraw only so no need to impact @TBL_Withdraw". Added by KateM 22/08/2023. |
| 4 | @WithdrawTypeID | INT | YES | NULL | CODE-BACKED | Withdrawal type classification (0=standard, 1=special, 2=alternate). Injected into the MERGE and written to `Billing.Withdraw.WithdrawTypeID` on INSERT. Also written to History. NULL = not specified (legacy records). See `Billing.Withdraw` Section 2.3 for `WithdrawTypeID` value meanings and interaction with `FlowID` in downstream processing. |
| 5 | @FlowID | INT | YES | NULL | CODE-BACKED | Processing flow identifier (0=standard, 2=eToroMoney, 3=alternate). Injected into the MERGE and written to `Billing.Withdraw.FlowID` on INSERT. Also written to History. NULL = not specified (legacy records). FlowID=2 with FundingTypeID=33 triggers eToroMoney-specific balance accounting in `WithdrawToFundingProcess`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Withdraw | Billing.TBL_Withdraw | TVP Parameter | Input type; mirrors Billing.Withdraw column structure |
| (MERGE target) | Billing.Withdraw | Write | UPSERT target - inserts new or updates existing withdrawal record |
| @Info (internal) | History.TBL_WithdrawAction | Internal TVP | Table variable used to capture MERGE OUTPUT for history logging |
| (INSERT target) | History.WithdrawAction | Write | Audit log - always receives one row per call |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.WithdrawRequestAdd | EXEC | Caller | Creates new withdrawal request (WHEN NOT MATCHED path) |
| Billing.CashoutRequestUpdate | EXEC | Caller | Updates withdrawal status to InProcess (WHEN MATCHED path) |
| Billing.WithdrawalService_WithdrawRequestAdd | EXEC | Caller | Alternative withdrawal creation path |
| Billing.WithdrawToFundingProcess | EXEC | Caller | Updates withdrawal status and fields during payout processing |
| Billing.WithdrawToFundingProcess_v2 | EXEC | Caller | V2 payout processing path |
| Billing.WithdrawReject | EXEC | Caller | Sets withdrawal to rejected status |
| Billing.WithdrawRequestReverse | EXEC | Caller | Reverses a withdrawal request |
| Billing.WithdrawRequestToReverse | EXEC | Caller | Marks withdrawal for reversal |
| Billing.WithdrawToFundingReject | EXEC | Caller | Rejects a funding link for a withdrawal |
| Billing.WithdrawToFundingReverse | EXEC | Caller | Reverses a funding link |
| Billing.WithdrawToFundingUpdate | EXEC | Caller | Updates funding link state |
| Billing.UpdateWithdrawStatus | EXEC | Caller | Direct status update wrapper |
| Billing.AddCashoutRollback | EXEC | Caller | Modifies withdrawal during cashout rollback |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpsertWithdraw (procedure)
+-- Billing.Withdraw (table) [MERGE target]
+-- History.WithdrawAction (table) [INSERT target]
+-- Billing.TBL_Withdraw (type) [input TVP parameter]
+-- History.TBL_WithdrawAction (type) [internal @Info table variable]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | MERGE target - all INSERT and UPDATE operations |
| History.WithdrawAction | Table | INSERT target - mandatory audit record per call |
| Billing.TBL_Withdraw | User Defined Type | Input TVP parameter @Withdraw |
| History.TBL_WithdrawAction | User Defined Type | Internal @Info table variable for OUTPUT capture |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawRequestAdd | Stored Procedure | Creates new withdrawal (INSERT path) |
| Billing.CashoutRequestUpdate | Stored Procedure | Status transition (UPDATE path) |
| Billing.WithdrawalService_WithdrawRequestAdd | Stored Procedure | Alternative creation path |
| Billing.WithdrawToFundingProcess | Stored Procedure | Payout processing updates |
| Billing.WithdrawToFundingProcess_v2 | Stored Procedure | V2 payout updates |
| Billing.WithdrawReject | Stored Procedure | Rejection status update |
| Billing.WithdrawRequestReverse | Stored Procedure | Reversal path |
| Billing.WithdrawRequestToReverse | Stored Procedure | Mark-for-reversal path |
| Billing.WithdrawToFundingReject | Stored Procedure | Funding rejection |
| Billing.WithdrawToFundingReverse | Stored Procedure | Funding reversal |
| Billing.WithdrawToFundingUpdate | Stored Procedure | Funding update |
| Billing.UpdateWithdrawStatus | Stored Procedure | Status update wrapper |
| Billing.AddCashoutRollback | Stored Procedure | Rollback path |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Notable behavior**: The procedure sets `SET NOCOUNT ON`. It will not return row-count messages to the caller. The WithdrawID is returned via `RETURN` (integer), not a result set. Callers that need the ID must use `EXEC @rc = Billing.UpsertWithdraw ...`.

---

## 8. Sample Queries

### 8.1 Call to insert a new withdrawal request

```sql
DECLARE @Info [Billing].[TBL_Withdraw]
INSERT INTO @Info (CID, CurrencyID, FundingTypeID, CashoutStatusID, Amount, Fee,
                   RequestDate, ModificationDate, FundingID, SessionID,
                   SuggestedBonusDeductionAmount, Commission, Approved)
VALUES (@CID, @CurrencyID, @FundingTypeID, 1, @Amount, @Fee,
        GETUTCDATE(), GETUTCDATE(), @FundingID, @SessionID, 0, 0, 0)

DECLARE @NewWithdrawID INT
EXEC @NewWithdrawID = Billing.UpsertWithdraw
    @Withdraw = @Info,
    @ExTransactionID = @ProviderTransactionRef,
    @WithdrawTypeID = 0,
    @FlowID = 0

SELECT @NewWithdrawID AS InsertedWithdrawID
```

### 8.2 Call to update only the CashoutStatus of an existing withdrawal

```sql
DECLARE @Info [Billing].[TBL_Withdraw]
INSERT INTO @Info (WithdrawID, CashoutStatusID, ManagerID, ModificationDate, Remark)
VALUES (@WithdrawID, 2, @ManagerID, GETUTCDATE(), 'Moved to InProcess')
-- All other columns are NULL -> ISNULL logic preserves existing values

EXEC Billing.UpsertWithdraw
    @Withdraw = @Info,
    @HistoryOnlyRemark = 'Status changed to InProcess by ops workflow'
```

### 8.3 Verify the audit trail for a withdrawal

```sql
SELECT
    ha.WithdrawID,
    ha.CashoutStatusID,
    ha.ManagerID,
    ha.Amount,
    ha.Comment,
    ha.ModificationDate,
    ha.ExTransactionID,
    ha.WithdrawTypeID,
    ha.FlowID
FROM History.WithdrawAction ha WITH (NOLOCK)
WHERE ha.WithdrawID = @WithdrawID
ORDER BY ha.ModificationDate ASC
-- One row per UpsertWithdraw call - both INSERTs and UPDATEs are logged
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 13 callers analyzed | App Code: 0 repos (no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.UpsertWithdraw | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpsertWithdraw.sql*
