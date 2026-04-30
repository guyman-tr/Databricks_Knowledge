# Log.TransactionStep

> Audit trail for every discrete step in the MoneyBus transaction and withdrawal execution pipelines, capturing the step name, outcome, errors, and correlation data for each stage of a financial fund movement.

| Property | Value |
|----------|-------|
| **Schema** | Log |
| **Object Type** | Table |
| **Key Identifier** | ID (int, identity) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered only) |

---

## 1. Business Meaning

Log.TransactionStep is the step-by-step execution log for the MoneyBus payment processing system. Every time a money transfer (deposit, internal transfer, or withdrawal) progresses through a pipeline step - such as setup, validation, hold, debit, credit, or commit - the executing service writes a row to this table recording whether that step passed, failed, or was terminated. This provides a granular, chronological record of how each transaction was processed.

Without this table, there would be no visibility into which specific step of a transaction's pipeline succeeded or failed. When a transaction ends in a declined or technical-error state, this log reveals exactly where in the pipeline the failure occurred and what error was returned - critical for operational troubleshooting, alerting, and reconciliation.

Data flows into this table exclusively through the `MoneyBus.TransactionStepAdd` stored procedure, called by two application services: the **MoneyBus Transactions Executer** (for deposits and internal transfers) and the **MoneyBus Withdraw Executer** (for withdrawals). Each service logs its pipeline steps as the transaction progresses. The table is append-only - rows are never updated or deleted. The `TransactionID` links back to `MoneyBus.Transactions` (for transaction flow) or `MoneyBus.Withdrawals` (for withdrawal flow), identified by the `TransactionTypeID` column.

---

## 2. Business Logic

### 2.1 Dual Pipeline Architecture

**What**: Two distinct execution pipelines share this single log table, distinguished by naming convention and TransactionTypeID.

**Columns/Parameters Involved**: `StepName`, `TransactionTypeID`, `TransactionID`

**Rules**:
- When `TransactionTypeID` is NULL, the row logs a **transaction pipeline** step (deposit or internal transfer). StepNames use kebab-case convention (e.g., `setup`, `validate`, `hold-initiate`, `credit-finalize`)
- When `TransactionTypeID = 2`, the row logs a **withdrawal pipeline** step. StepNames use camelCase convention (e.g., `holdInitiate`, `authorizeInitiate`, `payoutFinalize`)
- `TransactionID` references `MoneyBus.Transactions` for the transaction flow and `MoneyBus.Withdrawals` for the withdrawal flow
- Withdrawal flow steps include authorization and payout stages not present in the transaction flow

**Diagram**:
```
TRANSACTION FLOW (TransactionTypeID = NULL):
  setup -> validate -> set-currencies -> hold-initiate -> hold-finalize
    -> credit-initiate -> credit-finalize -> debit -> delete-container
    -> commit -> finalize-setup -> [send-mail]

WITHDRAWAL FLOW (TransactionTypeID = 2):
  setup -> holdInitiate -> holdFinalize -> authorizeInitiate
    -> authorizeFinalize -> payoutInitiate -> payoutFinalize
    -> [cancelInitiate] (on abort)
```

### 2.2 Step Outcome Classification

**What**: Each pipeline step produces one of three outcomes that determine whether the pipeline continues, terminates gracefully, or records a technical failure.

**Columns/Parameters Involved**: `StepStatus`, `Error`

**Rules**:
- `Pass`: Step completed successfully - pipeline continues to the next step. Error column is empty
- `Terminate`: Step failed due to a business validation (e.g., insufficient funds, invalid amount). The pipeline stops gracefully and the transaction is declined. Error column contains the validation failure message
- `Fail`: Step failed due to a technical/system error (e.g., null reference, connectivity issue). The pipeline stops with an unexpected error. Error column contains the exception message
- `Terminate` is the normal rejection path (business decline); `Fail` indicates a bug or infrastructure issue requiring investigation

---

## 3. Data Overview

