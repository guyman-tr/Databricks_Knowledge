# Trade.GetPositionForXML

> UNION ALL view combining open positions (from Trade.Position) with closed game positions (from History.Position) for game session restoration, enriched with hedge details and instrument metadata, values in cents and booleans as strings.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from Trade.Position / History.Position) |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.GetPositionForXML is a **game/session restoration view** that provides both open and closed positions in a format suitable for XML serialization. It consists of two UNION ALL parts: (1) open positions from Trade.Position with live PnL calculation via Internal.GetNetProfit, and (2) closed game positions from History.Position filtered to non-MAP/non-ROPE game subtypes via Game.ForexResult/History.ForexResult and Dictionary.GameType.

This view exists because eToro's game/demo system needs to restore a player's complete session state, including both currently open positions and positions that were closed during the session. The closed-position part specifically targets game sessions (not all closed positions), joining through ForexResultID to find the game type and filtering out MAP (4) and ROPE (6) subtypes which don't need position restoration.

Both parts share the same column contract with values in cents (Amount*100, Commission*100, NetProfit*100, EndOfWeekFee*100), boolean fields as strings ('true'/'false'), and hedge enrichment (UNION ALL of History.Hedge + Trade.Hedge). The open part sets IsOpened=1, EndForexRate/EndDateTime/ActionType=NULL. The closed part uses actual close values.

---

## 2. Business Logic

### 2.1 Open Position Part (UNION ALL Part 1)

**What**: Current open positions with live PnL and hedge details.

**Rules**:
- Source: Trade.Position LEFT JOIN hedges (History.Hedge UNION ALL Trade.Hedge), Instrument, ProviderToInstrument
- IsOpened = 1, EndForexRate/EndDateTime/ActionType = NULL
- NetProfit = CAST(Internal.GetNetProfit(PositionID) AS INTEGER) - live PnL in cents

### 2.2 Closed Game Position Part (UNION ALL Part 2)

**What**: Historically closed positions from game sessions (excluding MAP and ROPE games).

**Rules**:
- Source: History.Position joined through ForexResultID to Game.ForexResult UNION History.ForexResult, filtered by Dictionary.GameType.GameSubTypeID NOT IN (4, 6)
- IsOpened = 0, uses actual EndForexRate, EndDateTime, ActionType
- NetProfit = CAST(HPOS.NetProfit * 100 AS INTEGER)
- Several fields hardcoded to 0/NULL: OrderID=0, TradeRange=0, InitForexPriceRateID=0, all PriceRate fields=0

---

## 3. Data Overview

