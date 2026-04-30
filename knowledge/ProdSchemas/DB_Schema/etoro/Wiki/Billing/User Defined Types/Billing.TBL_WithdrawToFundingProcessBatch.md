# Billing.TBL_WithdrawToFundingProcessBatch

> Table-valued parameter type extending the single-process WTF type with VendorCode, MID, and entry method fields for batch withdrawal processing, used by `Billing.WithdrawToFundingProcessForBatch`.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | User Defined Type |
| **Key Identifier** | (WithdrawID, FundingID, ID) - uniquely identifies one WTF record |
| **Partition** | N/A |
| **Indexes** | N/A - inline table type, no persistent indexes |

---

## 1. Business Meaning

`Billing.TBL_WithdrawToFundingProcessBatch` is a table-valued parameter (TVP) type that extends `TBL_WithdrawToFundingProcess` with three additional fields needed for batch payment processing: `VendorCode` (provider transaction reference), `Mid` (Merchant ID for routing), and `RequestExecuteEntryMethodId` (payment entry method). Each row represents one withdrawal-to-funding record to be processed in a single batch run.

This type exists because batch processing (via `Billing.WithdrawToFundingProcessForBatch`) needs to pass provider-specific routing data (MID and VendorCode) alongside the standard processing fields. The V3 successor (`TBL_WithdrawToFundingProcessBatchV3`) additionally carries `MoveMoneyReasonID`, which was added in April 2024.

Data flows from the payment orchestration service: a batch processing job assembles a set of WTF records into this TVP and calls `WithdrawToFundingProcessForBatch`, which iterates over the rows using a cursor and calls `WithdrawToFundingProcess` for each individual record.

---

## 2. Business Logic

### 2.1 Batch Processing Pattern

**What**: Enables multiple WTF records to be processed in a single stored procedure call, with the procedure iterating over each row and processing them individually.

**Columns/Parameters Involved**: `WithdrawID`, `FundingID`, `ID`, `ManagerID`, all fields

**Rules**:
- The consumer (`WithdrawToFundingProcessForBatch`) uses a CURSOR to iterate over each row in the TVP
- Each row is processed by calling `Billing.WithdrawToFundingProcess` with the row's individual field values
- Processing errors for individual rows are caught and stored in an `@Errors` table, allowing partial batch success
- The SP returns the failed `ID` values so the caller can retry or handle errors
- Session-level: the TVP is passed READONLY to the procedure

### 2.2 MID Routing Fields

**What**: The VendorCode and Mid fields enable provider-specific routing for each WTF record in the batch.

**Columns/Parameters Involved**: `VendorCode`, `Mid`, `ProtocolMIDSettingsID`

**Rules**:
- `Mid` (Merchant ID) is passed to `WithdrawToFundingProcess` which resolves it to a `ProtocolMIDSettingsID` via `Billing.ProtocolMIDSettings`
- `VendorCode` is the provider's transaction reference for this payment leg
- Added in `Billing.WithdrawToFundingProcess` comment: "Eliran BL 07/07/2021 Adding MID Parameter MIMOPS-4536"

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WithdrawID | int | NO | - | CODE-BACKED | ID of the parent withdrawal in `Billing.Withdraw`. Part of the WTF record identifier. |
| 2 | FundingID | int | NO | - | CODE-BACKED | ID of the funding (payment instrument) in `Billing.Funding`. Combined with WithdrawID to identify the payment leg. |
| 3 | ManagerID | int | NO | - | CODE-BACKED | Manager processing the batch. -1 = billing service (preserve existing ManagerID on WTF record). |
| 4 | Remark | varchar(255) | YES | NULL | CODE-BACKED | Optional processing note passed to `WithdrawToFundingProcess` and stored in history. Collation: Latin1_General_BIN. |
| 5 | ID | int | NO | - | CODE-BACKED | Primary key of the specific `Billing.WithdrawToFunding` record. The CURSOR in `WithdrawToFundingProcessForBatch` iterates on this to call `WithdrawToFundingProcess @ID=@ID`. |
| 6 | VerificationCode | varchar(50) | YES | NULL | CODE-BACKED | Provider authorization code for this payment leg. Collation: Latin1_General_BIN. |
| 7 | ProcessorValueDate | datetime | NO | - | CODE-BACKED | Value date from the payment processor. Passed directly to `WithdrawToFundingProcess`. |
| 8 | VendorCode | nvarchar(250) | YES | NULL | CODE-BACKED | Payment provider's transaction reference code. Passed to `WithdrawToFundingProcess @VendorCode` for storage on the WTF record. Collation: Latin1_General_BIN. |
| 9 | Mid | nvarchar(250) | YES | NULL | CODE-BACKED | Merchant ID (MID) string for routing. Passed to `WithdrawToFundingProcess @MID` where it is resolved to `ProtocolMIDSettingsID` via `Billing.ProtocolMIDSettings WHERE Value=@MID AND ParameterID=52`. Collation: Latin1_General_BIN. |
| 10 | RequestExecuteEntryMethodId | int | YES | NULL | CODE-BACKED | Entry method identifier for the payment execution request (e.g., online, recurring, batch mode). Passed to `WithdrawToFundingProcess @RequestExecuteEntryMethodId`. |
| 11 | SessionID | bigint | YES | NULL | CODE-BACKED | Optional audit session identifier for correlating the batch processing action. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID | Billing.Withdraw | Implicit | Parent withdrawal request |
| FundingID | Billing.Funding | Implicit | Payment instrument |
| ID | Billing.WithdrawToFunding | Implicit | Specific WTF record to process |
| Mid | Billing.ProtocolMIDSettings | Implicit | Resolved to ProtocolMIDSettingsID by WithdrawToFundingProcess (VALUE match, ParameterID=52) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.WithdrawToFundingProcessForBatch | Parameter | TVP Parameter | Iterates over rows via CURSOR; calls WithdrawToFundingProcess for each |

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
| Billing.WithdrawToFundingProcessForBatch | Stored Procedure | Receives as READONLY TVP; cursor-iterates and calls WithdrawToFundingProcess per row |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Compare type columns vs V3 type

```sql
SELECT
    tt.name AS type_name,
    c.column_id,
    c.name AS column_name,
    t.name AS data_type
FROM sys.table_types tt WITH (NOLOCK)
JOIN sys.columns c WITH (NOLOCK) ON c.object_id = tt.type_table_object_id
JOIN sys.types t WITH (NOLOCK) ON t.user_type_id = c.user_type_id
WHERE tt.schema_id = SCHEMA_ID('Billing')
  AND tt.name IN ('TBL_WithdrawToFundingProcessBatch', 'TBL_WithdrawToFundingProcessBatchV3')
ORDER BY tt.name, c.column_id
```

### 8.2 View batch processing history

```sql
SELECT TOP 20
    wfa.BW2F_ID AS WTF_ID,
    wfa.WithdrawID,
    wfa.FundingID,
    wfa.CashoutStatusID,
    wfa.ManagerID,
    wfa.ModificationDate,
    wfa.AdditionalInformation,
    wfa.VendorCode
FROM History.WithdrawToFundingAction wfa WITH (NOLOCK)
WHERE wfa.CashoutStatusID = 3  -- Processed
ORDER BY wfa.ModificationDate DESC
```

### 8.3 Find MID settings used in batch processing

```sql
SELECT
    pms.ID AS ProtocolMIDSettingsID,
    pms.Value AS MID,
    pms.ParameterID
FROM Billing.ProtocolMIDSettings pms WITH (NOLOCK)
WHERE pms.ParameterID = 52
ORDER BY pms.ID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.TBL_WithdrawToFundingProcessBatch | Type: User Defined Type | Source: etoro/etoro/Billing/User Defined Types/Billing.TBL_WithdrawToFundingProcessBatch.sql*
