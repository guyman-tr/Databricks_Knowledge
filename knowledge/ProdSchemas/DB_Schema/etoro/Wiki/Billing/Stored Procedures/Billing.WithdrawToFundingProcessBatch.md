# Billing.WithdrawToFundingProcessBatch

> Batch processor for WithdrawToFunding settlement - iterates a TVP of withdrawal-funding records via cursor, calling Billing.WithdrawToFundingProcess per row with per-row error isolation; returns the IDs of any rows that failed.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @tbl Billing.TBL_WithdrawToFundingProcessBatchV3 - the batch of WTF records to process |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the batch gateway for settling multiple withdrawal-to-funding legs in a single service call. When the Cashout Service needs to mark a set of WithdrawToFunding records as processed (e.g., after receiving a bulk confirmation from a payment processor), it assembles a TVP of WTF records and calls this procedure once rather than making individual `Billing.WithdrawToFundingProcess` calls per record.

The critical design choice is **per-row error isolation**: each record is processed inside an inner TRY/CATCH block, so a failure on one record (e.g., a constraint violation or a deadlock on a specific `WithdrawID`) does not abort the entire batch. Failed record IDs are collected in an `@Errors` table variable and returned to the caller as a result set. If any failures occurred, a non-fatal RAISERROR is also raised so the caller can detect the partial failure. This pattern lets the service retry only the failed subset rather than the entire batch.

The procedure was initially created in August 2020 (MIMOPS-1864, Shay Oren) and updated in July 2021 (MIMOPS-4536, Eliran BL). The `@MoveMoneyReasonID` parameter was added in April 2024 (MIMOPSA-12732, Kate M) and forwarding was fixed in August 2024 (MIMOPSA-13595, Itay H), reflecting the Money Movement compliance requirement to categorize balance changes by reason.

---

## 2. Business Logic

### 2.1 Cursor-Based Iteration with Per-Row Error Isolation

**What**: Processes each TVP row independently - a failure on any row does not abort processing of remaining rows.

**Columns/Parameters Involved**: `ID` (error key), `@Errors TABLE`, `@@FETCH_STATUS`

**Rules**:
- A CURSOR is opened over `@tbl` in the order rows appear
- Each row: calls `Billing.WithdrawToFundingProcess` with all column values from that row
- On CATCH: the row's `ID` is inserted into `@Errors` and iteration continues (no re-raise)
- After all rows: returns `SELECT ID FROM @Errors`
- If `@@ROWCOUNT > 0` (any failures): `RAISERROR('There were errors with some of the withdraws', 16, 0)` is raised
- The outer TRY/CATCH wraps the entire cursor; if the cursor itself fails (e.g., OPEN fails), that error propagates via THROW

**Diagram**:
```
EXEC WithdrawToFundingProcessBatch(@MoveMoneyReasonID, @tbl):
  CURSOR over @tbl rows:
    FETCH row -> @WithdrawID, @FundingID, @ManagerID, @Remark, @ID,
                 @VerificationCode, @ProcessorValueDate, @SessionID,
                 @VendorCode, @MID, @RequestExecuteEntryMethodId,
                 @MoveMoneyReasonID (overrides SP param per row)
    TRY:
      EXEC WithdrawToFundingProcess(@WithdrawID, @FundingID, @ManagerID,
           @Remark, @ID, @VerificationCode, @ProcessorValueDate,
           @SessionID, @VendorCode, @MID, @RequestExecuteEntryMethodId,
           @MoveMoneyReasonID)
      -> settles the WTF record, debits balance, triggers notifications
    CATCH:
      INSERT @Errors(ID = @ID)  -- capture failure, continue
  CLOSE/DEALLOCATE cursor
  SELECT ID FROM @Errors          -- return failed IDs (empty if all succeeded)
  IF any errors: RAISERROR(...)   -- signal partial batch failure
```

### 2.2 MoveMoneyReasonID Scoping - TVP Column Overrides SP Parameter

**What**: The SP-level `@MoveMoneyReasonID` parameter is overwritten per-row by the cursor FETCH from the TVP. The TVP column is the effective value for each row.

**Columns/Parameters Involved**: `@MoveMoneyReasonID` (SP parameter + FETCH target), `MoveMoneyReasonID` (TVP column)

**Rules**:
- `@MoveMoneyReasonID INT = NULL` is declared at SP level (default NULL)
- The CURSOR FETCH assigns `@tbl.MoveMoneyReasonID` -> `@MoveMoneyReasonID` for every row
- Whatever was passed as the SP-level parameter is irrelevant after the first FETCH
- Each call to `WithdrawToFundingProcess` uses the per-row TVP value
- `WithdrawToFundingProcess` may further override based on withdrawal type (FundingTypeID=33/FlowID=2 -> `MoveMoneyReasonID=5`; FlowID=3 -> `MoveMoneyReasonID=6`)

