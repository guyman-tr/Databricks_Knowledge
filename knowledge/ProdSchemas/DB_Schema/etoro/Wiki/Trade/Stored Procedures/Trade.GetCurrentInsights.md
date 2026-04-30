# Trade.GetCurrentInsights

> Generates three market insight result sets for all instruments: unique trader counts by direction, unit totals by direction, and position counts by direction - based on non-copied open positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 3 result sets: unique traders, unit totals, position counts per instrument |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure produces the "market insights" or "market sentiment" data that shows what percentage of traders are buying vs selling each instrument. This is commonly displayed on trading platforms as a social trading feature (e.g., "78% of traders are buying Apple"). It aggregates data from all non-copied open positions to determine the directional bias of unique traders.

The MirrorID=0 filter excludes copied positions so only original (manual) trading decisions count toward the sentiment - this prevents copy-trading from artificially inflating the buy/sell percentages.

Data flow: The insights/analytics service calls this procedure periodically -> receives three result sets covering unique traders, units, and positions per instrument -> caches and serves to the platform UI.

---

## 2. Business Logic

### 2.1 Net Direction Determination

**What**: Determines each trader's net direction per instrument by netting their buy and sell units.

**Columns/Parameters Involved**: `IsBuy`, `Units`, `CID`, `MirrorID`

**Rules**:
- Only non-copied positions count (MirrorID=0) and only open positions (StatusID=1)
- A trader's net direction is determined by SUM(IIF(IsBuy=1, 1, -1) * Units) - if positive they're net long, if negative they're net short
- Result set 1: BuyUniques / SellUniques per instrument (unique traders per direction)
- Result set 2: BuyUnits / SellUnits per instrument (total units per direction)
- Result set 3: BuyPositions / SellPositions per instrument (position count per direction)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

None.

### Return Columns (Result Set 1 - Unique Traders)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument. |
| 2 | BuyUniques | INT | NO | - | CODE-BACKED | Number of unique traders with net positive (long) exposure in this instrument. |
| 3 | SellUniques | INT | NO | - | CODE-BACKED | Number of unique traders with net negative (short) exposure in this instrument. |

### Return Columns (Result Set 2 - Unit Totals)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument. |
| 2 | BuyUnits | MONEY | NO | - | CODE-BACKED | Total units held in buy/long positions for this instrument. |
| 3 | SellUnits | MONEY | NO | - | CODE-BACKED | Total units held in sell/short positions for this instrument. |

### Return Columns (Result Set 3 - Position Counts)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument. |
| 2 | BuyPositions | INT | NO | - | CODE-BACKED | Total number of buy/long positions for this instrument. |
| 3 | SellPositions | INT | NO | - | CODE-BACKED | Total number of sell/short positions for this instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.PositionTbl | Read | Aggregates non-copied open positions by instrument and direction |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Insights/Analytics Service | EXEC | Caller | Generates market sentiment data for platform UI |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCurrentInsights (procedure)
└── Trade.PositionTbl (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Source of open, non-copied positions for sentiment calculation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Market Insights UI | External | Displays buy/sell sentiment percentages |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Uses temp table #Exposure to avoid re-scanning PositionTbl for each of the 3 result sets
- CTE materializes into temp table for reuse
- SET NOCOUNT ON for performance
- Returns 3 separate result sets in one call

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Trade.GetCurrentInsights;
```

### 8.2 Get sentiment for a single instrument

```sql
SELECT InstrumentID, CID, IsBuy,
       SUM(AmountInUnitsDecimal) AS Units,
       COUNT(*) AS Positions
FROM Trade.PositionTbl WITH (NOLOCK)
WHERE MirrorID = 0 AND StatusID = 1
      AND InstrumentID = 1001
GROUP BY InstrumentID, CID, IsBuy;
```

### 8.3 Calculate buy percentage for top instruments

```sql
;WITH Sentiment AS (
    SELECT InstrumentID, CID,
           SUM(IIF(IsBuy = 1, 1, -1) * AmountInUnitsDecimal) AS NetUnits
    FROM Trade.PositionTbl WITH (NOLOCK)
    WHERE MirrorID = 0 AND StatusID = 1
    GROUP BY InstrumentID, CID
)
SELECT InstrumentID,
       SUM(IIF(NetUnits > 0, 1, 0)) AS BuyTraders,
       SUM(IIF(NetUnits < 0, 1, 0)) AS SellTraders,
       CAST(SUM(IIF(NetUnits > 0, 1, 0)) * 100.0 /
            NULLIF(SUM(IIF(NetUnits > 0, 1, 0)) + SUM(IIF(NetUnits < 0, 1, 0)), 0) AS DECIMAL(5,1)) AS BuyPct
FROM Sentiment
GROUP BY InstrumentID
ORDER BY SUM(IIF(NetUnits > 0, 1, 0)) + SUM(IIF(NetUnits < 0, 1, 0)) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCurrentInsights | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCurrentInsights.sql*
