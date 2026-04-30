# History.GetPayoutStepLogs

> Retrieves the payout workflow step log entries for a specific withdrawal-to-funding transaction, returning each step name and its pass/fail status.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @TransactionID - the WithdrawToFundingID to look up |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.GetPayoutStepLogs` is a read-only lookup procedure that fetches the execution step log for a payout (withdrawal-to-funding) transaction. The payout workflow is broken into named steps (e.g., validation, provider submission, confirmation), each recorded with a pass/fail status. This procedure answers the question: "What happened at each stage of this payout processing flow?"

The procedure exists to support debugging, support tooling, and operational monitoring of the payout pipeline. When a withdrawal gets stuck or fails, the calling application or operator queries this procedure with the transaction ID to see exactly which steps succeeded and which failed.

Data flows from the payout processing service into `History.PayoutStep` (a synonym for `DB_Logs.History.PayoutStep`) via `History.AddPayoutStepLog`. `History.GetPayoutStepLogs` is the read-side complement - it is called after-the-fact to retrieve the recorded steps for a given transaction.

---

## 2. Business Logic

### 2.1 Step-Level Payout Audit

**What**: Returns one row per named step in the payout workflow for a given transaction.

**Columns/Parameters Involved**: `@TransactionID`, `WithdrawToFundingID`, `Step`, `StepStatus`

**Rules**:
- Filters by `WithdrawToFundingID = @TransactionID` - one transaction can have multiple step rows
- Returns `Step` (the name of the workflow stage) and `StepStatus` (pass/fail outcome)
- No ordering is applied - rows are returned in storage order (typically insertion order, reflecting chronological step execution)
- StepStatus values are text: 'Pass' or 'Fail' (confirmed from History.AddPayoutStepLog writer logic)
- No rows returned means either the transaction ID does not exist or no steps have been logged yet

**Diagram**:
```
@TransactionID (WithdrawToFundingID)
         |
         v
History.PayoutStep (synonym -> DB_Logs.History.PayoutStep)
         |
         v
Returns: Step | StepStatus
         e.g. 'Validate'   | 'Pass'
              'Submit'      | 'Pass'
              'Confirm'     | 'Fail'
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TransactionID | INT | NO | - | CODE-BACKED | Input: The WithdrawToFundingID of the payout transaction to look up. Filters History.PayoutStep to return only the step log rows for this specific transaction. Corresponds to the transaction identifier used in History.AddPayoutStepLog's @TransactionID parameter, which maps to WithdrawToFundingID in the underlying DB_Logs table. |

**Output columns** (returned by SELECT):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Step | (varchar, from target table) | YES | - | CODE-BACKED | The name of the payout workflow step being logged (e.g., 'Validate', 'Submit', 'Confirm'). Identifies which stage of the payout pipeline this row represents. From History.PayoutStep (synonym for DB_Logs.History.PayoutStep). |
| 2 | StepStatus | (varchar, from target table) | YES | - | CODE-BACKED | The outcome of the step execution: 'Pass' for successful completion, 'Fail' for failure. Used by support and monitoring to identify at which stage a payout transaction broke down. Confirmed value set from History.AddPayoutStepLog writer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | History.PayoutStep | Reads via synonym | SELECT on the payout step log synonym; resolves to DB_Logs.History.PayoutStep |

### 5.2 Referenced By (other objects point to this)

No callers found in the etoro SSDT repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetPayoutStepLogs (procedure)
└── History.PayoutStep (synonym -> DB_Logs.History.PayoutStep)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PayoutStep | Synonym (resolves to DB_Logs.History.PayoutStep) | SELECT - reads Step and StepStatus filtered by WithdrawToFundingID |

### 6.2 Objects That Depend On This

No dependents found in the etoro SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get all payout step logs for a transaction

```sql
EXEC History.GetPayoutStepLogs @TransactionID = 123456
```

### 8.2 Call and capture results in a temp table

```sql
CREATE TABLE #PayoutSteps (Step VARCHAR(200), StepStatus VARCHAR(50))
INSERT INTO #PayoutSteps
EXEC History.GetPayoutStepLogs @TransactionID = 123456

SELECT * FROM #PayoutSteps WITH (NOLOCK)
```

### 8.3 Check if a specific transaction has any failed steps (via direct query)

```sql
SELECT [Step], [StepStatus]
FROM [History].[PayoutStep] WITH (NOLOCK)
WHERE [WithdrawToFundingID] = 123456
  AND [StepStatus] = 'Fail'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 1 repo / 0 files | Corrections: 0 applied*
*Object: History.GetPayoutStepLogs | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.GetPayoutStepLogs.sql*
