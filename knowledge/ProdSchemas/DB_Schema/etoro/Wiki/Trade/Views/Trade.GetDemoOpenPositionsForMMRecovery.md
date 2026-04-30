# Trade.GetDemoOpenPositionsForMMRecovery

> Identifies leader positions whose copy-trade mirrors are active but no copier position exists yet, flagging them for demo MM recovery to create the missing child positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from RealOpenPositions) |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.GetDemoOpenPositionsForMMRecovery finds open **leader positions** that should have generated copier (demo) positions but haven't. In eToro's CopyTrader, when a leader opens a position, the system should automatically create matching positions for all active copiers. If this propagation fails, copier positions are "missing." This view identifies the leader positions that need re-processing.

This is the opposite of ClosePositionsGetRecoveryItemsDemo (which finds orphaned copier positions after the leader closes). Here, the leader is still open but the expected copier positions were never created. Without recovery, the copier's portfolio would not reflect the leader's trades, breaking the copy-trade contract.

The view works by: (1) reading from RealOpenPositions (synonym), (2) joining to Trade.Mirror to find active mirrors where the leader's CID matches, (3) LEFT joining to Trade.GetPositionData to check if a copier position already exists (OrigParentPositionID = leader's PositionID AND same MirrorID), (4) filtering where no copier exists (TPOS.PositionID IS NULL), and (5) requiring the mirror amount exceeds a configurable threshold from Maintenance.Feature (FeatureID=100). Several columns are computed: NetProfit via Internal.GetNetProfit function, amounts in cents, and IsBuy/CloseOnEndOfWeek as string representations.

---

## 2. Business Logic

### 2.1 Missing Copier Detection

**What**: Finds leader positions that should have copier positions but don't.

**Columns/Parameters Involved**: `PositionID`, `CID`, `MirrorID`, `OrigParentPositionID`

**Rules**:
- Leader position is in RealOpenPositions (active, open)
- An active Mirror record exists (tm.ParentCID = leader.CID, tm.IsActive = 1)
- Mirror was created before or at the position's Occurred time
- No copier position exists with OrigParentPositionID = leader.PositionID AND matching MirrorID
- Mirror amount must exceed threshold: tm.Amount > Maintenance.Feature(100).Value / 100

### 2.2 Amount and Commission Conversion

**What**: Converts monetary values to cents and boolean flags to strings for legacy consumer compatibility.

**Columns/Parameters Involved**: `PositionAmountCents`, `CommissionCents`, `IsBuy`, `CloseOnEndOfWeek`

**Rules**:
- PositionAmountCents = CAST(Amount * 100 AS INTEGER) - converts to cents
- CommissionCents = CAST(Commission * 100 AS INTEGER) - converts to cents
- IsBuy output as string: 'true'/'false' (not bit) for legacy XML consumers
- CloseOnEndOfWeek output as string: 'true'/'false'
- NetProfit calculated via Internal.GetNetProfit(PositionID) cast to INTEGER

---

## 3. Data Overview

