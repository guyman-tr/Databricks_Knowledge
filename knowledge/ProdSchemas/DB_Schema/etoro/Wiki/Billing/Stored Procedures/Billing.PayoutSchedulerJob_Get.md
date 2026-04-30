# Billing.PayoutSchedulerJob_Get

> Returns all active payout scheduler job configurations, providing the payout and redeem services with the job names, cron schedules, and batch size limits they need to drive automated payment processing.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | IsActive=1 filter |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PayoutSchedulerJob_Get` is the configuration reader for eToro's payout scheduler. When the SecurePay integration (SQL_SecurePay) or the redeem service (RedeemServiceUser) starts up or needs to refresh its job configuration, it calls this procedure to discover which scheduled jobs are currently active. Each job record contains everything the service needs to run: a cron expression for timing, a maximum item count to cap batch sizes, and a parameter string for job-specific configuration.

This is a pure read-only, no-logic procedure - it is intentionally a thin veneer over `Billing.PayoutSchedulerJob` that enforces the `IsActive=1` business filter. Only enabled jobs are returned; soft-deleted or suspended jobs are excluded automatically. Services consuming this output drive the automated cashout and redemption pipelines.

---

## 2. Business Logic

### 2.1 Active Job Filter

**What**: Returns only jobs that are currently enabled for scheduling.

**Columns Involved**: `Billing.PayoutSchedulerJob.IsActive`

**Rules**:
- WHERE IsActive=1: excludes suspended or decommissioned jobs.
- No date-range filter: IsActive is the sole on/off switch.
- All six columns from the scheduler table are returned (no projection suppression).

**Diagram**:
```
Service startup / config refresh:
  EXEC Billing.PayoutSchedulerJob_Get
    |
  SELECT JobID, JobName, Cron, IsActive, Parameters, MaxItems
  FROM Billing.PayoutSchedulerJob
  WHERE IsActive = 1
    |
  Result: all currently-enabled payout/redeem scheduler jobs
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| *(no parameters)* | - | - | - | - | - | This procedure takes no parameters. |

**Result Set Columns**:

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | JobID | Billing.PayoutSchedulerJob.JobID | PK identity. Unique job identifier. |
| 2 | JobName | Billing.PayoutSchedulerJob.JobName | Human-readable name of the scheduled job (e.g., 'PayoutJob', 'RedeemJob'). Used by the service to identify which logic block to invoke. |
| 3 | Cron | Billing.PayoutSchedulerJob.Cron | Cron expression defining the run schedule (e.g., '*/5 * * * *' = every 5 minutes). Parsed by the calling service's scheduler. |
| 4 | IsActive | Billing.PayoutSchedulerJob.IsActive | Always 1 (the WHERE clause guarantees this). Returned for completeness so callers can confirm they received active records. |
| 5 | Parameters | Billing.PayoutSchedulerJob.Parameters | JSON or structured string with job-specific configuration (e.g., FundingTypeIDs to process, endpoint URLs). Parsed by the calling service. |
| 6 | MaxItems | Billing.PayoutSchedulerJob.MaxItems | Maximum number of items to process per job run. Used by the service as the @MaxNumOfItems argument when fetching payout records. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| IsActive=1 | [Billing.PayoutSchedulerJob](../Tables/Billing.PayoutSchedulerJob.md) | Read (SELECT) | Reads all active scheduler job configurations. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_SecurePay (db role) | - | EXEC | SecurePay integration reads active jobs on startup/refresh to drive payout scheduling. |
| RedeemServiceUser (db role) | - | EXEC | Redeem service reads active jobs to configure its redemption processing schedule. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayoutSchedulerJob_Get (procedure)
└── Billing.PayoutSchedulerJob (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.PayoutSchedulerJob](../Tables/Billing.PayoutSchedulerJob.md) | Table | SELECT - reads all rows WHERE IsActive=1. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_SecurePay application role | Application | Scheduler configuration reader for payout service. |
| RedeemServiceUser application role | Application | Scheduler configuration reader for redeem service. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

The WHERE IsActive=1 filter benefits from any index on IsActive in `Billing.PayoutSchedulerJob`. As a small configuration table (few rows), a full scan is negligible.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Fetch all active scheduler jobs

```sql
EXEC Billing.PayoutSchedulerJob_Get;
-- Returns all rows from Billing.PayoutSchedulerJob WHERE IsActive=1
```

### 8.2 Direct query equivalent

```sql
SELECT JobID, JobName, Cron, IsActive, Parameters, MaxItems
FROM Billing.PayoutSchedulerJob WITH (NOLOCK)
WHERE IsActive = 1;
```

### 8.3 Check which jobs are currently active vs inactive

```sql
SELECT
    JobID,
    JobName,
    Cron,
    IsActive,
    MaxItems
FROM Billing.PayoutSchedulerJob WITH (NOLOCK)
ORDER BY IsActive DESC, JobName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PayoutSchedulerJob_Get | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PayoutSchedulerJob_Get.sql*
