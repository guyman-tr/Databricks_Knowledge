# Trade.InstrumentsTradingConfigTbl

> TVP for bulk updates of full instrument trading configuration - SL/TP limits, position limits, order permissions, precision, and execution parameters.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

This type carries the complete per-instrument trading configuration: stop-loss and take-profit limits (min/max/default, leveraged vs non-leveraged), position size limits, order permissions (buy/sell, pending, entry, exit, edit SL/TP), trailing stop settings, redeem parameters, precision, market range, and designated execution system. It models the full trading rule set for each instrument.

The type exists to support bulk trading config updates when instruments are onboarded or when risk parameters change (e.g., new max SL/TP, position limits). UpdateInstrumentsTradingConfigurations and UpdateFuturesTradingConfigurations consume this TVP.

Services populate the TVP from admin UIs or configuration feeds, pass to procedures that MERGE or UPDATE the instrument trading config tables.

---

## 2. Business Logic

InstrumentID + comprehensive trading config column group. Each row defines the full trading rule set for one instrument. Column groups: (1) SL/TP limits (max/min/default, leveraged/non-leveraged, long/short), (2) position limits, (3) order permissions, (4) edit permissions, (5) trailing stop, (6) redeem, (7) precision and execution.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | References Trade.Instrument. Identifies the instrument |
| 2 | MaxStopLossPercentage | decimal(18,4) | YES | - | CODE-BACKED | Maximum allowed stop-loss percentage |
| 3 | MaxPositionUnits | decimal(18,4) | YES | - | CODE-BACKED | Maximum position size in units |
| 4 | MinPositionAmount | decimal(18,4) | YES | - | CODE-BACKED | Minimum position amount |
| 5 | MaxRateDiffPercentage | decimal(18,4) | YES | - | CODE-BACKED | Maximum allowed rate difference for execution |
| 6 | AllowBuy | bit | YES | - | CODE-BACKED | Whether buy orders are allowed |
| 7 | AllowSell | bit | YES | - | CODE-BACKED | Whether sell orders are allowed |
| 8 | AllowPendingOrders | bit | YES | - | CODE-BACKED | Whether pending orders are allowed |
| 9 | AllowEntryOrders | bit | YES | - | CODE-BACKED | Whether entry orders are allowed |
| 10 | VisibleInternallyOnly | bit | YES | - | CODE-BACKED | Internal visibility flag |
| 11 | AllowClosePosition | bit | YES | - | CODE-BACKED | Whether closing positions is allowed |
| 12 | AllowExitOrder | bit | YES | - | CODE-BACKED | Whether exit orders are allowed |
| 13 | GuaranteeSLTP | bit | YES | - | CODE-BACKED | Whether SL/TP execution is guaranteed |
| 14 | AllowEditSLTP | bit | YES | - | CODE-BACKED | Whether SL/TP can be edited after open |
| 15 | MaxTakeProfitPercentage | decimal(18,4) | YES | - | CODE-BACKED | Maximum take-profit percentage |
| 16 | AllowRedeem | bit | YES | - | CODE-BACKED | Whether redeem (withdraw) is allowed |
| 17 | MinPositionUnitsForRedeem | decimal(16,8) | YES | - | CODE-BACKED | Minimum units for redeem |
| 18 | MaxPositionUnitsForRedeem | decimal(16,4) | YES | - | CODE-BACKED | Maximum units for redeem |
| 19 | AllowEditTakeProfit | bit | YES | - | CODE-BACKED | Whether TP can be edited |
| 20 | AllowEditStopLoss | bit | YES | - | CODE-BACKED | Whether SL can be edited |
| 21 | DefaultTrailingStopLoss | bit | YES | - | CODE-BACKED | Default trailing SL on/off |
| 22 | AllowTrailingStopLoss | bit | YES | - | CODE-BACKED | Whether trailing SL is allowed |
| 23 | MinStopLossPercentage | decimal(18,4) | YES | - | CODE-BACKED | Minimum SL percentage |
| 24 | MinTakeProfitPercentage | decimal(18,4) | YES | - | CODE-BACKED | Minimum TP percentage |
| 25 | DefaultStopLossPercentage | decimal(18,4) | YES | - | CODE-BACKED | Default SL when opening |
| 26 | DefaultTakeProfitPercentage | decimal(18,4) | YES | - | CODE-BACKED | Default TP when opening |
| 27 | AllowLeveragedLongSL | bit | YES | - | CODE-BACKED | SL allowed for leveraged long |
| 28 | AllowNonLeveragedLongSL | bit | YES | - | CODE-BACKED | SL allowed for non-leveraged long |
| 29 | AllowLeveragedShortSL | bit | YES | - | CODE-BACKED | SL allowed for leveraged short |
| 30 | AllowNonLeveragedShortSL | bit | YES | - | CODE-BACKED | SL allowed for non-leveraged short |
| 31 | AllowLeveragedLongTP | bit | YES | - | CODE-BACKED | TP allowed for leveraged long |
| 32 | AllowNonLeveragedLongTP | bit | YES | - | CODE-BACKED | TP allowed for non-leveraged long |
| 33 | AllowLeveragedShortTP | bit | YES | - | CODE-BACKED | TP allowed for leveraged short |
| 34 | AllowNonLeveragedShortTP | bit | YES | - | CODE-BACKED | TP allowed for non-leveraged short |
| 35 | AllowEditTakeProfitLeveraged | bit | YES | - | CODE-BACKED | TP edit for leveraged positions |
| 36 | AllowEditStopLossLeveraged | bit | YES | - | CODE-BACKED | SL edit for leveraged positions |
| 37 | DefaultStopLossPercentageLeveraged | decimal(18,4) | YES | - | CODE-BACKED | Default SL for leveraged |
| 38 | DefaultStopLossPercentageNonLeveraged | decimal(18,4) | YES | - | CODE-BACKED | Default SL for non-leveraged |
| 39 | Precision | tinyint | YES | - | CODE-BACKED | Decimal precision for display/rounding |
| 40 | MarketRange | int | YES | - | NAME-INFERRED | Market range classification or flag |
| 41 | DesignatedExecutionSystem | int | YES | - | NAME-INFERRED | Execution venue or system identifier |

