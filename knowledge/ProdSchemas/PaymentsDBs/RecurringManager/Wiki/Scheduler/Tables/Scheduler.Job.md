# Scheduler.Job

> Configuration table defining the scheduled job types, their cron schedules, and the CCM keys that control queue routing and activation for the RecurringScheduler worker service.

| Property | Value |
|----------|-------|
| **Schema** | Scheduler |
| **Object Type** | Table |
| **Key Identifier** | JobId (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Scheduler.Job is a configuration table that defines the types of processing jobs available to the RecurringScheduler K8S worker service. Each row represents a distinct job type with its cron schedule, Azure Service Bus queue key, and CCM activation toggle. The worker reads this table on startup or refresh to know which jobs to run, when to run them, and where to route the work.

This table exists because the RecurringScheduler needs externalized configuration for its processing schedule. Rather than hardcoding cron expressions and queue names in application config files, this table allows operations to adjust scheduling parameters via database updates. Without it, changing a job's schedule or disabling a job would require a service redeployment.

The RecurringScheduler application reads this table directly (no stored procedure intermediary). On each cron tick, the worker checks the IsActiveKey via CCM to determine if the job should fire, then publishes work items to the Azure Service Bus queue identified by QueueKey. Currently only one job is configured (Recurring/Planned), though the schema supports adding a Dunning job for retry processing.

---

## 2. Business Logic

### 2.1 Job Activation Control via CCM

**What**: Each job has an external on/off switch through the CCM (Configuration Control Manager) system.

**Columns/Parameters Involved**: `IsActiveKey`, `QueueKey`

**Rules**:
- The `IsActiveKey` value (e.g., "RecurringProcessIsActive") is looked up in CCM at runtime
- If CCM returns true/active, the job fires on its cron schedule; if false, the job is silently skipped
- The `QueueKey` (e.g., "recurringProcessQueue") identifies which Azure Service Bus queue receives the work items
- This allows operations to pause processing without stopping the service or changing code

**Diagram**:
```
CCM Lookup                  Service Bus
    |                            |
[IsActiveKey] --true?--> [QueueKey] --> Worker processes executions
    |                                          |
  false                                   Scheduler.Execution
    |                                     (status transitions)
  skip
```

### 2.2 Cron-Based Scheduling

**What**: Jobs run on configurable cron schedules defined in standard Quartz cron format.

**Columns/Parameters Involved**: `Cron`, `JobTypeId`

**Rules**:
- The Cron column uses Quartz cron format (6 fields: seconds minutes hours day-of-month month day-of-week)
- Current configuration: `0 0 * ? * *` = every hour at the top of the hour
- Each JobTypeId maps to a distinct processing pipeline (1=Recurring processes planned executions, 2=Dunning processes retry executions)
- The cron schedule determines how frequently the worker scans for due executions via Scheduler.GetExecutionsToProcessWithLock or Scheduler.SetStampForExecutionsWithLock

---

## 3. Data Overview

| JobId | JobTypeId | Cron | QueueKey | IsActiveKey | Meaning |
|-------|-----------|------|----------|-------------|---------|
| 1 | 1 | 0 0 * ? * * | recurringProcessQueue | RecurringProcessIsActive | The primary recurring payment processing job - runs hourly, picks up all Planned executions whose PlannedDate has passed, stamps them, and routes them to the recurring process queue for charge submission |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | JobId | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key uniquely identifying each scheduler job configuration. Currently only 1 row exists. |
| 2 | JobTypeId | int | NO | - | VERIFIED | Classification of the job's processing pipeline: 1=Recurring (processes planned executions on schedule), 2=Dunning (processes retry attempts for soft-declined payments). See [Job Type](_glossary.md#job-type) for full definitions. (Dictionary.JobType) |
| 3 | Cron | varchar(50) | NO | - | CODE-BACKED | Quartz cron expression defining the job's schedule. Uses 6-field format: seconds minutes hours day-of-month month day-of-week. Current value "0 0 * ? * *" means every hour at :00. The RecurringScheduler worker parses this to schedule its processing loop. |
| 4 | QueueKey | varchar(50) | NO | - | CODE-BACKED | CCM key name that resolves to the Azure Service Bus queue where work items are published. Value "recurringProcessQueue" maps to the recurring processing queue. Different job types route to different queues for independent processing throughput. |
| 5 | IsActiveKey | varchar(50) | NO | - | CODE-BACKED | CCM key name that acts as a runtime on/off switch for this job. Value "RecurringProcessIsActive" is looked up in CCM before each cron tick. When the key returns false, the job skips that cycle. Allows operations to pause specific job types without service restart. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JobTypeId | Dictionary.JobType | Implicit Lookup | Classifies the job as Recurring (1) or Dunning (2), determining which processing pipeline executes |

### 5.2 Referenced By (other objects point to this)

No stored procedures, views, or functions in the SSDT project reference this table. It is read directly by the RecurringScheduler application code via Entity Framework or ADO.NET.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringScheduler application | External (C# service) | Reads job configuration to schedule processing loops |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Scheduler_Job | CLUSTERED PK | JobId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Scheduler_Job | PRIMARY KEY | Ensures unique JobId per row |

---

## 8. Sample Queries

### 8.1 View all configured jobs with their type names
```sql
SELECT j.JobId, jt.Name AS JobType, j.Cron, j.QueueKey, j.IsActiveKey
FROM Scheduler.Job j WITH (NOLOCK)
JOIN Dictionary.JobType jt WITH (NOLOCK) ON j.JobTypeId = jt.JobTypeId
ORDER BY j.JobId;
```

### 8.2 Find jobs by type (e.g., Dunning jobs)
```sql
SELECT j.*
FROM Scheduler.Job j WITH (NOLOCK)
WHERE j.JobTypeId = 2; -- Dunning
```

### 8.3 Check if a specific job type is configured
```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM Scheduler.Job WITH (NOLOCK)
    WHERE JobTypeId = 1 -- Recurring
) THEN 'Configured' ELSE 'Not Found' END AS RecurringJobStatus;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Scheduler](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1922891789/Recurring+Scheduler) | Confluence | RecurringScheduler is a K8S worker service with CCM integration, connects to Azure Service Bus queues, owned by MIMO US team |

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed (table read by app directly) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Scheduler.Job | Type: Table | Source: RecurringManager/Scheduler/Tables/Scheduler.Job.sql*
