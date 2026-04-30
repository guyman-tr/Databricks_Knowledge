# Trade.ExposurePerInstrument

> Aggregates net open position exposure (signed units and volume-weighted average rate) per instrument for retail customers, excluding demo/paper accounts and instruments with ID >= 1000.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ExposurePerInstrument answers: "What is the net exposure in units and average rate for each instrument across all open retail positions?" It sums AmountInUnitsDecimal (positive for buys, negative for sells) per instrument, restricted to open positions (StatusID=1), retail customers (PlayerLevelID <> 4 excludes demo/paper), and instruments with InstrumentID < 1000 (typically forex and indices; stocks/crypto often have IDs >= 1000).

This view exists to support hedge exposure reporting, risk dashboards, and aggregate position analytics. Without it, consumers would need to replicate the JOIN and aggregation logic across multiple procedures. The InstrumentID < 1000 filter focuses the view on traditional forex/commodity exposure; equity and crypto exposure may be reported separately or through other views.

Data flows: Read-only. Trade.PositionTbl is the primary source, joined to Customer.CustomerStatic (PlayerLevelID filter) and Trade.InstrumentMetaData (InstrumentDisplayName). No procedure references were found in the grep; the view may be used by reporting, BI tools, or external systems.

---

## 2. Business Logic

### 2.1 Net Exposure Calculation

**What**: Long positions add units; short positions subtract. Net = sum of signed AmountInUnitsDecimal per instrument.

**Columns/Parameters Involved**: `IsBuy`, `AmountInUnitsDecimal`, `ExposureInUnits`

**Rules**:
- IsBuy=1: contribution = +AmountInUnitsDecimal
- IsBuy=0: contribution = -AmountInUnitsDecimal
- ExposureInUnits = Format(SUM(signed units), '0') - integer string

### 2.2 Volume-Weighted Average Rate

**What**: AvgRate = sum(units * InitForexRate) / sum(units). Represents the effective average open rate across all positions in that instrument.

**Columns/Parameters Involved**: `AmountInUnitsDecimal`, `InitForexRate`, `IsBuy`, `AvgRate`

**Rules**:
- Numerator: SUM(CASE WHEN IsBuy=1 THEN AmountInUnitsDecimal ELSE -AmountInUnitsDecimal END * InitForexRate)
- Denominator: SUM(signed units). Same signed logic as ExposureInUnits.
- Format(..., '0') renders as integer string.

### 2.3 Filter Logic

**What**: Only retail, open, forex/indices.

**Columns/Parameters Involved**: PlayerLevelID, StatusID, InstrumentID

**Rules**:
- PlayerLevelID <> 4: Excludes demo/paper accounts (4 = paper/demo).
- StatusID = 1: Open positions only.
- InstrumentID < 1000: Forex, commodities, indices (stocks typically 1000+).

---

## 3. Data Overview

| InstrumentID | InstrumentDisplayName | ExposureInUnits | AvgRate | Meaning |
|--------------|------------------------|-----------------|---------|---------|
| 79 | (empty) | 5 | 5 | Minor forex with net long exposure. Empty display name may indicate metadata gap. |
| 80 | (empty) | 6 | 58 | Net long 6 units, avg rate 58. |
| 81 | (empty) | 2 | 8 | Small net long. |
| 349 | AED/USD | 0 | 297 | Net flat exposure; AvgRate from prior positions or edge case. |
| 47 | AUD/CAD | 406 | 11 | Substantial net long exposure on AUD/CAD. |

**Selection criteria**: Live data TOP 5. Mix of instruments with and without InstrumentDisplayName. ExposureInUnits and AvgRate are formatted strings.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | YES | - | CODE-BACKED | From Trade.InstrumentMetaData via LEFT JOIN. FK to Trade.Instrument. May be NULL if no metadata row (DC.InstrumentID in GROUP BY). |
| 2 | InstrumentDisplayName | varchar(100) | YES | - | CODE-BACKED | Human-readable name from Trade.InstrumentMetaData. e.g., "EUR/USD", "AUD/CAD". Used in UI and reports. |
| 3 | ExposureInUnits | varchar(50) | NO | - | CODE-BACKED | Computed: Format(SUM(signed AmountInUnitsDecimal), '0'). Net position size in units: positive = net long, negative = net short. Formatted as integer string. |
| 4 | AvgRate | varchar(50) | NO | - | CODE-BACKED | Computed: Format(SUM(signed units * InitForexRate) / SUM(signed units), '0'). Volume-weighted average open rate. Formatted as integer string. Division by zero possible if SUM(signed units)=0; Format may produce empty or error in edge case. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.InstrumentMetaData | JOIN | Via P.InstrumentID = DC.InstrumentID |
| (PositionTbl) | Trade.PositionTbl | FROM | Primary source of positions |
| CID | Customer.CustomerStatic | JOIN | PlayerLevelID filter |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ExposurePerInstrument (view)
├── Trade.PositionTbl (table)
├── Customer.CustomerStatic (table)
└── Trade.InstrumentMetaData (table)
      └── Trade.Instrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | FROM, INNER JOIN - position data |
| Customer.CustomerStatic | Table | INNER JOIN on CID, filter PlayerLevelID |
| Trade.InstrumentMetaData | Table | LEFT JOIN on InstrumentID, InstrumentDisplayName |

### 6.2 Objects That Depend On This

No dependents found in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Top instruments by absolute exposure
```sql
SELECT InstrumentID, InstrumentDisplayName, ExposureInUnits, AvgRate
  FROM Trade.ExposurePerInstrument WITH (NOLOCK)
 ORDER BY ABS(CAST(ExposureInUnits AS FLOAT)) DESC;
```

### 8.2 Exposure for specific instruments
```sql
SELECT InstrumentID, InstrumentDisplayName, ExposureInUnits, AvgRate
  FROM Trade.ExposurePerInstrument WITH (NOLOCK)
 WHERE InstrumentID IN (1, 47, 79);
```

### 8.3 Net long vs net short summary
```sql
SELECT CASE WHEN CAST(ExposureInUnits AS FLOAT) > 0 THEN 'Net Long'
            WHEN CAST(ExposureInUnits AS FLOAT) < 0 THEN 'Net Short'
            ELSE 'Flat' END AS ExposureDirection,
       COUNT(*) AS InstrumentCount
  FROM Trade.ExposurePerInstrument WITH (NOLOCK)
 GROUP BY CASE WHEN CAST(ExposureInUnits AS FLOAT) > 0 THEN 'Net Long'
               WHEN CAST(ExposureInUnits AS FLOAT) < 0 THEN 'Net Short'
               ELSE 'Flat' END;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.4/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.ExposurePerInstrument | Type: View | Source: etoro/etoro/Trade/Views/Trade.ExposurePerInstrument.sql*
