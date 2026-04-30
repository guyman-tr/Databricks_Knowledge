# Billing.PayoutSchedulerJob

> Configuration table defining the scheduled background jobs run by the payout service, including job names, cron expressions, active/inactive status, and batch size limits.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | JobID (INT, PK CLUSTERED - not identity, manually assigned) |
| **Partition** | PRIMARY filegroup (PAGE compressed) |
| **Indexes** | 1 active (PK clustered, FILLFACTOR=90) |

---

## 1. Business Meaning

Billing.PayoutSchedulerJob is the configuration registry for the payout service's background job scheduler. The payout service reads this table at startup (via PayoutSchedulerJob_Get) to know which jobs to schedule, how often to run them (cron expression), and how many items to process per invocation (MaxItems). This is a DB-driven scheduler configuration - changing IsActive or Cron in this table reconfigures the payout service without code deployment.

6 jobs are configured:
- **PayoutProcessJob** (every 10s, active): Processes pending withdrawal payouts via the standard payout pipeline.
- **WorldpayPullResultJob** (every 10s, **inactive**): Polls WorldPay for pending payout results. Disabled - possibly replaced by webhook-based notification.
- **RedeemClosePositionProcessJob** (every 10s, active): Processes copy-trading position redemption close requests.
- **RedeemTransferUnitsProcessJob** (every 10s, active): Processes redemption unit transfer operations.
- **RdeemNegativeBalanceProcessJob** (every 10s, active): Handles redemptions for negative balance scenarios (note: typo in JobName "Rdeem" instead of "Redeem").
- **InstantCashoutProcessJob** (every 1s, active): High-frequency job for instant cashout processing. Runs every second with a conservative MaxItems=10 (vs 1000 for others).

---

## 2. Business Logic

### 2.1 Job Scheduling Configuration

**What**: The cron expression and IsActive flag control when and whether a job runs.

**Columns/Parameters Involved**: `Cron`, `IsActive`, `MaxItems`

**Rules**:
- Cron format: Quartz-style cron (7 fields: seconds minutes hours day-of-month month day-of-week year).
- `0/10 * * * * ? *`: Every 10 seconds starting at second 0. Used by 5 of the 6 jobs.
- `*/1 * * * * ? *`: Every 1 second. Used only by InstantCashoutProcessJob for near-real-time processing.
- IsActive=0 (WorldpayPullResultJob): PayoutSchedulerJob_Get filters WHERE IsActive=1, so this job is never loaded. Likely disabled when WorldPay switched from polling to push notifications.
- MaxItems: The batch limit per invocation. Standard jobs: 1000. InstantCashoutProcessJob: 10 (high frequency but small batches to minimize latency per run).
- Parameters column: NULL for all current jobs. Reserved for future job-specific configuration parameters (JSON or key-value pairs).

---

## 3. Data Overview

| JobID | JobName | Cron | IsActive | MaxItems |
|-------|---------|------|---------|---------|
| 1 | PayoutProcessJob | Every 10s | Active | 1000 |
| 2 | WorldpayPullResultJob | Every 10s | **Inactive** | 1000 |
| 3 | RedeemClosePositionProcessJob | Every 10s | Active | 1000 |
| 4 | RedeemTransferUnitsProcessJob | Every 10s | Active | 1000 |
| 5 | RdeemNegativeBalanceProcessJob | Every 10s | Active | 1000 |
| 6 | InstantCashoutProcessJob | Every 1s | Active | 10 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | JobID | int | NO | - | CODE-BACKED | Manual (non-identity) integer PK. IDs 1-6 are sequential. New jobs are manually inserted with the next ID. |
| 2 | JobName | varchar(50) | NO | - | VERIFIED | Logical name of the background job. Must match the name the payout service code uses to register the job with its scheduler. Note: JobID=5 has typo "RdeemNegativeBalanceProcessJob" (should be "Redeem"). |
| 3 | Cron | varchar(160) | NO | - | VERIFIED | Quartz-style 7-field cron expression defining the run schedule. Current values: "0/10 * * * * ? *" (every 10 seconds) or "*/1 * * * * ? *" (every 1 second). 160-char limit allows complex cron expressions. |
| 4 | IsActive | bit | YES | 1 | VERIFIED | Whether the payout service should load and schedule this job. Default 1 (active). PayoutSchedulerJob_Get filters WHERE IsActive=1 - inactive jobs are never returned to the service. Currently only WorldpayPullResultJob is IsActive=0. |
| 5 | Parameters | varchar(500) | YES | - | CODE-BACKED | Optional job-specific configuration parameters. NULL for all current jobs. Reserved for future use - could hold JSON configuration for job variants or environment-specific settings. |
| 6 | MaxItems | int | YES | 1000 | CODE-BACKED | Maximum number of items to process per job invocation. Default 1000. InstantCashoutProcessJob uses 10 to keep each run fast and responsive. Controls throughput/latency tradeoff per job type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints. JobName values implicitly map to job class names in the payout service codebase.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.PayoutSchedulerJob_Get | JobID, JobName, Cron, IsActive, Parameters, MaxItems | SELECT reader | Only reader. Returns all active (IsActive=1) jobs. Called by the payout service at startup to configure its scheduler. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayoutSchedulerJob (table)
  (leaf - tables have no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.PayoutSchedulerJob_Get | Stored Procedure | Reads active jobs for payout service scheduler initialization |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Billing_PayoutSchedulerJob | CLUSTERED PK | JobID ASC | - | - | Active (PAGE compressed, FILLFACTOR=90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Billing_PayoutSchedulerJob | PRIMARY KEY | JobID clustered |
| Df_Billing_PayoutSchedulerJob_IsActive | DEFAULT | 1 for IsActive |
| Df_Billing_PayoutSchedulerJob_MaxItems | DEFAULT | 1000 for MaxItems |

---

## 8. Sample Queries

### 8.1 Get all active payout jobs (as the service does)

```sql
EXEC Billing.PayoutSchedulerJob_Get
-- Returns all IsActive=1 jobs
```

### 8.2 View full job configuration

```sql
SELECT JobID, JobName, Cron, IsActive, MaxItems, Parameters
FROM Billing.PayoutSchedulerJob WITH (NOLOCK)
ORDER BY JobID
```

---

## 9. Atlassian Knowledge Sources

Code comment in Billing.PayoutSchedulerJob_Get references Jira 43131 (Geri Reshef, 27/02/2017 - "DB - Cashout new SP"), the original cashout/payout service implementation ticket.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.PayoutSchedulerJob | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.PayoutSchedulerJob.sql*
