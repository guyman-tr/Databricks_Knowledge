# Trade.GetAverageHedgeInitRate

> Calculates the average initial execution rate for hedge positions at a given instrument and hedge server, used for exposure reporting and PnL estimation when buy and sell hedge counts differ.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns dtPrice (decimal) — average hedge init rate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetAverageHedgeInitRate computes the average opening rate of all executed hedges for a specific (ProviderID, InstrumentID, HedgeServerID) combination. eToro hedges client CFD exposure at liquidity providers; each hedge has an InitForexRate recorded when it was executed. This function aggregates those rates separately for long (IsBuy=1) and short (IsBuy=0) hedges, then returns a weighted average based on whether buy or sell hedges dominate.

This function exists because hedge exposure queries need a representative init rate when displaying aggregate PnL or mark-to-market. When buy and sell counts are equal, the function returns the midpoint of average buy and average sell rates. When asymmetric, it returns the average of the dominant side. The ProviderID is used to look up precision from Trade.ProviderToInstrument; the return is cast to decimal(20,4) regardless of precision (per code comment).

Data flows: Called by Trade.GetHedgeExposureDetailed and Trade.GetHedgeExposureDetailedWithActiveParent (commented-out references). Read from Trade.Hedge and Trade.ProviderToInstrument.

---

## 2. Business Logic

### 2.1 Average Init Rate by Buy vs Sell

**What**: Returns a representative average init rate when hedge counts are balanced or skewed.

**Columns/Parameters Involved**: `@ProviderID`, `@InstrumentID`, `@HedgeServerID`, `InitForexRate`, `IsBuy`

**Rules**:
- If BuyCount = SellCount: Result = (AverageBuy + AverageSell) / 2
- If BuyCount > SellCount: Result = AverageBuy
- If SellCount > BuyCount: Result = AverageSell
- NULL counts/averages are treated as 0 via ISNULL
- Return is always cast to decimal(20,4) (code comment: precision from ProviderToInstrument cannot be used in cast)

**Diagram**:
```
Trade.Hedge (InstrumentID, HedgeServerID, IsBuy, InitForexRate)
  |
  v
  AVG(InitForexRate) WHERE IsBuy=1  -> AverageBuy, BuyCount
  AVG(InitForexRate) WHERE IsBuy=0  -> AverageSell, SellCount
  |
  v
  IF BuyCount = SellCount -> (AvgBuy+AvgSell)/2
  IF BuyCount > SellCount  -> AvgBuy
  IF SellCount > BuyCount -> AvgSell
```

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderID | int | NO | - | CODE-BACKED | Execution provider ID. Used to look up Precision from Trade.ProviderToInstrument for display/formatting (not used in return cast due to type limitation). |
| 2 | @InstrumentID | int | NO | - | CODE-BACKED | Tradable instrument (Trade.Instrument). Filters hedges to this instrument. |
| 3 | @HedgeServerID | int | NO | - | CODE-BACKED | Hedge server (Trade.HedgeServer) managing the hedges. Filters hedges to this server. |
| 4 | Return value | decimal(20,4) | NO | - | CODE-BACKED | Average initial hedge rate. Weighted by buy/sell dominance; midpoint when balanced. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID, @HedgeServerID | Trade.Hedge | SELECT | Aggregates InitForexRate by IsBuy |
| @ProviderID, @InstrumentID | Trade.ProviderToInstrument | SELECT | Looks up Precision (not used in final cast) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetHedgeExposureDetailed | InitForexRate (commented) | Reader | Exposed as alternative init rate source |
| Trade.GetHedgeExposureDetailedWithActiveParent | InitForexRate (commented) | Reader | Same pattern |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAverageHedgeInitRate (function)
├── Trade.Hedge (table)
└── Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Hedge | Table | FROM — aggregates InitForexRate, COUNT by InstrumentID, HedgeServerID, IsBuy |
| Trade.ProviderToInstrument | Table | FROM — Precision lookup by ProviderID, InstrumentID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetHedgeExposureDetailed | View | Commented reference — alternative InitForexRate |
| Trade.GetHedgeExposureDetailedWithActiveParent | View | Commented reference — same |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Average hedge init rate for EUR/USD at hedge server 1
```sql
DECLARE @ProviderID INT = 1, @InstrumentID INT = 1, @HedgeServerID INT = 1;
SELECT Trade.GetAverageHedgeInitRate(@ProviderID, @InstrumentID, @HedgeServerID) AS AvgHedgeInitRate;
```

### 8.2 Compare to raw hedge averages
```sql
SELECT 'Buy' AS Side, AVG(InitForexRate) AS AvgRate, COUNT(*) AS Cnt
FROM Trade.Hedge WITH (NOLOCK)
WHERE InstrumentID = 1 AND HedgeServerID = 1 AND IsBuy = 1
UNION ALL
SELECT 'Sell', AVG(InitForexRate), COUNT(*)
FROM Trade.Hedge WITH (NOLOCK)
WHERE InstrumentID = 1 AND HedgeServerID = 1 AND IsBuy = 0;
```

### 8.3 Join to provider and instrument
```sql
SELECT PTI.ProviderID, PTI.InstrumentID, hs.HedgeServerID,
       Trade.GetAverageHedgeInitRate(PTI.ProviderID, PTI.InstrumentID, hs.HedgeServerID) AS AvgInitRate
FROM Trade.ProviderToInstrument PTI WITH (NOLOCK)
CROSS JOIN Trade.HedgeServer hs WITH (NOLOCK)
WHERE PTI.InstrumentID = 1
  AND EXISTS (SELECT 1 FROM Trade.Hedge h WITH (NOLOCK) WHERE h.InstrumentID = PTI.InstrumentID AND h.HedgeServerID = hs.HedgeServerID);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.2/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetAverageHedgeInitRate | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.GetAverageHedgeInitRate.sql*
