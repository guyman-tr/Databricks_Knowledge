# BI_DB_dbo.BI_DB_US_Stocks_Transactions_Per_Time_Unit

> 1.6K-row daily US stock/ETF transaction throughput metrics at 4 time granularities (day, peak hour, peak minute, peak second). One row per calendar day from 2021-11-01 to present. Tracks position counts and unique customer counts at each granularity plus Apex active account count. DELETE+INSERT via SP_US_Stocks_Transactions_Per_Time_Unit.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position + External_USABroker_Apex_ApexData via `SP_US_Stocks_Transactions_Per_Time_Unit` |
| **Refresh** | Daily (DELETE WHERE Date=@Date + INSERT) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | — |
| **Row Count** | ~1,625 (as of 2026-04-27) |

---

## 1. Business Meaning

`BI_DB_US_Stocks_Transactions_Per_Time_Unit` measures peak US stock and ETF trading throughput at decreasing time granularities. For each calendar day, it captures:

- **Daily**: Total position count and unique customers for the entire day
- **Hourly**: The single peak hour with the most transactions, and its counts
- **Minutely**: The single peak minute with the most transactions, and its counts
- **Secondly**: The single peak second with the most transactions, and its counts

The scope is limited to RegulationID=8 (FinCEN+FINRA) and InstrumentTypeID IN (5,6) — US stocks and ETFs only. Both position opens and closes are counted (union of opened + closed positions). Airdrop positions are excluded from opens; ClosePositionReasonID=10 is excluded from closes.

An additional Apex_Cnt column provides the count of distinct active Apex brokerage accounts (StatusID=12) for context.

As of 2026-04-27: 1,625 rows from 2021-11-01 to 2026-04-12. Weekend/holiday rows show Daily=0 with NULLs for time breakdowns.

---

## 2. Business Logic

### 2.1 Position Universe (Open + Close Union)

**What**: All US stock/ETF positions opened or closed on @Date.
**Columns Involved**: All transaction columns
**Rules**:
- Opens: Positions opened on @Date, RegulationID=8, InstrumentTypeID IN (5,6), not airdrops
- Closes: Positions closed on @Date, RegulationID=8, ClosePositionReasonID != 10
- UNION of both sets forms the base for all aggregations

### 2.2 Four-Granularity Aggregation

**What**: Transaction counts at day, hour, minute, and second level.
**Columns Involved**: `Daily`, `Hour`, `Hourly`, `Minute`, `Minutely`, `Second`, `Secondly`
**Rules**:
- Daily: COUNT(PositionID) across all positions in the union
- Hourly: TOP 1 hour by position count → Hour (0-23) and Hourly (count)
- Minutely: TOP 1 minute by position count → Minute (0-59) and Minutely (count)
- Secondly: TOP 1 second by position count → Second (0-59) and Secondly (count)
- CID variants: COUNT(DISTINCT CID) at each granularity level

### 2.3 Apex Active Account Count

