# Dictionary.JobType

> Lookup table classifying scheduler job types: Recurring (regular scheduled processing) and Dunning (retry processing for soft-declined payments).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | JobTypeId (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.JobType classifies the type of scheduler job being executed. The RecurringManager system runs two distinct job types: Recurring jobs that process planned executions on their regular schedule, and Dunning jobs that process retry attempts for previously soft-declined payments.

This table mirrors Dictionary.ExecutionType at the job level. While ExecutionType classifies individual execution records, JobType classifies the job instance that processes batches of executions. Recurring jobs create and process Planned executions, while Dunning jobs create and process Dunning executions.

The two job types likely run on different schedules and with different batch sizes, managed by the RecurringScheduler worker service.

---

## 2. Business Logic

### 2.1 Job-to-Execution Type Mapping

**What**: Each job type corresponds to a specific execution type, maintaining separation between regular and retry processing pipelines.

**Columns/Parameters Involved**: `JobTypeId`, `Name`

**Rules**:
- Recurring (1) jobs process Planned (ExecutionType=1) executions on the plan's regular schedule
- Dunning (2) jobs process Dunning (ExecutionType=2) executions to recover soft-declined payments
- Both job types are executed by the RecurringScheduler worker service
- Jobs of different types never process each other's executions

**Diagram**:
```
RecurringScheduler Worker
    |
    +-- Recurring Job (1) ----> Planned Executions (ExecutionType=1)
    |       Schedule: Frequency-driven (Weekly/BiWeekly/Monthly)
    |
    +-- Dunning Job (2) ------> Dunning Executions (ExecutionType=2)
            Schedule: Retry-policy-driven
```

---

## 3. Data Overview

| JobTypeId | Name | Meaning |
|---|---|---|
| 1 | Recurring | Regular scheduled job that processes planned executions when their due dates arrive. Runs on the plan's frequency cycle. |
| 2 | Dunning | Retry job that processes soft-declined executions, attempting to recover failed payments through re-charging the customer's payment method. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | JobTypeId | int | NO | - | CODE-BACKED | Primary key identifying the job type. 1=Recurring (regular charge processing), 2=Dunning (retry after soft decline). Maps 1:1 to Dictionary.ExecutionType. See [Job Type](../../_glossary.md#job-type) for full definitions. (Dictionary.JobType) |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable label for the job type. Values: "Recurring", "Dunning". |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Scheduler.Job | JobTypeId | Implicit FK | Classifies each scheduler job instance as Recurring or Dunning |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Job | Table | JobTypeId column references this table's values |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_JobType | CLUSTERED PK | JobTypeId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_JobType | PRIMARY KEY | Ensures each job type has a unique integer identifier |

---

## 8. Sample Queries

### 8.1 List all job types
```sql
SELECT JobTypeId, Name
FROM Dictionary.JobType WITH (NOLOCK)
ORDER BY JobTypeId
```

### 8.2 Count jobs by type
```sql
SELECT jt.Name AS JobType, COUNT(*) AS JobCount
FROM Scheduler.Job j WITH (NOLOCK)
INNER JOIN Dictionary.JobType jt WITH (NOLOCK) ON j.JobTypeId = jt.JobTypeId
GROUP BY jt.Name
```

### 8.3 Find recent dunning jobs
```sql
SELECT j.*, jt.Name AS JobTypeName
FROM Scheduler.Job j WITH (NOLOCK)
INNER JOIN Dictionary.JobType jt WITH (NOLOCK) ON j.JobTypeId = jt.JobTypeId
WHERE j.JobTypeId = 2 -- Dunning
ORDER BY j.JobId DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Scheduler](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1922891789) | Confluence | Architecture: RecurringScheduler is the dedicated worker that drives both Recurring and Dunning job processing |

---

*Generated: 2026-04-16 | Enriched: - | Quality: 7.9/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.JobType | Type: Table | Source: RecurringManager/Dictionary/Tables/Dictionary.JobType.sql*
