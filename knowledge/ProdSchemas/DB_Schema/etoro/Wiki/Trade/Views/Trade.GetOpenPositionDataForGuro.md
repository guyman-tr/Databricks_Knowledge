# Trade.GetOpenPositionDataForGuro

> Open-position feed for Guro optimizer. Exposes all open positions (StatusID=1) with instrument, hedge, and copy-trade metadata in the shape required by the Guro optimization engine.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetOpenPositionDataForGuro is the open-position data feed consumed by the Guro optimization engine. It returns all currently open positions (StatusID=1) with instrument buy/sell currencies, hedge server assignment, SL/TP levels, copy-trade hierarchy, settlement type, and root position metadata. The view enriches Trade.PositionTbl with Trade.Instrument (forex buy/sell currencies), Trade.ProviderToInstrument (Units, Precision), Trade.PositionTreeInfo (LimitRate, StopRate, CloseOnEndOfWeek, IsTslEnabled, IsDiscounted), Trade.Mirror (IsMirrorActive), and root PositionTbl row (IsRootSettled, RootSettlementTypeID).

The view exists because the Guro optimizer needs a single flattened dataset of open positions with all attributes required for portfolio optimization, margin calculation, and hedge routing. Trade.GetGuruOpenPositions uses this view as its base and applies additional filters (no redeem, not in terminal close flow) for positions eligible for optimization.

Data flows: The view reads from PositionTbl (open only), Instrument, ProviderToInstrument, PositionTreeInfo, Mirror (optional), and self-joins PositionTbl for root. All downstream consumers (e.g., Guro engine, portfolio APIs) read through this view or Trade.GetGuruOpenPositions.

---

## 2. Business Logic

### 2.1 Open Positions Only (StatusID=1)

**What**: Only rows with StatusID=1 (Open) are returned. Closed positions are excluded.

**Columns/Parameters Involved**: `TPOS.StatusID`

**Rules**:
- WHERE TPOS.StatusID = 1
- Trade.PositionClose sets StatusID=2 when closing; those rows never appear here
- IsOpened is always 1 (hardcoded) to indicate open-state to consumers

### 2.2 Partition-Aware Join to PositionTreeInfo

**What**: Join to PositionTreeInfo uses PartitionCol for partition elimination.

**Columns/Parameters Involved**: `TPOS.TreeID`, `TPTI.TreeID`, `TPTI.PartitionCol`

**Rules**:
- INNER JOIN Trade.PositionTreeInfo TPTI ON TPOS.TreeID = TPTI.TreeID AND abs(TPOS.TreeID%50) = TPTI.PartitionCol
- PositionTreeInfo is partitioned by abs(TreeID)%50; the join ensures correct partition access

### 2.3 Root Position Settlement Inheritance

**What**: RootSettled and RootSettlementTypeID come from the root position (TreeID = PositionID) for copy-trade consistency.

**Columns/Parameters Involved**: `RootData.IsSettled`, `RootData.SettlementTypeID`, `TPOS.TreeID`

**Rules**:
- INNER JOIN Trade.PositionTbl RootData ON TPOS.TreeID = RootData.PositionID
- Root position has TreeID = PositionID; children share TreeID
- IsRootSettled and RootSettlementTypeID apply to entire copy-trade tree

### 2.4 Boolean String Conversion for Guro

**What**: IsBuy and CloseOnEndOfWeek are converted to 'true'/'false' strings for Guro JSON/API compatibility.

**Columns/Parameters Involved**: `IsBuy`, `CloseOnEndOfWeek`

**Rules**:
- IsBuy = CASE TPOS.IsBuy WHEN 1 THEN 'true' ELSE 'false' END
- CloseOnEndOfWeek = CASE TPTI.CloseOnEndOfWeek WHEN 1 THEN 'true' ELSE 'false' END

---

## 3. Data Overview

