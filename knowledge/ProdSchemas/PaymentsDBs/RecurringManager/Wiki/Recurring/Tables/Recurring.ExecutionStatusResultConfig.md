# Recurring.ExecutionStatusResultConfig

> Rules engine configuration table that maps billing processor response codes (PaymentStatusId + StatusCode) to execution outcomes (ExecutionStatus, block decision, decline classification, and reason category), differentiated by program type.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Table |
| **Key Identifier** | ExecutionStatusResultConfigId (INT, IDENTITY) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Recurring.ExecutionStatusResultConfig is the decision engine for recurring payment execution outcomes. When a payment execution is sent to the billing processor and returns with a status code, the system looks up this table to determine exactly how to handle the result - whether the execution failed or completed, whether the recurring plan should be blocked from future attempts, what category of decline it represents, and whether it was a soft decline (retryable) or hard decline (terminal).

Without this table, the system would have no way to translate raw billing processor status codes into actionable business decisions. The billing system returns hundreds of different status codes, but the recurring payments system needs to classify each into a small set of outcomes (retry, block, soft decline, hard decline) to drive automated handling.

This table is read by application code (not stored procedures) when processing payment execution results. It acts as a static configuration layer that can be updated by operations teams to add new billing status code mappings without code changes. The 34 rows cover the known universe of billing processor responses that require special handling.

---

## 2. Business Logic

### 2.1 Billing Response Classification Rules

**What**: Maps billing processor responses to execution outcomes with different rule sets per program type.

**Columns/Parameters Involved**: `PaymentStatusId`, `StatusCode`, `ProgramTypeId`, `ExecutionStatusId`, `IsBlocked`, `ExecutionResultStatusId`, `ReasonCategoryId`

**Rules**:
- The lookup key is (PaymentStatusId, StatusCode, ProgramTypeId) - billing status + specific code + program type
- When StatusCode is NULL, the rule applies to ALL status codes for that PaymentStatusId (catch-all rule)
- RecurringDeposit (ProgramTypeId=1) has 3 generic catch-all rules (no StatusCode specificity)
- RecurringInvestment (ProgramTypeId=2) has 31 specific rules mapping individual StatusCodes to decline categories

**Diagram**:
```
Billing Response (PaymentStatusId + StatusCode)
  |
  v
Lookup by ProgramTypeId
  |
  +-- ProgramTypeId=1 (RecurringDeposit): 3 catch-all rules
  |     PaymentStatusId=35 -> Done + BLOCKED (terminal failure)
  |     PaymentStatusId=3  -> Done + not blocked (completed)
  |     PaymentStatusId=4  -> Done + not blocked (completed)
  |
  +-- ProgramTypeId=2 (RecurringInvestment): 31 specific rules
        PaymentStatusId=3 + specific StatusCode ->
          |
          +-- ExecutionStatusId=5 (Failed) + SoftDecline (retryable)
          |     ReasonCategory: INSUFFICIENT_FUNDS, TRANSACTION_NOT_PERMITTED,
          |                     INVALID_TRANSACTION, DECLINED_DO_NOT_HONOUR
          |
          +-- ExecutionStatusId=6 (Done) + HardDecline (terminal)
                ReasonCategory: EXCEEDS_WITHDRAWAL, EXPIRED_CARD
```

### 2.2 Soft vs Hard Decline Handling

**What**: The system distinguishes between retryable (soft) and terminal (hard) declines to determine the payment plan's future.

**Columns/Parameters Involved**: `ExecutionResultStatusId`, `ExecutionStatusId`, `IsBlocked`

**Rules**:
- SoftDecline (ExecutionResultStatusId=2): ExecutionStatusId=5 (Failed), IsBlocked=false - the execution failed but the plan stays active for retry
- HardDecline (ExecutionResultStatusId=3): ExecutionStatusId=6 (Done), IsBlocked=false - the execution is terminal but plan-level blocking depends on category
- Only one rule uses IsBlocked=true: PaymentStatusId=35 for RecurringDeposit, which permanently blocks the plan
- SoftDecline reason categories: INSUFFICIENT_FUNDS (12 codes), TRANSACTION_NOT_PERMITTED (1 code), INVALID_TRANSACTION (8 codes), DECLINED_DO_NOT_HONOUR (1 code)
- HardDecline reason categories: EXCEEDS_WITHDRAWAL (3 codes), EXPIRED_CARD (5 codes)

