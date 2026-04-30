# Trade.CurrencyPriceRemove

> Stub procedure originally designed to reset currency price data for a specific provider. The core logic is entirely commented out, making this an effectively empty procedure that only returns @@ERROR.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN @@ERROR |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CurrencyPriceRemove is a stub procedure that was originally intended to reset (zero out) bid, ask, and PriceRateID values in Trade.CurrencyPrice for a specific provider. The entire UPDATE statement is commented out, so the procedure currently does nothing except return @@ERROR (which will be 0 unless a prior error exists in the session).

This procedure likely became obsolete when the price management workflow changed. Zeroing out prices would make instruments untradable for the affected provider, which is a drastic operation that was probably replaced by a safer mechanism (such as disabling the provider in Trade.ProviderToInstrument). The procedure skeleton is preserved in SSDT for backward compatibility with any callers that still reference it.

No active consumers were found in the Trade schema.

---

## 2. Business Logic

No active business logic. All operational code is commented out.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderID | INTEGER | NO | - | CODE-BACKED | Provider ID whose currency prices would have been zeroed out. Currently unused - the UPDATE referencing this parameter is commented out. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no active references (all code is commented out). The commented code would have updated Trade.CurrencyPrice.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No active consumers found.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no active dependencies (all code is commented out).

### 6.1 Objects This Depends On

No active dependencies. Commented code referenced Trade.CurrencyPrice.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check current prices for a provider
```sql
SELECT TOP 10 InstrumentID, ProviderID, Bid, Ask, PriceRateID
FROM   Trade.CurrencyPrice WITH (NOLOCK)
WHERE  ProviderID = 1
```

### 8.2 Check provider configuration
```sql
SELECT DISTINCT ProviderID
FROM   Trade.CurrencyPrice WITH (NOLOCK)
```

### 8.3 Check if this procedure is called anywhere
```sql
SELECT name, base_object_name
FROM   sys.synonyms WITH (NOLOCK)
WHERE  base_object_name LIKE '%CurrencyPriceRemove%'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CurrencyPriceRemove | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CurrencyPriceRemove.sql*