---

## 5. Relationships

### 5.1 References To (this object points to)

InstrumentID semantically references Trade.Instrument but there is no declared FK on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateInstrumentsTradingConfigurations | @InstrumentNewConfigTbl | Parameter (TVP) | Bulk trading config updates |
| Trade.UpdateFuturesTradingConfigurations | @InstrumentNewConfigTbl | Parameter (TVP) | Futures-specific trading config updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateInstrumentsTradingConfigurations | Stored Procedure | READONLY parameter for trading config updates |
| Trade.UpdateFuturesTradingConfigurations | Stored Procedure | READONLY parameter for futures config updates |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Bulk trading config update
```sql
DECLARE @InstrumentNewConfigTbl Trade.InstrumentsTradingConfigTbl;
INSERT INTO @InstrumentNewConfigTbl (InstrumentID, MaxStopLossPercentage, MinPositionAmount, AllowBuy, AllowSell, Precision)
VALUES (1, 50.0, 0.01, 1, 1, 2), (2, 40.0, 0.1, 1, 1, 4);
EXEC Trade.UpdateInstrumentsTradingConfigurations @InstrumentNewConfigTbl = @InstrumentNewConfigTbl;
```

### 8.2 Futures config with margins
```sql
DECLARE @InstrumentNewConfigTbl Trade.InstrumentsTradingConfigTbl;
DECLARE @Instruments_NewMargin Trade.InstrumentsIDListSetMarginTbl;
INSERT INTO @InstrumentNewConfigTbl (InstrumentID, MaxStopLossPercentage, AllowBuy, AllowSell)
VALUES (100, 30.0, 1, 1);
INSERT INTO @Instruments_NewMargin (InstrumentID, InitialMarginInAssetCurrency, StopLossMarginInAssetCurrency)
VALUES (100, 1000, 500);
EXEC Trade.UpdateFuturesTradingConfigurations @InstrumentNewConfigTbl = @InstrumentNewConfigTbl, @Instruments_NewMargin = @Instruments_NewMargin;
```

### 8.3 Update SL/TP defaults only
```sql
DECLARE @InstrumentNewConfigTbl Trade.InstrumentsTradingConfigTbl;
INSERT INTO @InstrumentNewConfigTbl (InstrumentID, DefaultStopLossPercentage, DefaultTakeProfitPercentage, MinStopLossPercentage, MaxStopLossPercentage)
VALUES (10, 5.0, 10.0, 1.0, 50.0);
EXEC Trade.UpdateInstrumentsTradingConfigurations @InstrumentNewConfigTbl = @InstrumentNewConfigTbl;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 9/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 34 CODE-BACKED, 0 ATLASSIAN-ONLY, 7 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentsTradingConfigTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InstrumentsTradingConfigTbl.sql*
