# Trade.GetCurrentPrice

> Passthrough view exposing the live bid, ask, and price metadata from Trade.CurrencyPrice for order placement, position valuation, and rate display.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | ProviderID, InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetCurrentPrice is a thin passthrough view over Trade.CurrencyPrice. It exposes the current bid, ask, price rate ID, and timestamp fields that the trading engine and reporting procedures need for real-time price lookups. The view selects a subset of CurrencyPrice columns (ProviderID, InstrumentID, Bid, Ask, PriceRateID, ReceivedOnPriceServer, OccurredOnServer, Occurred) without filtering or transformation.

This view exists to provide a consistent, named interface for "current price" queries. Order placement (Trade.OrdersAdd), forex rate display (Trade.GetForexRates), position close logic, conversion rate lookups (Trade.FnGetCurrentClosingRate, Trade.FnGetCurrentConversionRate), and reporting (SSRS dashboards, Monitor.FX_NOP_Per_Book_Datadog) all need the latest executable prices. GetCurrentPrice is the primary read path for these consumers; Trade.GetCurrentPriceAndConversionRate extends it with conversion rate enrichment.

Data flows: Price feeds UPDATE Trade.CurrencyPrice continuously. GetCurrentPrice SELECTs from CurrencyPrice with NOLOCK. Consumers JOIN on ProviderID and InstrumentID (typically ProviderID=1 for the main provider). Trade.GetForexRates JOINs GetCurrentPrice with GetProviderToInstrument and GetInstrument for forex rate display.

---

## 2. Business Logic

### 2.1 One Row Per (ProviderID, InstrumentID)

**What**: Each provider-instrument pair has exactly one row. No filtering - all rows from CurrencyPrice are exposed.

**Columns/Parameters Involved**: `ProviderID`, `InstrumentID`, `Bid`, `Ask`, `Occurred`

**Rules**:
- View is a direct SELECT from CurrencyPrice - no WHERE clause
- Composite identifier (ProviderID, InstrumentID) matches CurrencyPrice PK
- Consumers typically filter by ProviderID=1 and InstrumentID for single-instrument lookups
- Occurred and ReceivedOnPriceServer indicate when the price was last updated

---

## 3. Data Overview

| ProviderID | InstrumentID | Bid | Ask | PriceRateID | Occurred | Meaning |
|------------|--------------|-----|-----|-------------|----------|---------|
| 1 | 1 | 1.14 | 1.145 | 46787288246 | 2026-03-14 19:11:26 | EUR/USD on Provider 1. Tight spread. Recent tick. |
| 1 | 2 | 1.33785 | 1.33788 | 46244457906 | 2025-12-05 21:41:54 | GBP (Instrument 2). Very tight spread. |
| 1 | 4 | 9.37765 | 9.37768 | 46787291887 | 2026-03-14 19:11:27 | CAD. Standard USD/CAD pair. |
| 1 | 5 | 566314.153 | 566314.156 | 46787320054 | 2026-03-14 19:11:26 | JPY pair - large numeric values typical for JPY. |
| 1 | 3 | 50.63964 | 50.63967 | 46214236984 | 2025-11-28 16:29:58 | Cross pair. Occurred shows last update time. |

