# Trade.CandleIntervalGroups

> Lookup table defining named groups of candlestick chart timeframes used to control which chart intervals are available per instrument type (e.g., Forex vs Stocks).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | GroupID (int, PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Trade.CandleIntervalGroups defines named groups that classify which candlestick chart timeframes (1 minute, 5 minutes, 1 hour, etc.) are available for a given instrument type. Each row represents a group (e.g., "Forex" or "Stocks") that is linked to a set of TimeframeIDs via Trade.CandleGroupToIntervals. Instruments assign a group via Trade.InstrumentMetaData.CandleTimeframeGroup to determine which chart intervals the platform displays for that instrument.

This table exists because different asset classes have different charting needs. Forex pairs trade 24/5 and typically support all timeframes; stocks may have different availability. By grouping timeframes, the system avoids per-instrument configuration while still allowing asset-class-level control over chart display options.

Data flows: Rows are created and maintained by configuration/ETL processes (no triggers or procedures directly insert into this table in the analyzed code). Trade.InstrumentMetaData.CandleTimeframeGroup references GroupID; Trade.InsertInstrumentMetaData uses default @CandleTimeframeGroup = 2 (Stocks). Trade.CandleGroupToIntervals links each GroupID to the TimeframeIDs it includes. Trade.GetInstrumentsTimeframeID joins InstrumentMetaData -> CandleGroupToIntervals to return InstrumentID and TimeframeID for each instrument's available chart intervals.

---

## 2. Business Logic

### 2.1 Group-to-Timeframe Mapping

**What**: Each group defines which candlestick chart intervals (Dictionary.CandleTimeframes) are available for instruments in that group.

**Columns/Parameters Involved**: `GroupID`, `GroupName`, `Trade.CandleGroupToIntervals.GroupID`, `Trade.CandleGroupToIntervals.TimeframeID`

**Rules**:
- GroupID 1 = Forex: typically all 9 timeframes (1min through 1 week) via CandleGroupToIntervals
- GroupID 2 = Stocks: same 9 timeframes in current data; stocks may be restricted in future
- Trade.CandleGroupToIntervals maps GroupID -> TimeframeID (Dictionary.CandleTimeframes) for each allowed interval
- Instruments set CandleTimeframeGroup (FK to GroupID) to indicate which group applies; NULL means no group assigned

**Diagram**:
```
Trade.CandleIntervalGroups
     |
     +-> GroupID 1 (Forex)  -->  CandleGroupToIntervals  -->  TimeframeID 1..9
     +-> GroupID 2 (Stocks) -->  CandleGroupToIntervals  -->  TimeframeID 1..9
     |
     v
Trade.InstrumentMetaData.CandleTimeframeGroup (FK) -> selects group per instrument
     |
     v
Trade.GetInstrumentsTimeframeID: InstrumentMetaData JOIN CandleGroupToIntervals ON CandleTimeframeGroup = GroupID
```

---

## 3. Data Overview

| GroupID | GroupName | Meaning |
|---------|-----------|---------|
| 1 | Forex | Group for forex/currency pair instruments. Used when InstrumentMetaData.CandleTimeframeGroup = 1. Enables all 9 standard chart timeframes (1min through 1 week) via CandleGroupToIntervals. |
| 2 | Stocks | Group for stock/equity instruments. Default in Trade.InsertInstrumentMetaData (@CandleTimeframeGroup = 2). Enables same 9 timeframes; used for instruments that trade during exchange hours. |

**Selection criteria for the 5 rows:**
- Table has only 2 rows; both are included.
- Forex (1) and Stocks (2) represent the two primary asset-class groupings for chart timeframe availability.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GroupID | int | NO | - | CODE-BACKED | Primary key. Unique identifier for the group. Value map: 1=Forex, 2=Stocks. Referenced by Trade.InstrumentMetaData.CandleTimeframeGroup (FK) and Trade.CandleGroupToIntervals.GroupID (FK). |
| 2 | GroupName | varchar(50) | YES | - | CODE-BACKED | Human-readable group name displayed in config and used for identification. Values: "Forex", "Stocks". Nullable per DDL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It is a leaf lookup table.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InstrumentMetaData | CandleTimeframeGroup | FK | Links each instrument to a candle interval group; determines which chart timeframes are available for that instrument. |
| Trade.CandleGroupToIntervals | GroupID | FK | Junction table that maps each group to the set of TimeframeIDs (Dictionary.CandleTimeframes) it supports. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CandleIntervalGroups (table)
```
This object has no dependencies. Tables have no code-level dependencies (no FROM/JOIN/CROSS APPLY in CREATE TABLE).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | FK CandleTimeframeGroup -> GroupID |
| Trade.CandleGroupToIntervals | Table | FK GroupID -> GroupID |
| Trade.GetInstrumentsTimeframeID | Procedure | JOINs InstrumentMetaData and CandleGroupToIntervals; CandleGroupToIntervals references this table via GroupID |
| Trade.InsertInstrumentMetaData | Procedure | Inserts CandleTimeframeGroup (default 2); value references GroupID |
| Trade.InsertInstrumentMetadataSecurityOpsAPI | Procedure | Inserts CandleTimeframeGroup |
| Trade.GetInstrumentByIdSecurityOpsAPI | Procedure | Selects CandleTimeframeGroup |
| Trade.GetAllFuturesMetadataSecurityOpsAPI | Procedure | Selects CandleTimeframeGroup |
| Trade.GetFuturesMetadataByInstrumentIdSecurityOpsAPI | Procedure | Selects CandleTimeframeGroup |
| Trade.UpdateFuturesMetadataSecurityOpsAPI | Procedure | References CandleTimeframeGroup |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CandleIntervalGroups | CLUSTERED | GroupID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CandleIntervalGroups | PRIMARY KEY | Enforces unique GroupID; clustered index for lookups. |

---

## 8. Sample Queries

### 8.1 List all candle interval groups
```sql
SELECT GroupID, GroupName
FROM Trade.CandleIntervalGroups WITH (NOLOCK)
ORDER BY GroupID;
```

### 8.2 Get timeframes available for Forex instruments
```sql
SELECT cig.GroupID, cig.GroupName, cgi.TimeframeID, ct.Name AS TimeframeName
FROM Trade.CandleIntervalGroups cig WITH (NOLOCK)
JOIN Trade.CandleGroupToIntervals cgi WITH (NOLOCK) ON cig.GroupID = cgi.GroupID
JOIN Dictionary.CandleTimeframes ct WITH (NOLOCK) ON cgi.TimeframeID = ct.Id
WHERE cig.GroupName = 'Forex'
ORDER BY cgi.TimeframeID;
```

### 8.3 Instruments by candle interval group
```sql
SELECT cig.GroupID, cig.GroupName, COUNT(im.InstrumentID) AS InstrumentCount
FROM Trade.CandleIntervalGroups cig WITH (NOLOCK)
LEFT JOIN Trade.InstrumentMetaData im WITH (NOLOCK) ON im.CandleTimeframeGroup = cig.GroupID
GROUP BY cig.GroupID, cig.GroupName
ORDER BY cig.GroupID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Split Process (Dealing CM)](https://etoro-jira.atlassian.net/wiki/spaces/EMM/pages/13952319750/Split+Process+Dealing+CM) | Confluence | Stock split process and CM workflows. |
| [CandleApi Support Delay Candles - HLD](https://etoro-jira.atlassian.net/wiki/spaces/MDT/pages/13944586241/CandleApi+Support+Delay+Candles+-+HLD) | Confluence | Candle API and delay candles support. |
| [Candle System Redesign HLD](https://etoro-jira.atlassian.net/wiki/spaces/MDT/pages/12068978923/Candle+System+Redesign+HLD) | Confluence | Candle chart system with predefined timeframe intervals (1min, 5min, 10min, 1day, 1week, etc.) for instrument charts. |

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.1/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 3 Confluence + 0 Jira | Procedures: 9 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CandleIntervalGroups | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.CandleIntervalGroups.sql*