| ID | StepName | StepStatus | TransactionID | TransactionTypeID | Error | Meaning |
|---|---|---|---|---|---|---|
| 78064778 | setup | Pass | 7747097 | NULL | (empty) | First step of a transaction pipeline - environment and context initialized successfully |
| 78062991 | debitFinalize | Pass | 7746917 | NULL | (empty) | Debit finalization completed for a transaction - funds confirmed debited from source account |
| 78063649 | holdInitiate | Pass | 773467 | 2 | (empty) | Withdrawal pipeline step - hold request sent to freeze funds in the user's account before payout |
| 78063638 | validate | Terminate | 7746983 | NULL | Insufficient funds - RequestedAmount: 51.77 EUR, ActualBalance: 36.99 EUR | Transaction terminated at validation because the source account lacks sufficient balance |
| 78011793 | debitInitiate | Fail | 7741895 | NULL | Value cannot be null. (Parameter 'value') | Technical failure during debit initiation - a required parameter was null, indicating a code defect or unexpected data state |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. Serves as the unique identifier for each logged step and provides chronological ordering (higher ID = later step). |
| 2 | Created | datetime | NO | getdate() | CODE-BACKED | Timestamp when the step was logged. The stored procedure `MoneyBus.TransactionStepAdd` overrides the DDL default with `GETUTCDATE()` when `@Created` is not provided, so values are in UTC. When the caller provides a specific timestamp, that value is used instead. |
| 3 | InitiateRequest | nvarchar(4000) | YES | - | NAME-INFERRED | Intended to store the serialized request payload that initiated the step. In practice, this column is almost always NULL in recent data - the application services do not consistently populate it. May have been used in early development or for specific debugging scenarios. |
| 4 | TransactionID | bigint | YES | - | CODE-BACKED | References the parent transaction or withdrawal being processed. When `TransactionTypeID` is NULL, this points to `MoneyBus.Transactions.TransactionID`. When `TransactionTypeID = 2`, this points to `MoneyBus.Withdrawals` withdrawal ID. Links this step log back to the master transaction record. |
| 5 | StepName | nvarchar(100) | YES | - | VERIFIED | Name of the pipeline step being executed. Application-level enum with 23 known values across two flows. Transaction flow (kebab-case): setup, validate, set-currencies, hold-initiate, hold-finalize, credit-initiate, credit-finalize, credit, debit, debitInitiate, debitFinalize, delete-container, commit, finalize-setup, hold, send-mail. Withdrawal flow (camelCase): holdInitiate, holdFinalize, authorizeInitiate, authorizeFinalize, payoutInitiate, payoutFinalize, cancelInitiate. See Section 2.1 for pipeline diagrams. |
| 6 | StepStatus | nvarchar(50) | YES | - | VERIFIED | Outcome of the pipeline step. Three known values: `Pass` (step succeeded, pipeline continues), `Terminate` (business validation failure - e.g., insufficient funds - pipeline stops gracefully), `Fail` (technical/system error - pipeline stops unexpectedly). See Section 2.2 for outcome classification rules. |
| 7 | Error | nvarchar(4000) | YES | - | CODE-BACKED | Error message when `StepStatus` is `Terminate` or `Fail`. Contains human-readable validation failure details (e.g., "Insufficient funds - RequestedAmount: 51.77 EUR, ActualBalance: 36.99 EUR") or .NET exception messages (e.g., "Value cannot be null. (Parameter 'value')"). Empty string when `StepStatus = Pass`. |
| 8 | Comment | nvarchar(4000) | YES | - | NAME-INFERRED | Free-text comment field for additional context about the step. In practice, this column is consistently empty across all recent data. The application services do not currently populate it. Reserved for future use or manual annotation. |
| 9 | CorrelationID | nvarchar(100) | YES | - | CODE-BACKED | Distributed tracing correlation identifier (UUID format) that links this step to the broader request context across microservices. Used to trace a single API request through the transaction/withdrawal execution pipeline. Transaction flow steps consistently carry a CorrelationID; withdrawal flow steps often have an empty string. |
| 10 | TransactionTypeID | int | YES | - | CODE-BACKED | Discriminator for the pipeline type. NULL = transaction flow (deposit/internal transfer, logged by MoneyBusTransactionsExecuter service). 2 = withdrawal flow (logged by MoneyBusWithdrawExecuter service). Added in April 2025 per procedure comments. No corresponding Dictionary lookup table exists - this is an application-level enum. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TransactionID | MoneyBus.Transactions | Implicit | When TransactionTypeID is NULL, links this step to the parent transaction record containing amount, status, creditor/debitor details |
| TransactionID | MoneyBus.Withdrawals | Implicit | When TransactionTypeID = 2, links this step to the parent withdrawal record containing payout amount, status, account details |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MoneyBus.TransactionStepAdd | INSERT INTO | Writer | The sole stored procedure that inserts rows into this table, called by both transaction and withdrawal execution services |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.TransactionStepAdd | Stored Procedure | WRITER - inserts step log rows via INSERT INTO [Log].[TransactionStep] |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Created | DEFAULT | `getdate()` for Created column - auto-stamps insertion time (note: overridden by GETUTCDATE() in the stored procedure when @Created is NULL) |

---

## 8. Sample Queries

### 8.1 Get all pipeline steps for a specific transaction

```sql
SELECT ID, Created, StepName, StepStatus, Error, CorrelationID
FROM [Log].[TransactionStep] WITH (NOLOCK)
WHERE TransactionID = 7746917
  AND TransactionTypeID IS NULL
ORDER BY ID ASC
```

### 8.2 Find recent failed or terminated steps

```sql
SELECT TOP 20 ID, Created, TransactionID, StepName, StepStatus, Error
FROM [Log].[TransactionStep] WITH (NOLOCK)
WHERE StepStatus IN ('Fail', 'Terminate')
  AND ID > (SELECT MAX(ID) - 100000 FROM [Log].[TransactionStep] WITH (NOLOCK))
ORDER BY ID DESC
```

### 8.3 Get withdrawal pipeline steps with step ordering

```sql
SELECT ID, Created, TransactionID, StepName, StepStatus, Error
FROM [Log].[TransactionStep] WITH (NOLOCK)
WHERE TransactionTypeID = 2
  AND TransactionID = 773467
ORDER BY ID ASC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [MoneyBus Transactions executer Service (AKS)](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/11966709761) | Confluence | Confirmed the Transaction Executer service (MIMO Core Team) connects to MoneyBusDB and uses adapter APIs for trading/options operations. Code repo: eToro.MoneyBus.TransactionsExecuter |
| [MoneyBus Withdraw Executer Service (AKS)](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/13080756254) | Confluence | Confirmed the Withdraw Executer service (MIMO Core Team) connects to MoneyBusDB and depends on IBAN Adapter and Transaction Authorizer. Code repo: eToro.MoneyBus.WithdrawExecuter |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 7.8/10 (Elements: 8.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Log.TransactionStep | Type: Table | Source: MoneyBusDB/Log/Tables/Log.TransactionStep.sql*
