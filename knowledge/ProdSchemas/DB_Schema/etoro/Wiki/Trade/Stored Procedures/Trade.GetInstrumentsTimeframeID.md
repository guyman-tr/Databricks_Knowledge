# Trade.GetInstrumentsTimeframeID

> Returns the candle chart timeframe assignment for each instrument, mapping instruments to their configured charting interval group for price chart generation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns InstrumentID + TimeframeID from InstrumentMetaData + CandleGroupToIntervals |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentsTimeframeID returns the timeframe ID for each instrument based on its candle timeframe group assignment. Instruments are assigned to candle groups (via InstrumentMetaData.CandleTimeframeGroup), and each group maps to specific timeframe intervals (via Trade.CandleGroupToIntervals). This data drives the price charting system to know which candle intervals (1min, 5min, 1hr, etc.) to generate for each instrument.

This procedure exists because not all instruments use the same charting intervals - high-liquidity instruments may have 1-minute candles while less-active instruments may only support hourly candles. The group-based mapping allows bulk configuration changes.

The LEFT JOIN ensures instruments without a candle group assignment still appear in results (with NULL TimeframeID), allowing the charting system to detect unconfigured instruments.

---

## 2. Business Logic

### 2.1 Candle Group to Timeframe Resolution

**What**: Resolves each instrument's candle group to specific timeframe intervals for chart generation.

**Columns/Parameters Involved**: `Trade.InstrumentMetaData.CandleTimeframeGroup`, `Trade.CandleGroupToIntervals.GroupID`, `Trade.CandleGroupToIntervals.TimeframeID`

**Rules**:
- InstrumentMetaData.CandleTimeframeGroup links instruments to candle interval groups
- LEFT JOIN to CandleGroupToIntervals means instruments without a group return NULL TimeframeID
- An instrument may appear in multiple rows if its group has multiple timeframe intervals

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Return Columns**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | InstrumentID | int | Trade.InstrumentMetaData.InstrumentID | CODE-BACKED | Instrument identifier. FK to Trade.Instrument. |
| R2 | TimeframeID | int | Trade.CandleGroupToIntervals.TimeframeID | CODE-BACKED | Candle timeframe interval identifier (e.g., 1min, 5min, 1hr). NULL if instrument has no candle group assignment. Used by charting system to generate appropriate candle data. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.InstrumentMetaData | Read (SELECT) | Source of InstrumentID and CandleTimeframeGroup |
| LEFT JOIN | Trade.CandleGroupToIntervals | Lookup | Resolves CandleTimeframeGroup to TimeframeID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Charting services | (application) | Consumer | Uses timeframe mapping to generate candle charts |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentsTimeframeID (procedure)
+-- Trade.InstrumentMetaData (table)
+-- Trade.CandleGroupToIntervals (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | FROM - source of instruments and their candle group assignments |
| Trade.CandleGroupToIntervals | Table | LEFT JOIN - maps candle groups to timeframe intervals |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Charting services | Application | Read timeframe assignments for candle generation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all instrument timeframe assignments

```sql
EXEC Trade.GetInstrumentsTimeframeID;
```

### 8.2 Find instruments without candle group assignment

```sql
SELECT  imd.InstrumentID, imd.InstrumentDisplayName, imd.CandleTimeframeGroup
FROM    Trade.InstrumentMetaData imd WITH (NOLOCK)
        LEFT JOIN Trade.CandleGroupToIntervals cgi WITH (NOLOCK) ON imd.CandleTimeframeGroup = cgi.GroupID
WHERE   cgi.GroupID IS NULL;
```

### 8.3 View candle groups and their timeframes

```sql
SELECT  cgi.GroupID, cig.GroupName, cgi.TimeframeID
FROM    Trade.CandleGroupToIntervals cgi WITH (NOLOCK)
        INNER JOIN Trade.CandleIntervalGroups cig WITH (NOLOCK) ON cgi.GroupID = cig.GroupID
ORDER BY cgi.GroupID, cgi.TimeframeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentsTimeframeID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentsTimeframeID.sql*
