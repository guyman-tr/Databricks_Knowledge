# Billing.TBL_WithdrawToFundingProcessBatchV3

> V3 batch WTF processing TVP extending V2 with `MoveMoneyReasonID` for Money Movement compliance tracking; the active version used by `Billing.WithdrawToFundingProcessBatch`.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | User Defined Type |
| **Key Identifier** | (WithdrawID, FundingID, ID) - uniquely identifies one WTF record |
| **Partition** | N/A |
| **Indexes** | N/A - inline table type, no persistent indexes |

---

## 1. Business Meaning

`Billing.TBL_WithdrawToFundingProcessBatchV3` is the current (V3) table-valued parameter type for batch WithdrawToFunding processing. It is identical to `TBL_WithdrawToFundingProcessBatch` with one addition: `MoveMoneyReasonID`, which was added in April 2024 (MIMOPSA-12732, Kate M) and again referenced in August 2024 (MIMOPSA-13595, Itay H).

This type is the active batch processing TVP: `Billing.WithdrawToFundingProcessBatch` accepts `@tbl Billing.TBL_WithdrawToFundingProcessBatchV3 READONLY` and uses a cursor to iterate over each row, calling `Billing.WithdrawToFundingProcess` for each record. The V2 type (`TBL_WithdrawToFundingProcessBatch`) is retained for backward compatibility.

The `MoveMoneyReasonID` addition was driven by a Money Movement compliance requirement (MIMOPS project): certain withdrawal flows require categorizing the reason funds are being moved (e.g., local currency withdrawal vs. eToroMoney transfer vs. internal transfer), and this ID is passed through to `Customer.SetBalance` to properly categorize the account balance change.

---

## 2. Business Logic

### 2.1 MoveMoneyReasonID Categorization (V3 Addition)

**What**: Classifies the reason for the money movement associated with this withdrawal, used by downstream balance accounting.

**Columns/Parameters Involved**: `MoveMoneyReasonID`, `WithdrawID`, `FundingID`

**Rules**:
- `MoveMoneyReasonID` is passed to `WithdrawToFundingProcess @MoveMoneyReasonID`
- `WithdrawToFundingProcess` may override this value based on the withdrawal type:
  - If `FundingTypeID=33 (eToroMoney) AND FlowID=2 AND WithdrawTypeID=1`: overrides to `MoveMoneyReasonID=5`
  - If `FlowID=3 AND WithdrawTypeID=1`: overrides to `MoveMoneyReasonID=6`
- The final `MoveMoneyReasonID` is passed to `Customer.SetBalance @MoveMoneyReasonID` for balance accounting
- NULL = reason not specified; the SP may derive a value based on the withdrawal flow type

### 2.2 Batch Processing with Error Isolation

**What**: The cursor-based iteration in `WithdrawToFundingProcessBatch` processes each row independently, catching per-row errors without aborting the entire batch.

**Columns/Parameters Involved**: `ID`, `WithdrawID`, `FundingID` (error key)

**Rules**:
- `WithdrawToFundingProcessBatch` opens a CURSOR on the TVP
- Each row calls `WithdrawToFundingProcess` in a TRY/CATCH
- Failed rows are stored in `@Errors TABLE(ID INT NOT NULL)`
- After iteration, if `@Errors` has rows: returns the failed IDs and raises a non-terminating error
- The calling application uses the returned IDs to retry or log failures

