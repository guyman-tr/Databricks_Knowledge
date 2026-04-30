# Trade.GetProviderToInstrument

> Provider-instrument configuration view that joins ProviderToInstrument with Instrument, GetInstrument, and InstrumentMetaData to expose enabled, tradeable instrument settings per provider with XML LeverageList and LotCountList.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | ProviderID, InstrumentID (composite from base table) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetProviderToInstrument is the primary view for exposing per-provider, per-instrument trading configuration to clients. It answers: "What instruments can this provider trade, and what are the fees, limits, allowed operations, and risk parameters?" The view joins Trade.ProviderToInstrument with Trade.Provider (active only), Trade.GetInstrument (InstrumentTypeID), Trade.Instrument (BuyCurrencyID, SellCurrencyID), and Trade.InstrumentMetaData (Tradable, Visible). It filters to ProviderID != 0, InstrumentID != 0, provider IsActive = 1, and ProviderToInstrument Enabled = 1.

The view adds computed LeverageList and LotCountList as XML (FOR XML RAW) from Dictionary.Leverage/ProviderInstrumentToLeverage and Dictionary.LotCount/ProviderInstrumentToLotCount. It exposes OrdersSpread as alias for MarketRange. Callers use this view for forex rates, orphaned-position checks, allowed rate-diff lookups, NFA exposure, and billing.

---

## 2. Business Logic

### 2.1 Active Provider-Instrument Pairs Only

**What**: Only enabled, active provider-instrument combinations are returned.

**Columns/Parameters Involved**: `ProviderID`, `InstrumentID`, `Enabled`, `IsActive`

**Rules**:
- WHERE TPVI.ProviderID != 0 AND TPVI.InstrumentID != 0
- WHERE TPRV.IsActive = 1 AND TPVI.Enabled = 1
- ProviderID=0 and InstrumentID=0 are system placeholders

### 2.2 LeverageList and LotCountList XML

**What**: Correlated subqueries produce XML for leverage options and lot counts per provider-instrument.

**Columns/Parameters Involved**: `LeverageList`, `LotCountList`

**Rules**:
- LeverageList: FROM Dictionary.Leverage, Trade.ProviderInstrumentToLeverage; ORDER BY DLVL.Value; FOR XML RAW('LeverageData'), BINARY BASE64, ELEMENTS, TYPE, ROOT('LeverageList')
- LotCountList: FROM Dictionary.LotCount, Trade.ProviderInstrumentToLotCount; FOR XML RAW('LotCountData'), BINARY BASE64, ELEMENTS, TYPE, ROOT('LotCountList')
- Each returns Value, Percentage, IsDefault (and LotCountGroupID for lot counts)

### 2.3 Visible and Tradable from Metadata

**What**: IMD.Tradable and IMD.InstrumentVisible (as Visible) control whether instrument is tradeable and visible in UI.

**Columns/Parameters Involved**: `Tradable`, `Visible`

**Rules**:
- Tradable from Trade.InstrumentMetaData
- Visible = IMD.InstrumentVisible

---

## 3. Data Overview

| ProviderID | InstrumentID | PresentationCode | InstrumentTypeID | AllowBuy | AllowSell | MinPositionAmount | Unit | Meaning |
|------------|--------------|-------------------|------------------|----------|-----------|-------------------|-----|---------|
| 1 | 1 | EURUSD= | 1 | true | true | 1000 | 1000 | EUR/USD forex; full buy/sell; InstrumentTypeID 1 |
| 1 | 2 | GBP= | 1 | true | false | 1000 | 1000 | GBP; buy only; sell disabled |
| 1 | 5 | JPY= | 1 | true | true | 1000 | 1000 | JPY forex; AboveDollarPrecision 5 |

