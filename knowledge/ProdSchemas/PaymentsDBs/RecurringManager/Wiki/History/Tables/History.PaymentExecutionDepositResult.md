# History.PaymentExecutionDepositResult

> Temporal history table storing previous versions of deposit result records that capture the outcome of each recurring payment charge attempt as returned by the billing/payment provider.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PaymentExecutionDepositResultId (mirrors PK of Recurring.PaymentExecutionDepositResult) |
| **Partition** | No |
| **Indexes** | 1 clustered (SysEndTime, SysStartTime) |

---

## 1. Business Meaning

History.PaymentExecutionDepositResult is the system-versioned temporal history table for `Recurring.PaymentExecutionDepositResult`. Each row represents a previous state of a deposit result - the concrete financial outcome returned by the billing/payment provider when a recurring charge is attempted. This table captures the provider's response details: the deposit ID, payment status code, execution result (success/soft-decline/hard-decline), the amount in USD, and the provider's status code.

This table exists to provide an audit trail of billing provider responses. When a deposit result is updated (e.g., a pending result resolves to declined, or a result is corrected), the previous version is preserved. This is critical for financial reconciliation, billing provider dispute resolution, and understanding the decline patterns that drive dunning logic.

Data enters this table automatically via SQL Server's temporal mechanism. Deposit results are created and updated by `Recurring.UpsertPaymentExecutionDepositResult` (upsert by PaymentExecutionId + CycleNumber). Each update to the billing result moves the old version here. With 26K+ rows, the history captures result updates as the billing provider's response progresses.

---

## 2. Business Logic

### 2.1 Deposit Result Upsert Pattern

**What**: One deposit result per payment execution per cycle, managed via an upsert pattern.

**Columns/Parameters Involved**: `PaymentExecutionId`, `CycleNumber`

**Rules**:
- `Recurring.UpsertPaymentExecutionDepositResult` checks `WHERE PaymentExecutionId = @PaymentExecutionId AND CycleNumber = @CycleNumber`
- If exists: UPDATE all result fields (DepositId, PaymentStatusId, StatusCode, GroupKey, ExecutionResultStatusId, PaymentDate, AmountInUsd)
- If not exists: INSERT with CreateDate and ModificationDate set to GETUTCDATE()
- This ensures exactly one result record per execution cycle, with updates replacing the previous state

### 2.2 Execution Result Classification

**What**: Provider responses are classified into three buckets that drive the dunning/retry logic.

**Columns/Parameters Involved**: `ExecutionResultStatusId`, `PaymentStatusId`, `StatusCode`, `GroupKey`