View references RealOpenPositions (synonym) and Internal.GetNetProfit (cross-schema function). When populated, each row represents a leader position missing its copier counterpart.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Leader's customer ID from RealOpenPositions. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | Leader's open position that needs copier creation. |
| 3 | ForexResultID | bigint | YES | - | CODE-BACKED | Legacy forex result tracking. From RealOpenPositions. |
| 4 | Currency | int | YES | - | CODE-BACKED | Denomination currency ID (aliased from CurrencyID). From RealOpenPositions. |
| 5 | ProviderID | int | YES | - | CODE-BACKED | Execution provider. From RealOpenPositions. |
| 6 | InstrumentID | int | YES | - | CODE-BACKED | Instrument traded. From RealOpenPositions. FK to Trade.Instrument. |
| 7 | PositionHedgeServerID | int | YES | - | CODE-BACKED | Hedge server (aliased from HedgeServerID). From RealOpenPositions. |
| 8 | Leverage | int | YES | - | CODE-BACKED | Leverage multiplier. From RealOpenPositions. |
| 9 | ForexBuy | int | YES | - | CODE-BACKED | Buy currency ID from Trade.Instrument.BuyCurrencyID. |
| 10 | ForexSell | int | YES | - | CODE-BACKED | Sell currency ID from Trade.Instrument.SellCurrencyID. |
| 11 | InitForexRate | float | YES | - | CODE-BACKED | Forex rate at position open. From RealOpenPositions. |
| 12 | EndForexRate | float | YES | - | CODE-BACKED | Always NULL (position is open). Hardcoded NULL. |
| 13 | InitDateTime | datetime | YES | - | CODE-BACKED | When position was opened. From RealOpenPositions. |
| 14 | NetProfit | int | YES | - | CODE-BACKED | Computed: CAST(Internal.GetNetProfit(PositionID) AS INTEGER). Live PnL in cents. |
| 15 | LimitRate | float | YES | - | CODE-BACKED | Take-profit rate. From RealOpenPositions. |
| 16 | StopRate | float | YES | - | CODE-BACKED | Stop-loss rate. From RealOpenPositions. |
| 17 | PositionAmountCents | int | YES | - | CODE-BACKED | Computed: CAST(Amount * 100 AS INTEGER). Position amount in cents. |
| 18 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position amount in units/shares. From RealOpenPositions. |
| 19 | CommissionCents | int | YES | - | CODE-BACKED | Computed: CAST(Commission * 100 AS INTEGER). Commission in cents. |
| 20 | Commission | money | YES | - | CODE-BACKED | Commission at open. From RealOpenPositions. |
| 21 | IsBuy | varchar | YES | - | CODE-BACKED | Direction as string: 'true' = buy/long, 'false' = sell/short. Converted from bit for legacy XML consumers. |
| 22 | CloseOnEndOfWeek | varchar | YES | - | CODE-BACKED | Weekend close preference as string: 'true'/'false'. Converted from bit for legacy consumers. |
| 23 | Units | decimal | YES | - | CODE-BACKED | Unit count from Trade.ProviderToInstrument.Unit. |
| 24 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count from provider. From RealOpenPositions. |
| 25 | UnitMargin | money | YES | - | CODE-BACKED | Unit margin. From RealOpenPositions. |
| 26 | AdditionalParam | varchar | YES | - | CODE-BACKED | Additional parameters. From RealOpenPositions. |
| 27 | OrderID | int | YES | - | CODE-BACKED | Originating order. From RealOpenPositions. |
| 28 | TradeRange | float | YES | - | CODE-BACKED | Market range tolerance. From RealOpenPositions. |
| 29 | InitForexPriceRateID | bigint | YES | - | CODE-BACKED | Price rate snapshot at open. From RealOpenPositions. |
| 30 | OrderPriceRate | decimal(16,8) | YES | - | CODE-BACKED | Order price rate. From RealOpenPositions. |
| 31 | OrderPriceRateID | bigint | YES | - | CODE-BACKED | Order price rate snapshot ID. From RealOpenPositions. |
| 32 | MarketPriceRate | decimal(16,8) | YES | - | CODE-BACKED | Market price rate at open. From RealOpenPositions. |
| 33 | MarketPriceRateID | bigint | YES | - | CODE-BACKED | Market price rate snapshot ID. From RealOpenPositions. |
| 34 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent position in hierarchy. From RealOpenPositions. |
| 35 | LastOpPriceRate | decimal(16,8) | YES | - | CODE-BACKED | Last operation price rate. From RealOpenPositions. |
| 36 | LastOpPriceRateID | bigint | YES | - | CODE-BACKED | Last op price rate snapshot ID. From RealOpenPositions. |
| 37 | LastOpConversionRate | decimal(16,8) | YES | - | CODE-BACKED | Last operation conversion rate. From RealOpenPositions. |
| 38 | LastOpConversionRateID | bigint | YES | - | CODE-BACKED | Last op conversion rate snapshot ID. From RealOpenPositions. |
| 39 | InstrumentPrecision | int | YES | - | CODE-BACKED | Decimal precision from Trade.ProviderToInstrument.Precision. |
| 40 | MirrorID | int | YES | - | CODE-BACKED | Mirror/copy-trade ID. From RealOpenPositions. |
| 41 | PositionRatio | decimal | YES | - | CODE-BACKED | Copy ratio relative to leader. From RealOpenPositions. |
| 42 | DirectAggLotCount | int | YES | - | CODE-BACKED | Hardcoded to 0. Not applicable in this context. |
| 43 | SpreadGroupID | int | YES | - | CODE-BACKED | Spread group assignment. From RealOpenPositions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (base) | RealOpenPositions | Synonym | Source of open positions (synonym to Trade.Position or similar) |
| CID | Trade.Mirror | JOIN | ParentCID match for active mirror detection |
| InstrumentID | Trade.Instrument | JOIN | BuyCurrencyID, SellCurrencyID for ForexBuy/ForexSell |
| ProviderID, InstrumentID | Trade.ProviderToInstrument | JOIN | Unit and Precision |
| OrigParentPositionID | Trade.GetPositionData | LEFT JOIN | Checks if copier already exists |
| FeatureID=100 | Maintenance.Feature | JOIN | Minimum mirror amount threshold |
| PositionID | Internal.GetNetProfit | Function call | Live PnL calculation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No direct consumers found) | - | - | Likely consumed by MM recovery orchestration procedures |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetDemoOpenPositionsForMMRecovery (view)
+-- RealOpenPositions (synonym)
+-- Trade.Mirror (table)
+-- Trade.Instrument (table)
+-- Trade.ProviderToInstrument (table)
+-- Trade.GetPositionData (view)
|     +-- Trade.PositionTbl (table)
|     +-- Trade.PositionTreeInfo (table)
+-- Maintenance.Feature (x-schema table)
+-- Internal.GetNetProfit (x-schema function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RealOpenPositions | Synonym | Base source of open leader positions |
| Trade.Mirror | Table | Active mirror detection |
| Trade.Instrument | Table | Currency pair lookup |
| Trade.ProviderToInstrument | Table | Unit and precision lookup |
| Trade.GetPositionData | View | Checks if copier position already exists |
| Maintenance.Feature | Table | Minimum mirror amount threshold (FeatureID=100) |
| Internal.GetNetProfit | Function | Live PnL calculation |

### 6.2 Objects That Depend On This

No direct dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 All leader positions needing copier creation

```sql
SELECT PositionID, CID, InstrumentID, Amount, MirrorID
FROM   Trade.GetDemoOpenPositionsForMMRecovery WITH (NOLOCK);
```

### 8.2 Recovery items with PnL

```sql
SELECT PositionID, CID, InstrumentID, PositionAmountCents, NetProfit
FROM   Trade.GetDemoOpenPositionsForMMRecovery WITH (NOLOCK)
ORDER BY NetProfit DESC;
```

### 8.3 Count by instrument

```sql
SELECT InstrumentID, COUNT(*) AS MissingCopierCount
FROM   Trade.GetDemoOpenPositionsForMMRecovery WITH (NOLOCK)
GROUP BY InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 43 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetDemoOpenPositionsForMMRecovery | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetDemoOpenPositionsForMMRecovery.sql*
