# Trade.GetAveragePositionInitRate

> Calculates the average initial execution rate for client positions at a given instrument and hedge server, used for exposure reporting and PnL estimation when buy and sell position counts differ.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns dtPrice (decimal) — average position init rate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetAveragePositionInitRate computes the average opening rate of all client positions for a specific (ProviderID, InstrumentID, HedgeServerID) combination. It reads from Trade.Position (legacy view over Trade.PositionTbl). Each position has an InitForexRate recorded when it was opened. This function aggregates those rates separately for long (IsBuy=1) and short (IsBuy=0) positions, then returns a weighted average based on whether buy or sell positions dominate.

This function exists because exposure and PnL aggregation need a representative init rate when displaying aggregate mark-to-market or reconciling hedge vs position rates. When buy and sell counts are equal, the function returns the midpoint of average buy and average sell rates. When asymmetric, it returns the average of the dominant side. The ProviderID is used to look up precision from Trade.ProviderToInstrument; the return is cast to decimal(20,4) regardless of precision (per code comment).

Data flows: Read from Trade.Position and Trade.ProviderToInstrument. No direct callers found in repository search; likely consumed by internal exposure or reporting code.

---

## 2. Business Logic

### 2.1 Average Init Rate by Buy vs Sell

**What**: Returns a representative average init rate when position counts are balanced or skewed.

**Columns/Parameters Involved**: `@ProviderID`, `@InstrumentID`, `@HedgeServerID`, `InitForexRate`, `IsBuy`

**Rules**:
- If BuyCount = SellCount: Result = (AverageBuy + AverageSell) / 2
- If BuyCount > SellCount: Result = AverageBuy
- If SellCount > BuyCount: Result = AverageSell
- NULL counts/averages are treated as 0 via ISNULL
- Return is always cast to decimal(20,4) (code comment: precision from ProviderToInstrument cannot be used in cast)

**Diagram**:
```
Trade.Position (InstrumentID, HedgeServerID, IsBuy, InitForexRate)
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
| 2 | @InstrumentID | int | NO | - | CODE-BACKED | Tradable instrument (Trade.Instrument). Filters positions to this instrument. |
| 3 | @HedgeServerID | int | NO | - | CODE-BACKED | Hedge server (Trade.HedgeServer) managing positions. Filters positions to this server. |
| 4 | Return value | decimal(20,4) | NO | - | CODE-BACKED | Average initial position rate. Weighted by buy/sell dominance; midpoint when balanced. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID, @HedgeServerID | Trade.Position | SELECT | Aggregates InitForexRate by IsBuy (view over Trade.PositionTbl) |
| @ProviderID, @InstrumentID | Trade.ProviderToInstrument | SELECT | Looks up Precision (not used in final cast) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAveragePositionInitRate (function)
├── Trade.Position (view)
│     └── Trade.PositionTbl (table)
└── Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | FROM — aggregates InitForexRate, COUNT by InstrumentID, HedgeServerID, IsBuy |
| Trade.ProviderToInstrument | Table | FROM — Precision lookup by ProviderID, InstrumentID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Average position init rate for EUR/USD at hedge server 1
```sql
DECLARE @ProviderID INT = 1, @InstrumentID INT = 1, @HedgeServerID INT = 1;
SELECT Trade.GetAveragePositionInitRate(@ProviderID, @InstrumentID, @HedgeServerID) AS AvgPositionInitRate;
```

### 8.2 Compare to raw position averages
```sql
SELECT 'Buy' AS Side, AVG(InitForexRate) AS AvgRate, COUNT(*) AS Cnt
FROM Trade.Position WITH (NOLOCK)
WHERE InstrumentID = 1 AND HedgeServerID = 1 AND IsBuy = 1
UNION ALL
SELECT 'Sell', AVG(InitForexRate), COUNT(*)
FROM Trade.Position WITH (NOLOCK)
WHERE InstrumentID = 1 AND HedgeServerID = 1 AND IsBuy = 0;
```

### 8.3 Join to provider and instrument
```sql
SELECT PTI.ProviderID, PTI.InstrumentID, hs.HedgeServerID,
       Trade.GetAveragePositionInitRate(PTI.ProviderID, PTI.InstrumentID, hs.HedgeServerID) AS AvgInitRate
FROM Trade.ProviderToInstrument PTI WITH (NOLOCK)
CROSS JOIN Trade.HedgeServer hs WITH (NOLOCK)
WHERE PTI.InstrumentID = 1
  AND EXISTS (SELECT 1 FROM Trade.Position p WITH (NOLOCK) WHERE p.InstrumentID = PTI.InstrumentID AND p.HedgeServerID = hs.HedgeServerID);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetAveragePositionInitRate | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.GetAveragePositionInitRate.sql*
