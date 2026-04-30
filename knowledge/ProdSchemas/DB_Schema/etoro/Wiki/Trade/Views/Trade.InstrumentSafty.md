# Trade.InstrumentSafty

> SCHEMABINDING safety wrapper exposing core instrument configuration columns from Trade.Instrument for critical real-time trading components.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.InstrumentSafty is a SCHEMABINDING view that exposes core instrument configuration columns from Trade.Instrument. It provides a stable, schema-locked interface for critical real-time trading components that cannot tolerate base table schema changes. The view selects InstrumentID, BuyCurrencyID, SellCurrencyID, TradeRange, DollarRatio, Passport, PipDifferenceThreshold, IsMajor, and PriceServerID.

This view exists because real-time trading logic depends on instrument configuration. SCHEMABINDING prevents the base table from being altered in ways that would break the view, ensuring that consumers of InstrumentSafty have a guaranteed contract. The typo "Safty" (vs "Safety") is retained for backward compatibility. Without this view, callers would query Trade.Instrument directly and risk breakage when columns are added, removed, or renamed.

The view is created with WITH SCHEMABINDING and performs a simple SELECT of the listed columns with no filters or JOINs. Output is one row per instrument in Trade.Instrument.

---

## 2. Business Logic

No complex business logic. This is a direct projection of selected columns from Trade.Instrument with SCHEMABINDING for schema stability.

---

## 3. Data Overview

N/A - output mirrors Trade.Instrument (subset of columns). See [Trade.Instrument](../Tables/Trade.Instrument.md) for data overview.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | PK, FK to Trade.Instrument. Unique identifier for the instrument. |
| 2 | BuyCurrencyID | int | YES | - | CODE-BACKED | Forex pair buy-side currency. FK to Dictionary.Currency. |
| 3 | SellCurrencyID | int | YES | - | CODE-BACKED | Forex pair sell-side currency. FK to Dictionary.Currency. |
| 4 | TradeRange | int | YES | - | CODE-BACKED | Market range tolerance for slippage and validation. |
| 5 | DollarRatio | float | YES | - | CODE-BACKED | Price scaling factor (e.g., 100 for JPY). Used for USD conversion. |
| 6 | Passport | nvarchar(50) | YES | - | CODE-BACKED | Instrument passport/code identifier. |
| 7 | PipDifferenceThreshold | float | YES | - | CODE-BACKED | Maximum pip difference before flagging for validation. |
| 8 | IsMajor | bit | YES | - | CODE-BACKED | 1 if major forex pair, 0 otherwise. |
| 9 | PriceServerID | int | YES | - | CODE-BACKED | Price feed server ID. Identifies which price server provides rates. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Base Table | Source of all columns. |
| BuyCurrencyID, SellCurrencyID | Dictionary.Currency | Implicit FK | Via Instrument.BuyCurrencyID, SellCurrencyID |
| PriceServerID | Trade.PriceServer (or similar) | Implicit FK | Price feed server reference |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentSafty (view)
    |
    +-- Trade.Instrument (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FROM - source of InstrumentID, BuyCurrencyID, SellCurrencyID, TradeRange, DollarRatio, Passport, PipDifferenceThreshold, IsMajor, PriceServerID |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

SCHEMABINDING. The view is created with WITH SCHEMABINDING, which prevents underlying table schema changes that would affect the view definition.

---

## 8. Sample Queries

### 8.1 Get instrument config for trading
```sql
SELECT InstrumentID, BuyCurrencyID, SellCurrencyID, TradeRange, DollarRatio, PipDifferenceThreshold, IsMajor, PriceServerID
FROM Trade.InstrumentSafty WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
```

### 8.2 Major forex pairs
```sql
SELECT InstrumentID, BuyCurrencyID, SellCurrencyID, Passport
FROM Trade.InstrumentSafty WITH (NOLOCK)
WHERE IsMajor = 1
ORDER BY InstrumentID
```

### 8.3 Instruments by price server
```sql
SELECT InstrumentID, PriceServerID, TradeRange, PipDifferenceThreshold
FROM Trade.InstrumentSafty WITH (NOLOCK)
WHERE PriceServerID = @PriceServerID
ORDER BY InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentSafty | Type: View | Source: etoro/etoro/Trade/Views/Trade.InstrumentSafty.sql*
