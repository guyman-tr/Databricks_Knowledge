# Hedge.Report_PriceLatencyTickByTick

> Price feed latency monitoring: computes average millisecond latency between when a price quote was received on the price server (ReceivedOnPriceServer) and when it was processed (Occurred) per second-level tick, reading from Price.History.CurrencyPrice for ProviderID=1 over a configurable look-back window.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Minutes INT=5; reads cross-DB Price.History.CurrencyPrice; DATA_READER has EXECUTE |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.Report_PriceLatencyTickByTick` is a price feed latency monitoring tool for the hedge desk. It measures the delay between:
- `ReceivedOnPriceServer`: when the price server received the quote from ProviderID=1 (the primary price feed provider)
- `Occurred`: when the price was processed/stamped as the market price

By grouping to second-level ticks (`CONVERT(VARCHAR(19), Occurred, 121)` = "YYYY-MM-DD HH:MM:SS") and averaging the per-tick latency in milliseconds, the procedure shows whether the price feed is delivering prices with acceptable latency or experiencing delays.

**Cross-database access**: The procedure reads from `Price.History.CurrencyPrice` - this is a DIFFERENT database (`Price`) than the current `etoro` DB. This is a cross-DB reference: `[Price].[History].[CurrencyPrice]`. ProviderID=1 is hardcoded - this monitors the primary price provider only.

The proc comment states: "THIS CALCULATES LATENCY AVERAGE OF ALL QUOTES PER TICK IN MILISEC - Set the @Minutes for the length of time back you want to see from this moment."

DATA_READER has EXECUTE, so this is used by BI analysts and the hedge desk for operational monitoring.

---

## 2. Business Logic

### 2.1 Tick-Level Latency Aggregation

**What**: Latency is measured per second-level tick - all quotes that occurred within the same second are grouped and averaged.

**Columns/Parameters Involved**: `@Minutes`, `Occurred`, `ReceivedOnPriceServer`, `ProviderID`

**Rules**:
- `CONVERT(VARCHAR(19), Occurred, 121)` groups to "YYYY-MM-DD HH:MM:SS" - second-level granularity.
- `AVG(DATEDIFF(ms, ReceivedOnPriceServer, Occurred))` = average milliseconds between receipt and timestamp. Small values (1-50ms) = healthy feed; large values (100ms+) = latency issue.
- `COUNT(*)` = number of quotes in that second = price feed throughput per tick.
- `ProviderID = 1`: hardcoded to the primary price provider (ProviderID=1).
- `Occurred >= DATEADD(mi, -@Minutes, GETDATE())` and `Occurred < GETDATE()`: time window from now-@Minutes to now.
- Default `@Minutes = 5`: last 5 minutes of price data.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Minutes | INT | YES | 5 | CODE-BACKED | Look-back window in minutes. Default=5: shows the last 5 minutes. Set to 1 for a quick health check; 60 for trend analysis. Controls the time range of price history scanned. |

Result set columns:

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | Tick | VARCHAR(19) | Second-level timestamp in "YYYY-MM-DD HH:MM:SS" format. Each row = one second of price activity. |
| 2 | AvgLatency | INT | Average milliseconds between ReceivedOnPriceServer and Occurred for all quotes in this tick. Lower = faster feed. |
| 3 | NumQuotes | INT | Number of price quotes received in this tick. Higher = more active price feed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Price.History.CurrencyPrice | Reader (NOLOCK) | Cross-DB read from Price database's History schema - raw price tick data |

### 5.2 Referenced By (other objects point to this)

DATA_READER role holds EXECUTE. Called by hedge desk and BI analysts for price feed latency monitoring.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.Report_PriceLatencyTickByTick (procedure)
+-- [Price].[History].[CurrencyPrice] (cross-DB table) [READ - raw price ticks with ReceivedOnPriceServer timestamp]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.History.CurrencyPrice | Cross-DB Table | Read: price tick data with received/occurred timestamps |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DATA_READER (role) | Permission | EXECUTE - BI/monitoring access |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ProviderID = 1 | Hardcoded scope | Only monitors the primary price provider. Other providers are not included. |
| Cross-DB access | Price database | Reads from Price.History.CurrencyPrice in a separate database. Requires cross-DB permission. |
| NOLOCK | Isolation | Read uncommitted on the price history table. |

---

## 8. Sample Queries

### 8.1 Check last 5 minutes of price latency (default)
```sql
EXEC [Hedge].[Report_PriceLatencyTickByTick]
-- Returns: Tick | AvgLatency (ms) | NumQuotes per second
-- Ordered by Tick DESC (most recent first)
```

### 8.2 Check last 30 minutes for trend analysis
```sql
EXEC [Hedge].[Report_PriceLatencyTickByTick]
    @Minutes = 30
```

### 8.3 Manual equivalent query
```sql
SELECT CONVERT(VARCHAR(19), Occurred, 121) AS Tick,
       AVG(DATEDIFF(ms, ReceivedOnPriceServer, Occurred)) AS AvgLatency,
       COUNT(*) AS NumQuotes
FROM Price.History.CurrencyPrice WITH (NOLOCK)
WHERE ProviderID = 1
  AND Occurred >= DATEADD(mi, -5, GETDATE())
  AND Occurred < GETDATE()
GROUP BY CONVERT(VARCHAR(19), Occurred, 121)
ORDER BY 1 DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL repo | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.Report_PriceLatencyTickByTick | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.Report_PriceLatencyTickByTick.sql*