**Rules**:
- ExecutionResultStatusId maps to Dictionary.ExecutionResultStatus: 1=Success, 2=SoftDecline, 3=HardDecline. See [Execution Result Status](../../_glossary.md#execution-result-status)
- History distribution: HardDecline 60%, SoftDecline 40%, Success <1% - history captures mostly decline results (successful results are rarely updated)
- PaymentStatusId is a provider-specific status. Observed values: 3 (99%), 4 (<1%), 13 (<1%), 2 (<1%) - these are external billing provider status codes, not Dictionary.PaymentExecutionStatus values
- StatusCode is the raw provider response code (e.g., 3379, 3377) - provider-specific error codes for decline reasons
- GroupKey classifies the provider response category ("A" or "B" observed) - possibly provider-specific grouping for soft/hard decline classification

---

## 3. Data Overview

| PaymentExecutionDepositResultId | PaymentExecutionId | AmountInUsd | ExecutionResultStatusId | StatusCode | GroupKey | Meaning |
|---|---|---|---|---|---|---|
| 102401 | 548075 | 0 | 3 | 3379 | B | Hard-declined deposit result with provider status code 3379. AmountInUsd=0 indicates no funds were collected. GroupKey "B" may classify the decline reason category. |
| 102406 | 555347 | 0 | 3 | 3377 | A | Hard-declined with a different status code (3377) and GroupKey "A" - shows multiple decline reason categories from the billing provider. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentExecutionDepositResultId | int | NO | - | CODE-BACKED | Mirrors the IDENTITY PK of Recurring.PaymentExecutionDepositResult. Identifies which deposit result this historical version belongs to. |
| 2 | PaymentExecutionId | int | NO | - | VERIFIED | References the payment execution this result belongs to. Links to Recurring.PaymentExecution / History.PaymentExecution. Part of the composite upsert key (with CycleNumber). Indexed in the base table (IX_PaymentExecutionDepositResult_PaymentExecutionId). |
| 3 | CycleNumber | int | NO | - | CODE-BACKED | The recurring payment cycle number this result corresponds to. Part of the composite upsert key (with PaymentExecutionId). Matches the CycleNumber from PaymentExecution, linking the result to a specific charge period. |
| 4 | AmountInUsd | money | NO | 0 | CODE-BACKED | The deposit amount in US dollars as reported by the billing provider. Default: 0 in UpsertPaymentExecutionDepositResult. All sample history rows show 0, indicating declined transactions where no funds were collected. Non-zero values would appear for successful or partially successful charges. |
| 5 | DepositId | int | NO | - | CODE-BACKED | External identifier from the billing/payment provider's system referencing the deposit transaction. Links to the provider's transaction record for reconciliation purposes. Updated on each upsert. |
| 6 | PaymentStatusId | int | NO | - | CODE-BACKED | Provider-specific payment status code. Observed values: 3 (99%), 4 (<1%), 13 (<1%), 2 (<1%). These are NOT Dictionary.PaymentExecutionStatus values - they are external billing provider status codes that classify the payment outcome from the provider's perspective. |
| 7 | StatusCode | int | YES | - | CODE-BACKED | Raw response code from the billing/payment provider indicating the specific decline or approval reason. Observed values: 3379, 3377. Provider-specific - maps to the provider's error code catalog. Used for diagnosing specific decline reasons beyond the broad ExecutionResultStatusId classification. |
| 8 | GroupKey | nvarchar(10) | YES | - | CODE-BACKED | Provider response category classifier. Observed values: "A" and "B". Likely categorizes decline reasons into groups for the dunning/retry logic (e.g., Group A = one type of decline, Group B = another). Provider-specific grouping. |
| 9 | ExecutionResultStatusId | int | NO | - | VERIFIED | Classifies the deposit outcome. Maps to Dictionary.ExecutionResultStatus: 1=Success, 2=SoftDecline, 3=HardDecline. See [Execution Result Status](../../_glossary.md#execution-result-status). Drives dunning decisions: SoftDecline triggers retries, HardDecline terminates. History shows 60% HardDecline, 40% SoftDecline (successful results are rarely updated). (Dictionary.ExecutionResultStatus) |
| 10 | PaymentDate | datetime | YES | - | CODE-BACKED | Timestamp when the billing provider processed the payment. Represents the provider's processing time, not the system's record creation time. May differ from CreateDate if there's a delay between provider processing and result recording. |
| 11 | CreateDate | datetime | NO | - | CODE-BACKED | Timestamp when the deposit result record was created in the system. Set to GETUTCDATE() by UpsertPaymentExecutionDepositResult on INSERT. Immutable after creation. |
| 12 | ModificationDate | datetime | NO | - | CODE-BACKED | Timestamp of the most recent update to the result. Set to GETUTCDATE() by UpsertPaymentExecutionDepositResult on both INSERT and UPDATE operations. |
| 13 | SysStartTime | datetime2(7) | NO | - | VERIFIED | System-managed temporal column. Part of the clustered index. |
| 14 | SysEndTime | datetime2(7) | NO | - | VERIFIED | System-managed temporal column. Part of the clustered index. Sub-second gaps indicate rapid result updates. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | Recurring.PaymentExecutionDepositResult | Temporal History | This is the system-versioned history table |
| PaymentExecutionId | Recurring.PaymentExecution / History.PaymentExecution | Implicit FK | The execution this result belongs to |
| ExecutionResultStatusId | Dictionary.ExecutionResultStatus | Implicit Lookup | Outcome: 1=Success, 2=SoftDecline, 3=HardDecline |
| DepositId | External (Billing provider) | Implicit FK | The provider's deposit transaction record |

### 5.2 Referenced By (other objects point to this)

No objects reference this history table directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Recurring.PaymentExecutionDepositResult | Table | This is the temporal history table (SYSTEM_VERSIONING = ON) |
| Recurring.UpsertPaymentExecutionDepositResult | Stored Procedure | WRITER/MODIFIER - upserts deposit results by (PaymentExecutionId, CycleNumber) |
| Recurring.GetResultsByPaymentExecution | Stored Procedure | READER - retrieves results for an execution |
| Recurring.GetPaymentExecutionsResultsForPayment | Stored Procedure | READER - retrieves results for a payment |
| Recurring.GetPaymentExecutionsDepositsResultByCid | Stored Procedure | READER - retrieves results for a customer |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_PaymentExecutionDepositResult | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

PAGE compression. The base table has one NC index (IX_PaymentExecutionDepositResult_PaymentExecutionId, PAGE compressed).

### 7.2 Constraints

None. The base table holds:
- PK_Recurring_PaymentExecutionDepositResult (PK on PaymentExecutionDepositResultId, PAGE compressed)

---

## 8. Sample Queries

### 8.1 View deposit result history for an execution
```sql
SELECT PaymentExecutionDepositResultId, PaymentExecutionId, CycleNumber,
       AmountInUsd, ExecutionResultStatusId, StatusCode, GroupKey,
       SysStartTime AS VersionStart, SysEndTime AS VersionEnd
FROM History.PaymentExecutionDepositResult WITH (NOLOCK)
WHERE PaymentExecutionId = 548075
ORDER BY SysStartTime ASC
```

### 8.2 Analyze decline patterns by status code and group
```sql
SELECT StatusCode, GroupKey,
       ers.Name AS ResultStatus,
       COUNT(*) AS Cnt
FROM History.PaymentExecutionDepositResult h WITH (NOLOCK)
JOIN Dictionary.ExecutionResultStatus ers WITH (NOLOCK) ON ers.ExecutionResultStatusId = h.ExecutionResultStatusId
GROUP BY StatusCode, GroupKey, ers.Name
ORDER BY Cnt DESC
```

### 8.3 Find executions where result changed from soft to hard decline
```sql
SELECT h1.PaymentExecutionId, h1.CycleNumber,
       h1.ExecutionResultStatusId AS PreviousResult,
       h2.ExecutionResultStatusId AS CurrentResult,
       h1.StatusCode AS PreviousCode, h2.StatusCode AS CurrentCode
FROM History.PaymentExecutionDepositResult h1 WITH (NOLOCK)
JOIN History.PaymentExecutionDepositResult h2 WITH (NOLOCK)
    ON h2.PaymentExecutionId = h1.PaymentExecutionId
    AND h2.CycleNumber = h1.CycleNumber
    AND h2.SysStartTime = h1.SysEndTime
WHERE h1.ExecutionResultStatusId = 2  -- Was SoftDecline
  AND h2.ExecutionResultStatusId = 3  -- Became HardDecline
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 8.8/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PaymentExecutionDepositResult | Type: Table | Source: RecurringManager/History/Tables/History.PaymentExecutionDepositResult.sql*
