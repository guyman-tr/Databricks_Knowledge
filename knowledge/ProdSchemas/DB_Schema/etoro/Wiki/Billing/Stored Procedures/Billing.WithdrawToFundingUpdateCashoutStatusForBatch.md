# Billing.WithdrawToFundingUpdateCashoutStatusForBatch

> Batch status transition machine for WithdrawToFunding legs - cursor-iterates a TVP, auto-detects current status when not provided, calls WithdrawToFundingUpdateCashoutStatus per row with per-row error isolation; returns IDs of failed rows.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @tbl Billing.TBL_CashoutStatusInfo - the batch of WTF status transitions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the batch wrapper for `Billing.WithdrawToFundingUpdateCashoutStatus`. When the Cashout Service or back-office tooling needs to transition multiple WTF legs to a new status in a single call (e.g., bulk-advancing a set of PendingReview records to InProcess after a compliance review is completed), this procedure accepts a TVP of WTF IDs with their target statuses and applies each transition via the single-record SP.

The key added value over calling the single-record SP individually is:
1. **Per-row error isolation**: a failure on one row doesn't abort the rest of the batch
2. **Auto-detect current status**: if `TBL_CashoutStatusInfo.CashoutStatusID` is NULL for a row, the procedure reads the current status from `Billing.WithdrawToFunding` and passes it to the underlying SP - callers can omit the current status and the SP resolves it automatically

The pattern mirrors `WithdrawToFundingProcessBatch` (which wraps `WithdrawToFundingProcess`): cursor loop, TRY/CATCH per row, @Errors table, return failed IDs. Unlike the process batch SP, this one does NOT raise a non-fatal RAISERROR after returning errors - callers must check the result set themselves.

---

## 2. Business Logic

### 2.1 Cursor-Based Iteration with Per-Row Error Isolation

**What**: Processes each TVP row independently; failures on any row don't abort the batch.

**Columns/Parameters Involved**: `@Errors TABLE`, `ID` (error key), `@@FETCH_STATUS`

**Rules**:
- CURSOR over `@tbl`: SELECT ID, ManagerID, Remark, CashoutStatusID, NewCashoutStatusID
- Each row: TRY block executes auto-detect + SP call; CATCH captures failed ID
- After cursor: `SELECT ID FROM @Errors` (empty on full success)
- No RAISERROR after the result set (unlike `WithdrawToFundingProcessBatch` which raises one) - caller must detect failures from result set

### 2.2 Auto-Detect Current Status

**What**: When CashoutStatusID is not provided in the TVP, reads the actual current status from the WTF record.

**Columns/Parameters Involved**: `CashoutStatusID` (TVP column), `Billing.WithdrawToFunding.CashoutStatusID`

**Rules**:
- `SET @CashoutStatusID = IIF(@CashoutStatusID IS NULL, (SELECT CashoutStatusID FROM Billing.WithdrawToFunding WHERE ID=@ID), @CashoutStatusID)`
- If `@CashoutStatusID IS NULL`: live read from `Billing.WithdrawToFunding` provides the current value
- If provided: used as-is (passed to the underlying SP which validates it matches the actual record)
- This reduces the burden on callers who just want to specify the target status

### 2.3 Single-Row Delegation

**What**: Each WTF transition is delegated to `WithdrawToFundingUpdateCashoutStatus`.

**Rules**:
- `EXEC [Billing].[WithdrawToFundingUpdateCashoutStatus] @ID, @ManagerID, @Remark, @CashoutStatusID, @NewCashoutStatusID`
- All validation logic (allowed transitions, pessimistic lock, history) is in the called SP
- If the transition is invalid (e.g., wrong current status or forbidden transition), it throws -> caught by CATCH -> ID added to @Errors