**Selection criteria**: Live MCP sample (TOP 5). Instrument 1 (EUR/USD), 2 (GBP), 5 (JPY). LeverageList and LotCountList contain XML.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | - | CODE-BACKED | Execution provider (e.g., 1=Tradonomi). From Trade.ProviderToInstrument. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Tradeable instrument. From Trade.ProviderToInstrument. |
| 3 | Precision | tinyint | NO | - | CODE-BACKED | Decimal places for price display. From TPVI. |
| 4 | AboveDollarPrecision | tinyint | NO | - | CODE-BACKED | Precision for amounts above dollar threshold. From TPVI. |
| 5 | PresentationCode | varchar(20) | NO | - | CODE-BACKED | Display code (e.g., EURUSD=, GBP=). From TPVI. |
| 6 | PaymentBid | int | NO | - | CODE-BACKED | Bid-side payment adjustment. From TPVI. |
| 7 | PaymentAsk | int | NO | - | CODE-BACKED | Ask-side payment adjustment. From TPVI. |
| 8 | StopLossPercentage | int | NO | - | CODE-BACKED | Legacy SL percentage. From TPVI. |
| 9 | EndOfWeekFee | money | NO | - | CODE-BACKED | End-of-week holding fee. From TPVI. |
| 10 | Unit | int | NO | - | CODE-BACKED | Base unit size (e.g., 1000 for forex). From TPVI. |
| 11 | UnitMargin | int | NO | - | CODE-BACKED | Margin factor per unit. From TPVI. |
| 12 | Benchmark | int | NO | - | CODE-BACKED | Reference value for pricing. From TPVI. |
| 13 | LiquidityLotSize | int | NO | - | CODE-BACKED | Lot size for liquidity orders. From TPVI. |
| 14 | DisplayOrder | int | NO | - | CODE-BACKED | Sort order for UI. From TPVI. |
| 15 | InstrumentTypeID | int | YES | - | CODE-BACKED | Asset class from Trade.GetInstrument (1=Forex, 5=Stocks, etc.). From TISR. |
| 16 | WeekendPips | int | YES | - | CODE-BACKED | Weekend spread/fee in pips. From TPVI. |
| 17 | MinimumSpread | dbo.dtPrice | YES | - | CODE-BACKED | Minimum spread allowed. From TPVI. |
| 18 | OrdersSpread | int | YES | - | CODE-BACKED | Alias for MarketRange; spread for orders. From TPVI.MarketRange. |
| 19 | OrdersSpreadMax | int | YES | - | CODE-BACKED | Max spread for orders. From TPVI. |
| 20 | MarketRange | int | YES | - | CODE-BACKED | Market range validation limit. From TPVI. |
| 21 | LeverageList | xml | YES | - | CODE-BACKED | XML of leverage options (Value, Percentage, IsDefault) per provider-instrument. Correlated subquery. |
| 22 | LotCountList | xml | YES | - | CODE-BACKED | XML of lot count options (Value, Percentage, LotCountGroupID, IsDefault) per provider-instrument. Correlated subquery. |
| 23 | BuyCurrencyID | int | NO | - | CODE-BACKED | Buy-side currency from Trade.Instrument. From TI. |
| 24 | SellCurrencyID | int | NO | - | CODE-BACKED | Sell-side currency from Trade.Instrument. From TI. |
| 25 | BuyEOWFee | money | NO | - | CODE-BACKED | End-of-week fee for buy. From TPVI. |
| 26 | SellEOWFee | money | NO | - | CODE-BACKED | End-of-week fee for sell. From TPVI. |
| 27 | BuyOverNightFee | money | YES | - | CODE-BACKED | Overnight fee for buy. From TPVI. |
| 28 | SellOverNightFee | money | YES | - | CODE-BACKED | Overnight fee for sell. From TPVI. |
| 29 | MaxPositionUnits | decimal(18,4) | YES | - | CODE-BACKED | Max position size in units. From TPVI. |
| 30 | MinPositionAmount | money | NO | - | CODE-BACKED | Min position size in currency. From TPVI. |
| 31 | Tradable | bit | NO | - | CODE-BACKED | Whether instrument is tradeable. From IMD.InstrumentMetaData. |
| 32 | Enabled | tinyint | NO | - | CODE-BACKED | 1=instrument enabled for provider. From TPVI. |
| 33 | Visible | bit | NO | - | CODE-BACKED | Whether instrument is visible in UI. From IMD.InstrumentVisible. |
| 34 | AllowedRateDiffPercentage | decimal(5,2) | NO | - | CODE-BACKED | Max allowed rate diff for order validation. From TPVI. |
| 35 | AllowBuy | bit | NO | - | CODE-BACKED | 1=buy allowed, 0=buy disabled. From TPVI. |
| 36 | AllowSell | bit | NO | - | CODE-BACKED | 1=sell allowed, 0=sell disabled. From TPVI. |
| 37 | AllowPendingOrders | bit | NO | - | CODE-BACKED | 1=pending orders allowed. From TPVI. |
| 38 | AllowEntryOrders | bit | NO | - | CODE-BACKED | 1=entry orders allowed. From TPVI. |
| 39 | VisibleInternallyOnly | bit | NO | - | CODE-BACKED | 1=hidden from external clients. From TPVI. |
| 40 | AllowClosePosition | bit | NO | - | CODE-BACKED | 1=user can close position. From TPVI. |
| 41 | AllowExitOrder | bit | NO | - | CODE-BACKED | 1=exit orders allowed. From TPVI. |
| 42 | GuaranteeSLTP | bit | NO | - | CODE-BACKED | 1=broker guarantees SL/TP. From TPVI. |
| 43 | AllowEditSLTP | bit | NO | - | CODE-BACKED | 1=user can edit SL/TP. From TPVI. |
| 44 | MarketRangeValidationType | tinyint | NO | - | CODE-BACKED | How market range is validated (1=default, 2=percentage). From TPVI. |
| 45 | MarketRangePercentage | decimal(5,2) | YES | - | CODE-BACKED | Market range as percentage when MarketRangeValidationType=2. From TPVI. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|----------------|-------------------|-------------|
| ProviderID, InstrumentID | Trade.ProviderToInstrument | Base | Core config table |
| ProviderID | Trade.Provider | INNER JOIN | Provider must be active |
| InstrumentID | Trade.GetInstrument | INNER JOIN | InstrumentTypeID |
| InstrumentID | Trade.Instrument | INNER JOIN | BuyCurrencyID, SellCurrencyID |
| InstrumentID | Trade.InstrumentMetaData | INNER JOIN | Tradable, InstrumentVisible |
| LeverageList | Dictionary.Leverage, Trade.ProviderInstrumentToLeverage | Correlated subquery | Leverage options |
| LotCountList | Dictionary.LotCount, Trade.ProviderInstrumentToLotCount | Correlated subquery | Lot count options |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SI_GetProviderToInstrument | FROM | Reader | SELECT from view |
| Trade.GetInstrumentIDToAllowedRateDiff | FROM | Reader | InstrumentID, AllowedRateDiffPercentage |
| Trade.GetOrphanedPositionsData | INNER JOIN | Reader | Orphaned position checks |
| Trade.GetOrphanedPositionsDataTest | INNER JOIN | Reader | Test version |
| Trade.AlertForOrphanedPositions | INNER JOIN | Reader | Alert logic |
| Trade.GetForexRates | INNER JOIN | Reader | Forex rate display |
| dbo.PR_NFA_EXPOSURE | JOIN | Reader | NFA exposure |
| BILLING_MANAGER | GRANT SELECT | Permission | Billing role access |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetProviderToInstrument (view)
├── Trade.ProviderToInstrument (table)
├── Trade.Provider (table)
├── Trade.GetInstrument (view)
│   ├── Trade.Instrument
│   ├── Dictionary.Currency (x2)
│   └── Trade.InstrumentMetaData
├── Trade.Instrument (table)
├── Trade.InstrumentMetaData (table)
├── Dictionary.Leverage + Trade.ProviderInstrumentToLeverage (subquery)
└── Dictionary.LotCount + Trade.ProviderInstrumentToLotCount (subquery)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | FROM; main config |
| Trade.Provider | Table | INNER JOIN; IsActive filter |
| Trade.GetInstrument | View | INNER JOIN; InstrumentTypeID |
| Trade.Instrument | Table | INNER JOIN; BuyCurrencyID, SellCurrencyID |
| Trade.InstrumentMetaData | Table | INNER JOIN; Tradable, Visible |
| Dictionary.Leverage, Trade.ProviderInstrumentToLeverage | Table | Correlated subquery; LeverageList |
| Dictionary.LotCount, Trade.ProviderInstrumentToLotCount | Table | Correlated subquery; LotCountList |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.SI_GetProviderToInstrument | Procedure | FROM |
| Trade.GetInstrumentIDToAllowedRateDiff | Procedure | FROM |
| Trade.GetOrphanedPositionsData | Procedure | INNER JOIN |
| Trade.GetOrphanedPositionsDataTest | Procedure | INNER JOIN |
| Trade.AlertForOrphanedPositions | Procedure | INNER JOIN |
| Trade.GetForexRates | Procedure | INNER JOIN |
| dbo.PR_NFA_EXPOSURE | Procedure | JOIN |
| BILLING_MANAGER | Role | GRANT SELECT |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. SELECT TOP 100000 with ORDER BY TPVI.InstrumentID.

