# Price.SetCurrencyPriceBulk

> Stub/placeholder procedure - body is `SELECT 1 WHERE 1<>2` (no-op, always returns empty result set). Accepts a Price.CurrencyPriceTable TVP but performs no writes. The active bulk price update path uses SetCurrencyPriceBulkWithConversionRate or SetCurrencyPriceBulkWithUnitMargin instead.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PriceTable (TVP - accepted but not used) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.SetCurrencyPriceBulk is a placeholder/stub procedure. Despite accepting a `Price.CurrencyPriceTable` TVP (which in the active variants carries per-instrument bid/ask/skew/spread data), the procedure body contains only `SELECT 1 WHERE 1<>2` - a query that always returns zero rows. No INSERT, UPDATE, or any DML is performed.

This procedure is likely a versioned replacement: the original SetCurrencyPriceBulk was the primary price update path before the conversion rate and unit margin fields were added. When the active variants (SetCurrencyPriceBulkWithConversionRate and SetCurrencyPriceBulkWithUnitMargin) were introduced, this procedure was stubbed out rather than deleted - preserving any existing caller bindings while silently doing nothing.

Callers that invoke this procedure should be migrated to one of the active variants:
- `Price.SetCurrencyPriceBulkWithConversionRate`: UPDATE only, includes USDConversionRate fields
- `Price.SetCurrencyPriceBulkWithUnitMargin`: UPDATE only, sets USDConversionRate fields to NULL

---

## 2. Business Logic

### 2.1 No-Op Body

**What**: The procedure accepts input but does nothing.

**Rules**:
- Body: `SELECT 1 WHERE 1<>2` - this condition is always false; the SELECT always returns 0 rows
- No SET NOCOUNT ON - returns a "0 rows affected" message
- No DML - Trade.CurrencyPrice or any other table is never written
- The TVP parameter @PriceTable is declared but never referenced in the body

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PriceTable | Price.CurrencyPriceTable READONLY | NOT NULL (but ignored) | - | CODE-BACKED | TVP of bulk price updates. Defined as Price.CurrencyPriceTable (InstrumentID, Bid, Ask, SkewValueBid, SkewValueAsk, Spread, PriceRateID). Accepted but never read by this stub procedure. |

**Result set**: Empty (0 rows). `SELECT 1 WHERE 1<>2` always returns no rows.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PriceTable | Price.CurrencyPriceTable | TVP type (unused) | TVP type is declared but the parameter is never referenced in the body |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (legacy callers) | @PriceTable | CALLER | Any callers should be migrated to SetCurrencyPriceBulkWithConversionRate or SetCurrencyPriceBulkWithUnitMargin |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.SetCurrencyPriceBulk (stub procedure - no runtime dependencies)
+-- Price.CurrencyPriceTable (UDT) - TVP parameter type (declared only)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.CurrencyPriceTable | User Defined Type | TVP parameter type (declared only - body does not use it) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (legacy callers - if any) | External | Should be migrated to active variants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

No SET NOCOUNT ON. No error handling. No DML. Body is a pure stub. The procedure exists to preserve API compatibility for any callers that were bound to this procedure name before the active variants were introduced. Since it silently does nothing, callers that rely on it to update prices will see no price updates without any error indication.

**Active alternatives**:
| Procedure | Description |
|---|---|
| Price.SetCurrencyPriceBulkWithConversionRate | UPDATE Trade.CurrencyPrice with conversion rate fields |
| Price.SetCurrencyPriceBulkWithUnitMargin | UPDATE Trade.CurrencyPrice, sets conversion rate fields to NULL |
| Price.SetCurrencyPriceBulkSecondary | UPSERT Trade.CurrencyPriceSecondary (secondary feed) |
| Price.SetCurrencyPriceBulkSecondaryWithUnitMargin | UPSERT Trade.CurrencyPriceSecondary with unit margin |

---

## 8. Sample Queries

### 8.1 Demonstrating the stub behavior

```sql
DECLARE @Prices Price.CurrencyPriceTable;
INSERT INTO @Prices VALUES (1, 1.1050, 1.1052, 0, 0, 0.0002, 12345);

EXEC Price.SetCurrencyPriceBulk @PriceTable = @Prices;
-- Returns: 0 rows (the SELECT 1 WHERE 1<>2 returns nothing)
-- Trade.CurrencyPrice is NOT updated
```

### 8.2 Correct replacement - use active variant

```sql
DECLARE @Prices Price.CurrencyPriceTableWithConversionRate;
-- Populate @Prices with bid/ask/skew/spread/conversion rate data
EXEC Price.SetCurrencyPriceBulkWithConversionRate @PriceTable = @Prices;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 7/10, Logic: 8/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.SetCurrencyPriceBulk | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.SetCurrencyPriceBulk.sql*
