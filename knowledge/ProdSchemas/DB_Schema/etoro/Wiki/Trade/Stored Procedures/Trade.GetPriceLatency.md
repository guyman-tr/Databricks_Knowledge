# Trade.GetPriceLatency

> Returns percentile distribution of price latency (in seconds) between client-visible price rates and trade-server price rates, for the top N instruments by position activity in a given time window. Used for performance monitoring and SLA analysis.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartTime DATETIME, @EndTime DATETIME, @InstrumentsCnt INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a **price latency diagnostic tool**. It measures the time gap between the price rate that the trade server used to execute a trade (`LastOpPriceRateID`) and the price rate the client was seeing at the same moment (`ClientViewRateID`). This gap represents the latency experienced by customers: a positive difference (trade server time > client time) means the server acted on a price that was newer than what the client saw, which could indicate a pricing fairness concern or server advantage. A negative difference means the client saw a newer price than the server used.

The procedure returns full percentile distribution (10th through 99th percentile) across all analyzed trades in the window, giving operations and QA teams a statistical view of price latency rather than just averages. The procedure was moved to Azure (dbo.HistoryCurrencyPrice) in July 2022 for better performance.

Data flows: (1) Find the top @InstrumentsCnt instruments by position activity (open+failed) in the window. (2) Collect position events (fails + ChangeTypeID=0 open events) for those instruments where both LastOpPriceRateID and ClientViewRateID are populated. (3) Look up timestamps for both rate IDs from dbo.HistoryCurrencyPrice. (4) Calculate DATEDIFF(seconds) between the two timestamps. (5) Return full percentile distribution using PERCENTILE_CONT window functions.

---

## 2. Business Logic

### 2.1 Top Instruments by Activity

**What**: Scopes the analysis to the most active instruments in the window rather than all instruments.

**Columns/Parameters Involved**: `@InstrumentsCnt`, `Trade.PositionTbl`, `History.Position_Active`

**Rules**:
- UNION of Trade.PositionTbl (Occurred) and History.Position_Active (OpenOccurred) for the time window.
- GROUP BY InstrumentID, ORDER BY COUNT(*) DESC.
- TOP @InstrumentsCnt instruments by position count.

### 2.2 Data Sources: Fails and Open Events

**What**: Latency is measured on two event types: failed position attempts and successful open events.

**Columns/Parameters Involved**: `History.PositionFail`, `History.PositionChangeLog`, `ChangeTypeID=0`, `ClientViewRateID`, `LastOpPriceRateID`

**Rules**:
- Source 1: History.PositionFail - failed position attempts (MirrorID=0 filter = manual trades only). FailOccurred in window, ClientViewRateID IS NOT NULL, LastOpPriceRateID > 0.
- Source 2: History.PositionChangeLog ChangeTypeID=0 (position open events). MirrorID=0 (manual trades). ClientViewRateID IS NOT NULL, LastOpPriceRateID > 0.
- Both sources filtered to the @InstrumentsCnt most active instruments.
- MirrorID=0: only manual (non-copy) trades are analyzed for price latency.

### 2.3 Price Rate Timestamp Lookup

**What**: Looks up the actual timestamps for LastOpPriceRateID and ClientViewRateID from dbo.HistoryCurrencyPrice.

**Columns/Parameters Involved**: `dbo.HistoryCurrencyPrice.PriceRateID`, `dbo.HistoryCurrencyPrice.Occurred`

**Rules**:
- @RateStartTime = @StartTime - 20 minutes (buffer for rates slightly before the trade window).
- Query: WHERE Occurred BETWEEN @RateStartTime AND @EndTime.
- Both LastOpPriceRateID and ClientViewRateID are looked up from the same table with UNION ALL, differentiated by the 'Operation' discriminator column.
- JOIN to #Instrument on the rate IDs.

### 2.4 Latency Calculation and Percentile Distribution

**What**: Computes DATEDIFF in seconds and returns full percentile distribution.

**Columns/Parameters Involved**: `DATEDIFF(ss, ClientTime, TradeServerTime)`, `PERCENTILE_CONT`

**Rules**:
- Diff = DATEDIFF(seconds, ClientTime, TradeServerTime).
  - Positive diff: trade server price was MORE RECENT than client price (server had newer data).
  - Negative diff: client price was more recent (client saw a newer price than server used).
- Percentiles: 10th, 20th, 30th, 40th, 50th (median), 60th, 70th, 80th, 90th, 95th, 99th.
- PERCENTILE_CONT: interpolated continuous percentile (not discrete).
- Result is one row (DISTINCT with PARTITION BY @StartTime) with all percentile columns.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartTime | DATETIME | NO | - | CODE-BACKED | Start of analysis window. Positions opened/failed in [StartTime, EndTime) are included. |
| 2 | @EndTime | DATETIME | NO | - | CODE-BACKED | End of analysis window. |
| 3 | @InstrumentsCnt | INT | NO | - | CODE-BACKED | Number of most-active instruments to include. Limits scope to top N instruments by position count in the window. |

**Output Columns (one row)**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | startTime | DATETIME | NO | - | CODE-BACKED | Echo of @StartTime parameter. |
| 5 | @EndTime | DATETIME | NO | - | CODE-BACKED | Echo of @EndTime parameter. |
| 6 | @InstrumentsCnt | INT | NO | - | CODE-BACKED | Echo of @InstrumentsCnt parameter. |
| 7 | total | INT | NO | - | CODE-BACKED | Total number of trades analyzed. |
| 8 | 10thPerc | FLOAT | NO | - | CODE-BACKED | 10th percentile latency in seconds. |
| 9 | 20thPerc | FLOAT | NO | - | CODE-BACKED | 20th percentile latency in seconds. |
| 10 | 30thPerc | FLOAT | NO | - | CODE-BACKED | 30th percentile latency in seconds. |
| 11 | 40thPerc | FLOAT | NO | - | CODE-BACKED | 40th percentile latency in seconds. |
| 12 | 50thPerc | FLOAT | NO | - | CODE-BACKED | Median latency in seconds. |
| 13 | 60thPerc | FLOAT | NO | - | CODE-BACKED | 60th percentile latency in seconds. |
| 14 | 70thPerc | FLOAT | NO | - | CODE-BACKED | 70th percentile latency in seconds. |
| 15 | 80thPerc | FLOAT | NO | - | CODE-BACKED | 80th percentile latency in seconds. |
| 16 | 90thPerc | FLOAT | NO | - | CODE-BACKED | 90th percentile latency in seconds. |
| 17 | 95thPerc | FLOAT | NO | - | CODE-BACKED | 95th percentile latency in seconds. |
| 18 | 99thPerc | FLOAT | NO | - | CODE-BACKED | 99th percentile latency in seconds. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID (activity count) | Trade.PositionTbl | Reader | Position activity count for top-N instrument selection |
| InstrumentID (activity count) | History.Position_Active | Reader | Additional position activity count |
| PositionFailID, ClientViewRateID | History.PositionFail | Reader | Failed trade attempts with rate IDs |
| PositionID, rate IDs | History.PositionChangeLog | Reader | ChangeTypeID=0 open events with rate IDs |
| PriceRateID, Occurred | dbo.HistoryCurrencyPrice | Reader | Rate timestamps for latency calculation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Operations / QA teams | @StartTime, @EndTime, @InstrumentsCnt | Manual execution | Called to analyze price latency for SLA monitoring and incident investigation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPriceLatency (procedure)
+-- Trade.PositionTbl (table) [instrument activity count]
+-- History.Position_Active (table) [instrument activity count]
+-- History.PositionFail (table) [failed trade rate IDs]
+-- History.PositionChangeLog (table) [ChangeTypeID=0 open event rate IDs]
+-- dbo.HistoryCurrencyPrice (table/synonym) [rate timestamps, Azure-hosted]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Position count for top-N instrument selection (Occurred in window) |
| History.Position_Active | Table | Additional position activity for top-N instrument selection |
| History.PositionFail | Table | Failed trade events with ClientViewRateID and LastOpPriceRateID |
| History.PositionChangeLog | Table | ChangeTypeID=0 (open) events with rate IDs (manual trades only) |
| dbo.HistoryCurrencyPrice | Table | Timestamps for price rate IDs (moved to Azure 2022-07-31) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Operations / QA monitoring | Ad hoc | Price latency SLA analysis and incident investigation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure (temp tables: CLUSTERED on #Top_Instruments (InstrumentID), CLUSTERED on #PriceRateID (PriceRateID), CLUSTERED on #Instrument (LastOpPriceRateID) + NONCLUSTERED, CLUSTERED on #Rates (ClientTime, TradeServerTime), CLUSTERED on #Result (Diff)).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH RECOMPILE | Optimization | Fresh plan per run for varying @InstrumentsCnt and time windows |
| MirrorID=0 filter | Scope | Analyzes only manual trades; copy trades excluded from latency measurement |
| @RateStartTime = StartTime - 20min | Buffer | Includes price rates that were slightly before the trade window |
| OPTION(RECOMPILE) on #Price query | Optimization | Prevents plan caching for large HistoryCurrencyPrice range scans |

---

## 8. Sample Queries

### 8.1 Analyze price latency for top 20 instruments over the last hour

```sql
EXEC Trade.GetPriceLatency
    @StartTime = DATEADD(HOUR, -1, GETUTCDATE()),
    @EndTime = GETUTCDATE(),
    @InstrumentsCnt = 20;
```

### 8.2 Review latency for a specific historical window

```sql
EXEC Trade.GetPriceLatency
    @StartTime = '2024-01-15 14:00:00',
    @EndTime   = '2024-01-15 15:00:00',
    @InstrumentsCnt = 10;
-- 50thPerc (median) near 0 = acceptable. Large 99thPerc = tail latency issue.
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPriceLatency | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPriceLatency.sql*
