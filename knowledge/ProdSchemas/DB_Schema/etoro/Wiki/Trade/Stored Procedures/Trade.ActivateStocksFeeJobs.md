# Trade.ActivateStocksFeeJobs

> Initiates the stock fee claiming process by logging a fee run into History.FeeClaimedFromStocks and starting six parallel SQL Agent jobs (ClaimFeeFromStocks00-05).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ID (INT OUTPUT) - the generated fee run ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the **entry point for the stock fee claiming batch process**. eToro charges fees on real stock positions (overnight fees, management fees), and this procedure orchestrates the collection by creating a new fee run record and launching six parallel SQL Agent jobs that partition the work across customer segments.

Without this procedure, stock fees would not be claimed from customer accounts. The six parallel jobs (ClaimFeeFromStocks00 through ClaimFeeFromStocks05) divide the customer base for parallel processing, ensuring the fee run completes within acceptable time windows.

The procedure runs with `EXECUTE AS OWNER` because starting SQL Agent jobs via `msdb.dbo.sp_start_job` requires elevated permissions. The procedure must be signed by `JobRunnerCert` - altering the procedure invalidates the signature, which must then be reapplied.

---

## 2. Business Logic

### 2.1 Fee Run Lifecycle

**What**: Each invocation creates a new fee run ID that tracks this specific fee claiming cycle.

**Columns/Parameters Involved**: `@ID`, `History.FeeClaimedFromStocks`

**Rules**:
- INSERT DEFAULT VALUES into History.FeeClaimedFromStocks generates a new identity-based run ID
- @@IDENTITY captures the run ID into the OUTPUT parameter @ID
- The six Agent jobs use this run ID to coordinate their work
- Caller receives the run ID for monitoring and troubleshooting

### 2.2 Parallel Job Dispatch

**What**: Six SQL Agent jobs are started in rapid succession to parallelize fee claiming.

**Columns/Parameters Involved**: `msdb.dbo.sp_start_job`

**Rules**:
- Jobs ClaimFeeFromStocks00 through ClaimFeeFromStocks05 are started sequentially via sp_start_job
- Each job handles a different partition of customers (likely based on CID modulo or range)
- If any sp_start_job call fails (job already running, Agent stopped), the error propagates to the caller
- No TRY/CATCH - failures are not caught within the procedure

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | INT | NO | OUTPUT | CODE-BACKED | Returns the identity value from the newly inserted row in History.FeeClaimedFromStocks. This is the fee run ID that the six Agent jobs use to coordinate their work. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | History.FeeClaimedFromStocks | INSERT | Creates a new fee run record (DEFAULT VALUES) to generate a run ID |
| - | msdb.dbo.sp_start_job | EXEC | Starts six SQL Agent jobs for parallel fee claiming |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (External caller) | - | EXEC | Called by a scheduled process or operations to initiate fee claiming |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ActivateStocksFeeJobs (procedure)
+-- History.FeeClaimedFromStocks (table)
+-- msdb.dbo.sp_start_job (system procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.FeeClaimedFromStocks | Table | INSERT DEFAULT VALUES to generate fee run ID |
| msdb.dbo.sp_start_job | System Procedure | Starts six Agent jobs |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| EXECUTE AS OWNER | Impersonation | Required for msdb.dbo.sp_start_job permissions |
| Certificate signing | Security | Must be signed by JobRunnerCert; altering the procedure invalidates the signature |

---

## 8. Sample Queries

### 8.1 Execute the fee claiming process

```sql
DECLARE @RunID INT;
EXEC Trade.ActivateStocksFeeJobs @ID = @RunID OUTPUT;
SELECT @RunID AS FeeRunID;
```

### 8.2 Check recent fee run history

```sql
SELECT  TOP 10 *
FROM    History.FeeClaimedFromStocks WITH (NOLOCK)
ORDER BY 1 DESC;
```

### 8.3 Monitor Agent job status for fee claiming jobs

```sql
SELECT  j.name,
        ja.start_execution_date,
        ja.stop_execution_date,
        CASE ja.last_executed_step_id
            WHEN 0 THEN 'Not yet started'
            ELSE 'Step ' + CAST(ja.last_executed_step_id AS VARCHAR)
        END AS LastStep
FROM    msdb.dbo.sysjobs j WITH (NOLOCK)
        JOIN msdb.dbo.sysjobactivity ja WITH (NOLOCK)
            ON j.job_id = ja.job_id
WHERE   j.name LIKE 'ClaimFeeFromStocks%'
        AND ja.session_id = (SELECT MAX(session_id) FROM msdb.dbo.sysjobactivity WITH (NOLOCK))
ORDER BY j.name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ActivateStocksFeeJobs | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ActivateStocksFeeJobs.sql*
