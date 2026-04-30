# Hedge.ArchiveHedgeTables

> Master archive orchestrator for the primary server: sequentially archives AccountStatus, CustomerOpenPositions, AccountOpenPositions, AccountClosedPositions, and CustomerClosedPositions from Hedge tables into History schema, using interval-aligned date windows.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Orchestrator - calls 5 Archive* stored procedures sequentially |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.ArchiveHedgeTables` is the top-level orchestration procedure for the Hedge schema archiving pipeline. It coordinates the archival of 5 rolling Hedge tables into their corresponding History schema counterparts, ensuring that each archive covers precisely the time interval since the last successful archive run.

The procedure implements a "watermark advancement" pattern: for each table, it reads the maximum `OccurredAt` from the corresponding History table to find where the last archive ended, then rounds that date forward to the next complete interval window, and calls the respective Archive* procedure with the computed `@StartDate` and the current interval-aligned `@EndDate`.

The `@IntervalInMinutes` parameter defines the archive granularity - typically 15 minutes, meaning data is archived in 15-minute windows. This ensures the History tables contain complete, non-overlapping, interval-aligned windows.

A companion procedure `Hedge.ArchiveHedgeTables_SS` handles the secondary server (SS) variation where CustomerOpenPositions and CustomerClosedPositions are archived to a separate `DB_Logs` database.

Per the Confluence page "Database Archiving" (DBAC space), this procedure is part of the scheduled archiving infrastructure for trading data.

---

## 2. Business Logic

### 2.1 Interval-Aligned Date Window Calculation

**What**: Both @StartDate and @EndDate are rounded to the nearest @IntervalInMinutes boundary to ensure clean, non-overlapping archive windows.

**Columns/Parameters Involved**: `@IntervalInMinutes`, `@StartDate`, `@EndDate`

**Rules**:
- `@EndDate` = floor of current time to nearest @IntervalInMinutes: `DATEADD(minute, (DATEDIFF(minute,'2010-01-01', getdate())/@IntervalInMinutes)*@IntervalInMinutes, '2010-01-01')`
- `@StartDate` per table = ceiling of last History OccurredAt to next @IntervalInMinutes: `DATEADD(minute, (DATEDIFF(minute,'2010-01-01', @StartDate)/@IntervalInMinutes+1)*@IntervalInMinutes, '2010-01-01')`
- If History table is empty (first run), @StartDate defaults to '2010-01-01' (the epoch reference date)
- `@StartDate > @EndDate` is possible if last archive ran very recently - the Archive* SPs handle this gracefully

### 2.2 Sequential 5-Step Archive Pipeline

**What**: Each of 5 Hedge tables is archived in sequence, each with its own independently computed date window.

**Rules**:
1. AccountStatus -> History.AccountStatus watermark -> Hedge.ArchiveAccountStatus
2. CustomerOpenPositions -> History.CustomerOpenPositions watermark -> Hedge.ArchiveCustomerOpenPositions
3. AccountOpenPositions -> History.AccountOpenPositions watermark -> Hedge.ArchiveAccountOpenPositions
4. AccountClosedPositions -> History.AccountClosedPositions watermark -> Hedge.ArchiveAccountClosedPositions
5. CustomerClosedPositions -> History.CustomerClosedPositions watermark -> Hedge.ArchiveCustomerClosedPositions

Each step is independent - step N's watermark is computed fresh from the History table, not inherited from step N-1.

**Diagram**:
```
Hedge.ArchiveHedgeTables(@IntervalInMinutes)
      |
      @EndDate = interval_floor(getdate(), @IntervalInMinutes)
      |
      Step 1: @StartDate = interval_ceil(MAX(OccurredAt) FROM History.AccountStatus, @IntervalInMinutes)
              EXEC Hedge.ArchiveAccountStatus @StartDate, @EndDate, @IntervalInMinutes
      |
      Step 2: @StartDate = interval_ceil(MAX(OccurredAt) FROM History.CustomerOpenPositions, @IntervalInMinutes)
              EXEC Hedge.ArchiveCustomerOpenPositions @StartDate, @EndDate, @IntervalInMinutes
      |
      Step 3: EXEC Hedge.ArchiveAccountOpenPositions   (same pattern)
      Step 4: EXEC Hedge.ArchiveAccountClosedPositions (same pattern)
      Step 5: EXEC Hedge.ArchiveCustomerClosedPositions (same pattern)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IntervalInMinutes | int | NO | - | CODE-BACKED | Archive window granularity in minutes (typically 15). Drives both the @EndDate floor calculation and the @StartDate ceiling calculation per table. A value of 15 creates 15-minute archive windows; 60 creates hourly windows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | History.AccountStatus | Lookup | Reads MAX(OccurredAt) to compute archive start date |