| PositionID | CID | InstrumentID | MirrorID | IsMirrorActive | Amount | IsBuy | ForexBuy | ForexSell | Meaning |
|------------|-----|--------------|----------|---------------|--------|------|----------|-----------|---------|
| 2152641451 | 24486470 | 1 | 0 | 0 | 200 | false | 2 | 1 | Manual short EUR/USD. MirrorID=0, IsMirrorActive=0. |
| 2152645101 | 24486470 | 1 | 0 | 0 | 199.99 | false | 2 | 1 | Another manual short. Same customer, multiple positions. |
| 2152662052 | 24497758 | 1 | 1883758 | 1 | 37.87 | false | 2 | 1 | Copy-trade position. MirrorID>0, IsMirrorActive=1. |
| 2152648105 | 24486470 | 1 | 0 | 0 | 200 | false | 2 | 1 | Manual short. TreeID=PositionID (root). |
| 2152657714 | 24497758 | 1 | 1883758 | 1 | 37.92 | false | 2 | 1 | Copy-trade child. ParentPositionID, TreeID point to root. |

**Selection criteria**: Live MCP sample. Mix of manual vs copy-trade, multiple positions per customer. NULLs in EndForexRate, EndDateTime, ActionType, NetProfit, CloseOccurred, ExitOrderID, etc. expected (open positions only).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID. FK to Customer.Customer. From PositionTbl. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | Primary key. From PositionTbl. |
| 3 | ForexResultID | int | NO | - | CODE-BACKED | Forex result identifier. From PositionTbl. Sample: -1. |
| 4 | IsOpened | int | NO | 1 | CODE-BACKED | Always 1. Indicates open position to Guro. |
| 5 | Currency | int | NO | - | CODE-BACKED | Alias for PositionTbl.CurrencyID. Position denomination. |
| 6 | ProviderID | int | NO | - | CODE-BACKED | FK to Trade.Provider. Execution provider. From PositionTbl. |
| 7 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. Tradeable instrument. From PositionTbl. |
| 8 | PositionHedgeServerID | int | NO | - | CODE-BACKED | Alias for HedgeServerID. Hedge server managing this position. From PositionTbl. |
| 9 | Leverage | int | NO | - | CODE-BACKED | Position leverage. From PositionTbl. |
| 10 | ForexBuy | int | NO | - | CODE-BACKED | Instrument buy currency. From Instrument.BuyCurrencyID. |
| 11 | ForexSell | int | NO | - | CODE-BACKED | Instrument sell currency. From Instrument.SellCurrencyID. |
| 12 | InitForexRate | decimal | NO | - | CODE-BACKED | Rate at position open. From PositionTbl. |
| 13 | EndForexRate | - | YES | NULL | CODE-BACKED | Always NULL (open positions). Placeholder for close rate. |
| 14 | InitDateTime | datetime | NO | - | CODE-BACKED | Position open timestamp. From PositionTbl.InitDateTime. |
| 15 | EndDateTime | - | YES | NULL | CODE-BACKED | Always NULL (open positions). Placeholder for close time. |
| 16 | ActionType | - | YES | NULL | CODE-BACKED | Always NULL (open positions). Placeholder for close action. |
| 17 | NetProfit | - | YES | NULL | CODE-BACKED | Always NULL (open positions). Realized at close. |
| 18 | LimitRate | decimal | YES | - | CODE-BACKED | Take-profit level. From PositionTreeInfo.LimitRate. |
| 19 | StopRate | decimal | YES | - | CODE-BACKED | Stop-loss level. From PositionTreeInfo.StopRate. |
| 20 | Amount | decimal | NO | - | CODE-BACKED | Position amount in currency. From PositionTbl. |
| 21 | AmountInUnitsDecimal | decimal | NO | - | CODE-BACKED | Position size in instrument units. From PositionTbl. |
| 22 | Commission | decimal | NO | - | CODE-BACKED | Commission at open. From PositionTbl. |
| 23 | SpreadedCommission | decimal | NO | - | CODE-BACKED | Spread component of commission. From PositionTbl. |
| 24 | IsBuy | varchar(4) | NO | - | CODE-BACKED | 'true' or 'false'. From PositionTbl.IsBuy. |
| 25 | CloseOnEndOfWeek | varchar(4) | NO | - | CODE-BACKED | 'true' or 'false'. From PositionTreeInfo. Weekend close flag. |
| 26 | EndOfWeekFee | decimal | YES | - | CODE-BACKED | EOW fee. From PositionTbl. |
| 27 | LotCountDecimal | decimal | NO | - | CODE-BACKED | Lot count. From PositionTbl. |
| 28 | AdditionalParam | varchar | YES | - | CODE-BACKED | Extra params. From PositionTbl. |
| 29 | OpenOccurred | datetime | NO | - | CODE-BACKED | When position was opened. From PositionTbl.Occurred. |
| 30 | CloseOccurred | - | YES | NULL | CODE-BACKED | Always NULL (open positions). |
| 31 | OrderID | bigint | YES | - | CODE-BACKED | Order that opened position. From PositionTbl. |
| 32 | TradeRange | smallint | NO | - | CODE-BACKED | Trade range. From PositionTbl. |
| 33 | InitForexPriceRateID | bigint | YES | - | CODE-BACKED | Price rate at open. From PositionTbl. |
| 34 | ParentPositionID | bigint | NO | - | CODE-BACKED | Parent position (0=root). From PositionTbl. |
| 35 | OrigParentPositionID | bigint | YES | - | CODE-BACKED | Original parent. From PositionTbl. |
| 36 | LastOpPriceRate | decimal | YES | - | CODE-BACKED | Last operation price. From PositionTbl. |
| 37 | LastOpPriceRateID | bigint | YES | - | CODE-BACKED | Last op price rate ID. From PositionTbl. |
| 38 | LastOpConversionRate | decimal | YES | - | CODE-BACKED | Last conversion rate. From PositionTbl. |
| 39 | LastOpConversionRateID | bigint | YES | - | CODE-BACKED | Last conversion rate ID. From PositionTbl. |
| 40 | UnitMargin | decimal | YES | - | CODE-BACKED | Unit margin. From PositionTbl. |
| 41 | Units | int | NO | - | CODE-BACKED | Instrument unit size. From ProviderToInstrument.Unit. |
| 42 | InstrumentPrecision | int | NO | - | CODE-BACKED | Display precision. From ProviderToInstrument.Precision. |
| 43 | MirrorID | int | NO | - | CODE-BACKED | Copy-trade mirror (0=manual). From PositionTbl. |
| 44 | PositionRatio | decimal | YES | - | CODE-BACKED | Copy allocation ratio. From PositionTbl. |
| 45 | DirectAggLotCount | decimal | NO | - | CODE-BACKED | Direct aggregate lot count. From PositionTbl. |
| 46 | SpreadGroupID | int | NO | - | CODE-BACKED | Spread group. From PositionTbl. |
| 47 | InitialAmountCents | int | NO | - | CODE-BACKED | Initial amount in cents. From PositionTbl. |
| 48 | HedgeServerID | int | NO | - | CODE-BACKED | Hedge server. From PositionTbl. |
| 49 | InitExecutionID | bigint | YES | - | CODE-BACKED | Open execution ID. From PositionTbl. |
| 50 | EndExecutionID | int | NO | 0 | CODE-BACKED | Always 0 (open positions). |
| 51 | RootHedgeServerID | int | YES | - | CODE-BACKED | Root hedge server. From PositionTbl. |
| 52 | IsOpenOpen | bit | NO | - | CODE-BACKED | Open-order flag. From PositionTbl. |
| 53 | TreeID | bigint | NO | - | CODE-BACKED | Tree root PositionID. From PositionTbl. |
| 54 | IsComputeForHedge | bit | NO | - | CODE-BACKED | Include in hedge calc. From PositionTbl. |
| 55 | ExitOrderID | - | YES | NULL | CODE-BACKED | Always NULL (open positions). |
| 56 | IsTslEnabled | bit | NO | - | CODE-BACKED | Trailing stop enabled. From PositionTreeInfo. |
| 57 | IsMirrorActive | int | NO | 0 | CODE-BACKED | ISNULL(TM.IsActive,0). Copy-trade mirror active. |
| 58 | SLManualVer | int | YES | - | CODE-BACKED | SL manual version. From PositionTreeInfo. |
| 59 | FullCommission | decimal | YES | - | CODE-BACKED | Full commission. From PositionTbl. |
| 60 | FullCommissionOnClose | - | YES | NULL | CODE-BACKED | Always NULL (open positions). |
| 61 | IsSettled | bit | NO | - | CODE-BACKED | Real vs CFD. From PositionTbl. |
| 62 | SettlementTypeID | tinyint | NO | - | CODE-BACKED | ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)). |
| 63 | RedeemStatus | int | YES | - | CODE-BACKED | Redeem status. From PositionTbl. |
| 64 | RedeemID | - | YES | NULL | CODE-BACKED | Always NULL (open positions). |
| 65 | CommissionOnClose | - | YES | NULL | CODE-BACKED | Always NULL (open positions). |
| 66 | EndForexPriceRateID | - | YES | NULL | CODE-BACKED | Always NULL (open positions). |
| 67 | InitialUnits | decimal | YES | - | CODE-BACKED | Initial units at open. From PositionTbl. |
| 68 | OriginalPositionID | - | YES | NULL | CODE-BACKED | Always NULL. Placeholder. |
| 69 | UnitsBaseValueCents | int | NO | - | CODE-BACKED | ISNULL(UnitsBaseValueCents, CONVERT(INT, InitialAmountCents)). |
| 70 | IsDiscounted | bit | NO | - | CODE-BACKED | Discounted fee tier. From PositionTreeInfo. |
| 71 | ReopenForPositionID | bigint | YES | - | CODE-BACKED | Reopen link. From PositionTbl. |
| 72 | IsRootSettled | bit | YES | - | CODE-BACKED | Root IsSettled. From RootData. |
| 73 | RootSettlementTypeID | tinyint | YES | - | CODE-BACKED | Root SettlementTypeID. From RootData. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | FK | Customer |
| InstrumentID, ForexBuy, ForexSell | Trade.Instrument | JOIN | Instrument and currency pairing |
| ProviderID, InstrumentID, Units, InstrumentPrecision | Trade.ProviderToInstrument | JOIN | Provider-instrument config |
| TreeID, LimitRate, StopRate, CloseOnEndOfWeek, IsTslEnabled, IsDiscounted, SLManualVer | Trade.PositionTreeInfo | JOIN | SL/TP/TSL settings |
| MirrorID, IsMirrorActive | Trade.Mirror | LEFT JOIN | Copy-trade mirror active state |
| TreeID | Trade.PositionTbl (RootData) | SELF JOIN | Root position settlement |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetGuruOpenPositions | FROM | Base | Filters GetOpenPositionDataForGuro for redeem/close flow |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOpenPositionDataForGuro (view)
├── Trade.PositionTbl (table) [base + root]
├── Trade.Instrument (table)
├── Trade.ProviderToInstrument (table)
├── Trade.PositionTreeInfo (table)
└── Trade.Mirror (table) [LEFT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | FROM - base and root self-join |
| Trade.Instrument | Table | INNER JOIN - ForexBuy, ForexSell |
| Trade.ProviderToInstrument | Table | INNER JOIN - Units, InstrumentPrecision |
| Trade.PositionTreeInfo | Table | INNER JOIN - LimitRate, StopRate, CloseOnEndOfWeek, IsTslEnabled, IsDiscounted, SLManualVer |
| Trade.Mirror | Table | LEFT JOIN - IsMirrorActive |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetGuruOpenPositions | View | FROM - base dataset for Guro-eligible positions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None. View uses NOLOCK on all base tables.

---

## 8. Sample Queries

### 8.1 Open positions for a customer
```sql
SELECT CID, PositionID, InstrumentID, Amount, IsBuy, Leverage
  FROM Trade.GetOpenPositionDataForGuro WITH (NOLOCK)
 WHERE CID = 24486470;
```

### 8.2 Copy-trade positions with active mirror
```sql
SELECT CID, PositionID, MirrorID, IsMirrorActive, Amount
  FROM Trade.GetOpenPositionDataForGuro WITH (NOLOCK)
 WHERE MirrorID > 0 AND IsMirrorActive = 1;
```

### 8.3 Positions by instrument with SL/TP
```sql
SELECT InstrumentID, COUNT(*) AS Cnt, AVG(StopRate) AS AvgStop, AVG(LimitRate) AS AvgLimit
  FROM Trade.GetOpenPositionDataForGuro WITH (NOLOCK)
 GROUP BY InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 73 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOpenPositionDataForGuro | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetOpenPositionDataForGuro.sql*
