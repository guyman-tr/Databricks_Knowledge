# Trade.CurrencyPriceSafty

> Schema-bound view exposing a subset of Trade.CurrencyPrice columns for safe read-only consumption by procedures or applications that must not depend on the full table structure.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | ProviderID, InstrumentID (from base table) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CurrencyPriceSafty is a **reduced surface view** over Trade.CurrencyPrice. It selects only 9 columns (ProviderID, InstrumentID, Bid, Ask, Occurred, OccurredOnServer, PriceRateID, ReceivedOnPriceServer, MarketPriceRateID) and is created WITH SCHEMABINDING. The name "Safty" (likely intended as "Safety") suggests the view exists to provide a **stable, minimal contract** for consumers - procedures or applications that need current bid/ask and timestamp data without depending on the full CurrencyPrice schema (which includes BidDiscounted, AskDiscounted, UnitMargin, USD conversion rates, and many other columns that may change over time).

This view exists so that schema changes to Trade.CurrencyPrice (adding/removing columns) do not break code that only needs the core price columns. SCHEMABINDING prevents the underlying table from being altered in ways that would break this view. Without it, callers would need to SELECT * or enumerate all columns from the volatile CurrencyPrice table.

Data flows: Read-only. The view passes through rows from Trade.CurrencyPrice. No procedure references were found in the Trade schema; the view may be used by application code, reporting, or external consumers.

---

## 2. Business Logic

### 2.1 Minimal Price Contract

**What**: The view exposes only the columns necessary for basic price lookup: identifiers, bid/ask, and timestamps.

**Columns/Parameters Involved**: ProviderID, InstrumentID, Bid, Ask, Occurred, OccurredOnServer, PriceRateID, ReceivedOnPriceServer, MarketPriceRateID

**Rules**:
- All columns are pass-through from Trade.CurrencyPrice - no computed columns.
- SCHEMABINDING ensures the base table cannot drop or alter these columns without first dropping the view.
- Excludes: LastPrice, BidDiscounted, AskDiscounted, UnitMargin, USD conversion columns, skew columns.

---

## 3. Data Overview

| ProviderID | InstrumentID | Bid | Ask | Occurred | PriceRateID | Meaning |
|------------|--------------|-----|-----|----------|-------------|---------|
| 1 | 1 | 1.14 | 1.145 | 2026-03-14 19:11:26 | 46787288246 | EUR/USD - recent price, tight spread. |
| 1 | 2 | 1.33785 | 1.33788 | 2025-12-05 21:41:54 | 46244457906 | GBP - older occurrence date (stale in demo). |
| 1 | 3 | 50.63964 | 50.63967 | 2025-11-28 16:29:58 | 46214236984 | Commodity or index. |
| 1 | 4 | 9.37765 | 9.37768 | 2026-03-14 19:11:27 | 46787291887 | CAD pair. |
| 1 | 5 | 566314.153 | 566314.156 | 2026-03-14 19:11:26 | 46787320054 | JPY - large numeric values typical for JPY pairs. |

**Selection criteria**: Live data TOP 5. Mix of forex (1,2,4,5) and other instruments. Occurred shows recency of price updates.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | - | CODE-BACKED | Part of PK from Trade.CurrencyPrice. FK to Trade.ProviderToInstrument. Identifies the price provider. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Part of PK. Identifies the financial instrument. |
| 3 | Bid | dbo.dtPrice | NO | - | CODE-BACKED | Current bid rate. From Trade.CurrencyPrice. |
| 4 | Ask | dbo.dtPrice | NO | - | CODE-BACKED | Current ask rate. Used with Bid for mid-price and validation. |
| 5 | Occurred | datetime | NO | - | CODE-BACKED | When this price was last updated. TCRP_LASTUPDATE default in base table. |
| 6 | OccurredOnServer | datetime | NO | - | CODE-BACKED | Server timestamp of price reception. |
| 7 | PriceRateID | bigint | NO | - | CODE-BACKED | Tick/rate identifier. Links to price feed stream. |
| 8 | ReceivedOnPriceServer | datetime | YES | - | CODE-BACKED | When price server received the tick. |
| 9 | MarketPriceRateID | bigint | YES | - | CODE-BACKED | Market rate ID. TCRP_NullMarketPriceRateID default (0) in base. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderID, InstrumentID | Trade.ProviderToInstrument | Implicit | Via Trade.CurrencyPrice FK. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None in Trade procedures) | - | - | No procedure references found in etoro/Trade. May be used by app/reporting. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CurrencyPriceSafty (view)
└── Trade.CurrencyPrice (table)
      └── Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CurrencyPrice | Table | FROM - direct SELECT of 9 columns |

### 6.2 Objects That Depend On This

No dependents found in Trade schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

SCHEMABINDING: View is bound to Trade.CurrencyPrice. Base table cannot drop or alter referenced columns without dropping the view first.

---

## 8. Sample Queries

### 8.1 Get current bid/ask for an instrument
```sql
SELECT ProviderID, InstrumentID, Bid, Ask, Occurred
  FROM Trade.CurrencyPriceSafty WITH (NOLOCK)
 WHERE ProviderID = 1 AND InstrumentID = 1;
```

### 8.2 Find stale prices (not updated recently)
```sql
SELECT ProviderID, InstrumentID, Bid, Ask, Occurred,
       DATEDIFF(SECOND, Occurred, GETUTCDATE()) AS SecondsSinceUpdate
  FROM Trade.CurrencyPriceSafty WITH (NOLOCK)
 WHERE Occurred < DATEADD(MINUTE, -5, GETUTCDATE())
 ORDER BY Occurred ASC;
```

### 8.3 Resolve with instrument metadata
```sql
SELECT cps.ProviderID, cps.InstrumentID, imd.InstrumentDisplayName,
       cps.Bid, cps.Ask, cps.Occurred
  FROM Trade.CurrencyPriceSafty cps WITH (NOLOCK)
  LEFT JOIN Trade.InstrumentMetaData imd WITH (NOLOCK) ON imd.InstrumentID = cps.InstrumentID
 WHERE cps.InstrumentID IN (1, 5, 10);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.0/10 (Elements: 10/10, Logic: 6/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.CurrencyPriceSafty | Type: View | Source: etoro/etoro/Trade/Views/Trade.CurrencyPriceSafty.sql*