**Selection criteria**: Picked from live TOP 5 - major forex showing variety of instruments, bid/ask spreads, and timestamp patterns.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | - | CODE-BACKED | Part of composite key. FK to Trade.ProviderToInstrument. Identifies the liquidity provider. Typically 1 for main provider. Inherited from Trade.CurrencyPrice. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Part of composite key. FK to Trade.ProviderToInstrument. The instrument (forex pair, stock, etc.) for this price. Inherited from Trade.CurrencyPrice. |
| 3 | Bid | dbo.dtPrice | NO | - | CODE-BACKED | Current bid rate. Used for sell orders and closing long positions. Inherited from Trade.CurrencyPrice. |
| 4 | Ask | dbo.dtPrice | NO | - | CODE-BACKED | Current ask rate. Used for buy orders and closing short positions. Inherited from Trade.CurrencyPrice. |
| 5 | PriceRateID | bigint | NO | - | CODE-BACKED | Tick/rate identifier linking to price feed stream. Audit and reconciliation. Inherited from Trade.CurrencyPrice. |
| 6 | ReceivedOnPriceServer | datetime | YES | - | CODE-BACKED | When the price server received the tick. Latency measurement. Inherited from Trade.CurrencyPrice. |
| 7 | OccurredOnServer | datetime | NO | - | CODE-BACKED | Server timestamp of price reception. Inherited from Trade.CurrencyPrice. |
| 8 | Occurred | datetime | NO | - | CODE-BACKED | When this price was last updated. Default getdate() on insert. Inherited from Trade.CurrencyPrice. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderID, InstrumentID | Trade.ProviderToInstrument | FK | Must exist before CurrencyPrice row |
| InstrumentID | Trade.Instrument | Implicit | Instrument definition |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetForexRates | FROM | Reader | Forex rate display with spread |
| Trade.GetCurrentPriceAndConversionRate | FROM | Reader | Extends with conversion rate |
| dbo.SSRS_NewHedgeDashDynamic | JOIN | Reader | Hedge dashboard |
| dbo.SSRS_NewHedgeDashDynamic_Majors | JOIN | Reader | Majors hedge dashboard |
| dbo.SSRS_DynamicQueryForNOP | JOIN | Reader | NOP (Net Open Position) reporting |
| dbo.SSRS_AllPositionsForImmediateCloseScenario | LEFT JOIN | Reader | Close scenario analysis |
| dbo.SSRS_query_stocks_nop_leverage_units_pos | JOIN | Reader | Stock NOP reporting |
| Monitor.Monitor_FX_NOP_Per_Book_Datadog | JOIN | Reader | Datadog FX monitoring |
| DividendsApp | GRANT SELECT | Permission | Dividend app price access |
| BILLING_MANAGER | GRANT SELECT | Permission | Billing price access |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCurrentPrice (view)
└── Trade.CurrencyPrice (table)
      └── Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CurrencyPrice | Table | FROM - base table |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetForexRates | Procedure | FROM for bid/ask + spread |
| Trade.GetCurrentPriceAndConversionRate | View | JOINs for conversion |
| dbo.SSRS_NewHedgeDashDynamic | Procedure | JOIN |
| dbo.SSRS_DynamicQueryForNOP | Procedure | JOIN |
| dbo.SSRS_AllPositionsForImmediateCloseScenario | Procedure | LEFT JOIN |
| dbo.SSRS_query_stocks_nop_leverage_units_pos | Procedure | JOIN |
| Monitor.Monitor_FX_NOP_Per_Book_Datadog | Procedure | JOIN |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get current price for EUR/USD (Instrument 1)
```sql
SELECT ProviderID, InstrumentID, Bid, Ask, (Bid + Ask) / 2 AS MidPrice,
       PriceRateID, Occurred
  FROM Trade.GetCurrentPrice WITH (NOLOCK)
 WHERE ProviderID = 1 AND InstrumentID = 1
```

### 8.2 Resolve prices with instrument names
```sql
SELECT GCP.ProviderID, GCP.InstrumentID, IMD.Symbol, GCP.Bid, GCP.Ask,
       GCP.Occurred, DATEDIFF(SECOND, GCP.Occurred, GETUTCDATE()) AS SecondsAgo
  FROM Trade.GetCurrentPrice GCP WITH (NOLOCK)
  JOIN Trade.InstrumentMetaData IMD WITH (NOLOCK) ON GCP.InstrumentID = IMD.InstrumentID
 WHERE GCP.InstrumentID IN (1, 5, 10)
```

### 8.3 Find stale prices (not updated in 5+ minutes)
```sql
SELECT GCP.ProviderID, GCP.InstrumentID, GCP.Bid, GCP.Ask, GCP.Occurred
  FROM Trade.GetCurrentPrice GCP WITH (NOLOCK)
 WHERE GCP.Occurred < DATEADD(MINUTE, -5, GETUTCDATE())
 ORDER BY GCP.Occurred ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.7/10 (Elements: 10/10, Logic: 7/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8+ analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCurrentPrice | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetCurrentPrice.sql*
