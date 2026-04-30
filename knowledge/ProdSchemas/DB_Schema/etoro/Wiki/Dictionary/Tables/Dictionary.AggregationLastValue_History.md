# Dictionary.AggregationLastValue_History

> Historical audit trail of aggregation watermark snapshots, recording each execution's high-water marks for incremental data processing jobs so operators can troubleshoot aggregation delays and verify processing continuity.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 clustered (PK_DALV_Hist on ID) |

---

## 1. Business Meaning

Dictionary.AggregationLastValue_History is the time-series audit log for the aggregation watermark system. Each row captures a point-in-time snapshot of where incremental aggregation jobs (credit transactions, login sessions) had reached at the moment of execution. This creates a detailed history of aggregation progress over time.

Without this table, operators would have no way to diagnose aggregation delays, verify that watermarks are advancing steadily, or detect periods where aggregation stalled. It serves as the observability layer for the incremental processing engine that aggregates billions of rows from History.Credit and History.Login.

Rows are inserted by BackOffice.UpsertIntoAggregationTablesAction at the start of each aggregation cycle (approximately once per minute). The procedure captures the current watermark values from Dictionary.AggregationLastValue along with the maximum IDs found in source tables, then writes a snapshot row. A cross-database synonym (dbo.RW_AggregationLastValue_History) provides access from other databases.

---

## 2. Business Logic

### 2.1 Aggregation Progress Tracking

**What**: Each row is a timestamped snapshot of where aggregation jobs have reached in their source tables.

**Columns/Parameters Involved**: `EXECUTION_TIME`, `LastCreditID`, `MaxCreditID`, `LastLoggedOut`, `MaxLoggedOut`

**Rules**:
- `EXECUTION_TIME` is set to `GETUTCDATE()` at the moment of insertion — marks when the snapshot was taken
- `LastCreditID` captures the watermark from Dictionary.AggregationLastValue — the last credit ID that was fully aggregated
- `MaxCreditID` captures the actual maximum CreditID in History.Credit at snapshot time — the "frontier" of unaggregated data
- The gap between `LastCreditID` and `MaxCreditID` indicates how much work remains (aggregation backlog)
- `MaxCreditOccurred` records when the max credit row was created — used to measure aggregation latency in wall-clock time

**Diagram**:
```
Aggregation Cycle (~1 min intervals):
  ┌─────────────────────────────────────────────┐
  │  UpsertIntoAggregationTablesAction           │
  │  1. Read current watermarks from             │
  │     Dictionary.AggregationLastValue          │
  │  2. Read MAX(CreditID) from History.Credit   │
  │  3. INSERT snapshot into _History table  ◄───┤── THIS TABLE
  │  4. Process new rows (LastID → MaxID)        │
  │  5. Update watermarks in AggregationLastValue│
  └─────────────────────────────────────────────┘
```

### 2.2 Login vs Credit Tracking (Partial Deprecation)

**What**: The table has columns for both login and credit watermarks, but login tracking appears deprecated.

**Columns/Parameters Involved**: `MaxLoginID`, `MaxLoggedOut`, `LastLoggedOut`

**Rules**:
- `MaxLoginID` and `MaxLoggedOut` are always NULL in current data — login watermark tracking has been commented out in the INSERT statement
- `LastLoggedOut` still records a value but appears frozen (same value across all recent rows), suggesting login aggregation no longer advances
- Credit aggregation (`LastCreditID`/`MaxCreditID`) remains fully active and is the primary use case

---

## 3. Data Overview

