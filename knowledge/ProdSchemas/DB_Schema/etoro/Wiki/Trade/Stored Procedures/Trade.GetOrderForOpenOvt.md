# Trade.GetOrderForOpenOvt

> Returns completed open orders with execution data and instrument spread snapshots for a time window - used by operational view tools (OVT) for open order execution analysis and reconciliation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @start DATETIME + @end DATETIME |
| **Partition** | OccurredAsDate date partitions on both History.OrderForOpen and History.OrderExecutionData |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrderForOpenOvt` is the open-order counterpart to `GetOrderForCloseOvt`. It returns all completed open orders (StatusID IN 3, 9, 10) within a date range from `History.OrderForOpen`, enriched with execution data and instrument spread configuration at the time of execution.

**WHY:** Operations teams use this for open order execution quality analysis: what rates were used, how long did execution take, what spreads were in effect. Used for reconciliation, rebate calculations, and execution audit.

**HOW:** Joins `History.OrderForOpen` with `History.OrderExecutionData` (inner, execution must exist), then LEFT JOINs `History.InstrumentSpread` (historical spread at execution time) and `Trade.InstrumentSpread` (current live spread fallback). Same pattern and OPTION(RECOMPILE) as GetOrderForCloseOvt.

---

## 2. Business Logic

### 2.1 Status Filter - Completed Orders Only

**Rules:**
- `StatusID = 3` -> Filled / Executed
- `StatusID = 9` -> Partial Fill (completed as partial)
- `StatusID = 10` -> Other terminal success state
- Applied to `History.OrderForOpen.StatusID`

### 2.2 Dual Date Partition Filter

**Rules:**
- `hofo.RequestOccurred BETWEEN @start AND @end` -> datetime range filter
- `hofo.OccurredAsDate BETWEEN CAST(@start AS DATE) AND CAST(@end AS DATE)` -> date partition elimination on OrderForOpen
- `tofd.OccurredAsDate BETWEEN CAST(@start AS DATE) AND CAST(@end AS DATE)` -> date partition elimination on OrderExecutionData

### 2.3 Spread Data - History vs Live Fallback

**Rules:**
- `History.InstrumentSpread WHERE FeedID=1 AND hofo.CloseOccurred BETWEEN SysStartTime AND SysEndTime` -> spread at time of order close (open execution time)
- `Trade.InstrumentSpread WHERE FeedID=1` -> current live spread fallback
- `ISNULL(his.SpreadTypeID, tis.SpreadTypeID)` -> prefer historical
- `SpreadConfiguration = ISNULL(ISNULL(Ask-Bid from history, Ask-Bid from trade), 0)`

**Note:** `hofo.CloseOccurred` is used for the temporal spread lookup - for open orders, `CloseOccurred` represents when the order's open position was opened/completed.

### 2.4 OPTION (RECOMPILE)

Forces fresh query plan compilation to avoid parameter sniffing on date parameters.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @start | datetime | NO | - | CODE-BACKED | Start of the time window (RequestOccurred). |
| 2 | @end | datetime | NO | - | CODE-BACKED | End of the time window (RequestOccurred). |

**Return Columns:** All columns from `History.OrderForOpen` (hofo.*) plus:

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| R+ | ExecutionID1 | bigint | YES | CODE-BACKED | ExecutionID from History.OrderExecutionData. |
| R+ | ExecutionRateDiscounted | money | YES | CODE-BACKED | Discounted execution rate. |
| R+ | ExecutionRateSpreaded | money | YES | CODE-BACKED | Execution rate with spread. |
| R+ | ExecutionRateID | bigint | YES | CODE-BACKED | Rate record ID for execution rate. |
| R+ | ExecutionRate | money | YES | CODE-BACKED | Rate at which the order was executed. |
| R+ | Occurred | datetime | YES | CODE-BACKED | When execution occurred. |
| R+ | OrderExecutionTime | int | YES | CODE-BACKED | Execution latency in milliseconds. |
| R+ | OrderID1 | bigint | YES | CODE-BACKED | OrderID from execution data (alias to distinguish from hofo.OrderID). |
| R+ | OrderType1 | tinyint | YES | CODE-BACKED | OrderType from execution data. |
| R+ | SpreadTypeID | int | NO | CODE-BACKED | ISNULL(historical spread type, live spread type). 0 if none. |
| R+ | SpreadConfiguration | money | NO | CODE-BACKED | ISNULL(Ask-Bid historical, Ask-Bid live). 0 if none. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @start/@end date range | History.OrderForOpen | Direct query | Source of completed open orders |
| hofo.OrderID | History.OrderExecutionData | INNER JOIN | Execution rate and timing data |
| hofo.InstrumentID + CloseOccurred | History.InstrumentSpread | LEFT JOIN | Historical spread at execution time |
| hofo.InstrumentID | Trade.InstrumentSpread | LEFT JOIN | Current live spread as fallback |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Operations View Tool (OVT) | N/A | CALLER | Open order execution quality analysis |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderForOpenOvt (procedure)
├── History.OrderForOpen (table)
├── History.OrderExecutionData (table)
├── History.InstrumentSpread (table)
└── Trade.InstrumentSpread (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.OrderForOpen | Table | Source of completed open orders |
| History.OrderExecutionData | Table | INNER JOIN for execution rate and timing |
| History.InstrumentSpread | Table | Historical spread at execution time |
| Trade.InstrumentSpread | Table | Current live spread fallback |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Operations View Tool | External | Open order execution analysis |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Note:** `OPTION (RECOMPILE)`. `QUOTED_IDENTIFIER OFF`. Same structural pattern as `GetOrderForCloseOvt` - these two SPs are mirrors of each other for open vs close orders.

**Note:** The `DROP TABLE IF EXISTS #instrumentSpread` at the beginning is cleanup code for a temp table that is never actually created in the current version of this SP. It is likely a remnant from a prior version.

---

## 8. Sample Queries

### 8.1 Get open order OVT data for a day
```sql
EXEC Trade.GetOrderForOpenOvt @start = '2026-03-15 00:00:00', @end = '2026-03-15 23:59:59'
```

### 8.2 Manual equivalent (simplified)
```sql
SELECT hofo.*, tofd.ExecutionRate, tofd.ExecutionRateSpreaded, tofd.OrderExecutionTime,
       ISNULL(ISNULL(his.SpreadTypeID, tis.SpreadTypeID), 0) AS SpreadTypeID
FROM   History.OrderForOpen hofo WITH (NOLOCK)
       INNER JOIN History.OrderExecutionData tofd WITH (NOLOCK) ON hofo.OrderID = tofd.OrderID
       LEFT JOIN History.InstrumentSpread his WITH (NOLOCK)
           ON his.InstrumentID = hofo.InstrumentID AND his.FeedID = 1
           AND hofo.CloseOccurred BETWEEN his.SysStartTime AND his.SysEndTime
       LEFT JOIN Trade.InstrumentSpread tis WITH (NOLOCK)
           ON tis.InstrumentID = hofo.InstrumentID AND tis.FeedID = 1
WHERE  hofo.StatusID IN (3, 9, 10)
AND    hofo.RequestOccurred BETWEEN '2026-03-15 00:00:00' AND '2026-03-15 23:59:59'
OPTION (RECOMPILE)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B skipped-no app refs)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderForOpenOvt | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderForOpenOvt.sql*
