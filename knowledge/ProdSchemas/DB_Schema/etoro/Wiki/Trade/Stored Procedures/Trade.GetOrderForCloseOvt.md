# Trade.GetOrderForCloseOvt

> Returns completed close orders with execution data and instrument spread snapshots for a time window - used by operational view tools (OVT) for close order analysis and reconciliation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @start DATETIME + @end DATETIME |
| **Partition** | OccurredAsDate date partition used for both main and execution tables |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrderForCloseOvt` is an operational reporting SP that returns all completed close orders (StatusID IN 3, 9, 10) within a date range, enriched with execution data (rates, execution time) and spread configuration at the time of the close. It serves Operations teams' "OVT" (Operational View Tool) for analyzing how close orders were executed.

**WHY:** Operations and trading teams need to review executed close orders: what rates were used, what spreads were applied, when execution happened. The spread enrichment (bid/ask, SpreadTypeID) is key for rebate calculations and execution quality audits.

**HOW:** Joins `History.OrderForClose` (the completed order) with `History.OrderExecutionData` (the execution details including rates and timing), then LEFT JOINs to `History.InstrumentSpread` and `Trade.InstrumentSpread` to get the spread at the time of close. The `ISNULL(history_spread, live_spread)` pattern prefers historical spread data when available, falling back to current Trade spread.

---

## 2. Business Logic

### 2.1 Status Filter - Completed Orders Only

**What:** Only orders in terminal success states are returned.

**Columns/Parameters Involved:** `StatusID`

**Rules:**
- `StatusID = 3` -> Filled / Executed
- `StatusID = 9` -> Partial Fill (completed as partial)
- `StatusID = 10` -> Completed with some other terminal success state
- (Failed, cancelled, pending statuses are excluded)

### 2.2 Dual Date Partition Filter

**What:** The WHERE clause uses both a datetime range and a date-partitioned index filter for performance.

**Rules:**
- `hofc.RequestOccurred BETWEEN @start AND @end` -> timestamp range filter
- `hofc.OccurredAsDate BETWEEN CAST(@start AS DATE) AND CAST(@end AS DATE)` -> date partition elimination
- Same pattern on `tofd.OccurredAsDate` -> partition elimination on execution data table
- Both conditions must be true: datetime range for precision, date partition for index efficiency

### 2.3 Spread Data - History vs Live Fallback

**What:** The SP tries to get the historical spread at the time of the close (from History.InstrumentSpread), falling back to the current live spread (from Trade.InstrumentSpread).

**Columns/Parameters Involved:** `SpreadTypeID`, `SpreadConfiguration`, `AskSpread`, `BidSpread`

**Rules:**
- `History.InstrumentSpread WHERE FeedID=1 AND CloseOccurred BETWEEN SysStartTime AND SysEndTime` -> temporal spread lookup
- `Trade.InstrumentSpread WHERE FeedID=1` -> current live spread (no temporal filter)
- `ISNULL(his.SpreadTypeID, tis.SpreadTypeID)` -> prefer historical, fall back to live
- `SpreadConfiguration = Ask - Bid` (computed spread width)
- `FeedID = 1` on both = primary price feed

### 2.4 OPTION (RECOMPILE)

**What:** Forces query plan recompilation for this execution to avoid parameter sniffing issues on the date range.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @start | datetime | NO | - | CODE-BACKED | Start of the time window for close orders (RequestOccurred). |
| 2 | @end | datetime | NO | - | CODE-BACKED | End of the time window for close orders (RequestOccurred). |

**Return Columns:** All columns from `History.OrderForClose` (hofc.*) plus:

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| R+ | OrderID1 | bigint | YES | CODE-BACKED | OrderID from History.OrderExecutionData (alias to distinguish from hofc.OrderID). |
| R+ | ExecutionID1 | bigint | YES | CODE-BACKED | ExecutionID from execution data record. |
| R+ | OrderExecutionTime | int | YES | CODE-BACKED | Time taken for execution in milliseconds. |
| R+ | OrderType1 | tinyint | YES | CODE-BACKED | OrderType from execution data. |
| R+ | Occurred | datetime | YES | CODE-BACKED | When execution occurred. |
| R+ | ExecutionRate | money | YES | CODE-BACKED | Rate at which the order was executed. |
| R+ | ExecutionRateSpreaded | money | YES | CODE-BACKED | Execution rate including spread adjustment. |
| R+ | ExecutionRateID | bigint | YES | CODE-BACKED | Rate record ID for the execution rate. |
| R+ | ExecutionRateDiscounted | money | YES | CODE-BACKED | Discounted execution rate (for commission-discount positions). |
| R+ | SpreadTypeID | int | NO | CODE-BACKED | ISNULL(History spread type, Trade spread type). 0 if neither available. |
| R+ | SpreadConfiguration | money | NO | CODE-BACKED | ISNULL(Ask-Bid from History, Ask-Bid from Trade). 0 if neither available. |
| R+ | AskSpread | money | NO | CODE-BACKED | ISNULL(History.Ask, Trade.Ask). 0 if not available. |
| R+ | BidSpread | money | NO | CODE-BACKED | ISNULL(History.Bid, Trade.Bid). 0 if not available. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @start/@end date range | History.OrderForClose | Direct query | Source of completed close orders |
| hofc.OrderID | History.OrderExecutionData | INNER JOIN | Execution rate and timing data |
| hofc.InstrumentID + CloseOccurred | History.InstrumentSpread | LEFT JOIN | Historical spread at time of close |
| hofc.InstrumentID | Trade.InstrumentSpread | LEFT JOIN | Current live spread as fallback |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Operations View Tool (OVT) | N/A | CALLER | Close order execution analysis |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderForCloseOvt (procedure)
├── History.OrderForClose (table)
├── History.OrderExecutionData (table)
├── History.InstrumentSpread (table)
└── Trade.InstrumentSpread (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.OrderForClose | Table | Source of completed close orders in date range |
| History.OrderExecutionData | Table | INNER JOIN for execution rate and timing |
| History.InstrumentSpread | Table | LEFT JOIN for historical spread at close time |
| Trade.InstrumentSpread | Table | LEFT JOIN fallback for current spread |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Operations View Tool | External | Close order execution quality analysis |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Hint:** `OPTION (RECOMPILE)` avoids parameter sniffing. The dual date filter (datetime + OccurredAsDate) is a performance pattern - the date column enables partition/index elimination while the datetime provides the precise range filter.

**Note:** `QUOTED_IDENTIFIER OFF` in this SP's DDL header. This is a legacy setting that affects how string literals and identifiers are handled. Generally does not affect correctness for this query pattern.

---

## 8. Sample Queries

### 8.1 Get close order OVT data for a day
```sql
EXEC Trade.GetOrderForCloseOvt @start = '2026-03-15 00:00:00', @end = '2026-03-15 23:59:59'
```

### 8.2 Manual equivalent (simplified)
```sql
SELECT hofc.*, tofd.OrderExecutionTime, tofd.ExecutionRate,
       ISNULL(ISNULL(his.SpreadTypeID, tis.SpreadTypeID), 0) AS SpreadTypeID
FROM   History.OrderForClose hofc WITH (NOLOCK)
       INNER JOIN History.OrderExecutionData tofd WITH (NOLOCK) ON hofc.OrderID = tofd.OrderID
       LEFT JOIN History.InstrumentSpread his WITH (NOLOCK)
           ON his.InstrumentID = hofc.InstrumentID AND his.FeedID = 1
           AND hofc.CloseOccurred BETWEEN his.SysStartTime AND his.SysEndTime
       LEFT JOIN Trade.InstrumentSpread tis WITH (NOLOCK)
           ON tis.InstrumentID = hofc.InstrumentID AND tis.FeedID = 1
WHERE  hofc.StatusID IN (3, 9, 10)
AND    hofc.RequestOccurred BETWEEN '2026-03-15 00:00:00' AND '2026-03-15 23:59:59'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B skipped-no app refs)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderForCloseOvt | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderForCloseOvt.sql*
