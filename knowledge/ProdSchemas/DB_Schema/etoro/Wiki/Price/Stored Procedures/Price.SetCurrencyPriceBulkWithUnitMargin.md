# Price.SetCurrencyPriceBulkWithUnitMargin

> Bulk UPDATE of Trade.CurrencyPrice (primary price table) with unit margins - identical to SetCurrencyPriceBulkWithConversionRate except USD conversion rate fields (USDConversionRateBidSpreaded, USDConversionRateAskSpreaded, USDConversionPriceRateID) are explicitly set to NULL. Used when conversion rates are not available from the primary feed.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RatesToUpdate (TVP), @ProviderID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.SetCurrencyPriceBulkWithUnitMargin is the primary bulk price update procedure for cases where the pricing feed provides unit margins but not USD conversion rates. It updates Trade.CurrencyPrice with full price, skew, and margin data, but explicitly nullifies the three USD conversion rate fields.

The only behavioral difference from SetCurrencyPriceBulkWithConversionRate:
| Field | WithConversionRate | WithUnitMargin |
|---|---|---|
| USDConversionRateBidSpreaded | From TVP | Explicitly set to NULL |
| USDConversionRateAskSpreaded | From TVP | Explicitly set to NULL |
| USDConversionPriceRateID | From TVP | Explicitly set to NULL |

This is used when the feed provides instrument prices and unit margins but the USD conversion rates are determined separately (e.g., by a separate conversion rate engine or cross-rate calculation) rather than being bundled with the price tick. By nullifying these fields, the procedure signals to consumers that the conversion rates need to be sourced separately.

Both procedures are UPDATE-only (no INSERT), use the same temp table pattern with UNIQUE CLUSTERED INDEX (InstrumentID), and update all other fields identically.

---

## 2. Business Logic

### 2.1 TVP to Temp Table

**What**: Same pattern as SetCurrencyPriceBulkWithConversionRate but with a different TVP type.

**Columns/Parameters Involved**: `@RatesToUpdate`, `#CurrencyPriceTableWithUnitMargin`

**Rules**:
- `CREATE TABLE #CurrencyPriceTableWithUnitMargin ... INDEX CIX UNIQUE CLUSTERED (InstrumentID)`
- TVP type: `Price.CurrencyPriceTableWithUnitMargin` - same as WithConversionRate except WITHOUT the three USD conversion rate columns (USDConversionRateBidSpreaded, USDConversionRateAskSpreaded, USDConversionPriceRateID)
- `INSERT INTO #CurrencyPriceTableWithUnitMargin SELECT * FROM @RatesToUpdate`

### 2.2 UPDATE Trade.CurrencyPrice with NULL Conversion Rates

**What**: Full price field update but conversion rate columns explicitly nullified.

**Columns/Parameters Involved**: `USDConversionRateBidSpreaded`, `USDConversionRateAskSpreaded`, `USDConversionPriceRateID`

**Rules**:
- `FROM Trade.CurrencyPrice CP WITH (NOLOCK) JOIN #CurrencyPriceTableWithUnitMargin RTU ON CP.InstrumentID = RTU.InstrumentID`
- No PriceRateID change guard (same as WithConversionRate)
- `USDConversionRateBidSpreaded = NULL`: explicitly nulls out bid conversion rate
- `USDConversionRateAskSpreaded = NULL`: explicitly nulls out ask conversion rate
- `USDConversionPriceRateID = NULL`: explicitly nulls out conversion rate ID
- All other fields (Bid, Ask, SkewValueBid/Ask, UnitMarginBid/Ask, Discounted prices, timestamps) updated from TVP

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RatesToUpdate | Price.CurrencyPriceTableWithUnitMargin READONLY | NOT NULL | - | CODE-BACKED | TVP with price and unit margin data but no USD conversion rate columns. Same as CurrencyPriceTableWithConversionRate minus the three USD conversion rate fields. |
| 2 | @ProviderID | INT | NOT NULL | - | CODE-BACKED | The primary feed provider ID. Written to Trade.CurrencyPrice.ProviderID. |

**Result set**: None.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RatesToUpdate | Price.CurrencyPriceTableWithUnitMargin | TVP type | Input price tick batch without conversion rates |
| InstrumentID | Trade.CurrencyPrice | WRITER (UPDATE only) | Updates all price fields; explicitly sets USD conversion rate fields to NULL |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (primary pricing engine - without conversion rates) | @RatesToUpdate | CALLER | Called when conversion rates are not bundled with price ticks |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.SetCurrencyPriceBulkWithUnitMargin (procedure)
+-- Price.CurrencyPriceTableWithUnitMargin (UDT) - TVP type
+-- Trade.CurrencyPrice (table) - UPDATE target
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.CurrencyPriceTableWithUnitMargin | User Defined Type | TVP parameter type |
| Trade.CurrencyPrice | Table | UPDATE target - full price update with NULL conversion rates |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (primary pricing engine - margin-only mode) | External | Calls when price ticks do not include USD conversion rates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Creates temp table with UNIQUE CLUSTERED INDEX (InstrumentID) at runtime.

### 7.2 Constraints

No SET NOCOUNT ON. No explicit transaction. No INSERT path. No PriceRateID change guard. Identical to SetCurrencyPriceBulkWithConversionRate except: (1) TVP type lacks USD conversion rate columns, and (2) the three USD conversion rate fields are set to NULL. When to use which procedure: if the pricing engine calculates USD conversion rates as part of each price update, use WithConversionRate; if conversion rates are computed separately or not available at tick time, use WithUnitMargin.

---

## 8. Sample Queries

### 8.1 Update primary prices without conversion rates

```sql
DECLARE @Rates Price.CurrencyPriceTableWithUnitMargin;
INSERT INTO @Rates
    (InstrumentID, Bid, Ask, Occurred, PriceRateID, SkewValueBid, SkewValueAsk,
     UnitMarginBid, UnitMarginAsk)
VALUES (1, 1.10500000, 1.10520000, GETUTCDATE(), 12345, 0, 0, 0.01, 0.01);

EXEC Price.SetCurrencyPriceBulkWithUnitMargin
    @RatesToUpdate = @Rates,
    @ProviderID = 1;
-- USDConversionRateBidSpreaded, USDConversionRateAskSpreaded, USDConversionPriceRateID -> NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.SetCurrencyPriceBulkWithUnitMargin | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.SetCurrencyPriceBulkWithUnitMargin.sql*