| (reads) | History.CustomerOpenPositions | Lookup | Watermark for CustomerOpenPositions archive |
| (reads) | History.AccountOpenPositions | Lookup | Watermark for AccountOpenPositions archive |
| (reads) | History.AccountClosedPositions | Lookup | Watermark for AccountClosedPositions archive |
| (reads) | History.CustomerClosedPositions | Lookup | Watermark for CustomerClosedPositions archive |
| (calls) | Hedge.ArchiveAccountStatus | Procedure call | Archives AccountStatus data to History |
| (calls) | Hedge.ArchiveCustomerOpenPositions | Procedure call | Archives CustomerOpenPositions data to History |
| (calls) | Hedge.ArchiveAccountOpenPositions | Procedure call | Archives AccountOpenPositions data to History |
| (calls) | Hedge.ArchiveAccountClosedPositions | Procedure call | Archives AccountClosedPositions data to History |
| (calls) | Hedge.ArchiveCustomerClosedPositions | Procedure call | Archives CustomerClosedPositions data to History |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Invoked by a scheduled SQL Agent job. See also `Hedge.ArchiveHedgeTables_SS` for the secondary-server variant.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ArchiveHedgeTables (procedure)
├── History.AccountStatus (table) - watermark read
├── History.CustomerOpenPositions (table) - watermark read
├── History.AccountOpenPositions (table) - watermark read
├── History.AccountClosedPositions (table) - watermark read
├── History.CustomerClosedPositions (table) - watermark read
├── Hedge.ArchiveAccountStatus (procedure)
├── Hedge.ArchiveCustomerOpenPositions (procedure)
├── Hedge.ArchiveAccountOpenPositions (procedure)
├── Hedge.ArchiveAccountClosedPositions (procedure)
└── Hedge.ArchiveCustomerClosedPositions (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.AccountStatus | Table | SELECT MAX(OccurredAt) watermark |
| History.CustomerOpenPositions | Table | SELECT MAX(OccurredAt) watermark |
| History.AccountOpenPositions | Table | SELECT MAX(OccurredAt) watermark |
| History.AccountClosedPositions | Table | SELECT MAX(OccurredAt) watermark |
| History.CustomerClosedPositions | Table | SELECT MAX(OccurredAt) watermark |
| Hedge.ArchiveAccountStatus | Procedure | Performs the actual AccountStatus archive |
| Hedge.ArchiveCustomerOpenPositions | Procedure | Performs the actual CustomerOpenPositions archive |
| Hedge.ArchiveAccountOpenPositions | Procedure | Performs the actual AccountOpenPositions archive |
| Hedge.ArchiveAccountClosedPositions | Procedure | Performs the actual AccountClosedPositions archive |
| Hedge.ArchiveCustomerClosedPositions | Procedure | Performs the actual CustomerClosedPositions archive |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (SQL Agent archiving job) | External | Calls with @IntervalInMinutes=15 on a schedule |
| Hedge.ArchiveHedgeTables_SS | Procedure | Companion for secondary server - same pattern, different CustomerOpen/Closed targets |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- No transaction wrapper - each Archive* call is independent
- No error handling - if one step fails, subsequent steps do not run
- Reference epoch date '2010-01-01' used consistently across all date calculations (not GETDATE() as epoch)

---

## 8. Sample Queries

### 8.1 Execute: Run archive for 15-minute windows

```sql
EXEC Hedge.ArchiveHedgeTables @IntervalInMinutes = 15
```

### 8.2 Preview: Check what date windows would be computed for each History table

```sql
DECLARE @Interval INT = 15
DECLARE @EndDate DATETIME = DATEADD(minute,(DATEDIFF(minute,'2010-01-01',getdate())/@Interval)*@Interval,'2010-01-01')

SELECT
    'AccountStatus' AS Table_Name,
    DATEADD(minute,(DATEDIFF(minute,'2010-01-01',ISNULL(MAX(OccurredAt),'2010-01-01'))/@Interval+1)*@Interval,'2010-01-01') AS StartDate,
    @EndDate AS EndDate
FROM History.AccountStatus WITH (NOLOCK)
UNION ALL
SELECT 'CustomerOpenPositions',
    DATEADD(minute,(DATEDIFF(minute,'2010-01-01',ISNULL(MAX(OccurredAt),'2010-01-01'))/@Interval+1)*@Interval,'2010-01-01'),
    @EndDate
FROM History.CustomerOpenPositions WITH (NOLOCK)
```

### 8.3 Monitor: Check archive lag per History table

```sql
SELECT
    'History.AccountStatus' AS Table_Name, MAX(OccurredAt) AS LastArchived, DATEDIFF(MINUTE, MAX(OccurredAt), GETUTCDATE()) AS LagMinutes
FROM History.AccountStatus WITH (NOLOCK)
UNION ALL
SELECT 'History.CustomerOpenPositions', MAX(OccurredAt), DATEDIFF(MINUTE, MAX(OccurredAt), GETUTCDATE())
FROM History.CustomerOpenPositions WITH (NOLOCK)
ORDER BY LagMinutes DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Database Archiving](https://etoro-jira.atlassian.net/wiki/spaces/DBAC/pages/11834951297/Database+Archiving) | Confluence | This procedure is part of the scheduled archiving infrastructure for hedge trading data (DBAC space) |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ArchiveHedgeTables | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.ArchiveHedgeTables.sql*
