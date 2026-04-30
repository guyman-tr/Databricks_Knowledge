# Hedge.GetReferenceAccountStatus

> Returns the most recent LP account status snapshot (balance, equity, margin, leverage) within a date range for specified hedge servers, providing a point-in-time reference of the LP account financial state for reconciliation and reporting.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartReferenceDate + @EndReferenceDate + @HedgeServerIDs - date window and server filter |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetReferenceAccountStatus` retrieves the most recent LP account status snapshot for each hedge server within a specified date range. While `Hedge.GetReferenceAccountOpenPositions` captures position-level data (what instruments are hedged), this procedure captures account-level financial state: balance, equity, margin usage, and leverage. Together they provide the complete reference picture of the LP account's state for a given reporting period.

The "reference" designation (shared with GetReferenceAccountOpenPositions) indicates this is the point-in-time reference snapshot used for reconciliation, not the live current state. The hedge cost reporting pipeline uses both procedures to compute the difference between what eToro's customers gained/lost (customer book) and what the LP account gained/lost (hedge book) - the difference is the hedge cost.

The `Hedge.AccountStatus` table (from the summary context) is a rolling 30-day time-series of LP account snapshots. This procedure distills that time-series to a single reference row per hedge server by selecting the most recent row within the analysis window. The ROW_NUMBER() function (unlike RANK() in GetReferenceAccountOpenPositions) guarantees exactly one row per partition even for tied timestamps.

`OccurredAtAccount` is the LP-side timestamp of the status update (when the LP's own systems recorded the account state), while `OccurredAt` is when eToro's hedge server recorded the snapshot. The `Cushion` column (Equity - Maintenance Margin) indicates how much buffer remains before a margin call from the LP.

---

## 2. Business Logic

### 2.1 Most-Recent-Snapshot Selection via ROW_NUMBER()

**What**: A CTE uses ROW_NUMBER() to identify the single most recent account status row per HedgeServerID within the date window. Exactly one row per HedgeServerID is returned.

**Columns/Parameters Involved**: `HedgeServerID`, `OccurredAt`, `RowNum`

**Rules**:
- ROW_NUMBER() OVER (PARTITION BY HedgeServerID ORDER BY OccurredAt DESC): partitions by hedge server, assigns sequential row numbers descending by snapshot time
- RowNum=1 is the most recent snapshot for each HedgeServerID in the window - exactly one row, even for tied timestamps (ROW_NUMBER breaks ties arbitrarily, unlike RANK)
- WHERE OccurredAt BETWEEN @StartReferenceDate AND @EndReferenceDate: restricts to the reference window
- Note: partitioned by HedgeServerID only (not LiquidityAccountID) - one reference row per server regardless of how many LP accounts the server manages

### 2.2 Dynamic SQL with IN-List Injection

**What**: Same pattern as GetReferenceAccountOpenPositions - @HedgeServerIDs is injected into the IN clause, date parameters are safely parameterized.

**Columns/Parameters Involved**: `@HedgeServerIDs`, `@StartReferenceDate`, `@EndReferenceDate`

**Rules**:
- Identical dynamic SQL construction pattern to GetReferenceAccountOpenPositions
- @HedgeServerIDs directly concatenated into IN clause (internal reporting design pattern)
- @StartReferenceDate and @EndReferenceDate passed as typed parameters to sp_executesql

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartReferenceDate | datetime | NO | - | VERIFIED | Start of the reference date window (inclusive). Filters Hedge.AccountStatus to OccurredAt >= this value. Parameterized safely in sp_executesql. |
| 2 | @EndReferenceDate | datetime | NO | - | VERIFIED | End of the reference date window (inclusive). Filters Hedge.AccountStatus to OccurredAt <= this value. Parameterized safely in sp_executesql. |
| 3 | @HedgeServerIDs | varchar(4000) | NO | - | VERIFIED | Comma-separated list of integer HedgeServerIDs (e.g., '1,2,3'). Injected directly into the IN clause of dynamic SQL. Mirrors the same parameter convention as GetReferenceAccountOpenPositions. |

**Output columns** (from Hedge.AccountStatus):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | HedgeServerID | int | NO | - | VERIFIED | The hedge server that recorded this account status snapshot. Partition key for ROW_NUMBER(). One row per HedgeServerID in the output. |
| 5 | LiquidityAccountID | int | NO | - | VERIFIED | The LP account whose status is captured. FK to Trade.LiquidityAccounts. Multiple LP accounts may be managed by one hedge server; the most recent snapshot across all accounts is returned per server. |
| 6 | OccurredAt | datetime | NO | - | VERIFIED | eToro-side timestamp when the hedge server recorded this status snapshot. The most recent value within the date window for each HedgeServerID partition. |
| 7 | OccurredAtAccount | datetime | YES | - | VERIFIED | LP-side timestamp from the FIX account statement message (when the LP's system generated the status). May lag OccurredAt due to message transport time. Used to reconcile eToro's recording time vs LP's statement time. |
| 8 | Balance | decimal | YES | - | VERIFIED | LP account cash balance at snapshot time. Excludes unrealized P&L. Starting cash balance before open position effects. |
| 9 | NetPL | decimal | YES | - | VERIFIED | Net realized profit/loss on the LP account as of this snapshot. Accumulates all closed position P&L for the account. |
| 10 | Equity | decimal | YES | - | VERIFIED | Total account equity: Balance + unrealized P&L from open positions. The primary solvency indicator. A negative Equity triggers LP margin calls. |
| 11 | UsedMargin | decimal | YES | - | VERIFIED | Margin currently committed to open hedge positions. Amount of the account balance locked as collateral. |
| 12 | UsableMargin | decimal | YES | - | VERIFIED | Available margin for new positions: Equity - UsedMargin. Determines capacity to add new hedge positions. |
| 13 | MaintenanceMargin | decimal | YES | - | VERIFIED | Minimum equity threshold required by the LP before a margin call is triggered. When Equity < MaintenanceMargin, the LP may force-close positions. |
| 14 | CurrentLeverage | decimal | YES | - | VERIFIED | Current leverage ratio: GrossPositionsValue / Equity. Indicates how many times the account's equity is deployed in open positions. High leverage increases liquidation risk. |
| 15 | Cushion | decimal | YES | - | VERIFIED | Safety buffer: Equity - MaintenanceMargin. Positive cushion = safe; approaching zero = near margin call; negative = margin call triggered. Key risk monitoring metric in hedge reporting. |
| 16 | GrossPositionsValue | decimal | YES | - | VERIFIED | Total gross market value of all open hedge positions on this LP account. Used for leverage calculation and position size monitoring. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Hedge.AccountStatus | SELECT (dynamic SQL) | Time-series source of LP account financial status snapshots. Rolling 30-day history table with provider-specific Balance adjustments. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge reporting / reconciliation | - | Caller | Called during daily reconciliation or ad-hoc analysis to get reference LP account financial status for a reporting period. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetReferenceAccountStatus (procedure)
└── Hedge.AccountStatus (table)
      - Rolling 30-day time-series of LP account status snapshots
      - Partitioned by HedgeServerID + LiquidityAccountID + OccurredAt PK
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AccountStatus | Table | Dynamic SQL SELECT - source of LP account financial status time-series |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge reporting application | External | READER - called for reconciliation and HedgeCost reporting analysis |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Mirrors the dynamic SQL construction pattern of GetReferenceAccountOpenPositions. Performance depends on Hedge.AccountStatus having an index on (HedgeServerID, OccurredAt) for the partition and filter operations.

### 7.2 Constraints

N/A for Stored Procedure. ROW_NUMBER() (vs RANK() used in GetReferenceAccountOpenPositions) guarantees exactly one row per HedgeServerID partition regardless of OccurredAt ties. This is appropriate here because account-level status is one row per server (not per instrument), so exactly one reference row per server is the correct behavior. The partition key is HedgeServerID-only (not including LiquidityAccountID), meaning the procedure returns the most recent status snapshot across ALL LP accounts for each hedge server.

---

## 8. Sample Queries

### 8.1 Get reference account status for all servers for a specific day
```sql
EXEC [Hedge].[GetReferenceAccountStatus]
    @StartReferenceDate = '2026-03-18 00:00:00',
    @EndReferenceDate   = '2026-03-18 23:59:59',
    @HedgeServerIDs     = '1,2,3';