---

## 3. Data Overview

| ExecutionStatusResultConfigId | PaymentStatusId | StatusCode | ExecutionStatusId | IsBlocked | ExecutionResultStatusId | ProgramTypeId | ReasonCategoryId | Meaning |
|---|---|---|---|---|---|---|---|---|
| 1 | 35 | NULL | 6 (Done) | true | NULL | 1 (Deposit) | NULL | Catch-all for billing status 35 on recurring deposits. Terminal and blocked - the most severe outcome. Only rule that blocks a plan permanently. |
| 5 | 3 | 1214 | 5 (Failed) | false | 2 (SoftDecline) | 2 (Investment) | 1 (INSUFFICIENT_FUNDS) | Billing code 1214 on investment: soft decline due to insufficient funds. Execution fails but plan stays active for retry. |
| 27 | 3 | 2156 | 6 (Done) | false | 3 (HardDecline) | 2 (Investment) | 5 (EXCEEDS_WITHDRAWAL) | Billing code 2156 on investment: hard decline - amount exceeds card withdrawal limit. Terminal. |
| 30 | 3 | 1960 | 6 (Done) | false | 3 (HardDecline) | 2 (Investment) | 6 (EXPIRED_CARD) | Billing code 1960 on investment: hard decline - card expired. Terminal, customer must update payment method. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExecutionStatusResultConfigId | int | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing primary key. 34 rows total. |
| 2 | PaymentStatusId | int | NO | - | VERIFIED | Billing processor payment status code (NOT the same as Recurring.Payment.StatusId). Observed values: 3 (31 rows - most declined transactions), 4 (1 row), 35 (1 row - severe/blocking failure). These are external billing system codes, not from Dictionary.PaymentExecutionStatus. |
| 3 | StatusCode | int | YES | - | VERIFIED | Specific billing processor sub-code within the PaymentStatusId. NULL means "catch-all for any StatusCode with this PaymentStatusId". When populated, provides granular mapping (e.g., code 1214=insufficient funds, code 1960=expired card). 31 rows have specific codes, 3 rows are catch-all (NULL). |
| 4 | ExecutionStatusId | int | NO | - | VERIFIED | The execution status to assign based on this rule. FK to Dictionary.ExecutionStatus: 5=Failed (22 rows - soft decline, retryable), 6=Done (12 rows - hard decline or completed, terminal). |
| 5 | IsBlocked | bit | NO | - | VERIFIED | Whether this result should permanently block the recurring payment plan from future executions. Only 1 of 34 rules sets IsBlocked=true (PaymentStatusId=35 for RecurringDeposit). All other rules leave the plan unblocked. |
| 6 | ExecutionResultStatusId | int | YES | - | VERIFIED | Decline classification. FK to Dictionary.ExecutionResultStatus: 1=Success, 2=SoftDecline (22 rows - retryable failure), 3=HardDecline (9 rows - terminal failure). NULL for the 3 RecurringDeposit catch-all rules. |
| 7 | ProgramTypeId | int | YES | - | VERIFIED | Which recurring program type this rule applies to. FK to Dictionary.RecurringProgramType: 1=RecurringDeposit (3 generic rules), 2=RecurringInvestment (31 specific rules). RecurringInvestment has much more granular decline handling. |
| 8 | ReasonCategoryId | int | YES | - | VERIFIED | Decline reason category for this rule. FK to Recurring.ReasonCategory: 0=UNKNOWN, 1=INSUFFICIENT_FUNDS (12 codes), 2=TRANSACTION_NOT_PERMITTED (1 code), 3=INVALID_TRANSACTION (8 codes), 4=DECLINED_DO_NOT_HONOUR (1 code), 5=EXCEEDS_WITHDRAWAL (3 codes), 6=EXPIRED_CARD (5 codes). NULL for the 3 RecurringDeposit catch-all rules. See [Recurring.ReasonCategory](Recurring.ReasonCategory.md). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ExecutionStatusId | Dictionary.ExecutionStatus | Implicit FK (Lookup) | Target execution status: 5=Failed, 6=Done |
| ExecutionResultStatusId | Dictionary.ExecutionResultStatus | Implicit FK (Lookup) | Decline classification: 2=SoftDecline, 3=HardDecline |
| ProgramTypeId | Dictionary.RecurringProgramType | Implicit FK (Lookup) | Which program type this rule targets: 1=Deposit, 2=Investment |
| ReasonCategoryId | Recurring.ReasonCategory | Implicit FK (Lookup) | Decline reason category (INSUFFICIENT_FUNDS, EXPIRED_CARD, etc.) |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views reference this table directly. It is consumed by application code to determine execution outcome handling.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (leaf table).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No database-level dependents found. Consumed by application code.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Recurring_ExecutionStatusResultConfig | CLUSTERED | ExecutionStatusResultConfigId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Recurring_ExecutionStatusResultConfig | PRIMARY KEY | Clustered on ExecutionStatusResultConfigId |

