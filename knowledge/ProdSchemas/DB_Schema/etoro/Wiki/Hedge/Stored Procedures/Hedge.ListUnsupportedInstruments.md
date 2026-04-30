# Hedge.ListUnsupportedInstruments

> Monitoring query called by Splunk and Nagios: returns (HedgeServerID, InstrumentID) pairs where HBC execution failed with "is not active for hedging" in the last 5 minutes, enabling external alerting systems to detect instruments that have been rejected from the hedging flow.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Zero-parameter monitoring SELECT; callers: SplunkUser, Nagios |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.ListUnsupportedInstruments` is a monitoring procedure that surfaces instruments recently rejected from HBC hedging due to the "is not active for hedging" failure reason. When an HBC execution is submitted for an instrument that the hedge server or liquidity provider considers inactive (e.g., market is closed, instrument was delisted, provider configuration removed), the execution is rejected with a `FailReason` containing this string, which is logged into `Hedge.HBCOrderLog`.

This procedure is NOT called by the hedge server application itself. Instead, it is called by external monitoring systems: **Splunk** (log aggregation/alerting) and **Nagios** (infrastructure monitoring), both of which hold EXECUTE permission. It is the "full list" variant - returning one row per (HedgeServerID, InstrumentID) combination with recent failures. A companion procedure `Monitor.ListUnsupportedInstruments_Datadog` uses the identical logic but returns a boolean (1/0) for Datadog alert integration.

**Important filter note**: The time filter `hol.StartTime = DATEADD(minute,-5,GETUTCDATE())` uses an exact datetime equality comparison. Because `StartTime` is a `datetime` column (millisecond precision) and `DATEADD` produces a precise datetime value, this filter will almost never match rows in practice - a range predicate (`>=`) appears to have been intended. The `OPTION (RECOMPILE)` hint ensures SQL Server compiles a fresh plan for each execution (relevant because `GETUTCDATE()` produces a runtime value), but the equality filter means this procedure effectively returns empty results in production unless the call happens to coincide precisely with a matching stored datetime.

Note: An earlier documentation source (the `Hedge.HBCOrder` UDT doc) incorrectly listed this procedure as accepting an `@HBCOrders` TVP parameter. The SSDT DDL - the authoritative source - confirms this procedure has **no parameters**.

---

## 2. Business Logic

### 2.1 "Not Active for Hedging" Failure Detection

**What**: Surfaces instruments where HBC executions have been rejected due to inactivity status.

**Columns/Parameters Involved**: `hol.FailReason`, `hol.StartTime`, `hel.HedgeServerID`, `hel.InstrumentID`

**Rules**:
- `FailReason LIKE '%is not active for hedging%'`: partial string match allows for minor variations in the failure message prefix/suffix.
- `StartTime = DATEADD(minute,-5,GETUTCDATE())`: intended as a 5-minute lookback window. Due to exact equality on datetime precision, this virtually never matches in practice. The intended behavior was likely `>= DATEADD(minute,-5,...)`.
- Grouping by (HedgeServerID, InstrumentID): collapses multiple order-level failures for the same instrument/server into one output row. An instrument that failed 10 times in the window appears once.
- JOIN to HBCExecutionLog: required because HBCOrderLog does not directly carry InstrumentID - only ExecutionID and order-level data. HBCExecutionLog has InstrumentID and HedgeServerID.

**Diagram**:
```
Monitoring System (Splunk / Nagios)
  |
  | EXEC Hedge.ListUnsupportedInstruments (no params)
  |
  | SELECT hel.HedgeServerID, hel.InstrumentID
  |   FROM Hedge.HBCOrderLog hol WITH (NOLOCK)
  |   JOIN Hedge.HBCExecutionLog hel WITH (NOLOCK)
  |     ON hol.ExecutionID = hel.ExecutionID
  |   WHERE hol.FailReason LIKE '%is not active for hedging%'
  |     AND hol.StartTime = DATEADD(minute,-5,GETUTCDATE())
  |   GROUP BY hel.HedgeServerID, hel.InstrumentID
  |   OPTION (RECOMPILE)
  |
  v
Result set: (HedgeServerID INT, InstrumentID INT)
  - One row per server/instrument combination with recent "not active" rejections
  - Consumed by Splunk/Nagios for alerting dashboards
```

### 2.2 Companion Procedures - Monitoring Ecosystem

**What**: Three related procedures serve different monitoring consumers with the same underlying data.

**Rules**:
- `Hedge.ListUnsupportedInstruments` (this procedure): returns full (HedgeServerID, InstrumentID) list. Callers: SplunkUser, Nagios.
- `Monitor.ListUnsupportedInstruments_Datadog`: wraps the same query in `IF EXISTS(...)` and returns 1 (alert) or 0 (clear). Caller: Datadog integration.
- Both share identical join logic and the same `StartTime =` filter.
- The separation allows different monitoring platforms to consume results in their native format (tabular vs boolean).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure accepts no parameters. The result set contains:

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | HedgeServerID | INT | The hedge server instance that attempted the rejected execution. Sourced from `Hedge.HBCExecutionLog.HedgeServerID`. |
| 2 | InstrumentID | INT | The instrument that was rejected as "not active for hedging". Sourced from `Hedge.HBCExecutionLog.InstrumentID`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Hedge.HBCOrderLog | Reader (NOLOCK) | Reads FailReason and StartTime to detect "not active for hedging" failures |
| - | Hedge.HBCExecutionLog | Reader (NOLOCK) | Joins on ExecutionID to resolve InstrumentID and HedgeServerID |

### 5.2 Referenced By (other objects point to this)

| Object | Type | How Used |
|--------|------|----------|
| SplunkUser (db role) | Permission | EXECUTE - Splunk log integration calls this for alerting |
| Nagios (db role) | Permission | EXECUTE - Nagios monitoring calls this for infrastructure alerts |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ListUnsupportedInstruments (procedure)
|-- Hedge.HBCOrderLog (table) [READ - FailReason filter, StartTime filter]
+-- Hedge.HBCExecutionLog (table) [READ - InstrumentID, HedgeServerID resolution via ExecutionID JOIN]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HBCOrderLog | Table | Read: FailReason LIKE filter and StartTime filter to find "not active" rejections |
| Hedge.HBCExecutionLog | Table | Read: JOIN to resolve InstrumentID and HedgeServerID for each failed order |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SplunkUser | Database Role | EXECUTE permission - monitoring consumer |
| Nagios | Database Role | EXECUTE permission - monitoring consumer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OPTION (RECOMPILE) | Query hint | Forces fresh execution plan per call. Important because GETUTCDATE() produces a runtime value that should influence the plan's cardinality estimate. |
| NOLOCK on both tables | Isolation hint | Read uncommitted - prevents lock contention with the HBC execution write path (LogHBCExecution inserts into both tables). |
| StartTime = DATEADD(minute,-5,...) | Datetime equality | Intended as a 5-minute lookback filter. In practice, exact datetime equality against GETUTCDATE() output almost never matches stored rows (millisecond precision mismatch). |

---

## 8. Sample Queries

### 8.1 Execute and review result
```sql
EXEC [Hedge].[ListUnsupportedInstruments]
```

### 8.2 Manually simulate the filter with a range (intended behavior)
```sql
-- What the procedure INTENDS to return (range vs equality)
SELECT hel.HedgeServerID, hel.InstrumentID
FROM Hedge.HBCOrderLog hol WITH (NOLOCK)
JOIN Hedge.HBCExecutionLog hel WITH (NOLOCK)
    ON hol.ExecutionID = hel.ExecutionID
WHERE hol.FailReason LIKE '%is not active for hedging%'
  AND hol.StartTime >= DATEADD(minute, -5, GETUTCDATE())
GROUP BY hel.HedgeServerID, hel.InstrumentID
```

### 8.3 Check historical "not active for hedging" failures by instrument
```sql
SELECT hel.InstrumentID, hel.HedgeServerID,
       COUNT(1) AS FailureCount,
       MIN(hol.StartTime) AS FirstFailure,
       MAX(hol.StartTime) AS LastFailure
FROM Hedge.HBCOrderLog hol WITH (NOLOCK)
JOIN Hedge.HBCExecutionLog hel WITH (NOLOCK)
    ON hol.ExecutionID = hel.ExecutionID
WHERE hol.FailReason LIKE '%is not active for hedging%'
  AND hol.StartTime >= DATEADD(day, -7, GETUTCDATE())
GROUP BY hel.InstrumentID, hel.HedgeServerID
ORDER BY FailureCount DESC
```

### 8.4 Compare with Datadog boolean companion
```sql
-- Datadog version: same logic, returns 1/0
EXEC [Monitor].[ListUnsupportedInstruments_Datadog]
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL repo | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ListUnsupportedInstruments | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.ListUnsupportedInstruments.sql*