**What**: Count of active Apex brokerage accounts for context.
**Columns Involved**: `Apex_Cnt`
**Rules**:
- COUNT(DISTINCT GCID) from External_USABroker_Apex_ApexData WHERE StatusID=12 AND date within range

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — small table, full scans are fast.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Peak trading day | `ORDER BY Daily DESC LIMIT 1` |
| Busiest second ever | `ORDER BY Secondly DESC LIMIT 1` |
| Trading volume trend | `WHERE Daily > 0 ORDER BY Date` |
| Weekend/holiday detection | `WHERE Daily = 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Calendar/Date dimension | `Date = DateValue` | Business day classification |

### 3.4 Gotchas

- **Peak columns are TOP 1**: Hour, Minute, Second represent the single busiest unit — not averages
- **Weekend/holiday rows**: Daily=0, time breakdown columns are NULL
- **Union of opens + closes**: A single position can be counted twice if opened and closed on the same day
- **RegulationID=8 only**: FinCEN+FINRA regulated accounts only — not all US accounts
- **InstrumentTypeID 5,6**: Stocks and ETFs only — no crypto, forex, or commodities

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code analysis |
| Tier 5 | ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | NO | Calendar date for the row. One row per day. @Date parameter from SP invocation. (Tier 2 — SP_US_Stocks_Transactions_Per_Time_Unit) |
| 2 | Daily | int | YES | Total position count (opens + closes) for the entire day. COUNT(PositionID) across the union of opened and closed positions. (Tier 2 — SP_US_Stocks_Transactions_Per_Time_Unit) |
| 3 | Hour | int | YES | Hour number (0-23) of the peak trading hour. TOP 1 hour by position count. NULL on non-trading days. (Tier 2 — SP_US_Stocks_Transactions_Per_Time_Unit) |
| 4 | Hourly | int | YES | Position count in the peak trading hour. NULL on non-trading days. (Tier 2 — SP_US_Stocks_Transactions_Per_Time_Unit) |
| 5 | Minute | int | YES | Minute (0-59) of the peak trading minute. TOP 1 minute by position count. NULL on non-trading days. (Tier 2 — SP_US_Stocks_Transactions_Per_Time_Unit) |
| 6 | Minutely | int | YES | Position count in the peak trading minute. NULL on non-trading days. (Tier 2 — SP_US_Stocks_Transactions_Per_Time_Unit) |
| 7 | Second | int | YES | Second (0-59) of the peak trading second. TOP 1 second by position count. NULL on non-trading days. (Tier 2 — SP_US_Stocks_Transactions_Per_Time_Unit) |
| 8 | Secondly | int | YES | Position count in the peak trading second. NULL on non-trading days. (Tier 2 — SP_US_Stocks_Transactions_Per_Time_Unit) |
| 9 | CID_Daily | int | YES | Count of distinct customers who traded during the entire day. COUNT(DISTINCT CID). (Tier 2 — SP_US_Stocks_Transactions_Per_Time_Unit) |
| 10 | CID_Hourly | int | YES | Count of distinct customers who traded during the peak hour. COUNT(DISTINCT CID) in the TOP 1 hour. (Tier 2 — SP_US_Stocks_Transactions_Per_Time_Unit) |
| 11 | CID_Minutely | int | YES | Count of distinct customers who traded during the peak minute. COUNT(DISTINCT CID) in the TOP 1 minute. (Tier 2 — SP_US_Stocks_Transactions_Per_Time_Unit) |
| 12 | CID_Secondly | int | YES | Count of distinct customers who traded during the peak second. COUNT(DISTINCT CID) in the TOP 1 second. (Tier 2 — SP_US_Stocks_Transactions_Per_Time_Unit) |
| 13 | Apex_Cnt | int | YES | Count of distinct active Apex brokerage accounts. COUNT(DISTINCT GCID) from External_USABroker_Apex_ApexData WHERE StatusID=12. (Tier 2 — SP_US_Stocks_Transactions_Per_Time_Unit) |
| 14 | UpdateDate | datetime | NO | ETL execution timestamp. GETDATE() at SP execution time. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Daily, Hourly, Minutely, Secondly | Trading.Position | PositionID | COUNT via Dim_Position |
| CID_Daily, CID_Hourly, CID_Minutely, CID_Secondly | Trading.Position | CID | COUNT DISTINCT via Dim_Position |
| Apex_Cnt | External_USABroker_Apex_ApexData | GCID | COUNT DISTINCT WHERE StatusID=12 |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (RegulationID=8, InstrumentTypeID IN 5,6)
  |-- #op: Positions OPENED on @Date (not airdrops)
  |-- #cp: Positions CLOSED on @Date (ClosePositionReasonID!=10)
  |-- UNION → base position set
  |
  |-- SP_US_Stocks_Transactions_Per_Time_Unit @Date
  |   Step 1: Daily aggregate (COUNT all, COUNT DISTINCT CID)
  |   Step 2: Hourly peak (TOP 1 hour by count)
  |   Step 3: Minutely peak (TOP 1 minute by count)
  |   Step 4: Secondly peak (TOP 1 second by count)
  |   Step 5: Apex_Cnt from External_USABroker_Apex_ApexData
  |   Step 6: JOIN all granularity levels + Apex
  |   DELETE WHERE Date=@Date + INSERT
  v
BI_DB_dbo.BI_DB_US_Stocks_Transactions_Per_Time_Unit (1.6K rows, ROUND_ROBIN HEAP)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Daily/Hourly/Minutely/Secondly | DWH_dbo.Dim_Position | Position counts from US stock/ETF trades |
| Apex_Cnt | External_USABroker_Apex_ApexData | Active Apex brokerage account count |

### 6.2 Referenced By (other objects point to this)

No known consumers in the current wiki inventory.

---

## 7. Sample Queries

### 7.1 Top 10 Busiest Trading Days

```sql
SELECT Date, Daily, CID_Daily, Hour AS PeakHour, Hourly AS PeakHourlyCount
FROM BI_DB_dbo.BI_DB_US_Stocks_Transactions_Per_Time_Unit
WHERE Daily > 0
ORDER BY Daily DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
```

### 7.2 Peak Second Throughput Trend

```sql
SELECT Date, Secondly, CID_Secondly, Apex_Cnt
FROM BI_DB_dbo.BI_DB_US_Stocks_Transactions_Per_Time_Unit
WHERE Secondly IS NOT NULL
ORDER BY Date DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 0 T1, 13 T2, 0 T3, 0 T4, 1 T5 | Elements: 14/14, Logic: 8/10, Lineage: 7/10*
*Object: BI_DB_dbo.BI_DB_US_Stocks_Transactions_Per_Time_Unit | Type: Table | Production Source: Dim_Position + Apex_ApexData via SP_US_Stocks_Transactions_Per_Time_Unit*