| ID | EXECUTION_TIME | LastCreditID | MaxCreditID | MaxCreditOccurred | Meaning |
|---|---|---|---|---|---|
| 3107952 | 2026-03-14 10:01 | 2174671929 | 2174671929 | 2026-03-14 09:42 | Most recent snapshot — aggregation is fully caught up (Last = Max), credit processing is current |
| 3107951 | 2026-03-14 10:00 | 2174671929 | 2174671929 | 2026-03-14 09:42 | One minute earlier — same watermarks confirm steady state with no new credits in that minute |
| 3107950 | 2026-03-14 09:59 | 2174671929 | 2174671929 | 2026-03-14 09:42 | Continued steady state — when the gap between Last and Max is zero, aggregation has no backlog |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-incrementing surrogate key. Each row represents one aggregation cycle snapshot. Over 3M rows accumulated at ~1 row/minute since system inception. |
| 2 | EXECUTION_TIME | datetime | NO | - | CODE-BACKED | UTC timestamp when this snapshot was taken, set via `GETUTCDATE()` in BackOffice.UpsertIntoAggregationTablesAction. Used to measure aggregation frequency and detect stalls. |
| 3 | LastCreditID | bigint | YES | - | CODE-BACKED | The last CreditID that was fully aggregated at snapshot time. Copied from Dictionary.AggregationLastValue.LastSampleID for the History.Credit source. When this equals MaxCreditID, aggregation is fully caught up. |
| 4 | LastLoggedOut | datetime | YES | - | CODE-BACKED | The last login LoggedOut timestamp that was aggregated. Currently appears frozen — login aggregation is no longer actively advancing. Historically tracked History.Login processing watermark. |
| 5 | MaxCreditID | bigint | YES | - | CODE-BACKED | The maximum CreditID found in History.Credit at the moment of this snapshot. Represents the "frontier" — the newest credit transaction that exists. Gap between LastCreditID and MaxCreditID measures aggregation backlog. |
| 6 | MaxCreditOccurred | datetime | YES | - | CODE-BACKED | Timestamp when the MaxCreditID row was created in History.Credit. Measures aggregation latency in wall-clock time: `EXECUTION_TIME - MaxCreditOccurred` = how far behind aggregation is in real time. |
| 7 | MaxLoginID | bigint | YES | - | CODE-BACKED | Maximum LoginID from History.Login at snapshot time. Currently always NULL — login watermark tracking has been commented out in the INSERT statement of UpsertIntoAggregationTablesAction. |
| 8 | MaxLoggedOut | datetime | YES | - | CODE-BACKED | Maximum LoggedOut timestamp from History.Login at snapshot time. Currently always NULL — deprecated alongside MaxLoginID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (no FK constraints). Logically related to Dictionary.AggregationLastValue (the live watermark table whose values are snapshotted here).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.RW_AggregationLastValue_History | (synonym) | Synonym | Cross-database access alias for this history table |
| BackOffice.UpsertIntoAggregationTablesAction | INSERT | Writer | Inserts one snapshot row per aggregation cycle |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.AggregationLastValue_History (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.UpsertIntoAggregationTablesAction | Stored Procedure | Writer — inserts snapshot rows each aggregation cycle |
| dbo.RW_AggregationLastValue_History | Synonym | Cross-database access alias |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DALV_Hist | CLUSTERED | ID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 Check current aggregation backlog
```sql
SELECT TOP 5
        ID,
        EXECUTION_TIME,
        LastCreditID,
        MaxCreditID,
        MaxCreditID - LastCreditID AS CreditBacklog,
        DATEDIFF(SECOND, MaxCreditOccurred, EXECUTION_TIME) AS LatencySeconds
FROM    [Dictionary].[AggregationLastValue_History] WITH (NOLOCK)
ORDER BY ID DESC;
```

### 8.2 Detect aggregation stalls (no watermark advancement in 10+ minutes)
```sql
SELECT  a.EXECUTION_TIME AS StallStart,
        b.EXECUTION_TIME AS StallEnd,
        DATEDIFF(MINUTE, a.EXECUTION_TIME, b.EXECUTION_TIME) AS StallMinutes
FROM    [Dictionary].[AggregationLastValue_History] a WITH (NOLOCK)
JOIN    [Dictionary].[AggregationLastValue_History] b WITH (NOLOCK)
        ON b.ID = a.ID + 10
WHERE   a.LastCreditID = b.LastCreditID
        AND DATEDIFF(MINUTE, a.EXECUTION_TIME, b.EXECUTION_TIME) > 10
ORDER BY a.ID DESC;
```

### 8.3 Daily aggregation throughput summary
```sql
SELECT  CAST(EXECUTION_TIME AS DATE) AS AggDate,
        MIN(LastCreditID) AS DayStartCredit,
        MAX(LastCreditID) AS DayEndCredit,
        MAX(LastCreditID) - MIN(LastCreditID) AS CreditsProcessed,
        COUNT(*) AS SnapshotCount
FROM    [Dictionary].[AggregationLastValue_History] WITH (NOLOCK)
GROUP BY CAST(EXECUTION_TIME AS DATE)
ORDER BY AggDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AggregationLastValue_History | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.AggregationLastValue_History.sql*
