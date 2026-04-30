# Trade.GetOpenPositionsForMMRecovery

> CTE-based view finding open leader positions with active mirrors where copier positions are missing, used for real (non-demo) MM recovery to create the missing copy-trade positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from Trade.Position) |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.GetOpenPositionsForMMRecovery is the **real (non-demo) counterpart** to Trade.GetDemoOpenPositionsForMMRecovery. It identifies open leader positions that have active copy-trade mirrors but no corresponding copier positions. When a leader opens a position, the CopyTrader system should automatically create matching positions for all active copiers. If propagation fails, this view surfaces the missing items for recovery.

Unlike the Demo variant, this view uses CTEs and does not require the Maintenance.Feature minimum threshold check. It: (1) builds OpenParentPositions by joining Trade.Position with Trade.Mirror (active only) plus Instrument and ProviderToInstrument for enrichment, (2) builds SonPositions from GetPositionData matching by OrigParentPositionID and copier CID, (3) LEFT JOINs the two CTEs and returns leaders where no son/copier exists.

The view computes NetProfit via Internal.GetNetProfit, converts monetary amounts to cents, and formats boolean fields as strings for legacy XML consumers. Includes ParentCID from Mirror to identify which copier relationship is broken.

---

## 2. Business Logic

### 2.1 Missing Copier Detection (CTE Approach)

**What**: Two-step CTE pipeline to find leaders without copier positions.

**Columns/Parameters Involved**: `PositionID`, `OrigParentPositionID`, `SonCID`, `MirrorID`

**Rules**:
- CTE1 (OpenParentPositions): All open positions belonging to leaders with active mirrors (TM.ParentCID = TPOS.CID, TM.IsActive=1, mirror created before position)
- CTE2 (SonPositions): All existing copier positions where OrigParentPositionID matches a leader position and CID matches the copier
- Final: LEFT JOIN CTE1 to CTE2 WHERE CTE2.PositionID IS NULL (copier does not exist)

### 2.2 Monetary and Boolean Conversions

**What**: Converts values for legacy XML consumer compatibility.

**Columns/Parameters Involved**: `PositionAmountCents`, `CommissionCents`, `EndOfWeekFee`, `IsBuy`, `CloseOnEndOfWeek`, `NetProfit`

**Rules**:
- PositionAmountCents = CAST(Amount * 100 AS INTEGER)
- CommissionCents = CAST(Commission * 100 AS INTEGER)
- EndOfWeekFee = CAST(EndOfWeekFee * 100 AS INTEGER) (also in cents)
- NetProfit = CAST(Internal.GetNetProfit(PositionID) AS INTEGER) (live PnL in cents)
- IsBuy / CloseOnEndOfWeek as 'true'/'false' strings

---

## 3. Data Overview

