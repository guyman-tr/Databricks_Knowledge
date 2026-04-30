# Hedge.GetAccountClosedPositionsData

> Aggregates recent hedge account closed position P&L and execution volume from a reference date, grouped by hedge server, liquidity account, and instrument - used by the hedge cost monitoring service.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ReferenceDate, @HedgeServers - filter parameters for recent execution window |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves aggregated P&L and volume data from `Hedge.AccountClosedPositions` for a specified time window and set of hedge servers. It is called by the hedge cost monitoring service to feed the realized hedge cost calculation pipeline.

Each execution of this procedure returns one row per (HedgeServerID, LiquidityAccountID, InstrumentID) combination, with summed `NetPL` and `ExecutionVolumeInUSD` since the reference date. This aggregated data is compared with the corresponding client-side (`CustomerClosedPositions`) data to compute the realized hedge cost - the difference represents eToro's profit or loss from hedging activity.

The procedure is designed for high-frequency calls by the monitoring service (the developer comments note "since this query runs lots of times") and uses dynamic SQL with a comma-separated `@HedgeServers` parameter to avoid repeated XML/string parsing overhead for the IN clause. However, this approach introduces a SQL injection risk since `@HedgeServers` is directly concatenated into the query string.

---

## 2. Business Logic

### 2.1 P&L Aggregation for Hedge Cost Calculation

**What**: Returns summed NetPL and ExecutionVolumeInUSD since a reference date, enabling the hedge cost service to compute the delta between account-side and client-side P&L.

**Columns/Parameters Involved**: `@ReferenceDate`, `@HedgeServers`, `NetPL`, `ExecutionVolumeInUSD`, `OccurredAt`

**Rules**:
- Only rows where `OccurredAt > @ReferenceDate` are included - this is a "since last check" window
- `@HedgeServers` must be a comma-separated list of integer IDs without leading/trailing commas (e.g., "1,3,5,6")
- Groups are: (HedgeServerID, LiquidityAccountID, InstrumentID) - one output row per combination
- `SUM(NetPL)` - total realized P&L from the broker/execution side for this group
- `SUM(ExecutionVolumeInUSD)` - total USD notional traded for this group
- `MAX(OccurredAt)` - the most recent event timestamp in this group (for watermark tracking)

**Diagram**:
```
Hedge.AccountClosedPositions (OccurredAt > @ReferenceDate, HedgeServerID IN (...))
  --> GROUP BY HedgeServerID, LiquidityAccountID, InstrumentID
  --> SUM(NetPL), SUM(ExecutionVolumeInUSD), MAX(OccurredAt)
  --> [compare with CustomerClosedPositions to get Hedge Cost - Realized]
```

### 2.2 Dynamic SQL Pattern (Performance vs Security Trade-off)

**What**: The `@HedgeServers` IN clause is built via string concatenation to avoid CSV parsing overhead on a high-frequency call path.

**Rules**:
- `@HedgeServers` is directly concatenated: `'...HedgeServerID IN (' + @HedgeServers + ')'`
- Developer comment: "I didn't want to have to parse XML and comma separated string in order to know which HedgeServerID should be in the query"
- The `@ReferenceDate` parameter IS properly parameterized via sp_executesql (no injection risk for the date)
- Risk: If `@HedgeServers` is not validated by the caller, SQL injection is possible - the caller must ensure this is a clean integer list
- Companion procedure `GetAccountTransactionsData` uses the same pattern

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ReferenceDate | datetime | NO | - | CODE-BACKED | Lower bound for the time window. Only `AccountClosedPositions` rows with `OccurredAt > @ReferenceDate` are included. Typically set to the timestamp of the last successful check by the monitoring service (watermark pattern). |
| 2 | @HedgeServers | varchar(300) | NO | - | CODE-BACKED | Comma-separated list of HedgeServerID integers to include in the filter (e.g., "1,3,5,6"). Directly injected into the IN clause of dynamic SQL - must be a validated integer list from the caller. Maximum 300 characters supports approximately 30-40 server IDs. |

**Output Columns** (not a declared result set - derived from the dynamic SQL SELECT):

| Column | Source | Description |
|--------|--------|-------------|
| HedgeServerID | Hedge.AccountClosedPositions | The hedge server that executed the closing events |
| LiquidityAccountID | Hedge.AccountClosedPositions | The liquidity provider account that held the positions |
| InstrumentID | Hedge.AccountClosedPositions | The trading instrument being closed |
| NetPL | SUM(NetPL) | Total account-side realized P&L since @ReferenceDate for this group |
| ExecutionVolumeInUSD | SUM(ExecutionVolumeInUSD) | Total USD notional executed for this group |
| OccurredAt | MAX(OccurredAt) | Most recent close event timestamp in this group (watermark tracking) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Hedge.AccountClosedPositions | Direct read (SELECT) | Source of hedge account closed position data - broker-side P&L and volume |

### 5.2 Referenced By (other objects point to this)

The `Hedge.AccountClosedPositions` doc notes this procedure is called by the "hedge cost monitoring service" to feed the realized hedge cost calculation. No SQL-level callers found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetAccountClosedPositionsData (procedure)
└── Hedge.AccountClosedPositions (table) - SELECT source
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AccountClosedPositions | Table | SELECT with GROUP BY - aggregates closed position P&L and volume by (HedgeServerID, LiquidityAccountID, InstrumentID) since a reference date |

### 6.2 Objects That Depend On This

No SQL-level dependents found. Called externally by the hedge cost monitoring application service.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dynamic SQL | Design | Uses sp_executesql with partial parameterization - @ReferenceDate is a proper SQL parameter, @HedgeServers is concatenated directly (injection risk if caller doesn't validate) |
| SET NOCOUNT ON | Performance | Suppresses row count messages for high-frequency call path |
| Result grouping | Business Rule | One row per (HedgeServerID, LiquidityAccountID, InstrumentID) with SUM aggregates - designed for delta comparison with CustomerClosedPositions |

---

## 8. Sample Queries

### 8.1 Equivalent of what the procedure returns (for testing)

```sql
DECLARE @ReferenceDate datetime = DATEADD(hour, -1, GETUTCDATE())

SELECT HedgeServerID, LiquidityAccountID, InstrumentID,
       SUM(NetPL) AS NetPL,
       SUM(ExecutionVolumeInUSD) AS ExecutionVolumeInUSD,
       MAX(OccurredAt) AS OccurredAt
FROM Hedge.AccountClosedPositions WITH (NOLOCK)
WHERE OccurredAt > @ReferenceDate
  AND HedgeServerID IN (1,2,3)
GROUP BY HedgeServerID, LiquidityAccountID, InstrumentID
```

### 8.2 Validate recent data available for the reference window

```sql
SELECT HedgeServerID,
       MIN(OccurredAt) AS OldestInWindow,
       MAX(OccurredAt) AS NewestInWindow,
       COUNT(*) AS RawRows
FROM Hedge.AccountClosedPositions WITH (NOLOCK)
WHERE OccurredAt > DATEADD(hour, -1, GETUTCDATE())
GROUP BY HedgeServerID
ORDER BY HedgeServerID
```

### 8.3 Compare with expected hedge server list

```sql
SELECT DISTINCT HedgeServerID
FROM Hedge.AccountClosedPositions WITH (NOLOCK)
WHERE OccurredAt > DATEADD(day, -1, GETUTCDATE())
ORDER BY HedgeServerID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Context from `Hedge.AccountClosedPositions` doc (Confluence DROD space): this procedure is part of the "Hedge Cost Service" pipeline, comparing broker-side P&L with client-side data to measure realized hedge cost.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetAccountClosedPositionsData | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetAccountClosedPositionsData.sql*