N/A - UNION ALL view combining open and closed positions. The open part mirrors Trade.Position; the closed part pulls from History.Position for game restoration.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | Position identifier (open or historically closed). |
| 3 | ForexResultID | bigint | YES | - | CODE-BACKED | Forex result ID linking to game sessions. |
| 4 | IsOpened | int | NO | - | CODE-BACKED | 1 = open position (Part 1), 0 = closed game position (Part 2). |
| 5 | Currency | int | YES | - | CODE-BACKED | Denomination currency ID (aliased from CurrencyID). |
| 6 | ProviderID | int | YES | - | CODE-BACKED | Execution provider. |
| 7 | InstrumentID | int | YES | - | CODE-BACKED | Instrument traded. FK to Trade.Instrument. |
| 8 | HedgeID | bigint | YES | - | CODE-BACKED | Hedge record ID. |
| 9 | PositionHedgeServerID | int | YES | - | CODE-BACKED | Hedge server from position. |
| 10 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server from hedge record. |
| 11 | Leverage | int | YES | - | CODE-BACKED | Leverage multiplier. |
| 12 | ForexBuy | int | YES | - | CODE-BACKED | Buy currency from Trade.Instrument.BuyCurrencyID. |
| 13 | ForexSell | int | YES | - | CODE-BACKED | Sell currency from Trade.Instrument.SellCurrencyID. |
| 14 | InitForexRate | float | YES | - | CODE-BACKED | Forex rate at open. |
| 15 | EndForexRate | float | YES | - | CODE-BACKED | Forex rate at close. NULL for open positions. |
| 16 | InitDateTime | datetime | YES | - | CODE-BACKED | When position was opened. |
| 17 | EndDateTime | datetime | YES | - | CODE-BACKED | When position was closed. NULL for open. |
| 18 | ActionType | int | YES | - | CODE-BACKED | Close action type. NULL for open. |
| 19 | NetProfit | int | YES | - | CODE-BACKED | PnL in cents. Open: live via Internal.GetNetProfit. Closed: from history. |
| 20 | LimitRate | float | YES | - | CODE-BACKED | Take-profit rate. |
| 21 | StopRate | float | YES | - | CODE-BACKED | Stop-loss rate. |
| 22 | PositionAmountCents | int | YES | - | CODE-BACKED | Position amount in cents (Amount * 100). |
| 23 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position amount in units. |
| 24 | CommissionCents | int | YES | - | CODE-BACKED | Commission in cents (Commission * 100). |
| 25 | SpreadedCommission | money | YES | - | CODE-BACKED | Spread-adjusted commission. |
| 26 | IsBuy | varchar | YES | - | CODE-BACKED | Direction as string: 'true'/'false'. |
| 27 | CloseOnEndOfWeek | varchar | YES | - | CODE-BACKED | Weekend close as string: 'true'/'false'. |
| 28 | EndOfWeekFee | int | YES | - | CODE-BACKED | Weekend fee in cents (EndOfWeekFee * 100). |
| 29 | Unit | decimal | YES | - | CODE-BACKED | Unit count from ProviderToInstrument. |
| 30 | HedgedLotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count from hedge record. |
| 31 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position lot count. |
| 32 | AdditionalParam | varchar | YES | - | CODE-BACKED | Additional parameters. NULL for closed game positions. |
| 33 | TradeID | varchar | YES | - | CODE-BACKED | External trade ID from provider's hedge. |
| 34 | AccountID | varchar | YES | - | CODE-BACKED | External account on provider. |
| 35 | Occurred | datetime | YES | - | CODE-BACKED | When position was executed. For closed: OpenOccurred. |
| 36 | OrderID | int | YES | - | CODE-BACKED | Originating order. 0 for closed game positions. |
| 37 | TradeRange | float | YES | - | CODE-BACKED | Market range. 0 for closed game positions. |
| 38 | InitForexPriceRateID | bigint | YES | - | CODE-BACKED | Price rate snapshot. 0 for closed game positions. |
| 39 | OrderPriceRateID | bigint | YES | - | CODE-BACKED | Order price rate snapshot. 0 for closed. |
| 40 | OrderPriceRate | decimal(16,8) | YES | - | CODE-BACKED | Order price rate. 0 for closed. |
| 41 | MarketPriceRateID | bigint | YES | - | CODE-BACKED | Market price rate snapshot. 0 for closed. |
| 42 | MarketPriceRate | decimal(16,8) | YES | - | CODE-BACKED | Market price rate. 0 for closed. |
| 43 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent position in hierarchy. |
| 44 | OrigParentPositionID | bigint | YES | - | CODE-BACKED | Original parent before splits. |
| 45 | LastOpPriceRate | decimal(16,8) | YES | - | CODE-BACKED | Last operation price rate. |
| 46 | LastOpPriceRateID | bigint | YES | - | CODE-BACKED | Last op price rate snapshot. |
| 47 | LastOpConversionRate | decimal(16,8) | YES | - | CODE-BACKED | Last operation conversion rate. |
| 48 | LastOpConversionRateID | bigint | YES | - | CODE-BACKED | Last op conversion rate snapshot. |
| 49 | UnitMargin | money | YES | - | CODE-BACKED | Unit margin. |
| 50 | Units | decimal | YES | - | CODE-BACKED | Unit count (duplicate of Unit). |
| 51 | InstrumentPrecision | int | YES | - | CODE-BACKED | Decimal precision from ProviderToInstrument. |
| 52 | MirrorID | int | YES | - | CODE-BACKED | Mirror/copy-trade ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (Part 1) | Trade.Position | FROM | Open positions |
| (Part 2) | History.Position | FROM | Closed game positions |
| HedgeID | Trade.Hedge + History.Hedge | LEFT JOIN (UNION ALL) | Hedge enrichment |
| InstrumentID | Trade.Instrument | JOIN | Currency pair lookup |
| ProviderID, InstrumentID | Trade.ProviderToInstrument | JOIN | Unit and precision |
| ForexResultID | Game.ForexResult + History.ForexResult | JOIN (Part 2) | Game session link |
| GameTypeID | Dictionary.GameType | JOIN (Part 2) | Game subtype filter (NOT IN 4, 6) |
| PositionID | Internal.GetNetProfit | Function call (Part 1) | Live PnL |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetOpenPositionAsXML | FROM | View consumer | Adds customer data for open position XML |
| Trade.GetPositionAsXML | FROM | View consumer | Adds customer data for all position XML |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionForXML (view)
+-- Trade.Position (view)
|     +-- Trade.PositionTbl (table)
|     +-- Trade.PositionTreeInfo (table)
+-- History.Position (x-schema table)
+-- Trade.Hedge (table)
+-- History.Hedge (x-schema table)
+-- Trade.Instrument (table)
+-- Trade.ProviderToInstrument (table)
+-- Game.ForexResult (x-schema table)
+-- History.ForexResult (x-schema table)
+-- Dictionary.GameType (x-schema table)
+-- Internal.GetNetProfit (x-schema function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | Open positions (Part 1) |
| History.Position | Table | Closed game positions (Part 2) |
| Trade.Hedge | Table | Hedge lookup (UNION ALL) |
| History.Hedge | Table | Historical hedge lookup (UNION ALL) |
| Trade.Instrument | Table | Currency pair (BuyCurrencyID, SellCurrencyID) |
| Trade.ProviderToInstrument | Table | Unit and precision |
| Game.ForexResult | Table | Game session link (Part 2) |
| History.ForexResult | Table | Historical game session link (Part 2) |
| Dictionary.GameType | Table | Game subtype filter |
| Internal.GetNetProfit | Function | Live PnL (Part 1) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetOpenPositionAsXML | View | Adds customer data for open positions |
| Trade.GetPositionAsXML | View | Adds customer data for all positions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Open positions for a customer (XML format)

```sql
SELECT PositionID, InstrumentID, IsBuy, PositionAmountCents, NetProfit, IsOpened
FROM   Trade.GetPositionForXML WITH (NOLOCK)
WHERE  CID = 12345 AND IsOpened = 1;
```

### 8.2 Closed game positions for session restoration

```sql
SELECT PositionID, ForexResultID, InstrumentID, EndForexRate, NetProfit, IsOpened
FROM   Trade.GetPositionForXML WITH (NOLOCK)
WHERE  CID = 12345 AND IsOpened = 0;
```

### 8.3 All positions with hedge details

```sql
SELECT PositionID, IsOpened, HedgedLotCountDecimal, TradeID, AccountID
FROM   Trade.GetPositionForXML WITH (NOLOCK)
WHERE  HedgeID IS NOT NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.8/10 (Elements: 10.0/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 52 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionForXML | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetPositionForXML.sql*
