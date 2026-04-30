# Hedge.GetCurrentAccountStatus

> Inline TVF: returns the single most-recent account status row per HedgeServerID from Hedge.AccountStatus, filtered to data within the last hour and after a caller-supplied @LastRunTime. Used for polling current LP account financial metrics.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Function (Inline Table-Valued) |
| **Parameters** | @LastRunTime datetime |
| **Returns** | TABLE - one row per HedgeServerID (latest status within constraints) |

---

## 1. Business Meaning

Hedge.GetCurrentAccountStatus is a polling function: callers supply the timestamp of their last run, and it returns the latest account status for each hedge server, but only if that status is fresh (within the past hour AND newer than @LastRunTime).

This implements a "give me what's changed since I last asked" contract:
- The `@LastRunTime` filter returns only rows newer than the caller's last observation
- The `DATEADD(hh,-1,getutcdate())` filter ensures NO stale data is returned - if a hedge server hasn't reported status in over an hour, it is excluded entirely
- `ROW_NUMBER() OVER (PARTITION BY HedgeServerID ORDER BY OccurredAt DESC)` collapses multiple status rows per server to just the latest one

The function reads from Hedge.AccountStatus which is an append-only status log. This function provides the "current snapshot" view of that log.

**Commented-out design decision**: The PARTITION BY originally included `, LiquidityAccountID` (still visible as a comment). The current design returns ONE row per HedgeServerID (the latest status regardless of which LP account), not per (HedgeServerID, LiquidityAccountID). This simplification suggests callers care about the server's overall financial state, not per-account granularity.

---

## 2. Business Logic

### 2.1 Two-Layer Time Filter

**Parameters**: `@LastRunTime datetime`

**Rules**:
1. `OccurredAt >= @LastRunTime` - only return status newer than caller's last observation (incremental polling)
2. `OccurredAt >= DATEADD(hh,-1, getutcdate())` - hard cap: never return data older than 1 hour, regardless of @LastRunTime
3. Both conditions must be true (AND) - the stricter of the two applies
4. If @LastRunTime is more than 1 hour ago: the 1-hour cap takes precedence
5. If @LastRunTime is within the last hour: @LastRunTime takes precedence

**Practical behavior**:
- Callers pass their own last-check timestamp and get only new data since then
- If a hedge server hasn't reported in over an hour, no row is returned for it (excluded by filter)
- This provides implicit staleness detection: missing rows = server not reporting

### 2.2 Latest-Row Deduplication (ROW_NUMBER)

**Logic**:
```sql
ROW_NUMBER() OVER (PARTITION BY HedgeServerID ORDER BY OccurredAt DESC) AS RowNum
```
WHERE RowNum = 1 -> the single most recent status row per HedgeServerID

**Commented-out partition extension**:
```sql
--, LiquidityAccountID
```
If un-commented, the result would include one row per (HedgeServerID, LiquidityAccountID) instead of one per HedgeServerID. The comment indicates this was considered but reverted - the function currently ignores per-account granularity.

---

## 3. Output Columns

| Column | Source | Description |
|--------|--------|-------------|
| HedgeServerID | Hedge.AccountStatus | Hedge server that reported this status |
| LiquidityAccountID | Hedge.AccountStatus | LP account the status pertains to |
| OccurredAt | Hedge.AccountStatus | When this status was recorded (latest within filter) |
| OccurredAtAccount | Hedge.AccountStatus | Account-side timestamp (may differ from OccurredAt) |
| Balance | Hedge.AccountStatus | Cash balance of the LP account in account currency |
| NetPL | Hedge.AccountStatus | Net profit/loss on open positions |
| Equity | Hedge.AccountStatus | Balance + NetPL = total equity |
| UsedMargin | Hedge.AccountStatus | Margin currently in use by open positions |
| UsableMargin | Hedge.AccountStatus | Available margin (Equity - UsedMargin) |
| MaintenanceMargin | Hedge.AccountStatus | Minimum margin required to maintain positions |
| CurrentLeverage | Hedge.AccountStatus | Current leverage ratio |
| Cushion | Hedge.AccountStatus | Safety buffer between Equity and MaintenanceMargin |
| GrossPositionsValue | Hedge.AccountStatus | Total notional value of all open positions |

For full column descriptions and value semantics, see [Hedge.AccountStatus](Hedge.AccountStatus.md).

---

## 4. Usage Example

```sql
-- Poll for updated account status since last check
DECLARE @LastCheck datetime = '2026-03-19 09:00:00';

SELECT  HedgeServerID, LiquidityAccountID, OccurredAt,
        Balance, Equity, UsedMargin, UsableMargin, Cushion
FROM    [Hedge].[GetCurrentAccountStatus](@LastCheck) WITH (NOLOCK)
ORDER BY HedgeServerID;
-- Returns: one row per HedgeServerID with fresh status since @LastCheck
-- Missing servers: no status update in the last hour (potential connectivity issue)
```

---

## 5. Relationships

### 5.1 Source Tables

| Table | How Used |
|-------|----------|
| Hedge.AccountStatus | Source table - queried for status rows within time bounds |

### 5.2 Consumed By

No stored procedures found referencing this function. Application code calls it directly.

---

## 6. Dependencies

```
Hedge.GetCurrentAccountStatus (function)
+-- Hedge.AccountStatus (table) [see Hedge.AccountStatus.md]
```

---

## 7. Atlassian Knowledge Sources

No Atlassian sources found for this function.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11 (Function phases)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | Corrections: 0 applied*
*Object: Hedge.GetCurrentAccountStatus | Type: Function | Source: etoro/etoro/Hedge/Functions/Hedge.GetCurrentAccountStatus.sql*