### 2.3 Error Return Contract

**What**: The procedure returns a result set of failed IDs and signals partial failure via RAISERROR.

**Columns/Parameters Involved**: `ID` (WTF record identifier), RAISERROR severity 16

**Rules**:
- Always returns a result set (empty on full success, rows on partial failure)
- RAISERROR severity 16 = user-correctable error (non-fatal to the connection)
- The caller is responsible for re-queuing or alerting on failed IDs
- `@GetNotifications TABLE(I INT)` captures the notification return value from each `WithdrawToFundingProcess` call (notification triggered internally)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MoveMoneyReasonID | int | YES | NULL | CODE-BACKED | Input parameter (SP-level). Initial money movement reason category. **Effectively overridden per-row** by the TVP's `MoveMoneyReasonID` column during cursor FETCH - this SP-level value is not used after the first FETCH. Added MIMOPSA-12732 (Apr 2024). |
| 2 | @tbl | Billing.TBL_WithdrawToFundingProcessBatchV3 | NO | - | CODE-BACKED | Input TVP (READONLY). V3 batch type carrying all WTF records to process. Contains: WithdrawID, FundingID, ManagerID, Remark, ID, VerificationCode, ProcessorValueDate, SessionID, VendorCode, Mid, RequestExecuteEntryMethodId, MoveMoneyReasonID. See [Billing.TBL_WithdrawToFundingProcessBatchV3](../User Defined Types/Billing.TBL_WithdrawToFundingProcessBatchV3.md). |
| 3 | ID (output) | int | NO | - | CODE-BACKED | Output result set column. The `Billing.WithdrawToFunding.ID` of each row that failed processing. Empty result set = full success. Non-empty = partial failure (use IDs to retry or alert). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @tbl | Billing.TBL_WithdrawToFundingProcessBatchV3 | TVP Type | V3 batch input type; each column mapped to local variables per cursor row |
| (EXEC per row) | Billing.WithdrawToFundingProcess | Procedure call (cursor loop) | Core settlement SP called once per TVP row; handles all WTF status updates, balance debits, and notifications |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from application code (Cashout Service bulk settlement flows).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawToFundingProcessBatch (procedure)
|- Billing.TBL_WithdrawToFundingProcessBatchV3 (type) -- TVP input
+-- Billing.WithdrawToFundingProcess (procedure) -- called per row
      +-- [see WithdrawToFundingProcess dependency chain]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.TBL_WithdrawToFundingProcessBatchV3 | User Defined Type | READONLY TVP parameter type - defines the batch row structure |
| Billing.WithdrawToFundingProcess | Stored Procedure | Called via INSERT...EXEC for each cursor row; performs the actual WTF settlement |

### 6.2 Objects That Depend On This

No SQL callers found in SSDT repo. Called by Cashout Service application code for bulk settlement.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute for a single-row batch (test/diagnostic)

```sql
DECLARE @Batch AS [Billing].[TBL_WithdrawToFundingProcessBatchV3];
INSERT INTO @Batch (WithdrawID, FundingID, ManagerID, ID, ProcessorValueDate)
VALUES (12345, 67890, -1, 999, GETUTCDATE());

EXEC Billing.WithdrawToFundingProcessBatch
    @MoveMoneyReasonID = NULL,
    @tbl = @Batch;
-- Returns empty result set on success; returns ID=999 on failure
```

### 8.2 Check for recent WTF batch processing errors via history

```sql
SELECT TOP 20
    wfa.BW2F_ID   AS WTF_ID,
    wfa.WithdrawID,
    wfa.CashoutStatusID,
    wfa.Remark,
    wfa.ModificationDate
FROM History.WithdrawToFundingAction wfa WITH (NOLOCK)
WHERE wfa.CashoutStatusID != 3  -- not processed
ORDER BY wfa.ModificationDate DESC;
```

### 8.3 Count of WTF records in process vs processed (batch health check)

```sql
SELECT
    CashoutStatusID,
    COUNT(*) AS RecordCount
FROM Billing.WithdrawToFunding WITH (NOLOCK)
WHERE ModificationDate >= DATEADD(HOUR, -1, GETUTCDATE())
GROUP BY CashoutStatusID
ORDER BY CashoutStatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFundingProcessBatch | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawToFundingProcessBatch.sql*