**Diagram**:
```
WithdrawToFundingProcessBatch(@tbl TBL_WithdrawToFundingProcessBatchV3):
  CURSOR over @tbl:
    For each row:
      TRY: EXEC WithdrawToFundingProcess @WithdrawID, @FundingID, @ManagerID,
                 @Remark, @ID, @VerificationCode, @ProcessorValueDate,
                 @SessionID, @VendorCode, @MID, @RequestExecuteEntryMethodId,
                 @MoveMoneyReasonID
      CATCH: INSERT @Errors(ID)  -- log failure, continue batch
  SELECT ID FROM @Errors  -- return failed IDs to caller
  IF @@ROWCOUNT > 0: RAISERROR('partial failures')
```

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WithdrawID | int | NO | - | CODE-BACKED | ID of the parent withdrawal in `Billing.Withdraw`. |
| 2 | FundingID | int | NO | - | CODE-BACKED | ID of the funding record in `Billing.Funding`. |
| 3 | ManagerID | int | NO | - | CODE-BACKED | Manager processing the batch. -1 = billing service (preserve existing ManagerID). |
| 4 | Remark | varchar(255) | YES | NULL | CODE-BACKED | Optional processing note. Collation: Latin1_General_BIN. |
| 5 | ID | int | NO | - | CODE-BACKED | `Billing.WithdrawToFunding.ID` - the specific WTF payment leg record. This is the error key: failed rows are identified by `ID` in the `@Errors` table. |
| 6 | VerificationCode | varchar(50) | YES | NULL | CODE-BACKED | Provider authorization code for this payment. Collation: Latin1_General_BIN. |
| 7 | ProcessorValueDate | datetime | NO | - | CODE-BACKED | Value date from the payment processor. |
| 8 | VendorCode | nvarchar(250) | YES | NULL | CODE-BACKED | Provider transaction reference code. Collation: Latin1_General_BIN. |
| 9 | Mid | nvarchar(250) | YES | NULL | CODE-BACKED | Merchant ID (MID) string for routing. Resolved to `ProtocolMIDSettingsID` by `WithdrawToFundingProcess`. Collation: Latin1_General_BIN. |
| 10 | RequestExecuteEntryMethodId | int | YES | NULL | CODE-BACKED | Entry method identifier for the payment execution request. |
| 11 | MoveMoneyReasonID | int | YES | NULL (DEFAULT NULL) | CODE-BACKED | **V3 addition (MIMOPSA-12732, Apr 2024)**: Classification of the reason funds are being moved. Passed to `Customer.SetBalance @MoveMoneyReasonID`. May be overridden by `WithdrawToFundingProcess` based on withdrawal flow: 5=eToroMoney local currency withdrawal (FundingTypeID=33, FlowID=2), 6=specific FlowID=3 withdrawal type. |
| 12 | SessionID | bigint | YES | NULL | CODE-BACKED | Optional audit session identifier. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID | Billing.Withdraw | Implicit | Parent withdrawal |
| FundingID | Billing.Funding | Implicit | Payment instrument |
| ID | Billing.WithdrawToFunding | Implicit | Specific WTF record |
| Mid | Billing.ProtocolMIDSettings | Implicit | Resolved to ProtocolMIDSettingsID (ParameterID=52) |
| MoveMoneyReasonID | Customer.SetBalance | Implicit | Passed to SetBalance for balance accounting categorization |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.WithdrawToFundingProcessBatch | @tbl parameter | TVP Parameter | Primary consumer - cursor-iterates and calls WithdrawToFundingProcess per row |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFundingProcessBatch | Stored Procedure | Accepts as READONLY parameter; cursor loop calls WithdrawToFundingProcess for each row |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| MoveMoneyReasonID DEFAULT (NULL) | DEFAULT | MoveMoneyReasonID defaults to NULL if not provided, maintaining backward compatibility |

---

## 8. Sample Queries

### 8.1 Confirm V3 vs V2 type difference

```sql
SELECT
    tt.name AS TypeName,
    c.name AS ColumnName,
    t.name AS DataType,
    c.is_nullable
FROM sys.table_types tt WITH (NOLOCK)
JOIN sys.columns c WITH (NOLOCK) ON c.object_id = tt.type_table_object_id
JOIN sys.types t WITH (NOLOCK) ON t.user_type_id = c.user_type_id
WHERE tt.schema_id = SCHEMA_ID('Billing')
  AND tt.name IN ('TBL_WithdrawToFundingProcessBatch', 'TBL_WithdrawToFundingProcessBatchV3')
ORDER BY tt.name, c.column_id
```

### 8.2 View WTF records processed via batch (by MoveMoneyReason)

```sql
SELECT TOP 20
    wtf.ID,
    wtf.WithdrawID,
    w.FundingTypeID,
    w.FlowID,
    w.WithdrawTypeID,
    wtf.ModificationDate
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
JOIN Billing.Withdraw w WITH (NOLOCK) ON w.WithdrawID = wtf.WithdrawID
WHERE wtf.CashoutStatusID = 3
ORDER BY wtf.ModificationDate DESC
```

### 8.3 View batch processing errors from recent history

```sql
SELECT TOP 20
    wfa.BW2F_ID AS WTF_ID,
    wfa.WithdrawID,
    wfa.CashoutStatusID,
    wfa.ModificationDate,
    wfa.Remark
FROM History.WithdrawToFundingAction wfa WITH (NOLOCK)
WHERE wfa.CashoutActionStatusID != 2  -- Not processed successfully
ORDER BY wfa.ModificationDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.TBL_WithdrawToFundingProcessBatchV3 | Type: User Defined Type | Source: etoro/etoro/Billing/User Defined Types/Billing.TBL_WithdrawToFundingProcessBatchV3.sql*
