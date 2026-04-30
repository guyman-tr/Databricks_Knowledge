# Dictionary.CandleTimeframes

> Lookup table defining the 9 candlestick chart time intervals — from 1 minute to 1 week — used for price chart display and candle data aggregation.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (int, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Dictionary.CandleTimeframes defines the standard time intervals for candlestick price charts displayed on the eToro trading platform. Each row represents a duration over which OHLC (Open/High/Low/Close) price data is aggregated into a single candle. These are the time intervals users select when viewing instrument price charts (e.g., "1 minute", "1 hour", "1 day" candles).

This table is essential for the charting system. The `Trade.CandleGroupToIntervals` table has an explicit FK (`FK_CandleGroupToIntervals_CandleTimeframes`) referencing this table, mapping which timeframes are available for each candle interval group. Different instrument types may support different subsets of these timeframes based on their trading hours and data availability.

The candle aggregation engine uses these timeframe IDs to determine how to bucket raw price tick data into OHLC candle bars for storage and display.

---

## 2. Business Logic

### 2.1 Standard Charting Timeframes

**What**: Nine progressively longer time intervals for price chart display.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- **Sub-hourly (IDs 1-5)**: Short-term intraday candles — 1min, 5min, 10min, 15min, 30min. Used by active traders and day traders for short-term price action analysis.
- **Hourly (IDs 6-7)**: Medium-term intraday candles — 1hr, 4hr. Used for intraday trend identification and swing trading analysis.
- **Daily+ (IDs 8-9)**: Longer-term candles — 1 day, 1 week. Used for position trading, trend analysis, and portfolio management decisions.

**Diagram**:
```
Timeframe Hierarchy
├── Intraday (sub-hourly)
│   ├── 1: OneMinute    (1 min)
│   ├── 2: FiveMinutes  (5 min)
│   ├── 3: TenMinutes   (10 min)
│   ├── 4: FifteenMinutes (15 min)
│   └── 5: ThirtyMinutes (30 min)
├── Intraday (hourly)
│   ├── 6: OneHour      (1 hr)
│   └── 7: FourHours    (4 hr)
└── Daily+
    ├── 8: OneDay        (1 day)
    └── 9: OneWeek       (1 week)
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | OneMinute | Finest granularity — each candle represents 1 minute of price action. Used by scalpers and algorithmic trading for rapid entry/exit decisions. |
| 5 | ThirtyMinutes | Half-hour candles for intraday trend analysis — balances detail and noise reduction for active traders. |
| 6 | OneHour | Hourly candles — standard timeframe for intraday swing trading. Shows clear trend formation within a trading day. |
| 8 | OneDay | Daily candles — most widely used timeframe for general market analysis, earnings reactions, and multi-day trend identification. |
| 9 | OneWeek | Weekly candles — used for long-term trend analysis, portfolio reviews, and macro-level price pattern recognition. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | VERIFIED | Primary key identifying the timeframe. Values 1-9. Referenced by `Trade.CandleGroupToIntervals.TimeframeID` (FK) to map which timeframes are available per instrument group. |
| 2 | Name | varchar(50) | YES | - | VERIFIED | PascalCase name of the timeframe (e.g., 'OneMinute', 'FourHours', 'OneWeek'). Used by the charting UI as a programmatic key for timeframe selection. Nullable but all 9 production rows have values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CandleGroupToIntervals | TimeframeID | FK (FK_CandleGroupToIntervals_CandleTimeframes) | Maps timeframes to candle interval groups — controls which chart intervals are available for each instrument group |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CandleGroupToIntervals | Table | FK reference — maps timeframes to instrument candle groups |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CandleTimeframes | CLUSTERED PK | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all candlestick timeframes
```sql
SELECT  Id,
        Name
FROM    Dictionary.CandleTimeframes WITH (NOLOCK)
ORDER BY Id;
```

### 8.2 Show timeframes available per candle group
```sql
SELECT  CGI.GroupID,
        CT.Id AS TimeframeID,
        CT.Name AS Timeframe
FROM    Trade.CandleGroupToIntervals CGI WITH (NOLOCK)
INNER JOIN Dictionary.CandleTimeframes CT WITH (NOLOCK)
        ON CT.Id = CGI.TimeframeID
ORDER BY CGI.GroupID, CT.Id;
```

### 8.3 Find daily and weekly timeframes
```sql
SELECT  Id,
        Name
FROM    Dictionary.CandleTimeframes WITH (NOLOCK)
WHERE   Name IN ('OneDay', 'OneWeek')
ORDER BY Id;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CandleTimeframes | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CandleTimeframes.sql*
