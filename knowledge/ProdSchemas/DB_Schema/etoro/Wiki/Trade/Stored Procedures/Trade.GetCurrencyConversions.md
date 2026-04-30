# Trade.GetCurrencyConversions

> Returns all currency conversion mappings from the GetCurrencyConversionsView, defining how each currency converts to its base currency via a specific instrument and whether the rate is reciprocal.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all rows from Trade.GetCurrencyConversionsView |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides the currency conversion mapping table that the trading platform uses to convert amounts between currencies. Each row defines: a source currency, a target conversion currency, the instrument whose price is used for the conversion rate, and whether the rate needs to be inverted (reciprocal). This is essential for multi-currency PnL calculations, margin calculations, and account balance conversions.

For example, if a customer's account is in EUR but they trade a USD-denominated instrument, the system needs to know which forex pair to use and whether to multiply or divide by the rate.

Data flow: Trading services call this procedure at startup or periodically -> receive the full conversion map -> cache it for real-time currency conversion during trade execution, PnL calculation, and margin computation.

---

## 2. Business Logic

### 2.1 Reciprocal Rate Flag

**What**: Indicates whether the conversion rate from the instrument needs to be inverted.

**Columns/Parameters Involved**: `IsReciprocal`, `ConversionInstrumentID`

**Rules**:
- IsReciprocal=0: Use the instrument price directly (e.g., EUR/USD instrument, converting EUR to USD)
- IsReciprocal=1: Invert the instrument price (e.g., EUR/USD instrument, converting USD to EUR requires 1/rate)
- The ConversionInstrumentID is a forex pair instrument whose live price provides the conversion rate

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

None.

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CurrencyID | INT | - | - | CODE-BACKED | Source currency to convert from. FK to Dictionary.Currency. |
| 2 | ConversionCurrencyID | INT | - | - | CODE-BACKED | Target currency to convert to. FK to Dictionary.Currency. Typically the base/account currency. |
| 3 | ConversionInstrumentID | INT | - | - | CODE-BACKED | Forex instrument whose live price provides the conversion rate between CurrencyID and ConversionCurrencyID. |
| 4 | IsReciprocal | BIT | - | - | CODE-BACKED | Whether to invert the instrument rate: 0=use rate directly, 1=use 1/rate. Depends on the direction of the forex pair relative to the conversion direction. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.GetCurrencyConversionsView | Read | Reads all currency conversion mappings from the view |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trading Services | EXEC | Caller | Loads currency conversion map for real-time rate lookups |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCurrencyConversions (procedure)
└── Trade.GetCurrencyConversionsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetCurrencyConversionsView | View | Source of currency conversion mappings |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trading Services | External | Currency conversion map cache loading |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- SET NOCOUNT ON for performance
- No WHERE filter - returns all conversion mappings

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Trade.GetCurrencyConversions;
```

### 8.2 Query the view directly

```sql
SELECT CurrencyID, ConversionCurrencyID, ConversionInstrumentID, IsReciprocal
FROM Trade.GetCurrencyConversionsView WITH (NOLOCK);
```

### 8.3 Find conversion path for a specific currency

```sql
SELECT CurrencyID, ConversionCurrencyID, ConversionInstrumentID, IsReciprocal
FROM Trade.GetCurrencyConversionsView WITH (NOLOCK)
WHERE CurrencyID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.4/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCurrencyConversions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCurrencyConversions.sql*
