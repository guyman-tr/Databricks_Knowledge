# Trade.UserPositionsTableType_MOT

> Memory-optimized table-valued parameter type for passing user position data to aggregation and portfolio procedures.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | PositionID (bigint) |
| **Partition** | N/A |
| **Indexes** | 3: IX_GroupBy, IX_MirrorID, IX_RedeemStatus |

---

## 1. Business Meaning

UserPositionsTableType_MOT carries a set of position-like rows for use in portfolio aggregation. Each row includes PositionID, MirrorID, InstrumentID, IsBuy, IsSettled, PnLVersion, RedeemStatus, Units, Amount, fees, taxes, leverage, InitDateTime, and related fields. It models a snapshot or subset of user positions for aggregation (e.g., PnL, exposure).

This type exists to pass position data efficiently to procedures that compute portfolio aggregates. Memory-optimized types reduce tempdb pressure and improve performance for large position sets. Trade.GetPortfolioAggregates declares a table variable of this type and uses it to hold positions for aggregation.

The type flows from callers that populate position data (or the procedure populates it from queries) into Trade.GetPortfolioAggregates. The procedure uses the TVP for grouping and aggregation.

---

## 2. Business Logic

Position grouping by MirrorID + InstrumentID + IsBuy + IsSettled + PnLVersion (IX_GroupBy). MirrorID and RedeemStatus have dedicated indexes for filtering. Multi-column config pattern for position-level aggregation inputs.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Position identifier |
| 2 | MirrorID | int | YES | - | CODE-BACKED | Mirror (copy-trading) identifier; NULL if not mirrored |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | Instrument identifier |
| 4 | IsBuy | bit | NO | - | CODE-BACKED | True for buy/long, false for sell/short |
| 5 | IsSettled | bit | NO | - | CODE-BACKED | Whether position is settled |
| 6 | PnLVersion | tinyint | YES | - | CODE-BACKED | PnL calculation version |
| 7 | RedeemStatus | tinyint | YES | - | CODE-BACKED | Redemption status of position |
| 8 | Units | decimal(18,8) | YES | - | CODE-BACKED | Position size in units |
| 9 | InitForexRate | decimal(16,8) | NO | - | CODE-BACKED | Initial forex rate at open |
| 10 | InitConversionRate | decimal(16,8) | YES | - | CODE-BACKED | Initial conversion rate |
| 11 | Amount | decimal(18,2) | NO | - | CODE-BACKED | Position amount |
| 12 | OpenTotalFees | decimal(18,2) | YES | - | CODE-BACKED | Total fees at open |
| 13 | OpenTotalTaxes | decimal(18,2) | YES | - | CODE-BACKED | Total taxes at open |
| 14 | LotCount | decimal(18,8) | YES | - | CODE-BACKED | Lot count |
| 15 | Leverage | int | NO | - | CODE-BACKED | Leverage multiplier |
| 16 | AmountFormula | tinyint | YES | - | CODE-BACKED | Amount calculation formula ID |
| 17 | InitDateTime | datetime | NO | - | CODE-BACKED | Initial/open datetime |

---

## 5. Relationships

### 5.1 References To (this object points to)

PositionID, MirrorID, InstrumentID semantically reference Trade.Position, Trade.Mirror, Trade.Instrument but no declared FK on the type.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetPortfolioAggregates | @UserPositions (table variable) | Internal table variable | Holds positions for portfolio aggregation |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPortfolioAggregates | Stored Procedure | Internal table variable for position aggregation |

---

## 7. Technical Details

### 7.1 Indexes

IX_GroupBy (NONCLUSTERED): MirrorID, InstrumentID, IsBuy, IsSettled, PnLVersion. IX_MirrorID (NONCLUSTERED): MirrorID. IX_RedeemStatus (NONCLUSTERED): RedeemStatus. Type is memory-optimized (WITH MEMORY_OPTIMIZED = ON).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare table variable for use in procedure
```sql
DECLARE @UserPositions Trade.UserPositionsTableType_MOT;
INSERT INTO @UserPositions (PositionID, MirrorID, InstrumentID, IsBuy, IsSettled, PnLVersion, RedeemStatus, Units, InitForexRate, InitConversionRate, Amount, OpenTotalFees, OpenTotalTaxes, LotCount, Leverage, AmountFormula, InitDateTime)
SELECT PositionID, MirrorID, InstrumentID, IsBuy, IsSettled, PnLVersion, RedeemStatus, Units, InitForexRate, InitConversionRate, Amount, OpenTotalFees, OpenTotalTaxes, LotCount, Leverage, AmountFormula, InitDateTime
FROM Trade.Position WHERE CID = 12345;
-- Use @UserPositions in aggregation logic
```

### 8.2 Single position for aggregation
```sql
DECLARE @UserPositions Trade.UserPositionsTableType_MOT;
INSERT INTO @UserPositions (PositionID, MirrorID, InstrumentID, IsBuy, IsSettled, PnLVersion, RedeemStatus, Units, InitForexRate, InitConversionRate, Amount, OpenTotalFees, OpenTotalTaxes, LotCount, Leverage, AmountFormula, InitDateTime)
VALUES (99999, NULL, 100, 1, 0, 1, NULL, 0.5, 1.1, 1.0, 1000, 0, 0, 0.5, 10, 1, GETDATE());
```

### 8.3 Filter by MirrorID (index-supported)
```sql
DECLARE @UserPositions Trade.UserPositionsTableType_MOT;
INSERT INTO @UserPositions SELECT * FROM Trade.Position WHERE MirrorID = 100;
SELECT * FROM @UserPositions WHERE MirrorID = 100;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 1/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UserPositionsTableType_MOT | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.UserPositionsTableType_MOT.sql*
