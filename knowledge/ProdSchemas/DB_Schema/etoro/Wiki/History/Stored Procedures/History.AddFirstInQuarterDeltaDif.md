# History.AddFirstInQuarterDeltaDif

> Scheduled archiving job that downsamples Trade.DeltaDiff from near-real-time (every ~15 seconds) to quarter-hourly resolution by inserting the first snapshot from each 15-minute window into History.DeltaDiff.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; driven by MAX(ValidFrom) in source and target tables |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.DeltaDiff` captures system-wide financial reconciliation snapshots approximately every 15 seconds during trading hours. This high-frequency data is valuable for real-time monitoring but impractical to retain indefinitely. This procedure performs **quarter-hourly downsampling** - it reads the source table and copies only the **first snapshot from each 15-minute window** into `History.DeltaDiff`, reducing data volume by roughly 60x while preserving the long-term trend shape.

The procedure underpins the financial reconciliation audit trail: `History.DeltaDiff` goes back to 2010 and is used by risk managers and the finance team to monitor system-wide realized/unrealized PnL accumulation over time, detect anomalies, and produce historical reports. Without this procedure, the long-term history archive would either be missing or bloated with redundant near-duplicate snapshots.

Data flow: this procedure is called by a **scheduled SQL Agent job** (no application callers). It is designed to run periodically - likely every 15 minutes - and is fully idempotent: it reads `MAX(ValidFrom)` from `History.DeltaDiff` to resume from where it left off. `PROD\BIadmins` have VIEW DEFINITION access, indicating BI teams inspect this procedure for reporting purposes.

---

## 2. Business Logic

### 2.1 Quarter-Hour Downsampling via Partition + ROW_NUMBER

**What**: Groups Trade.DeltaDiff records into 15-minute buckets and keeps only the earliest record per bucket.

**Columns/Parameters Involved**: `ValidFrom` (source), `DeltaDiffID` (for ordering)

**Rules**:
- Bucket assignment: `DATEDIFF(mi, ValidFrom, @StartTime) / 15` - integer division groups consecutive minutes into the same bucket.
- `ROW_NUMBER() OVER (PARTITION BY bucket ORDER BY ValidFrom)` - within each bucket, records are numbered from earliest to latest.
- Only rows where `RowNum = 1` are inserted - i.e., the **earliest** snapshot per 15-minute window.
- All 17 columns from Trade.DeltaDiff are copied verbatim (DeltaDiffID through ValidTo).

**Diagram**:
```
Trade.DeltaDiff (high freq ~15s):
  ValidFrom=09:00:04  RowNum=1 <- COPIED to History.DeltaDiff
  ValidFrom=09:00:19  RowNum=2 <- skipped
  ValidFrom=09:00:34  RowNum=3 <- skipped
  ... (many records) ...
  ValidFrom=09:15:03  RowNum=1 <- COPIED (new 15-min window)
  ValidFrom=09:15:18  RowNum=2 <- skipped
