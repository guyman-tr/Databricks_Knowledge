# Billing.TBL_WithdrawToFundingProcess

> Table-valued parameter type carrying the core fields required to process a single WithdrawToFunding record, passed to `Billing.WithdrawToFundingProcess` and `Billing.WithdrawToFundingProcess_v2`.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | User Defined Type |
| **Key Identifier** | (WithdrawID, FundingID, ID) - uniquely identifies one WTF record |
| **Partition** | N/A |
| **Indexes** | N/A - inline table type, no persistent indexes |

---

## 1. Business Meaning

`Billing.TBL_WithdrawToFundingProcess` is a table-valued parameter (TVP) type used internally within `Billing.WithdrawToFundingProcess` to stage WithdrawToFunding (WTF) record updates. It captures the exact state to write when processing or partially processing a withdrawal against a specific funding instrument.

This type exists as part of the DBA-648 refactoring: `WithdrawToFundingProcess` declares local variables of `TBL_Withdraw2Funding` and `TBL_Withdraw` instead of issuing direct UPDATE statements, then calls `UpdateWithdraw2Funding` and `UpsertWithdraw` to perform the actual writes. `TBL_WithdrawToFundingProcess` is used when the processing logic needs to work with a reduced set of fields (the minimum required for processing a WTF record) without carrying the full 31-column `TBL_Withdraw2Funding` structure.

Data flows entirely within stored procedures: `WithdrawToFundingProcess` populates this type from its input parameters and the existing WTF record, then calls `UpdateWithdraw2Funding` to write the status change and history log.

---

## 2. Business Logic

### 2.1 WTF Processing Fields

**What**: Contains the essential identifiers and processing metadata to mark a WithdrawToFunding record as processed by a specific manager with a specific provider code.

**Columns/Parameters Involved**: `WithdrawID`, `FundingID`, `ID`, `ManagerID`, `VerificationCode`, `ProcessorValueDate`

**Rules**:
- `ID` is the specific WTF record (`Billing.WithdrawToFunding.ID`) being processed - used to identify which payment leg
- `VerificationCode` is the confirmation code returned by the payment provider
- `ProcessorValueDate` is the value date assigned by the payment processor; defaults to GETUTCDATE() if NULL
- `ManagerID` may be -1, in which case `WithdrawToFundingProcess` preserves the existing ManagerID from the WTF record (`@RelevantManagerID`)
- `SessionID` is optional audit context (bigint to handle high-volume session IDs)

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WithdrawID | int | NO | - | CODE-BACKED | Primary key of the parent withdrawal in `Billing.Withdraw`. Combined with FundingID and ID to uniquely identify the WTF record being processed. |
| 2 | FundingID | int | NO | - | CODE-BACKED | ID of the funding (payment instrument) record in `Billing.Funding`. Together with WithdrawID, identifies the payment leg. |
| 3 | ManagerID | int | NO | - | CODE-BACKED | Manager ID for the processing action. Special value -1 means the billing service is running the process and the existing ManagerID on the WTF record should be preserved (`Case When @ManagerID != -1 Then @ManagerID Else (Select ManagerID From Billing.WithdrawToFunding Where ID=@ID) End`). |
| 4 | Remark | varchar(255) | YES | NULL | CODE-BACKED | Optional processing note or reason. Passed through to history logging in `History.WithdrawToFundingAction`. Collation: Latin1_General_BIN. |
| 5 | ID | int | NO | - | CODE-BACKED | The specific `Billing.WithdrawToFunding.ID` (WTF record primary key) being processed. Used to lock and update the exact payment leg record. |
| 6 | VerificationCode | varchar(50) | YES | NULL | CODE-BACKED | Authorization or confirmation code from the payment provider confirming the transaction. Stored on the WTF record for reconciliation. Collation: Latin1_General_BIN. |
| 7 | ProcessorValueDate | datetime | NO | - | CODE-BACKED | Value date set by the payment processor - when the funds are considered transferred. `WithdrawToFundingProcess` sets this to GETUTCDATE() if NULL: `SET @ProcessorValueDate = ISNULL(@ProcessorValueDate, GETUTCDATE())`. |
| 8 | SessionID | bigint | YES | NULL | CODE-BACKED | Audit session identifier. Optional context for correlating the processing action to a specific user/service session. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID | Billing.Withdraw | Implicit | Parent withdrawal request |
| FundingID | Billing.Funding | Implicit | Payment instrument |
| ID | Billing.WithdrawToFunding | Implicit | Specific WTF record being processed |
| ManagerID | BackOffice.Manager | Implicit | Manager performing the processing action |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.WithdrawToFundingProcess | @InfoWTF (local, TBL_Withdraw2Funding) | TVP (local) | Used internally to stage WTF status transitions via UpdateWithdraw2Funding |
| Billing.WithdrawToFundingProcess_v2 | Local variable | TVP (local) | V2 processing path - same pattern |
| Billing.WithdrawToFundingProcessForBatch | @tbl parameter | TVP Parameter | Legacy batch input type - 8-column V1 row structure for cursor-based processing |

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
| Billing.WithdrawToFundingProcess | Stored Procedure | Declares local variable of this type to stage WTF status update before calling UpdateWithdraw2Funding |
| Billing.WithdrawToFundingProcess_v2 | Stored Procedure | Same pattern as v1 |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Inspect type column definitions

```sql
SELECT c.name, t.name AS type_name, c.max_length, c.is_nullable
FROM sys.table_types tt WITH (NOLOCK)
JOIN sys.columns c WITH (NOLOCK) ON c.object_id = tt.type_table_object_id
JOIN sys.types t WITH (NOLOCK) ON t.user_type_id = c.user_type_id
WHERE tt.schema_id = SCHEMA_ID('Billing')
  AND tt.name = 'TBL_WithdrawToFundingProcess'
ORDER BY c.column_id
```

### 8.2 View recently processed WTF records

```sql
SELECT TOP 20
    wtf.ID,
    wtf.WithdrawID,
    wtf.FundingID,
    wtf.CashoutStatusID,
    wtf.VerificationCode,
    wtf.ProcessorValueDate,
    wtf.ModificationDate,
    wtf.ManagerID
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
WHERE wtf.CashoutStatusID = 3  -- Processed
ORDER BY wtf.ModificationDate DESC
```

### 8.3 View WTF history for a specific withdrawal

```sql
SELECT
    wfa.BW2F_ID AS WTF_ID,
    wfa.WithdrawID,
    wfa.FundingID,
    wfa.CashoutStatusID,
    wfa.ManagerID,
    wfa.ModificationDate,
    wfa.Remark
FROM History.WithdrawToFundingAction wfa WITH (NOLOCK)
-- WHERE wfa.WithdrawID = @WithdrawID
ORDER BY wfa.ModificationDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.TBL_WithdrawToFundingProcess | Type: User Defined Type | Source: etoro/etoro/Billing/User Defined Types/Billing.TBL_WithdrawToFundingProcess.sql*
