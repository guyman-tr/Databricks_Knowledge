# Trade.GetLoadedInstrumentsForCommission

> Returns instrument IDs from Trade.PositionTbl that have a high number of open hedge-eligible positions, used by the Hedge Cost Service to identify heavily loaded instruments for commission calculations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: InstrumentID list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetLoadedInstrumentsForCommission identifies instruments that have a very high number of open, hedge-eligible positions. The procedure groups open positions (StatusID=1, IsComputeForHedge=1) by instrument and returns those whose position count has more digits than the threshold. This is used by the Hedge Cost Service to determine which instruments are "heavily loaded" and may require special commission handling.

This procedure exists because instruments with extremely high position counts (e.g., 100,000+ positions) may need different commission calculation strategies. The threshold parameter controls the minimum digit count (defaulting to 5, meaning 10,000+ positions), and the service uses this list to optimize its processing.

Called by the HedgeCostService application user. The filtering logic uses LEN(COUNT(*)) > @Threshold, which counts the number of digits in the position count - a threshold of 5 means instruments with 100,000+ open hedge-eligible positions.

---

## 2. Business Logic

### 2.1 Digit-Count Threshold Filter

**What**: Filters instruments by the number of digits in their open position count, identifying heavily loaded instruments.

**Columns/Parameters Involved**: `@Threshold`, `Trade.PositionTbl.InstrumentID`, `IsComputeForHedge`, `StatusID`

**Rules**:
- Filters to open positions: StatusID=1 (Open)
- Filters to hedge-eligible: IsComputeForHedge=1
- Groups by InstrumentID
- HAVING LEN(COUNT(*)) > @Threshold filters by digit count of position count
- Default @Threshold=5 means: instruments with > 99,999 open hedge positions (6+ digit counts)
- @Threshold=4 would mean > 9,999 positions
- @Threshold=3 would mean > 999 positions

**Diagram**:
```
Trade.PositionTbl
  |
  +-- WHERE StatusID=1 AND IsComputeForHedge=1
  |
  +-- GROUP BY InstrumentID
  |
  +-- HAVING LEN(COUNT(*)) > @Threshold
  |
  v
Instruments with very high open hedge position counts
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @Threshold | int | IN | 5 (if NULL) | CODE-BACKED | Minimum digit count for the position count filter. Instruments with LEN(COUNT(*)) > @Threshold are returned. Default 5 means instruments with 100,000+ open hedge positions. |

### 4.2 Result Set

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | InstrumentID | int | NO | CODE-BACKED | Instrument identifier for an instrument with a very high number of open, hedge-eligible positions exceeding the threshold. FK to Trade.Instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.PositionTbl | SELECT (READER) | Reads open hedge-eligible positions grouped by instrument |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| HedgeCostService | GRANT EXECUTE | Application User | Hedge Cost Service calls to identify heavily loaded instruments for commission calculation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetLoadedInstrumentsForCommission (procedure)
+-- Trade.PositionTbl (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | SELECT with GROUP BY and HAVING to find heavily loaded instruments |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| HedgeCostService | Application User | Calls to get loaded instruments for commission |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get loaded instruments with default threshold

```sql
EXEC Trade.GetLoadedInstrumentsForCommission @Threshold = NULL;
```

### 8.2 Get instruments with 10,000+ open hedge positions

```sql
EXEC Trade.GetLoadedInstrumentsForCommission @Threshold = 4;
```

### 8.3 Preview position counts per instrument for hedge-eligible positions

```sql
SELECT  TP.InstrumentID,
        COUNT(*) AS OpenHedgePositions,
        LEN(COUNT(*)) AS DigitCount
FROM    Trade.PositionTbl TP WITH (NOLOCK)
WHERE   IsComputeForHedge = 1
        AND StatusID = 1
GROUP BY TP.InstrumentID
ORDER BY OpenHedgePositions DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetLoadedInstrumentsForCommission | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetLoadedInstrumentsForCommission.sql*
