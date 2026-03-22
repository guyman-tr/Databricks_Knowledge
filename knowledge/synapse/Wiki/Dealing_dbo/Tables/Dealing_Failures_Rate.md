# Dealing_dbo.Dealing_Failures_Rate

> Daily dealing execution failure rate — the single-metric companion to the Dealing_Failures error breakdown table.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | `etoro.Hedge.ExecutionLog` (production) |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on Date |

---

## 1. Business Meaning

This table stores a single daily metric: the proportion of hedge executions that failed. It answers: "What percentage of dealing executions failed today?"

The failure rate is calculated from `CopyFromLake.etoro_Hedge_ExecutionLog`, which records every hedge execution attempt with a `Success` flag (0=fail, 1=success). The formula: `failures / total_executions`.

Loaded by the same `SP_Failures(@Date)` that fills `Dealing_Failures`. One row per day.

---

## 2. Business Logic

### 2.1 Failure Rate Calculation

**What**: Overall ratio of failed to total hedge execution attempts.

**Columns Involved**: `Failure_Rate`

**Rules**:
- `Failure_Rate = SUM(CASE WHEN Success = 0 THEN Success_Failure ELSE 0 END) / NULLIF(SUM(Success_Failure), 0)`
- `Success_Failure = CAST(COUNT(*) AS DECIMAL(16,6))` grouped by Success flag
- Source data filtered: `ExecutionTime >= @Date AND ExecutionTime < @DayAfter`
- Returns NULL when no execution records exist for the day (NULLIF protection)

---

## 3. Query Advisory

### 3.1 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Today's failure rate | `WHERE Date = @date` |
| Failure rate trend | `SELECT Date, Failure_Rate WHERE Date BETWEEN ... ORDER BY Date` |
| High failure days | `WHERE Failure_Rate > 0.05 ORDER BY Failure_Rate DESC` |

### 3.2 Gotchas

- **NULL Failure_Rate**: Recent data (Nov 2025+) shows NULL values. This may indicate the CopyFromLake.etoro_Hedge_ExecutionLog source stopped loading or the ExecutionLog path changed. Investigate before relying on recent data.
- **Scope**: This rate covers hedge (LP-side) execution only, not client-side order failures. For client-side error breakdown, use `Dealing_Failures`.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Report date. (Tier 2 — SP_Failures) |
| 2 | Failure_Rate | decimal(16,6) | YES | Proportion of hedge executions that failed. `failed_count / total_count`. Range: 0.000000 (no failures) to 1.000000 (all failed). Typical: 0.01-0.02 (1-2%). NULL when no data. (Tier 2 — SP_Failures) |
| 3 | UpdateDate | datetime | YES | ETL load timestamp. `GETDATE()`. (Tier 2 — SP_Failures) |

---

## 5. Lineage

### 5.1 ETL Pipeline

```
etoro.Hedge.ExecutionLog → CopyFromLake → SP_Failures → Dealing_Failures_Rate
```

---

## 6. Relationships

### 6.1 Companion Objects

| Object | Relationship |
|--------|-------------|
| Dealing_dbo.Dealing_Failures | Loaded by same SP. Provides error code breakdown. |

---

*Generated: 2026-03-21 | Quality: 7.0/10 (★★★☆☆) | Phases: 7/14*
*Tiers: 0 T1, 3 T2, 0 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 8/10, Relationships: 6/10, Sources: 7/10*
*Object: Dealing_dbo.Dealing_Failures_Rate | Type: Table | Production Source: Derived*