```

### 8.2 Get reference account status for a single server
```sql
EXEC [Hedge].[GetReferenceAccountStatus]
    @StartReferenceDate = '2026-03-18 00:00:00',
    @EndReferenceDate   = '2026-03-19 00:00:00',
    @HedgeServerIDs     = '1';
```

### 8.3 Direct equivalent query checking current account health
```sql
WITH RankedRows AS (
    SELECT HedgeServerID, LiquidityAccountID, OccurredAt, Balance, Equity,
           UsedMargin, MaintenanceMargin, Cushion, CurrentLeverage,
           ROW_NUMBER() OVER (PARTITION BY HedgeServerID
                              ORDER BY OccurredAt DESC) AS RowNum
    FROM   [Hedge].[AccountStatus] WITH (NOLOCK)
    WHERE  OccurredAt BETWEEN '2026-03-18' AND '2026-03-19'
      AND  HedgeServerID IN (1, 2, 3)
)
SELECT HedgeServerID, LiquidityAccountID, OccurredAt, Balance, Equity,
       UsedMargin, MaintenanceMargin, Cushion, CurrentLeverage
FROM   RankedRows
WHERE  RowNum = 1
ORDER BY HedgeServerID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 10 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetReferenceAccountStatus | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetReferenceAccountStatus.sql*