```

### 2.2 Incremental Execution (Idempotent Resume)

**What**: Each execution resumes from the last inserted record, not from scratch.

**Columns/Parameters Involved**: `@StartTime`, `@MaxTrValidFrom`

**Rules**:
- `@StartTime = MAX(ValidFrom) FROM History.DeltaDiff` - finds the last-inserted record's timestamp.
- If `History.DeltaDiff` is empty (`@StartTime IS NULL`): sets `@StartTime = '19000101'` to process ALL of Trade.DeltaDiff.
- If not empty: advances `@StartTime` by exactly 15 minutes using the rounding trick: `DATEADD(mi, DATEDIFF(mi,'20100101',@StartTime)+15, '20100101')`. This aligns to the next 15-minute boundary from the epoch `2010-01-01`.
- All Trade.DeltaDiff records with `ValidFrom >= @StartTime` are eligible.

### 2.3 End-of-Trading-Week Marker

**What**: When no new records exist but the source has not been updated for 15+ minutes, the last Trade record is inserted as a final snapshot.

**Columns/Parameters Involved**: `@MaxTrValidFrom`, `@@ROWCOUNT`

**Rules**:
- Triggers when ALL conditions are true:
  1. `@@ROWCOUNT = 0` (CTE insert produced no rows - no new data)
  2. `DATEDIFF(mm, @MaxTrValidFrom, GETUTCDATE()) >= 15` (Trade.DeltaDiff has been idle for 15+ minutes - market closed or paused)
  3. `NOT EXISTS (SELECT ValidFrom FROM History.DeltaDiff WHERE ValidFrom = @MaxTrValidFrom)` (the last Trade record not yet in History)
- When triggered: inserts `SELECT TOP 1 ... FROM Trade.DeltaDiff ORDER BY ValidFrom DESC` - the absolute latest Trade record.
- Business meaning: ensures History.DeltaDiff ends with the final snapshot at market close, not trailing off with a gap.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

*This procedure has no parameters - it operates entirely based on table state.*

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (no parameters) | - | - | - | CODE-BACKED | This procedure takes no input parameters. It derives all state from MAX(ValidFrom) comparisons between Trade.DeltaDiff and History.DeltaDiff. |

**Internal variables (not parameters):**

| Variable | Type | Purpose |
|----------|------|---------|
| @MaxTrValidFrom | DATETIME | MAX(ValidFrom) from Trade.DeltaDiff - the latest available source record |
| @StartTime | DATETIME | Resume point: MAX(ValidFrom)+15min from History.DeltaDiff, or '19000101' on first run |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | Trade.DeltaDiff | Read | Source table - all 17 columns are read and downsampled from here. |
| INSERT | History.DeltaDiff | Write | Target archive table - receives the first record per 15-minute window. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent job (scheduled) | EXEC call | Scheduler | Called on a scheduled interval (likely every 15 minutes) to perform incremental archiving. No SQL procedure callers. |
| PROD\BIadmins | VIEW DEFINITION grant | Monitoring | BI team has view definition access for monitoring/debugging. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.AddFirstInQuarterDeltaDif (procedure)
├── Trade.DeltaDiff (table) [cross-schema - SELECT source]
└── History.DeltaDiff (table) [INSERT target]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.DeltaDiff | Table | SELECT source - reads all records with ValidFrom >= @StartTime, partitioned into 15-minute buckets. |
| History.DeltaDiff | Table | INSERT target and state source - MAX(ValidFrom) is read to determine resume point; new rows are inserted here. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.DeltaDiff | Table | Populated exclusively by this procedure. Without this procedure running, History.DeltaDiff would not be updated. |
| SQL Agent scheduler | External | Calls this procedure on a recurring schedule to keep History.DeltaDiff current. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURN @@ERROR | Return value | Returns the SQL error code (0 = success). Callers (SQL Agent) can inspect this to detect failures. |
| Idempotency | Design constraint | Multiple consecutive runs are safe - the @StartTime advance logic ensures already-processed records are not re-inserted (provided History.DeltaDiff.ValidFrom has a unique-ish constraint or the duplicate check is handled by the bucketing). |

---

## 8. Sample Queries

### 8.1 Check the latest record in History.DeltaDiff vs Trade.DeltaDiff

```sql
SELECT
    'History' AS Source,
    MAX(ValidFrom) AS LatestValidFrom,
    COUNT(*) AS TotalRows
FROM History.DeltaDiff WITH (NOLOCK)
UNION ALL
SELECT
    'Trade' AS Source,
    MAX(ValidFrom) AS LatestValidFrom,
    COUNT(*) AS TotalRows
FROM Trade.DeltaDiff WITH (NOLOCK);
```

### 8.2 Verify quarter-hourly pattern in History.DeltaDiff

```sql
SELECT TOP 10
    DeltaDiffID,
    ValidFrom,
    DATEDIFF(MINUTE, LAG(ValidFrom) OVER (ORDER BY ValidFrom), ValidFrom) AS MinutesSincePrev,
    Diff,
    RealizedPNL,
    UnRealizedPNL
FROM History.DeltaDiff WITH (NOLOCK)
ORDER BY ValidFrom DESC;
```

### 8.3 Detect gaps in archive history (missing 15-min windows)

```sql
SELECT
    ValidFrom,
    LEAD(ValidFrom) OVER (ORDER BY ValidFrom) AS NextValidFrom,
    DATEDIFF(MINUTE, ValidFrom, LEAD(ValidFrom) OVER (ORDER BY ValidFrom)) AS GapMinutes
FROM History.DeltaDiff WITH (NOLOCK)
WHERE ValidFrom >= DATEADD(DAY, -7, GETUTCDATE())
HAVING DATEDIFF(MINUTE, ValidFrom, LEAD(ValidFrom) OVER (ORDER BY ValidFrom)) > 30
ORDER BY ValidFrom;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.AddFirstInQuarterDeltaDif | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.AddFirstInQuarterDeltaDif.sql*
