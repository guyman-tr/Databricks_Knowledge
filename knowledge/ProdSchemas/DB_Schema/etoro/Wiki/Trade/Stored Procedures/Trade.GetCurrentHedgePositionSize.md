# Trade.GetCurrentHedgePositionSize

> Calculates the total buy and sell lot sizes for a specific instrument from the hedge position table, used by the hedge engine to determine current market exposure.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns buy and sell lot sums via OUTPUT parameters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure queries the Trade.Hedge table to calculate the total buy (long) and sell (short) lot exposure for a given instrument. The hedge engine uses this to understand the platform's current net market exposure, which determines whether additional hedging is needed.

The procedure separates lots by direction (IsBuy) so the hedge engine can compute the net position (buy - sell) and decide whether to increase or decrease the external hedge.

Data flow: Hedge engine provides an InstrumentID -> procedure sums LotCountDecimal from Trade.Hedge grouped by direction -> returns buy and sell totals via OUTPUT parameters.

---

## 2. Business Logic

### 2.1 Direction-Split Lot Aggregation

**What**: Separates total lots into buy and sell components using CASE expressions.

**Columns/Parameters Involved**: `IsBuy`, `LotCountDecimal`

**Rules**:
- IsBuy=1: Contributes to @BuyLotSum (long exposure)
- IsBuy=0: Contributes to @SellLotSum (short exposure)
- Returns 0 via ISNULL when no positions exist for the instrument
- No status filter - aggregates all hedge records for the instrument

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument to calculate hedge exposure for. |
| 2 | @BuyLotSum | INT | NO | - (OUTPUT) | CODE-BACKED | OUTPUT: Total lots on the buy/long side for the instrument. Sum of LotCountDecimal where IsBuy=1. |
| 3 | @SellLotSum | INT | NO | - (OUTPUT) | CODE-BACKED | OUTPUT: Total lots on the sell/short side for the instrument. Sum of LotCountDecimal where IsBuy=0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.Hedge | Read | Aggregates lot counts from the hedge position table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge Engine | EXEC | Caller | Reads current market exposure per instrument |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCurrentHedgePositionSize (procedure)
└── Trade.Hedge (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Hedge | Table | Source of hedge position lot counts |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge Engine | External | Market exposure calculation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- No NOLOCK hint on Trade.Hedge - may experience blocking
- SET NOCOUNT ON for performance
- OUTPUT parameters typed as INT but LotCountDecimal is DECIMAL - implicit truncation may occur

---

## 8. Sample Queries

### 8.1 Execute for a specific instrument

```sql
DECLARE @Buy INT, @Sell INT;
EXEC Trade.GetCurrentHedgePositionSize @InstrumentID = 1001, @BuyLotSum = @Buy OUTPUT, @SellLotSum = @Sell OUTPUT;
SELECT @Buy AS BuyLots, @Sell AS SellLots, @Buy - @Sell AS NetExposure;
```

### 8.2 Query hedge positions directly

```sql
SELECT InstrumentID, IsBuy,
       SUM(LotCountDecimal) AS TotalLots,
       COUNT(*) AS PositionCount
FROM Trade.Hedge WITH (NOLOCK)
WHERE InstrumentID = 1001
GROUP BY InstrumentID, IsBuy;
```

### 8.3 Find instruments with highest net exposure

```sql
SELECT InstrumentID,
       SUM(CASE WHEN IsBuy = 1 THEN LotCountDecimal ELSE 0 END) AS BuyLots,
       SUM(CASE WHEN IsBuy = 0 THEN LotCountDecimal ELSE 0 END) AS SellLots,
       SUM(CASE WHEN IsBuy = 1 THEN LotCountDecimal ELSE -LotCountDecimal END) AS NetLots
FROM Trade.Hedge WITH (NOLOCK)
GROUP BY InstrumentID
ORDER BY ABS(SUM(CASE WHEN IsBuy = 1 THEN LotCountDecimal ELSE -LotCountDecimal END)) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.4/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCurrentHedgePositionSize | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCurrentHedgePositionSize.sql*
