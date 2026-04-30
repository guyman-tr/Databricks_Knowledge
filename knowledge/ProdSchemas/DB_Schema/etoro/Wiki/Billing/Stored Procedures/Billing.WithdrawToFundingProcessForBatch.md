# Billing.WithdrawToFundingProcessForBatch

> Legacy batch processor for WithdrawToFunding settlement - cursor-iterates the V1 TVP calling Billing.WithdrawToFundingProcess per row with per-row error isolation; predecessor to WithdrawToFundingProcessBatch which uses the V3 TVP with MoveMoneyReasonID.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @tbl Billing.TBL_WithdrawToFundingProcess - the batch of WTF records to settle |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the original batch gateway for settling multiple WithdrawToFunding records in one service call. It is functionally identical to `Billing.WithdrawToFundingProcessBatch` but uses the older `Billing.TBL_WithdrawToFundingProcess` TVP type (8 columns, no `MoveMoneyReasonID`, `VendorCode`, `MID`, or `RequestExecuteEntryMethodId`).

Both procedures exist because the V3 batch type (`TBL_WithdrawToFundingProcessBatchV3`) was introduced in 2024 (MIMOPSA-12732) when Money Movement compliance required categorizing balance changes by reason. The V3 type and `WithdrawToFundingProcessBatch` were added for new flows; this procedure is retained for callers that still use the older V1 type and do not require the additional fields.

The same per-row error isolation design applies: each cursor row is processed in a TRY/CATCH; failures are collected in `@Errors`; failed IDs are returned as a result set; RAISERROR is raised if any failures occurred. The inline comment in the DDL explicitly documents the `@GetNotifications` table variable pattern: "Sometimes when we activate the inner procedure ([Billing].[WithdrawToFundingProcess]) we get resultsets from the inner procedures that interferes with the resultsets of this procedure. In order to stop it, I created this table and then I execute the procedure with insert statement."

---

## 2. Business Logic

### 2.1 Cursor-Based Iteration with Per-Row Error Isolation

**What**: Processes each V1 TVP row independently - errors on any row do not abort the batch.

**Columns/Parameters Involved**: `ID` (error key), `@Errors TABLE`, `@@FETCH_STATUS`

**Rules**:
- CURSOR opened over `@tbl` columns: WithdrawID, FundingID, ManagerID, Remark, ID, VerificationCode, ProcessorValueDate, SessionID
- Each row: calls `Billing.WithdrawToFundingProcess` with positional parameters (8 args, no MoveMoneyReasonID/VendorCode/MID)
- On CATCH: `ID` inserted into `@Errors`, iteration continues
- After cursor: `SELECT ID FROM @Errors` returned
- If `@@ROWCOUNT > 0`: `RAISERROR('There were errors with some of the withdraws', 16, 0)` raised

**Diagram**:
```
EXEC WithdrawToFundingProcessForBatch(@tbl):
  CURSOR over @tbl (TBL_WithdrawToFundingProcess - 8 columns):
    FETCH -> @WithdrawID, @FundingID, @ManagerID, @Remark, @ID,
             @VerificationCode, @ProcessorValueDate, @SessionID
    TRY:
      INSERT @GetNotifications  <- suppresses inner procedure resultsets
      EXEC WithdrawToFundingProcess(@WithdrawID, @FundingID, @ManagerID,
           @Remark, @ID, @VerificationCode, @ProcessorValueDate, @SessionID)
      -> settles WTF record, debits balance, triggers notifications
    CATCH:
      INSERT @Errors(ID)
  SELECT ID FROM @Errors          -- empty = success, non-empty = partial failure
  IF errors: RAISERROR(...)
```

### 2.2 Resultset Suppression via INSERT...EXEC

**What**: The `@GetNotifications TABLE(I INT)` captures return values from `WithdrawToFundingProcess` to prevent inner procedure result sets from reaching the client.

**Columns/Parameters Involved**: `@GetNotifications`, `INSERT...EXEC`