N/A - recovery view producing dynamically computed results. Each row represents a leader position missing its copier counterpart.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ParentCID | int | YES | - | CODE-BACKED | The copier's CID (from Trade.Mirror). The customer who should have a copy position but doesn't. |
| 2 | CID | int | NO | - | CODE-BACKED | Leader's customer ID who owns the original position. |
| 3 | PositionID | bigint | NO | - | CODE-BACKED | Leader's open position that needs copier creation. |
| 4 | ForexResultID | bigint | YES | - | CODE-BACKED | Legacy forex result tracking. |
| 5 | IsOpened | int | NO | 1 | CODE-BACKED | Hardcoded to 1 (open). |
| 6 | Currency | int | YES | - | CODE-BACKED | Denomination currency ID (aliased from CurrencyID). |
| 7 | ProviderID | int | YES | - | CODE-BACKED | Execution provider. FK to Trade.Provider. |
| 8 | InstrumentID | int | YES | - | CODE-BACKED | Instrument traded. FK to Trade.Instrument. |
| 9 | HedgeID | bigint | YES | - | CODE-BACKED | Hedge record ID from Trade.Position. |
| 10 | PositionHedgeServerID | int | YES | - | CODE-BACKED | Hedge server for the position. |
| 11 | Leverage | int | YES | - | CODE-BACKED | Leverage multiplier. |
| 12 | ForexBuy | int | YES | - | CODE-BACKED | Buy currency from Trade.Instrument.BuyCurrencyID. |
| 13 | ForexSell | int | YES | - | CODE-BACKED | Sell currency from Trade.Instrument.SellCurrencyID. |
| 14 | InitForexRate | float | YES | - | CODE-BACKED | Forex rate at open. |
| 15 | EndForexRate | float | YES | - | CODE-BACKED | Always NULL (open position). |
| 16 | InitDateTime | datetime | YES | - | CODE-BACKED | When position was opened. |
| 17 | EndDateTime | datetime | YES | - | CODE-BACKED | Always NULL (open position). |
| 18 | ActionType | int | YES | - | CODE-BACKED | Always NULL (open position). |
| 19 | NetProfit | int | YES | - | CODE-BACKED | Computed: CAST(Internal.GetNetProfit(PositionID) AS INTEGER). Live PnL in cents. |
| 20 | LimitRate | float | YES | - | CODE-BACKED | Take-profit rate. |
| 21 | StopRate | float | YES | - | CODE-BACKED | Stop-loss rate. |
| 22 | PositionAmountCents | int | YES | - | CODE-BACKED | Computed: Amount * 100. Position amount in cents. |
| 23 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position amount in units/shares. |
| 24 | CommissionCents | int | YES | - | CODE-BACKED | Computed: Commission * 100. Commission in cents. |
| 25 | SpreadedCommission | money | YES | - | CODE-BACKED | Spread-adjusted commission. |
| 26 | IsBuy | varchar | YES | - | CODE-BACKED | Direction as string: 'true'/'false'. |
| 27 | CloseOnEndOfWeek | varchar | YES | - | CODE-BACKED | Weekend close preference as string: 'true'/'false'. |
| 28 | EndOfWeekFee | int | YES | - | CODE-BACKED | Computed: EndOfWeekFee * 100. Weekend fee in cents. |
| 29 | Unit | decimal | YES | - | CODE-BACKED | Unit count from Trade.ProviderToInstrument. |
| 30 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count from provider. |
| 31 | AdditionalParam | varchar | YES | - | CODE-BACKED | Additional parameters. |
| 32 | Occurred | datetime | YES | - | CODE-BACKED | When position was executed. |
| 33 | OrderID | int | YES | - | CODE-BACKED | Originating order. |
| 34 | TradeRange | float | YES | - | CODE-BACKED | Market range tolerance. |
| 35 | InitForexPriceRateID | bigint | YES | - | CODE-BACKED | Price rate snapshot at open. |
| 36 | OrderPriceRateID | bigint | YES | - | CODE-BACKED | Order price rate snapshot ID. |
| 37 | OrderPriceRate | decimal(16,8) | YES | - | CODE-BACKED | Order price rate. |
| 38 | MarketPriceRateID | bigint | YES | - | CODE-BACKED | Market price rate snapshot ID. |
| 39 | MarketPriceRate | decimal(16,8) | YES | - | CODE-BACKED | Market price rate at open. |
| 40 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent in add-to-position hierarchy. |
| 41 | OrigParentPositionID | bigint | YES | - | CODE-BACKED | Original parent before splits. |
| 42 | LastOpPriceRate | decimal(16,8) | YES | - | CODE-BACKED | Last operation price rate. |
| 43 | LastOpPriceRateID | bigint | YES | - | CODE-BACKED | Last op price rate snapshot. |
| 44 | LastOpConversionRate | decimal(16,8) | YES | - | CODE-BACKED | Last operation conversion rate. |
| 45 | LastOpConversionRateID | bigint | YES | - | CODE-BACKED | Last op conversion rate snapshot. |
| 46 | UnitMargin | money | YES | - | CODE-BACKED | Unit margin. |
| 47 | Units | decimal | YES | - | CODE-BACKED | Unit count (duplicate of Unit). |
| 48 | InstrumentPrecision | int | YES | - | CODE-BACKED | Decimal precision from ProviderToInstrument. |
| 49 | MirrorID | int | YES | - | CODE-BACKED | Mirror/copy-trade ID. |
| 50 | PositionRatio | decimal | YES | - | CODE-BACKED | Copy ratio. |
| 51 | DirectAggLotCount | decimal(16,6) | YES | - | CODE-BACKED | Aggregated lot count. |
| 52 | SpreadGroupID | int | YES | - | CODE-BACKED | Spread group assignment. |
| 53 | InitialAmountCents | int | YES | - | CODE-BACKED | Initial amount in cents. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (base) | Trade.Position | CTE source | Open leader positions |
| CID | Trade.Mirror | JOIN | Active mirror detection (ParentCID match) |
| InstrumentID | Trade.Instrument | JOIN | Currency pair lookup |
| ProviderID, InstrumentID | Trade.ProviderToInstrument | JOIN | Unit and precision |
| OrigParentPositionID | Trade.GetPositionData | CTE | Checks if copier position exists |
| PositionID | Internal.GetNetProfit | Function call | Live PnL |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOpenPositionsForMMRecovery (view)
+-- Trade.Position (view)
|     +-- Trade.PositionTbl (table)
|     +-- Trade.PositionTreeInfo (table)
+-- Trade.Mirror (table)
+-- Trade.Instrument (table)
+-- Trade.ProviderToInstrument (table)
+-- Trade.GetPositionData (view)
+-- Internal.GetNetProfit (x-schema function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | Base open positions (CTE1) |
| Trade.Mirror | Table | Active mirror matching (CTE1) |
| Trade.Instrument | Table | Currency pair lookup |
| Trade.ProviderToInstrument | Table | Unit and precision |
| Trade.GetPositionData | View | Copier existence check (CTE2) |
| Internal.GetNetProfit | Function | Live PnL calculation |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 All recovery items

```sql
SELECT ParentCID, CID, PositionID, InstrumentID, PositionAmountCents
FROM   Trade.GetOpenPositionsForMMRecovery WITH (NOLOCK);
```

### 8.2 Recovery items by leader

```sql
SELECT CID, COUNT(*) AS MissingCopiers, SUM(PositionAmountCents) AS TotalAmountCents
FROM   Trade.GetOpenPositionsForMMRecovery WITH (NOLOCK)
GROUP BY CID;
```

### 8.3 Detailed recovery items with PnL

```sql
SELECT ParentCID, CID, PositionID, InstrumentID, NetProfit, MirrorID
FROM   Trade.GetOpenPositionsForMMRecovery WITH (NOLOCK)
ORDER BY ABS(NetProfit) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.2/10 (Elements: 10.0/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 53 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOpenPositionsForMMRecovery | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetOpenPositionsForMMRecovery.sql*
