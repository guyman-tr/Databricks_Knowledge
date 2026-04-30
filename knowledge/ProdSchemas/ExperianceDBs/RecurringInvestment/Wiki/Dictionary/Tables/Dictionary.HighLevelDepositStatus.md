# Dictionary.HighLevelDepositStatus

> Lookup table classifying recurring deposit outcomes at a high level - success, soft decline (retryable), or hard decline (permanent).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table classifies the outcome of a recurring investment deposit attempt into three high-level categories. The deposit is processed by the Money Group's Recurring Deposit system, and the result is communicated to the Recurring Investment service via ServiceBus messages. This high-level classification drives the system's response: successful deposits trigger order placement, soft declines allow retry, and hard declines may block the user or cancel the plan.

Without this table, the system could not distinguish between retryable and permanent deposit failures, leading to either unnecessary retries on permanently failed payments or premature plan cancellation on temporary issues.

The Deposit Message Handler in the recurring investment backend service receives deposit status from Money ServiceBus and writes the HighLevelDepositStatusId to PlanInstances. The value maps to more granular DepositStatusID for detailed tracking. This status is also used in PlanEventCode ranges 200-205 for event classification.

---

## 2. Business Logic

### 2.1 Deposit Outcome Classification and Response

**What**: Three-state classification that drives different business flows based on deposit outcome severity.

**Columns/Parameters Involved**: `ID`, `HighLevelDepositStatus`

**Rules**:
- Success (1): Deposit processed - proceed to order placement (OrderExecution Job)
- SoftDecline (2): Temporary failure (insufficient funds, network timeout) - eligible for retry in next cycle
- HardDecline (3): Permanent failure (card expired, account closed) - may trigger PlanEventCode 200 (blocked) or 203 (not blocked) and potential plan cancellation

**Diagram**:
```
Deposit Attempt (from Money ServiceBus)
    |
    +-- Success (1) -----> Update PlanInstance --> OrderExecution Job
    |
    +-- SoftDecline (2) --> Update PlanInstance --> Skip this cycle, retry next
    |
    +-- HardDecline (3) --> Update PlanInstance --> Check blocking rules
                                                    |
                                                    +-- Blocked --> PlanEventCode 200
                                                    +-- Not Blocked --> PlanEventCode 203
```

---

## 3. Data Overview

| ID | HighLevelDepositStatus | Meaning |
|----|------------------------|---------|
| 1 | Success | Deposit was processed successfully by the Money system and funds are available in the user's account for the order to be placed. Triggers the next step in the recurring investment cycle. |
| 2 | SoftDecline | Deposit was declined for a temporary reason such as insufficient funds or a network timeout. The plan remains active and the system will attempt the deposit again in the next cycle. |
| 3 | HardDecline | Deposit was permanently declined for a non-recoverable reason such as an expired card or closed account. Depending on business rules, this may block the user (PlanEventCode 200) or leave them unblocked (PlanEventCode 203), and may ultimately cancel the plan. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Unique numeric identifier for the high-level deposit status. 1=Success, 2=SoftDecline, 3=HardDecline. See [High Level Deposit Status](../../_glossary.md#high-level-deposit-status). |
| 2 | HighLevelDepositStatus | varchar(50) | NO | - | VERIFIED | Human-readable label describing the deposit outcome category. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.PlanInstances | HighLevelDepositStatusId | Implicit Lookup | Classifies the deposit outcome for each plan instance cycle |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | HighLevelDepositStatusId column references this domain |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HighLevelDepositStatus | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all deposit status categories
```sql
SELECT ID, HighLevelDepositStatus
FROM [Dictionary].[HighLevelDepositStatus] WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Find plan instances with deposit failures
```sql
SELECT pi.InstanceID, pi.PlanID, pi.HighLevelDepositStatusId,
       hlds.HighLevelDepositStatus AS StatusName, pi.DepositDate
FROM [RecurringInvestment].[PlanInstances] pi WITH (NOLOCK)
JOIN [Dictionary].[HighLevelDepositStatus] hlds WITH (NOLOCK)
  ON pi.HighLevelDepositStatusId = hlds.ID
WHERE pi.HighLevelDepositStatusId IN (2, 3)
```

### 8.3 Count deposit outcomes by status
```sql
SELECT hlds.ID, hlds.HighLevelDepositStatus, COUNT(*) AS InstanceCount
FROM [RecurringInvestment].[PlanInstances] pi WITH (NOLOCK)
JOIN [Dictionary].[HighLevelDepositStatus] hlds WITH (NOLOCK)
  ON pi.HighLevelDepositStatusId = hlds.ID
GROUP BY hlds.ID, hlds.HighLevelDepositStatus
ORDER BY hlds.ID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | HighLevelDepositStatusId based on a dictionary table in Billing DB; source is [Dictionary].[ExecutionResultStatus] |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523/Recurring+Investment+Backend+HLD) | Confluence | Deposit Message Handler listens to deposit success messages from Money ServiceBus |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.HighLevelDepositStatus | Type: Table | Source: RecurringInvestment/Dictionary/Tables/Dictionary.HighLevelDepositStatus.sql*
