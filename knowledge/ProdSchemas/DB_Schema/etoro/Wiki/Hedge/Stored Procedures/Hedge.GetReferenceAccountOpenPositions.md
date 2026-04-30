# Hedge.GetReferenceAccountOpenPositions

> Returns the most recent LP account open position snapshot within a date range for specified hedge servers, used for end-of-day or point-in-time reconciliation of the hedge account's open position book against internal records.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartReferenceDate + @EndReferenceDate + @HedgeServerIDs - date window and server filter |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetReferenceAccountOpenPositions` retrieves the most recent snapshot of the LP hedge account's open position state for each (HedgeServerID, LiquidityAccountID) pair within a specified date range. The "reference" in the name indicates this is a point-in-time reference snapshot - not the live current state, but the latest recorded state within the analysis window. This is used for reconciliation, auditing, and the HedgeCost reporting pipeline.

The procedure addresses a time-series problem: `Hedge.AccountOpenPositions` stores periodic snapshots of the LP account's open position state (multiple rows per server per account per day). For reconciliation, analysts need exactly one reference row per (server, account) - the most recent one within the reporting window. The RANK() window function selects that row.

The @HedgeServerIDs parameter is a comma-separated string injected directly into the SQL IN clause (dynamic SQL). This allows the caller to query a specific subset of hedge servers - for example, only active production servers or only a specific server being analyzed. The date range restricts to a reporting period (typically a single day or a week).

The output columns (HedgedUnits, NetHedgedInUSD, UnrealizedNetPL, PriceRateID) represent the LP account's aggregate hedge book state at that reference timestamp - how many units are hedged, the USD value, unrealized P&L, and the price rate used for valuation.

---

## 2. Business Logic

### 2.1 Most-Recent-Snapshot Selection via RANK()

**What**: A CTE uses RANK() to identify the most recent snapshot row per (HedgeServerID, LiquidityAccountID) within the date window. Only RowNum=1 rows are returned.

**Columns/Parameters Involved**: `HedgeServerID`, `LiquidityAccountID`, `OccurredAt`, `RowNum`

**Rules**:
- RANK() OVER (PARTITION BY HedgeServerID, LiquidityAccountID ORDER BY OccurredAt DESC): partitions by the hedge server + LP account pair, ranks by snapshot timestamp descending
- RowNum=1 is the most recent snapshot for each (HedgeServerID, LiquidityAccountID) pair in the window
- RANK() (not ROW_NUMBER()): if multiple rows share the identical OccurredAt, all receive RowNum=1 and all are returned. In practice snapshots at the same timestamp for the same partition are expected to be distinct by InstrumentID.
- WHERE OccurredAt BETWEEN @StartReferenceDate AND @EndReferenceDate: restricts to the reference window

### 2.2 Dynamic SQL with IN-List Injection

**What**: @HedgeServerIDs is injected directly into the SQL string to form an IN clause. @StartReferenceDate and @EndReferenceDate are properly parameterized via sp_executesql.

**Columns/Parameters Involved**: `@HedgeServerIDs`, `@StartReferenceDate`, `@EndReferenceDate`

**Rules**:
- @HedgeServerIDs (varchar(4000)): caller passes comma-separated integer list, e.g., '1,2,3'. This is directly concatenated: `HedgeServerID IN (1,2,3)`. This is an intentional design pattern for this class of internal reporting procedure.
- @StartReferenceDate, @EndReferenceDate: passed as typed parameters to sp_executesql - safe from injection
- Reporting convention: typically called with a single day's date range or the full reporting period

**Diagram**:
```
AccountOpenPositions table (time-series snapshots):
  HedgeServerID=1, LiquidityAccountID=10, OccurredAt=09:00, InstrumentID=1, HedgedUnits=500M
  HedgeServerID=1, LiquidityAccountID=10, OccurredAt=12:00, InstrumentID=1, HedgedUnits=490M
  HedgeServerID=1, LiquidityAccountID=10, OccurredAt=17:00, InstrumentID=1, HedgedUnits=485M
  HedgeServerID=1, LiquidityAccountID=10, OccurredAt=17:00, InstrumentID=5, HedgedUnits=50M

RANK() OVER PARTITION BY (1,10) ORDER BY OccurredAt DESC:
  17:00 rows -> RowNum=1 (tie - same timestamp, both returned)
  12:00 row  -> RowNum=3
  09:00 row  -> RowNum=4

Output for window: OccurredAt=17:00, InstrumentID=1, HedgedUnits=485M
                   OccurredAt=17:00, InstrumentID=5, HedgedUnits=50M
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartReferenceDate | datetime | NO | - | VERIFIED | Start of the reference date window (inclusive). Filters AccountOpenPositions to OccurredAt >= this value. Parameterized safely in sp_executesql. |
| 2 | @EndReferenceDate | datetime | NO | - | VERIFIED | End of the reference date window (inclusive). Filters AccountOpenPositions to OccurredAt <= this value. Parameterized safely in sp_executesql. |
| 3 | @HedgeServerIDs | varchar(4000) | NO | - | VERIFIED | Comma-separated list of integer HedgeServerIDs to include (e.g., '1,2,3'). Injected directly into IN clause of dynamic SQL. Allows multi-server queries in a single call. |

**Output columns** (from Hedge.AccountOpenPositions):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | HedgeServerID | int | NO | - | VERIFIED | The hedge server that generated this open position snapshot. Partition key for the RANK() function. |
| 5 | LiquidityAccountID | int | NO | - | VERIFIED | The LP account whose open position state is captured. Partition key for the RANK() function alongside HedgeServerID. |
| 6 | InstrumentID | int | NO | - | VERIFIED | The financial instrument of the open position. Multiple instruments can appear at the same OccurredAt timestamp for the same (HedgeServerID, LiquidityAccountID). |
| 7 | OccurredAt | datetime | NO | - | VERIFIED | Timestamp of the snapshot. The most recent OccurredAt within the date window for each (HedgeServerID, LiquidityAccountID) partition. |
| 8 | UnrealizedNetPL | decimal | YES | - | VERIFIED | Unrealized net profit/loss on the LP account's open hedge positions at this snapshot time. Used in HedgeCost report reconciliation. |
| 9 | PriceRateID | int | YES | - | VERIFIED | Reference to the price rate snapshot used for valuation at OccurredAt. Links to the price record used to compute UnrealizedNetPL and NetHedgedInUSD. |
| 10 | NetHedgedInUSD | decimal | YES | - | VERIFIED | Total net hedged position value in USD at snapshot time. Represents the aggregate USD notional of all open hedge positions on this LP account. |
| 11 | HedgedUnits | decimal | YES | - | VERIFIED | Total units hedged by the LP account at snapshot time, in eToro's internal unit denomination. Used to reconcile against customer exposure data. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Hedge.AccountOpenPositions | SELECT (dynamic SQL) | Time-series source of LP account open position snapshots. Not in SSDT DDL - runtime table managed by AddAccountOpenPositions/DelAccountOpenPositions procedures. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge reporting / reconciliation | - | Caller | Called during daily reconciliation or ad-hoc analysis to get reference LP account positions for a reporting period. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetReferenceAccountOpenPositions (procedure)
└── Hedge.AccountOpenPositions (table) [not in SSDT - runtime managed]
      -> written by: Hedge.AddAccountOpenPositions
      -> cleaned by: Hedge.DelAccountOpenPositions
      -> archived by: Hedge.ArchiveAccountOpenPositions
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AccountOpenPositions | Table | Dynamic SQL SELECT - source of LP account open position time-series snapshots |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge reporting application | External | READER - called for reconciliation and HedgeCost reporting analysis |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. The dynamic SQL uses no query hints. Performance depends on Hedge.AccountOpenPositions having an index on (HedgeServerID, OccurredAt) for the WHERE and RANK() operations. The IN clause from @HedgeServerIDs is injected into the SQL string rather than parameterized, which prevents plan reuse for different server combinations.

### 7.2 Constraints

N/A for Stored Procedure. The dynamic SQL pattern using string concatenation for @HedgeServerIDs (vs parameterized list) is an intentional design for internal reporting procedures where the caller is trusted. Note: @StartReferenceDate and @EndReferenceDate ARE parameterized. The RANK() function (vs ROW_NUMBER()) means ties at identical OccurredAt timestamps return multiple RowNum=1 rows - callers should be aware that multiple instrument rows per (HedgeServerID, LiquidityAccountID) can share the same timestamp and all will appear in results.

---

## 8. Sample Queries

### 8.1 Get reference open positions for all servers for a specific day
```sql
EXEC [Hedge].[GetReferenceAccountOpenPositions]
    @StartReferenceDate = '2026-03-18 00:00:00',
    @EndReferenceDate   = '2026-03-18 23:59:59',
    @HedgeServerIDs     = '1,2,3';
```

### 8.2 Get reference open positions for a single hedge server
```sql
EXEC [Hedge].[GetReferenceAccountOpenPositions]
    @StartReferenceDate = '2026-03-18 00:00:00',
    @EndReferenceDate   = '2026-03-19 00:00:00',
    @HedgeServerIDs     = '1';
```

### 8.3 Direct equivalent query (static, for a single server)
```sql
WITH RankedRows AS (
    SELECT HedgeServerID, LiquidityAccountID, InstrumentID, OccurredAt,
           UnrealizedNetPL, PriceRateID, NetHedgedInUSD, HedgedUnits,
           RANK() OVER (PARTITION BY HedgeServerID, LiquidityAccountID
                        ORDER BY OccurredAt DESC) AS RowNum
    FROM   [Hedge].[AccountOpenPositions]
    WHERE  OccurredAt BETWEEN '2026-03-18' AND '2026-03-19'
      AND  HedgeServerID IN (1)
)
SELECT HedgeServerID, LiquidityAccountID, InstrumentID, OccurredAt,
       UnrealizedNetPL, PriceRateID, NetHedgedInUSD, HedgedUnits
FROM   RankedRows
WHERE  RowNum = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetReferenceAccountOpenPositions | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetReferenceAccountOpenPositions.sql*
