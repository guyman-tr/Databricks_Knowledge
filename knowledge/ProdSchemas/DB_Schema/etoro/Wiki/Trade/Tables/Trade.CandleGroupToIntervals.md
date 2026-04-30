# Trade.CandleGroupToIntervals

> Junction table mapping each candle interval group (Forex, Stocks) to the set of chart timeframes (1min through 1 week) available for that group.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | GroupID + TimeframeID (composite PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Trade.CandleGroupToIntervals is a junction table that links candle interval groups (Trade.CandleIntervalGroups) to the individual chart timeframes (Dictionary.CandleTimeframes) each group supports. Each row represents one allowed timeframe for one group. For example, GroupID 1 (Forex) maps to TimeframeIDs 1-9, meaning Forex instruments can display all nine chart intervals from 1 minute to 1 week.

This table exists because the platform needs to control which candlestick chart intervals are available per instrument type without configuring each instrument individually. Trade.InstrumentMetaData.CandleTimeframeGroup assigns each instrument to a group (1=Forex, 2=Stocks); the group determines which TimeframeIDs are valid. Without this junction, the system would need per-instrument or per-asset-class hardcoding of timeframe availability.

Data flows: Configuration/ETL processes populate this table. Trade.GetInstrumentsTimeframeID reads it via LEFT JOIN on CandleTimeframeGroup = GroupID to return InstrumentID and TimeframeID for each instrument's available chart intervals. No procedures insert into this table in the analyzed code; it is maintained as reference data.

---

## 2. Business Logic

### 2.1 Group-to-Timeframe Mapping

**What**: Each group (Forex or Stocks) defines which candlestick chart intervals are available for instruments assigned to that group.

**Columns/Parameters Involved**: `GroupID`, `TimeframeID`

**Rules**:
- GroupID references Trade.CandleIntervalGroups (1=Forex, 2=Stocks)
- TimeframeID references Dictionary.CandleTimeframes (1-9: OneMinute through OneWeek)
- Each (GroupID, TimeframeID) pair is unique (composite PK)
- Both groups in current data (Forex and Stocks) include all 9 timeframes
- Instruments with CandleTimeframeGroup = GroupID get TimeframeID via this table; NULL group means no intervals

**Diagram**:
```
Trade.CandleIntervalGroups (GroupID, GroupName)
         |
         +-> GroupID 1 (Forex)  -> CandleGroupToIntervals -> TimeframeID 1..9
         +-> GroupID 2 (Stocks) -> CandleGroupToIntervals -> TimeframeID 1..9
         |
         v
Trade.InstrumentMetaData.CandleTimeframeGroup (FK) -> selects group per instrument
         |
         v
Trade.GetInstrumentsTimeframeID: InstrumentMetaData LEFT JOIN CandleGroupToIntervals ON CandleTimeframeGroup = GroupID
```

---

## 3. Data Overview

| GroupID | TimeframeID | Meaning |
|---------|-------------|---------|
| 1 | 1 | Forex group allows 1-minute chart interval. Used for scalping and short-term forex analysis. |
| 1 | 6 | Forex group allows 1-hour chart interval. Used for intraday trend analysis on currency pairs. |
| 1 | 8 | Forex group allows daily chart interval. Standard timeframe for forex position trading. |
| 2 | 1 | Stocks group allows 1-minute chart interval. Used for intraday stock analysis during exchange hours. |
| 2 | 8 | Stocks group allows daily chart interval. Most common timeframe for stock trend analysis. |

**Selection criteria for the 5 rows:**
- Both groups (1=Forex, 2=Stocks) and a range of timeframes (sub-hourly, hourly, daily) to show the junction's role.
- Table has 18 rows total; both groups include all 9 timeframes (1-9) in current data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GroupID | int | NO | - | CODE-BACKED | FK to Trade.CandleIntervalGroups.GroupID. Values: 1=Forex, 2=Stocks. Identifies which candle interval group this row belongs to. Used by Trade.GetInstrumentsTimeframeID to resolve available timeframes per instrument via InstrumentMetaData.CandleTimeframeGroup. |
| 2 | TimeframeID | int | NO | - | CODE-BACKED | FK to Dictionary.CandleTimeframes.Id. Values 1-9: OneMinute, FiveMinutes, TenMinutes, FifteenMinutes, ThirtyMinutes, OneHour, FourHours, OneDay, OneWeek. Identifies a chart interval that is available for this group. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GroupID | Trade.CandleIntervalGroups | FK | Links to the candle interval group (Forex or Stocks) that includes this timeframe. |
| TimeframeID | Dictionary.CandleTimeframes | FK | Links to the chart interval (1min through 1 week) that is available for this group. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetInstrumentsTimeframeID | Procedure (b alias) | JOIN | LEFT JOINs InstrumentMetaData (CandleTimeframeGroup) to CandleGroupToIntervals (GroupID) to return InstrumentID and TimeframeID for each instrument's available chart intervals. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CandleGroupToIntervals (table)
```
This object has no dependencies. Tables have no code-level dependencies (no FROM/JOIN/CROSS APPLY in CREATE TABLE). FK targets (Trade.CandleIntervalGroups, Dictionary.CandleTimeframes) are structural dependencies only.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CandleIntervalGroups | Table | FK GroupID references GroupID |
| Dictionary.CandleTimeframes | Table | FK TimeframeID references Id |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrumentsTimeframeID | Procedure | LEFT JOIN on CandleTimeframeGroup = GroupID to return InstrumentID and TimeframeID pairs |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CandleGroupToIntervals | CLUSTERED | GroupID ASC, TimeframeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CandleGroupToIntervals | PRIMARY KEY | Unique (GroupID, TimeframeID); prevents duplicate group-timeframe pairs. |
| FK_CandleGroupToIntervals_CandleIntervalGroups | FOREIGN KEY | GroupID -> Trade.CandleIntervalGroups.GroupID |
| FK_CandleGroupToIntervals_CandleTimeframes | FOREIGN KEY | TimeframeID -> Dictionary.CandleTimeframes.Id |

---

## 8. Sample Queries

### 8.1 List all group-to-timeframe mappings
```sql
SELECT  GroupID,
        TimeframeID
FROM    Trade.CandleGroupToIntervals WITH (NOLOCK)
ORDER BY GroupID, TimeframeID;
```

### 8.2 Get timeframes available for each group with names
```sql
SELECT  cgi.GroupID,
        cig.GroupName,
        cgi.TimeframeID,
        ct.Name AS TimeframeName
FROM    Trade.CandleGroupToIntervals cgi WITH (NOLOCK)
JOIN    Trade.CandleIntervalGroups cig WITH (NOLOCK)
        ON cig.GroupID = cgi.GroupID
JOIN    Dictionary.CandleTimeframes ct WITH (NOLOCK)
        ON ct.Id = cgi.TimeframeID
ORDER BY cgi.GroupID, cgi.TimeframeID;
```

### 8.3 Get instrument-to-timeframe pairs (replicate GetInstrumentsTimeframeID logic)
```sql
SELECT  a.InstrumentID,
        b.TimeframeID
FROM    Trade.InstrumentMetaData a WITH (NOLOCK)
LEFT JOIN Trade.CandleGroupToIntervals b WITH (NOLOCK)
        ON a.CandleTimeframeGroup = b.GroupID
ORDER BY a.InstrumentID, b.TimeframeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.7/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CandleGroupToIntervals | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.CandleGroupToIntervals.sql*