**Rules**:
- `WithdrawToFundingProcess` internally executes procedures that return rows (notification triggers)
- If `WithdrawToFundingProcess` were called directly (EXEC without INSERT), those rows would be returned to the client, interfering with the error result set from this procedure
- The `INSERT INTO @GetNotifications ... EXEC` pattern swallows the inner result set
- Only `SELECT ID FROM @Errors` reaches the client

### 2.3 Difference from WithdrawToFundingProcessBatch (V3)

**What**: This procedure is functionally equivalent but uses the V1 TVP type, which lacks the newer fields added in 2024.

**Rules**:
- V1 TVP (`TBL_WithdrawToFundingProcess`): 8 columns - WithdrawID, FundingID, ManagerID, Remark, ID, VerificationCode, ProcessorValueDate, SessionID
- V3 TVP (`TBL_WithdrawToFundingProcessBatchV3`): 12 columns - adds VendorCode, Mid, RequestExecuteEntryMethodId, MoveMoneyReasonID
- This procedure passes only 8 positional args to `WithdrawToFundingProcess` (remaining default to NULL)
- No SP-level `@MoveMoneyReasonID` parameter - callers using this procedure cannot specify money movement reason

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @tbl | Billing.TBL_WithdrawToFundingProcess | NO | - | CODE-BACKED | Input TVP (READONLY). V1 batch type with 8 columns: WithdrawID, FundingID, ManagerID, Remark, ID, VerificationCode, ProcessorValueDate, SessionID. Lacks MoveMoneyReasonID/VendorCode/MID columns present in V3. See [Billing.TBL_WithdrawToFundingProcess](../User Defined Types/Billing.TBL_WithdrawToFundingProcess.md). |
| 2 | ID (output) | int | NO | - | CODE-BACKED | Output result set column. `Billing.WithdrawToFunding.ID` of each row that failed. Empty result set = full batch success. Non-empty = partial failure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @tbl | Billing.TBL_WithdrawToFundingProcess | TVP Type | V1 input type; 8 columns per batch row |
| (EXEC per row) | Billing.WithdrawToFundingProcess | Procedure call (cursor loop) | Core settlement SP called once per TVP row with 8 positional args |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from application code (legacy Cashout Service flows using V1 TVP).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawToFundingProcessForBatch (procedure)
|- Billing.TBL_WithdrawToFundingProcess (type) -- TVP input (V1)
+-- Billing.WithdrawToFundingProcess (procedure) -- called per row
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.TBL_WithdrawToFundingProcess | User Defined Type | READONLY TVP parameter type - V1 batch row structure |
| Billing.WithdrawToFundingProcess | Stored Procedure | Called via INSERT...EXEC per cursor row; performs WTF settlement |

### 6.2 Objects That Depend On This

No SQL callers found in SSDT repo. Called by legacy application code paths.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute for a single-row batch (legacy caller pattern)

```sql
DECLARE @Batch AS [Billing].[TBL_WithdrawToFundingProcess];
INSERT INTO @Batch (WithdrawID, FundingID, ManagerID, ID, ProcessorValueDate)
VALUES (12345, 67890, -1, 999, GETUTCDATE());

EXEC Billing.WithdrawToFundingProcessForBatch @tbl = @Batch;
-- Returns empty result set on success; ID=999 on failure
```

### 8.2 Compare V1 vs V3 TVP type columns

```sql
SELECT tt.name AS TypeName, c.column_id, c.name AS ColumnName, t.name AS DataType
FROM sys.table_types tt WITH (NOLOCK)
JOIN sys.columns c WITH (NOLOCK) ON c.object_id = tt.type_table_object_id
JOIN sys.types t WITH (NOLOCK) ON t.user_type_id = c.user_type_id
WHERE tt.schema_id = SCHEMA_ID('Billing')
  AND tt.name IN ('TBL_WithdrawToFundingProcess', 'TBL_WithdrawToFundingProcessBatchV3')
ORDER BY tt.name, c.column_id;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFundingProcessForBatch | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawToFundingProcessForBatch.sql*