**Diagram**:
```
EXEC WithdrawToFundingUpdateCashoutStatusForBatch(@tbl):
  CURSOR over @tbl (TBL_CashoutStatusInfo):
    FETCH -> @ID, @ManagerID, @Remark, @CashoutStatusID, @NewCashoutStatusID

    TRY:
      @CashoutStatusID = IIF(@CashoutStatusID IS NULL,
                             (SELECT CashoutStatusID FROM WTF WHERE ID=@ID),
                             @CashoutStatusID)
      EXEC WithdrawToFundingUpdateCashoutStatus(@ID, @ManagerID, @Remark,
           @CashoutStatusID, @NewCashoutStatusID)
      -> validates transition, acquires lock, sets NewCashoutStatusID + history
    CATCH:
      INSERT @Errors(ID)  -- capture failure, continue

  SELECT ID FROM @Errors  -- empty = full success
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @tbl | Billing.TBL_CashoutStatusInfo | NO | - | CODE-BACKED | Input TVP (READONLY). Each row: ID (`Billing.WithdrawToFunding.ID`), ManagerID, Remark, CashoutStatusID (expected current status - NULL triggers auto-detect), NewCashoutStatusID (target status). See [Billing.TBL_CashoutStatusInfo](../User Defined Types/Billing.TBL_CashoutStatusInfo.md). **Note**: in this SP's context, `ID` = WTF leg ID, not `Billing.Withdraw.WithdrawID` as in other TBL_CashoutStatusInfo consumers. |
| 2 | ID (output) | int | NO | - | CODE-BACKED | Output result set column. `Billing.WithdrawToFunding.ID` of each failed row. Empty result = full success. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @tbl | Billing.TBL_CashoutStatusInfo | TVP Type | Input batch row structure |
| (auto-detect read) | Billing.WithdrawToFunding | Read | Auto-detects current CashoutStatusID when not provided in TVP |
| (EXEC per row) | Billing.WithdrawToFundingUpdateCashoutStatus | Procedure call (cursor loop) | Validates and applies each status transition with history |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from application code (bulk status transitions in back-office and STP flows).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawToFundingUpdateCashoutStatusForBatch (procedure)
|- Billing.TBL_CashoutStatusInfo (type) -- TVP input
|- Billing.WithdrawToFunding (table) -- auto-detect current status read
+-- Billing.WithdrawToFundingUpdateCashoutStatus (procedure) -- per-row transition
      |- Billing.WithdrawToFunding (table) -- guard + lock + update
      |- Dictionary.CashoutStatus (table) -- error messages
      +-- Billing.UpdateWithdraw2Funding (procedure) -- write + history
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.TBL_CashoutStatusInfo | User Defined Type | READONLY TVP input type |
| Billing.WithdrawToFunding | Table | Auto-detect current CashoutStatusID for NULL TVP rows |
| Billing.WithdrawToFundingUpdateCashoutStatus | Stored Procedure | Validates and applies each individual WTF status transition |

### 6.2 Objects That Depend On This

No SQL callers found in SSDT repo. Called by application code.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Bulk advance PendingReview records to InProcess

```sql
DECLARE @Batch AS [Billing].[TBL_CashoutStatusInfo];
INSERT INTO @Batch (ID, ManagerID, Remark, CashoutStatusID, NewCashoutStatusID)
VALUES
    (11111, 999, 'Compliance cleared', 14, 2),  -- PendingReview -> InProcess
    (22222, 999, 'Compliance cleared', 14, 2),
    (33333, 999, 'Compliance cleared', NULL, 2); -- auto-detect current status

EXEC Billing.WithdrawToFundingUpdateCashoutStatusForBatch @tbl = @Batch;
-- Returns empty result on full success; IDs of failed rows otherwise
```

### 8.2 Check current statuses before batching

```sql
SELECT wtf.ID, wtf.CashoutStatusID, cs.Name AS StatusName
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
JOIN Dictionary.CashoutStatus cs WITH (NOLOCK) ON cs.CashoutStatusID = wtf.CashoutStatusID
WHERE wtf.ID IN (11111, 22222, 33333);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFundingUpdateCashoutStatusForBatch | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawToFundingUpdateCashoutStatusForBatch.sql*
