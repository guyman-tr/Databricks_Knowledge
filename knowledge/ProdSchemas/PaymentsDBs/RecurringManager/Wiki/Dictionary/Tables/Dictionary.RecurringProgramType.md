# Dictionary.RecurringProgramType

> Lookup table classifying the two types of recurring programs: RecurringDeposit (automatic fund deposits) and RecurringInvestment (automatic deposits plus instrument allocation).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RecurringProgramTypeID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.RecurringProgramType is the core business domain classifier for the entire RecurringManager database. It defines the two types of recurring programs that users can enroll in: RecurringDeposit (automatic fund deposits on a schedule) and RecurringInvestment (automatic deposits plus allocation to specific instruments/portfolios).

This distinction drives the entire processing pipeline. RecurringDeposit plans simply charge the user's payment method and add funds to their account. RecurringInvestment plans do the same, but then additionally trigger an investment order on a chosen instrument. Per the Confluence HLD, "The Recurring Investment Plan is based on the Recurring Deposit Plan and triggered by the actual deposit."

The RecurringProgramTypeId is stored on Scheduler.Execution records and passed to Scheduler.CreateOrGetExecution, ensuring that execution results are routed to the correct downstream handler based on the program type.

---

## 2. Business Logic

### 2.1 Deposit vs Investment Program Processing

**What**: The two program types follow different processing pipelines after the billing charge succeeds - deposits stop at fund addition, while investments continue to position opening.

**Columns/Parameters Involved**: `RecurringProgramTypeID`, `Name`

**Rules**:
- RecurringDeposit (1): Charge payment method -> Add funds to account. Processing ends after successful deposit.
- RecurringInvestment (2): Charge payment method -> Add funds to account -> Open position on chosen instrument. Superset of RecurringDeposit with additional investment step.
- RecurringInvestment plans are managed by a separate service (recurring-investment-back) that coordinates with the RecurringManager for the deposit portion
- Scheduler.CreateOrGetExecution stores RecurringProgramTypeId on execution records for downstream routing

**Diagram**:
```
RecurringDeposit (1):
  Schedule -> Charge MOP -> Deposit Funds -> Done

RecurringInvestment (2):
  Schedule -> Charge MOP -> Deposit Funds -> Open Position on Instrument -> Done
                                              ^
                                              |
                                    RecurringInvestment service
                                    (separate backend)
```

---

## 3. Data Overview

| RecurringProgramTypeID | Name | Meaning |
|---|---|---|
| 1 | RecurringDeposit | User has set up automatic recurring deposits into their eToro account. Funds are added on schedule (Weekly/BiWeekly/Monthly). Managed by Money Group. |
| 2 | RecurringInvestment | User has set up automatic recurring investments. Funds are deposited AND then allocated to a specific instrument. Managed by RecurringInvestment backend service in coordination with RecurringManager. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RecurringProgramTypeID | int | NO | - | VERIFIED | Primary key identifying the program type. 1=RecurringDeposit (deposit only), 2=RecurringInvestment (deposit + invest). Core business classifier for the entire RecurringManager domain. See [Recurring Program Type](../../_glossary.md#recurring-program-type) for full definitions. (Dictionary.RecurringProgramType) |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable label for the program type. Values: "RecurringDeposit", "RecurringInvestment". |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Scheduler.Execution | RecurringProgramTypeId | Implicit FK | Stored on execution records to route results to the correct downstream handler |
| Scheduler.CreateOrGetExecution | @RecurringProgramTypeId | Parameter | Passed when creating new execution records |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Execution | Table | RecurringProgramTypeId column classifies the execution's program type |
| Scheduler.CreateOrGetExecution | Stored Procedure | @RecurringProgramTypeId parameter for creation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_RecurringProgramType | CLUSTERED PK | RecurringProgramTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_RecurringProgramType | PRIMARY KEY | Ensures each program type has a unique integer identifier |

Storage: DATA_COMPRESSION = PAGE

---

## 8. Sample Queries

### 8.1 List all program types
```sql
SELECT RecurringProgramTypeID, Name
FROM Dictionary.RecurringProgramType WITH (NOLOCK)
ORDER BY RecurringProgramTypeID
```

### 8.2 Count executions by program type
```sql
SELECT rpt.Name AS ProgramType, COUNT(*) AS ExecutionCount
FROM Scheduler.Execution e WITH (NOLOCK)
INNER JOIN Dictionary.RecurringProgramType rpt WITH (NOLOCK)
    ON e.RecurringProgramTypeId = rpt.RecurringProgramTypeID
GROUP BY rpt.Name
```

### 8.3 Find all recurring investment executions with status
```sql
SELECT e.ExecutionId, e.PlanId, e.PlannedDate, es.Name AS ExecutionStatus
FROM Scheduler.Execution e WITH (NOLOCK)
INNER JOIN Dictionary.ExecutionStatus es WITH (NOLOCK) ON e.ExecutionStatusId = es.ExecutionStatusID
WHERE e.RecurringProgramTypeId = 2 -- RecurringInvestment
ORDER BY e.PlannedDate DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Business definition: "Recurring Investment Plan is based on the Recurring Deposit Plan and triggered by the actual deposit"; separate backend service (recurring-investment-back) manages investment plans |
| [HLD- Recurring Integration with provider](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1860534325) | Confluence | Business context: Recurring deposits marked as DepositTypeID=3 in Billing.Deposit; scheme identifiers connect all payments to the same plan on the issuer side |

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 1 analyzed (references) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RecurringProgramType | Type: Table | Source: RecurringManager/Dictionary/Tables/Dictionary.RecurringProgramType.sql*
