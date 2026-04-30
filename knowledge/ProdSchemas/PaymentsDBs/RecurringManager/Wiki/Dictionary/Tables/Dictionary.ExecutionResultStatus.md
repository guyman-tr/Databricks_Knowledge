# Dictionary.ExecutionResultStatus

> Lookup table defining the three possible outcomes of a payment execution attempt: Success, SoftDecline (recoverable), or HardDecline (terminal).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ExecutionResultStatusID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.ExecutionResultStatus classifies the outcome of a payment execution after it has been processed by the external billing/payment provider (Worldpay or Checkout). Every execution attempt that reaches a provider receives one of three result classifications: Success, SoftDecline, or HardDecline.

This table is fundamental to the dunning/retry system. When an execution returns SoftDecline, the system creates a new dunning execution to retry the charge. When an execution returns HardDecline, the system stops retrying and may escalate to plan-level status changes (e.g., stopping the plan). Success means funds will be collected and the execution cycle is complete.

The result status is recorded after the billing provider responds and is separate from the ExecutionStatus lifecycle (which tracks the processing steps) and the PaymentExecutionStatus (which tracks the end-to-end journey). ExecutionResultStatus specifically captures the provider's verdict on the charge attempt.

---

## 2. Business Logic

### 2.1 Decline Classification and Dunning Trigger

**What**: The distinction between SoftDecline and HardDecline drives the retry/dunning behavior of the entire recurring payment system.

**Columns/Parameters Involved**: `ExecutionResultStatusID`, `Name`

**Rules**:
- SoftDecline (2) triggers dunning: the system creates a new execution with ExecutionType=Dunning to retry the charge
- HardDecline (3) terminates retries: no further attempts are made, and this can cascade to a plan-level status change via StatusReason=5 (HardDecline)
- Success (1) completes the execution cycle: funds are collected, no further action needed for this cycle

**Diagram**:
```
Execution Attempt
       |
       v
  Provider Response
       |
  +----+----+----------+
  |         |          |
  v         v          v
Success  SoftDecline  HardDecline
(1)      (2)          (3)
  |         |          |
  v         v          v
 Done    Dunning     Stop/Escalate
         Retry       (StatusReason=5)
```

---

## 3. Data Overview

| ExecutionResultStatusID | Name | Meaning |
|---|---|---|
| 1 | Success | Provider approved the charge - funds will be collected from the customer's payment method. Execution cycle is complete for this period. |
| 2 | SoftDecline | Provider declined but reason is potentially recoverable (e.g., insufficient funds, temporary hold, issuer timeout). System will schedule a dunning retry execution. |
| 3 | HardDecline | Provider permanently declined (e.g., card expired, account closed, fraud flag). No retry will be attempted. May trigger plan stoppage via StatusReason.HardDecline (ID=5). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExecutionResultStatusID | int | NO | - | CODE-BACKED | Primary key identifying the execution result. 1=Success, 2=SoftDecline, 3=HardDecline. Drives dunning logic: SoftDecline triggers retry, HardDecline terminates. See [Execution Result Status](../../_glossary.md#execution-result-status) for full definitions. (Dictionary.ExecutionResultStatus) |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable label for the result status. Values: "Success", "SoftDecline", "HardDecline". |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.StatusReason | StatusReasonID=5 (HardDecline) | Semantic | HardDecline result at execution level maps to StatusReason.HardDecline at plan level - connecting execution outcome to plan lifecycle |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No explicit dependents found in SSDT. Consumed by application code to determine whether to retry (dunning) or stop after a provider response.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_ExecutionResultStatus | CLUSTERED PK | ExecutionResultStatusID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_ExecutionResultStatus | PRIMARY KEY | Ensures each result status has a unique integer identifier |

Storage: DATA_COMPRESSION = PAGE

---

## 8. Sample Queries

### 8.1 List all execution result statuses
```sql
SELECT ExecutionResultStatusID, Name
FROM Dictionary.ExecutionResultStatus WITH (NOLOCK)
ORDER BY ExecutionResultStatusID
```

### 8.2 Identify recoverable vs terminal declines
```sql
SELECT
    CASE WHEN ExecutionResultStatusID = 2 THEN 'Recoverable (Dunning Eligible)'
         WHEN ExecutionResultStatusID = 3 THEN 'Terminal (No Retry)'
         ELSE 'Success'
    END AS DeclineCategory,
    Name
FROM Dictionary.ExecutionResultStatus WITH (NOLOCK)
```

### 8.3 Join with execution data to analyze outcomes
```sql
SELECT ers.Name AS ResultStatus, COUNT(*) AS ExecutionCount
FROM Scheduler.Execution e WITH (NOLOCK)
INNER JOIN Dictionary.ExecutionResultStatus ers WITH (NOLOCK)
    ON e.ExecutionResultStatusID = ers.ExecutionResultStatusID
GROUP BY ers.Name
ORDER BY ExecutionCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HLD- Recurring Integration with provider](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1860534325) | Confluence | Business context: Recurring payments use Worldpay and Checkout providers with scheme identifiers for MIT transactions; error handling follows decline classification |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Business flow: Deposit Message Handler and Order Execution Job consume execution results to determine next steps |

---

*Generated: 2026-04-16 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ExecutionResultStatus | Type: Table | Source: RecurringManager/Dictionary/Tables/Dictionary.ExecutionResultStatus.sql*