### 7.2 Constraints

None. Filters: ProviderID != 0, InstrumentID != 0, IsActive = 1, Enabled = 1.

---

## 8. Sample Queries

### 8.1 List enabled instruments for provider
```sql
SELECT ProviderID, InstrumentID, PresentationCode, Precision, Unit, MinPositionAmount,
       AllowBuy, AllowSell, InstrumentTypeID
  FROM Trade.GetProviderToInstrument WITH (NOLOCK)
 WHERE ProviderID = 1
 ORDER BY InstrumentID;
```

### 8.2 Get allowed rate diff by instrument
```sql
SELECT InstrumentID, AllowedRateDiffPercentage
  FROM Trade.GetProviderToInstrument WITH (NOLOCK)
 WHERE InstrumentID IN (1, 2, 5)
   AND ProviderID = 1;
```

### 8.3 Forex instruments with buy/sell flags
```sql
SELECT ProviderID, InstrumentID, PresentationCode, InstrumentTypeID,
       AllowBuy, AllowSell, AllowPendingOrders, AllowEntryOrders
  FROM Trade.GetProviderToInstrument WITH (NOLOCK)
 WHERE InstrumentTypeID = 1
   AND ProviderID = 1
 ORDER BY InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 45 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetProviderToInstrument | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetProviderToInstrument.sql*
