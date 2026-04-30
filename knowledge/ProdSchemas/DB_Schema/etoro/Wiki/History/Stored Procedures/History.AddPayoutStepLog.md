# History.AddPayoutStepLog

> Payout (withdraw-to-funding) processing step logger: inserts one step log entry into History.PayoutStep (via synonym to DB_Logs), returning the new StepID. Simpler than its deposit counterpart - no recovery state side effects on other tables.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StepID OUTPUT (populated via OUTPUT clause from INSERT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.AddPayoutStepLog` is the payout workflow step logger. It writes to `History.PayoutStep` (a synonym for `DB_Logs.History.PayoutStep`), recording each step executed in the payout (withdraw-to-funding) processing pipeline. It is the payout-side counterpart to `History.AddDepositStepLog`, but with a simpler design: unlike its deposit counterpart, this procedure has no side effects on other tables - it is a pure append-only logger.

The key structural difference from `AddDepositStepLog` is that the foreign key parameter is `@TransactionID` which maps to `WithdrawToFundingID` in the target table (not `DepositID`). This reflects that payouts in eToro's system are tracked via `WithdrawToFundingID` transaction identifiers in the Billing schema.

The procedure was introduced on 2020-07-19 by Elrom for PAYIL-2799 (same ticket as AddDepositStepLog), with CorrelationID added in 2021-08-05 PAYIL-2860.

On failure, THROW re-propagates the exception. RETURN(-1) after THROW is unreachable.

---

## 2. Business Logic

### 2.1 Payout Step Audit Log

**What**: Each call inserts one step execution record for a payout transaction.

**Columns/Parameters Involved**: `@TransactionID`, `@Step`, `@StepStatus`, `@StepRetries`, `@StepID OUTPUT`

**Rules**:
- @TransactionID maps to WithdrawToFundingID in History.PayoutStep (different column name than DepositStep which uses DepositID)
- @StepStatus accepts text values ('Pass', 'Fail', etc.) - no integer enum
- No Billing table side effects (unlike AddDepositStepLog which updates Billing.Deposit.DRStatusID)
- No LastStatus lookup (unlike AddDepositStepLog which reads prior step status)
- @StepID OUTPUT is correctly populated via OUTPUT clause (unlike AddDepositFinalizationLog which has the bug of not returning the ID)
- No explicit BEGIN TRAN (simpler than AddDepositStepLog) - single INSERT operation

**Diagram**:
```
Payout transaction #67890 processing:
    Step "InitiateTransfer" -> AddPayoutStepLog(@TransactionID=67890, @Step="InitiateTransfer", @StepStatus="Pass")
    Step "FundingCallback"  -> AddPayoutStepLog(@TransactionID=67890, @Step="FundingCallback", @StepStatus="Fail", @Error="Timeout")
    Step "FundingCallback"  -> AddPayoutStepLog(@TransactionID=67890, @Step="FundingCallback", @StepStatus="Pass", @StepRetries=1)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StepID | int OUTPUT | YES | - | CODE-BACKED | OUTPUT parameter for the new step row ID. Correctly implemented via `OUTPUT INSERTED.StepID INTO @Out` followed by `SELECT TOP 1 @StepID = ID FROM @Out`. Returns the IDENTITY value generated for the new row. |
| 2 | @TransactionID | int | NO | - | CODE-BACKED | Payout transaction ID. Maps to WithdrawToFundingID in History.PayoutStep (the FK to the payout transaction in the Billing schema). Note: the parameter is named @TransactionID but the column is WithdrawToFundingID - the mapping is explicit in the INSERT statement. |
| 3 | @InitiateRequest | nvarchar(max) | YES | N'' | CODE-BACKED | Full request payload for this payout processing step. Stored in History.PayoutStep.InitiateRequest. Defaults to empty string. Enables replay and debugging of failed payout steps. |
| 4 | @Step | nvarchar(100) | NO | - | CODE-BACKED | Name of the payout processing step (e.g., "InitiateTransfer", "FundingCallback", "SendNotification"). Free-text step name defined by the calling application. |
| 5 | @StepStatus | nvarchar(20) | NO | - | CODE-BACKED | Outcome of this payout step. Free-text (e.g., 'Pass', 'Fail'). Unlike AddDepositStepLog, status values here do NOT drive DRStatusID updates - this is a pure audit field. |
| 6 | @StepRetries | int | NO | - | CODE-BACKED | Number of retries for this step before reaching the logged outcome. 0 = no retries needed. |
| 7 | @Error | nvarchar(max) | YES | N'' | CODE-BACKED | Error details when @StepStatus indicates failure. Empty string on success. |
| 8 | @Created | datetime | YES | NULL | CODE-BACKED | Step execution timestamp. Defaults to GETUTCDATE() via COALESCE(@Created, GETUTCDATE()) in the INSERT. UTC (unlike AddDepositStepLog which uses GETDATE()). |
| 9 | @Comment | nvarchar(max) | YES | N'' | CODE-BACKED | Optional free-text notes about this step. |
| 10 | @CorrelationID | nvarchar(50) | YES | N'' | CODE-BACKED | Distributed tracing ID added in PAYIL-2860 (2021-08-05). Correlates this log entry with the originating service request. Stored in History.PayoutStep.CorrelationID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TransactionID + all params | History.PayoutStep (via synonym) | Write target | Inserts one step log row per payout processing step execution |
| @TransactionID | Billing schema (WithdrawToFunding) | Implicit | @TransactionID represents a WithdrawToFundingID in the Billing schema |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payout processing service | (application call) | Application | Called for each step in the payout workflow. No SSDT procedures call this. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.AddPayoutStepLog (procedure)
└── History.PayoutStep (synonym -> DB_Logs.History.PayoutStep)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PayoutStep | Synonym -> Table (DB_Logs) | INSERT target - one step row per payout workflow step |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payout processing service | Application | Calls for each step in the payout processing workflow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. No explicit BEGIN TRAN (single-statement INSERT). On CATCH: THROW (re-propagates); RETURN(-1) is unreachable after THROW. Timestamp uses GETUTCDATE() (unlike deposit counterpart which uses GETDATE()).

---

## 8. Sample Queries

### 8.1 Find payout step logs for a specific transaction

```sql
SELECT TOP 20
    StepID,
    WithdrawToFundingID,
    Step,
    StepStatus,
    StepRetries,
    Error,
    Created,
    CorrelationID
FROM History.PayoutStep WITH (NOLOCK)
WHERE WithdrawToFundingID = 67890
ORDER BY Created ASC
```

### 8.2 Find recent failed payout steps

```sql
SELECT TOP 20
    StepID,
    WithdrawToFundingID,
    Step,
    StepRetries,
    Error,
    Created
FROM History.PayoutStep WITH (NOLOCK)
WHERE StepStatus = 'Fail'
ORDER BY Created DESC
```

### 8.3 Count payout step outcomes by step name

```sql
SELECT
    Step,
    StepStatus,
    COUNT(*) AS Count,
    AVG(CAST(StepRetries AS FLOAT)) AS AvgRetries
FROM History.PayoutStep WITH (NOLOCK)
GROUP BY Step, StepStatus
ORDER BY Step, StepStatus
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 applicable (Phase 9B: no app code match)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: History.AddPayoutStepLog | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.AddPayoutStepLog.sql*
