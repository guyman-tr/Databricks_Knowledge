# Recurring.PaymentExecutionDepositResult

> Records the outcome of each billing processor deposit attempt for a payment execution, storing the processor's response status, the resulting deposit ID, the USD-equivalent amount, and the decline classification.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Table |
| **Key Identifier** | PaymentExecutionDepositResultId (INT, IDENTITY) |
| **Partition** | No |
| **Indexes** | 1 clustered PK (PAGE) + 1 nonclustered (PAGE) |

---

## 1. Business Meaning

Recurring.PaymentExecutionDepositResult stores the billing processor's response for each payment execution attempt. When the system charges a customer's payment method, the processor returns a result - success or decline with a specific status code. This table captures that response along with the deposit ID (the actual financial transaction reference), the amount in USD, and the system's classification of the result (Success, SoftDecline, or HardDecline).

This table is critical for financial reconciliation, decline analysis, and the execution outcome pipeline. It provides the evidence trail of what the billing processor actually reported, separate from the execution status (which reflects the system's interpretation). The ExecutionStatusResultConfig table is used to interpret these raw processor responses.

Data enters through Recurring.UpsertPaymentExecutionDepositResult (upsert by PaymentExecutionId + CycleNumber). Results are read by GetResultsByPaymentExecution, GetPaymentExecutionsDepositsResultByCid, and GetPaymentExecutionsResultsForPayment. System-versioned with History.PaymentExecutionDepositResult.

---

## 2. Business Logic

### 2.1 Billing Processor Response Classification

**What**: Each deposit result captures the raw billing processor response and classifies it into one of three outcome categories.

**Columns/Parameters Involved**: `PaymentStatusId`, `StatusCode`, `ExecutionResultStatusId`

**Rules**:
- PaymentStatusId is the billing processor's high-level status (NOT the same as Recurring.Payment.StatusId):
  - 2 = Approved/Success (89.5%) - payment processed successfully
  - 3 = Declined (10%) - payment was declined by processor
  - 35 = Severe failure (0.5%) - maps to blocking in ExecutionStatusResultConfig
  - 4 = Other failure (0.1%)
  - 1, 0 = Rare edge cases
- StatusCode provides the specific processor sub-code for declined transactions (e.g., 1214=insufficient funds)
- ExecutionResultStatusId classifies the outcome (Dictionary.ExecutionResultStatus):
  - 1=Success (89.5%) - deposit completed
  - 2=SoftDecline (3.2%) - retryable failure
  - 3=HardDecline (7.4%) - terminal failure

### 2.2 Upsert by Execution + Cycle

**What**: Each execution+cycle combination has at most one deposit result, maintained via upsert.

**Columns/Parameters Involved**: `PaymentExecutionId`, `CycleNumber`

**Rules**:
- UpsertPaymentExecutionDepositResult checks `WHERE PaymentExecutionId = @PaymentExecutionId AND CycleNumber = @CycleNumber`
- On UPDATE: all fields are refreshed (DepositId, PaymentStatusId, StatusCode, GroupKey, ExecutionResultStatusId, PaymentDate, AmountInUsd, ModificationDate)
- On INSERT: a new result row is created
- This ensures the latest processor response overwrites any previous partial response for the same cycle

---

## 3. Data Overview

| PaymentExecutionDepositResultId | PaymentExecutionId | CycleNumber | AmountInUsd | PaymentStatusId | ExecutionResultStatusId | Meaning |
|---|---|---|---|---|---|---|
| 354564 | 851004 | 10 | 67.18 | 2 (Approved) | 1 (Success) | Successful deposit of $67.18 USD on the 10th billing cycle. Deposit ID 75251627 created in the billing system. |
| 354563 | 854704 | 8 | 13.44 | 2 (Approved) | 1 (Success) | Small recurring deposit of $13.44 on the 8th cycle. Successful with no status code issues. |
| (example) | - | - | - | 3 (Declined) | 2 (SoftDecline) | Processor declined the charge. StatusCode would identify the specific reason (e.g., 1214=insufficient funds). SoftDecline means the system can retry. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentExecutionDepositResultId | int | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing primary key. PAGE compressed. Current max ~354,564. |
| 2 | PaymentExecutionId | int | NO | - | VERIFIED | FK to Recurring.PaymentExecution.PaymentExecutionId. Links this result to the execution that triggered the billing attempt. Part of the upsert key with CycleNumber. Indexed (PAGE compressed). |
| 3 | CycleNumber | int | NO | - | CODE-BACKED | Billing cycle number matching the execution's cycle. Part of the upsert key with PaymentExecutionId. |
| 4 | AmountInUsd | money | NO | - | CODE-BACKED | The deposit amount converted to USD. Used for financial reporting and reconciliation. The original amount in the payment's currency is stored in PaymentExecutionRequest.Amount. |
| 5 | DepositId | int | NO | - | CODE-BACKED | External reference to the deposit transaction in the billing/payments system. Created by the payment processor when the charge is initiated. Used for reconciliation between the recurring system and the billing ledger. |
| 6 | PaymentStatusId | int | NO | - | VERIFIED | Raw billing processor response status. NOT from Dictionary.PaymentExecutionStatus - these are external billing system codes: 2=Approved (89.5%), 3=Declined (10%), 35=Severe failure (0.5%), 4=Other failure (0.1%). Maps to ExecutionStatusResultConfig for outcome classification. |
| 7 | StatusCode | int | YES | - | CODE-BACKED | Specific billing processor sub-code for declined transactions. NULL for successful deposits. Combined with PaymentStatusId, used to look up the handling rule in ExecutionStatusResultConfig (e.g., code 1214=insufficient funds, code 1960=expired card). |
| 8 | GroupKey | nvarchar(10) | YES | - | CODE-BACKED | Grouping key for batched deposit results. Typically empty string in current data. May be used for multi-part transactions or grouped charges. |
| 9 | ExecutionResultStatusId | int | NO | - | VERIFIED | System's classification of the billing result. FK to Dictionary.ExecutionResultStatus: 1=Success (89.5%), 2=SoftDecline (3.2%), 3=HardDecline (7.4%). Determined by looking up (PaymentStatusId, StatusCode) in ExecutionStatusResultConfig. |
| 10 | PaymentDate | datetime | YES | - | CODE-BACKED | Timestamp of when the billing processor actually processed the payment. May differ from CreateDate if there was a processing delay. NULL in some edge cases. |
| 11 | CreateDate | datetime | NO | - | CODE-BACKED | UTC timestamp when this result row was first created. Set to GETUTCDATE() by UpsertPaymentExecutionDepositResult. |
| 12 | ModificationDate | datetime | NO | - | CODE-BACKED | UTC timestamp of the last update. Set to GETUTCDATE() by UpsertPaymentExecutionDepositResult on both insert and update. |
| 13 | SysStartTime | datetime2(7) | NO | sysutcdatetime() | CODE-BACKED | System-versioning row start time (HIDDEN). |
| 14 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | System-versioning row end time (HIDDEN). History in History.PaymentExecutionDepositResult. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PaymentExecutionId | Recurring.PaymentExecution | Implicit FK | The execution attempt this result belongs to |
| ExecutionResultStatusId | Dictionary.ExecutionResultStatus | Implicit FK (Lookup) | 1=Success, 2=SoftDecline, 3=HardDecline |
| (PaymentStatusId, StatusCode) | Recurring.ExecutionStatusResultConfig | Logical Reference | These values are looked up in the config table to determine outcome handling |
| - | History.PaymentExecutionDepositResult | System Versioning | Full audit trail |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Recurring.UpsertPaymentExecutionDepositResult | - | Stored Procedure (WRITER/MODIFIER) | Upserts results by (PaymentExecutionId, CycleNumber) |
| Recurring.GetResultsByPaymentExecution | - | Stored Procedure (READER) | Reads results for a specific execution |
| Recurring.GetPaymentExecutionsDepositsResultByCid | - | Stored Procedure (READER) | Reads results for a customer via PE+Payment join |
| Recurring.GetPaymentExecutionsResultsForPayment | - | Stored Procedure (READER) | Reads results for a payment via PE+Request join |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (leaf table).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Recurring.UpsertPaymentExecutionDepositResult | Stored Procedure | WRITER/MODIFIER - upserts billing results |
| Recurring.GetResultsByPaymentExecution | Stored Procedure | READER - results by execution ID |
| Recurring.GetPaymentExecutionsDepositsResultByCid | Stored Procedure | READER - results by customer |
| Recurring.GetPaymentExecutionsResultsForPayment | Stored Procedure | READER - results by payment |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Recurring_PaymentExecutionDepositResult | CLUSTERED (PAGE) | PaymentExecutionDepositResultId ASC | - | - | Active |
| IX_PaymentExecutionDepositResult_PaymentExecutionId | NONCLUSTERED (PAGE) | PaymentExecutionId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Recurring_PaymentExecutionDepositResult | PRIMARY KEY | Clustered, PAGE compressed |
| DEFAULT SysStartTime | DEFAULT | sysutcdatetime() |
| DEFAULT SysEndTime | DEFAULT | CONVERT(datetime2, '9999-12-31 23:59:59.9999999') |
| SYSTEM_VERSIONING | TEMPORAL | History: History.PaymentExecutionDepositResult |

---

## 8. Sample Queries

### 8.1 Get deposit results for a payment execution with status names
```sql
SELECT pedr.PaymentExecutionDepositResultId, pedr.AmountInUsd, pedr.DepositId,
       pedr.PaymentStatusId, pedr.StatusCode,
       ers.Name AS ResultStatus, pedr.PaymentDate
FROM Recurring.PaymentExecutionDepositResult pedr WITH (NOLOCK)
INNER JOIN Dictionary.ExecutionResultStatus ers WITH (NOLOCK) ON pedr.ExecutionResultStatusId = ers.ExecutionResultStatusID
WHERE pedr.PaymentExecutionId = @PaymentExecutionId
```

### 8.2 Find recent declined deposits with reason categories
```sql
SELECT pedr.PaymentExecutionId, pedr.PaymentStatusId, pedr.StatusCode,
       ers.Name AS ResultStatus,
       esrc.ReasonCategoryId, rc.Name AS ReasonCategory
FROM Recurring.PaymentExecutionDepositResult pedr WITH (NOLOCK)
INNER JOIN Dictionary.ExecutionResultStatus ers WITH (NOLOCK) ON pedr.ExecutionResultStatusId = ers.ExecutionResultStatusID
LEFT JOIN Recurring.ExecutionStatusResultConfig esrc WITH (NOLOCK)
    ON pedr.PaymentStatusId = esrc.PaymentStatusId AND pedr.StatusCode = esrc.StatusCode
LEFT JOIN Recurring.ReasonCategory rc WITH (NOLOCK) ON esrc.ReasonCategoryId = rc.ReasonCategoryId
WHERE pedr.ExecutionResultStatusId IN (2, 3)
ORDER BY pedr.CreateDate DESC
```

### 8.3 Deposit result summary by outcome
```sql
SELECT ers.Name AS ResultStatus, COUNT(*) AS ResultCount,
       SUM(pedr.AmountInUsd) AS TotalAmountUsd
FROM Recurring.PaymentExecutionDepositResult pedr WITH (NOLOCK)
INNER JOIN Dictionary.ExecutionResultStatus ers WITH (NOLOCK) ON pedr.ExecutionResultStatusId = ers.ExecutionResultStatusID
GROUP BY ers.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.PaymentExecutionDepositResult | Type: Table | Source: RecurringManager/Recurring/Tables/Recurring.PaymentExecutionDepositResult.sql*
