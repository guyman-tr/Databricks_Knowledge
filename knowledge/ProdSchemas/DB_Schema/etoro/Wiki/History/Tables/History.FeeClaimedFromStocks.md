# History.FeeClaimedFromStocks

> Execution log recording each activation of the stocks fee claiming batch process, with one row inserted per run to provide a timestamp audit trail and a correlation ID returned to the caller.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (IDENTITY PK, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (CLUSTERED PK on ID) |

---

## 1. Business Meaning

This table is an operation run log for the stocks overnight fee claiming batch process. Every time `Trade.ActivateStocksFeeJobs` is called, it inserts a single row here (via `INSERT DEFAULT VALUES`) before starting six parallel SQL Agent jobs (`ClaimFeeFromStocks00` through `ClaimFeeFromStocks05`). The auto-generated ID is returned to the caller via OUTPUT parameter, providing a correlation key for the batch run.

The stocks fee claiming process collects overnight/holding fees from positions in real stock instruments. Because the volume of stock positions requires parallel processing, the job is sharded across 6 SQL Agent jobs (shards 00-05). Each activation event is recorded here at the moment the jobs are launched, establishing an authoritative timestamp for when fee claiming was initiated.

The table has no rows in the current environment, indicating the stocks fee job activation has not been called (either the feature is inactive, the environment does not run this batch, or history has been pruned). The `NOT FOR REPLICATION` flag on the IDENTITY column prevents ID re-seeding during database replication scenarios. `WITH EXECUTE AS OWNER` and a certificate signature on `Trade.ActivateStocksFeeJobs` grant it the elevated permissions required to start SQL Agent jobs.

---

## 2. Business Logic

### 2.1 Run Activation Log Pattern

**What**: A single INSERT serves as both an audit record and the mechanism for generating a unique run ID that can be returned to the orchestrating caller.

**Columns/Parameters Involved**: `ID`, `TakenAt`

**Rules**:
- Only `Trade.ActivateStocksFeeJobs` writes to this table - called by the stocks fee orchestration layer
- `INSERT DEFAULT VALUES` requires no explicit values: ID auto-increments, TakenAt defaults to GETUTCDATE()
- `SET @ID = @@IDENTITY` immediately after INSERT returns the new run ID to the caller
- This ID can be used downstream to correlate job results with a specific activation event
- One row = one complete activation (all 6 shards started together)

**Diagram**:
```
Caller invokes Trade.ActivateStocksFeeJobs(@ID OUTPUT)
    |
    v
INSERT INTO History.FeeClaimedFromStocks DEFAULT VALUES
    -> ID = next identity, TakenAt = GETUTCDATE()
    -> @ID returned to caller
    |
    v
msdb.dbo.sp_start_job 'ClaimFeeFromStocks00'
msdb.dbo.sp_start_job 'ClaimFeeFromStocks01'
...
msdb.dbo.sp_start_job 'ClaimFeeFromStocks05'
    -> 6 parallel SQL Agent job shards launched
```

---

## 3. Data Overview

| ID | TakenAt | Meaning |
|---|---|---|
| (empty) | (empty) | Table currently has 0 rows. The stocks fee claiming job activation has not been recorded in this environment. Each future activation will add one row with the UTC timestamp of when the 6 ClaimFeeFromStocks jobs were started. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate PK, auto-incrementing identity. Unique run identifier for each stocks fee claiming activation. Returned as OUTPUT parameter from Trade.ActivateStocksFeeJobs - the caller uses this value to correlate the job activation with downstream results. NOT FOR REPLICATION prevents identity re-seeding during replication. |
| 2 | TakenAt | datetime | YES | GETUTCDATE() | CODE-BACKED | UTC timestamp when this fee claiming activation was initiated - i.e., when Trade.ActivateStocksFeeJobs was called and the 6 SQL Agent jobs were started. Populated automatically by DEFAULT constraint; no application code sets this value explicitly. NULL is allowed by DDL but in practice always populated by the default. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ActivateStocksFeeJobs | - | Writer | Sole writer: inserts one DEFAULT VALUES row per activation before starting the 6 ClaimFeeFromStocks SQL Agent jobs. Returns the new ID as an OUTPUT parameter. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.FeeClaimedFromStocks (table)
- no code-level dependencies (leaf table, operation log)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ActivateStocksFeeJobs | Stored Procedure | Inserts into this table to log each batch activation and obtain a run correlation ID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryFeeClaimedFromStocks | CLUSTERED | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_HistoryFeeClaiemdFromStocks_TakenAt | DEFAULT | TakenAt = GETUTCDATE() - automatically stamps UTC activation time on every row insert |

---

## 8. Sample Queries

### 8.1 All fee claiming activation events

```sql
SELECT
    ID,
    TakenAt,
    DATEDIFF(HOUR, TakenAt, GETUTCDATE()) AS HoursAgo
FROM History.FeeClaimedFromStocks WITH (NOLOCK)
ORDER BY TakenAt DESC;
```

### 8.2 How often is the fee claiming job activated? (frequency analysis)

```sql
SELECT
    CAST(TakenAt AS DATE) AS ActivationDate,
    COUNT(*) AS ActivationsOnDay,
    MIN(TakenAt) AS FirstActivation,
    MAX(TakenAt) AS LastActivation
FROM History.FeeClaimedFromStocks WITH (NOLOCK)
GROUP BY CAST(TakenAt AS DATE)
ORDER BY ActivationDate DESC;
```

### 8.3 Find gap in activations (missed fee runs)

```sql
SELECT
    curr.ID,
    curr.TakenAt AS ThisRun,
    prev.TakenAt AS PreviousRun,
    DATEDIFF(HOUR, prev.TakenAt, curr.TakenAt) AS HoursBetweenRuns
FROM History.FeeClaimedFromStocks curr WITH (NOLOCK)
JOIN History.FeeClaimedFromStocks prev WITH (NOLOCK)
    ON prev.ID = curr.ID - 1
WHERE DATEDIFF(HOUR, prev.TakenAt, curr.TakenAt) > 25  -- expected ~24h, flag if >25h
ORDER BY curr.TakenAt DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Trade.ActivateStocksFeeJobs) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.FeeClaimedFromStocks | Type: Table | Source: etoro/etoro/History/Tables/History.FeeClaimedFromStocks.sql*