---

## 8. Sample Queries

### 8.1 View all rules with resolved lookups
```sql
SELECT esrc.ExecutionStatusResultConfigId,
       esrc.PaymentStatusId, esrc.StatusCode,
       es.Name AS ExecutionStatus, esrc.IsBlocked,
       ers.Name AS ExecutionResultStatus,
       rpt.Name AS ProgramType,
       rc.Name AS ReasonCategory
FROM Recurring.ExecutionStatusResultConfig esrc WITH (NOLOCK)
LEFT JOIN Dictionary.ExecutionStatus es WITH (NOLOCK) ON esrc.ExecutionStatusId = es.ExecutionStatusID
LEFT JOIN Dictionary.ExecutionResultStatus ers WITH (NOLOCK) ON esrc.ExecutionResultStatusId = ers.ExecutionResultStatusID
LEFT JOIN Dictionary.RecurringProgramType rpt WITH (NOLOCK) ON esrc.ProgramTypeId = rpt.RecurringProgramTypeID
LEFT JOIN Recurring.ReasonCategory rc WITH (NOLOCK) ON esrc.ReasonCategoryId = rc.ReasonCategoryId
ORDER BY esrc.ProgramTypeId, esrc.ExecutionResultStatusId, esrc.ReasonCategoryId
```

### 8.2 Find the rule for a specific billing response
```sql
SELECT esrc.*, es.Name AS ExecutionStatus, ers.Name AS ResultStatus, rc.Name AS ReasonCategory
FROM Recurring.ExecutionStatusResultConfig esrc WITH (NOLOCK)
LEFT JOIN Dictionary.ExecutionStatus es WITH (NOLOCK) ON esrc.ExecutionStatusId = es.ExecutionStatusID
LEFT JOIN Dictionary.ExecutionResultStatus ers WITH (NOLOCK) ON esrc.ExecutionResultStatusId = ers.ExecutionResultStatusID
LEFT JOIN Recurring.ReasonCategory rc WITH (NOLOCK) ON esrc.ReasonCategoryId = rc.ReasonCategoryId
WHERE esrc.PaymentStatusId = 3 AND (esrc.StatusCode = @StatusCode OR esrc.StatusCode IS NULL)
  AND esrc.ProgramTypeId = @ProgramTypeId
```

### 8.3 Summary of rules by decline type and reason category
```sql
SELECT ers.Name AS DeclineType, rc.Name AS ReasonCategory, COUNT(*) AS RuleCount
FROM Recurring.ExecutionStatusResultConfig esrc WITH (NOLOCK)
LEFT JOIN Dictionary.ExecutionResultStatus ers WITH (NOLOCK) ON esrc.ExecutionResultStatusId = ers.ExecutionResultStatusID
LEFT JOIN Recurring.ReasonCategory rc WITH (NOLOCK) ON esrc.ReasonCategoryId = rc.ReasonCategoryId
WHERE esrc.ProgramTypeId = 2
GROUP BY ers.Name, rc.Name
ORDER BY DeclineType, ReasonCategory
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.3/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.ExecutionStatusResultConfig | Type: Table | Source: RecurringManager/Recurring/Tables/Recurring.ExecutionStatusResultConfig.sql*
