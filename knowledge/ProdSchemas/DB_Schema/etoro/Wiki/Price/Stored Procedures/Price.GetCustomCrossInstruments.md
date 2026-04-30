# Price.GetCustomCrossInstruments

> For a given instrument, finds the two USD-cross helper instruments needed to construct its price - one for the buy currency side and one for the sell currency side - by searching Trade.GetInstrument for pairs that cross through USD (SellCurrencyID=1 or BuyCurrencyID=1).

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID - the instrument whose cross instruments are needed |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetCustomCrossInstruments is a helper procedure for pricing cross-currency instruments. When eToro prices a "custom cross" instrument (one that does not directly trade against USD), it needs intermediate instruments - the "cross instruments" - that each trade against USD. By combining their prices, the pricing engine can derive the cross rate.

For example, to price EUR/GBP (a custom cross), the engine needs EUR/USD and GBP/USD. This procedure finds those two instruments: one for the buy currency (EUR/USD) and one for the sell currency (GBP/USD).

The procedure was updated in May 2019 (per inline code comment: "Ran Ovadia, 02/05/19, Using GetInstrument instead of Instrument") to use `Trade.GetInstrument` (a view) instead of `Trade.Instrument` directly. This likely provided additional filtering or logic in the view layer.

The result is two rows (one per SELECT/UNION arm), each identifying: the USD-cross instrument ID, which side it represents (BuyCurrency=1 for the buy-side cross, BuyCurrency=0 for the sell-side cross), whether the relationship is reciprocal (IsReciprocal), and its InstrumentTypeID for type validation.

---

## 2. Business Logic

### 2.1 Currency Pair Extraction

**What**: First, extract the base and quote currencies from the target instrument.

**Columns/Parameters Involved**: `@InstrumentID`, `@BuyCurrencyID`, `@SellCurrencyID`

**Rules**:
- `SELECT @BuyCurrencyID = BuyCurrencyID, @SellCurrencyID = SellCurrencyID FROM Trade.Instrument WHERE InstrumentID = @InstrumentID`
- No error handling if @InstrumentID does not exist - variables remain NULL, queries return no rows

### 2.2 USD-Cross Instrument Discovery

**What**: Two UNION SELECT arms find the instruments that cross each of the target's currencies to USD (CurrencyID=1).

**Columns/Parameters Involved**: `@BuyCurrencyID`, `@SellCurrencyID`, `IsReciprocal`, `BuyCurrency`

**Rules**:

**Arm 1 (BuyCurrency=1 - buy-side cross)**:
- Finds TOP 1 instrument where:
  - `(BuyCurrencyID = @BuyCurrencyID AND SellCurrencyID = 1)` - direct: e.g., EUR/USD for EUR
  - OR `(SellCurrencyID = @BuyCurrencyID AND BuyCurrencyID = 1)` - reciprocal: e.g., USD/EUR
- `IsReciprocal = CASE WHEN BuyCurrencyID = @BuyCurrencyID THEN 0 ELSE 1 END`
  - 0 = direct (BuyCurrency matches @BuyCurrencyID - no inversion needed)
  - 1 = reciprocal (need to invert the price: 1/rate)

**Arm 2 (BuyCurrency=0 - sell-side cross)**:
- Same logic but using @SellCurrencyID to find the sell-side USD cross instrument

**Diagram**:
```
Target: EUR/GBP (@InstrumentID)
  @BuyCurrencyID = 3 (EUR)
  @SellCurrencyID = 5 (GBP)

Arm 1 -> finds EUR/USD (InstrumentID=1, BuyCurrency=1, IsReciprocal=0)
         because: BuyCurrencyID=3(EUR) AND SellCurrencyID=1(USD) - direct match

Arm 2 -> finds GBP/USD (InstrumentID=2, BuyCurrency=0, IsReciprocal=0)
         because: BuyCurrencyID=5(GBP) AND SellCurrencyID=1(USD) - direct match

Pricing engine then: EUR/GBP price = EUR/USD rate / GBP/USD rate
```

### 2.3 IsReciprocal Flag

**What**: Tells the pricing engine whether it needs to invert the cross rate.

**Rules**:
- IsReciprocal=0: the cross instrument directly represents the target's currency vs USD (e.g., EUR/USD for EUR) - use rate as-is
- IsReciprocal=1: the cross instrument has the currencies reversed (e.g., USD/EUR instead of EUR/USD) - the pricing engine must invert: cross_rate = 1 / instrument_rate

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NOT NULL | - | CODE-BACKED | The custom cross instrument for which USD-cross helper instruments are needed. The procedure extracts its BuyCurrencyID and SellCurrencyID from Trade.Instrument, then searches Trade.GetInstrument for matching USD pairs. No validation - if the InstrumentID does not exist, returns empty result set. |

**Result set columns** (4 columns):

| # | Column | Description |
|---|--------|-------------|
| 1 | InstrumentID | The USD-cross instrument that can provide the pricing leg (e.g., EUR/USD or GBP/USD) |
| 2 | BuyCurrency | 1 = this is the buy-side (base currency) cross instrument; 0 = sell-side (quote currency) cross instrument |
| 3 | IsReciprocal | 0 = direct rate (use as-is); 1 = reciprocal (invert: use 1/rate) - indicates the USD-cross instrument has inverted currency order |
| 4 | InstrumentTypeID | Instrument type of the USD-cross instrument, used by the pricing engine to select appropriate rate calculation logic |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.Instrument | SELECT | Extracts BuyCurrencyID and SellCurrencyID for the target instrument |
| BuyCurrencyID, SellCurrencyID | Trade.GetInstrument | SELECT (UNION) | Finds USD-cross instruments by currency pair matching; 2019 update replaced direct Instrument table with this view |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (pricing engine) | @InstrumentID | CALLER | Called when constructing prices for custom cross instruments that don't directly trade against USD |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetCustomCrossInstruments (procedure)
+-- Trade.Instrument (table) - BuyCurrencyID, SellCurrencyID lookup
+-- Trade.GetInstrument (view) - USD-cross instrument search
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | SELECT - extracts BuyCurrencyID and SellCurrencyID for the input instrument |
| Trade.GetInstrument | View | SELECT UNION - searches for instruments that cross the target currencies through USD |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (pricing engine) | External | Calls this when computing prices for cross-currency instruments |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

No NOLOCK on the initial Trade.Instrument SELECT (reads with shared locks). Trade.GetInstrument SELECTs have no NOLOCK either. The UNION combines two TOP 1 results - one per currency direction. TOP 1 without ORDER BY means the "best" cross instrument is nondeterministic if multiple candidates exist. In practice, each currency typically has exactly one USD pair, so TOP 1 is sufficient. The 2019 comment "Using GetInstrument instead of Instrument" indicates this was changed from a direct table read to a view read - likely to include additional filtering (e.g., active-only instruments).

---

## 8. Sample Queries

### 8.1 Find cross instruments for EUR/GBP

```sql
EXEC Price.GetCustomCrossInstruments @InstrumentID = (
    SELECT InstrumentID FROM Trade.Instrument WITH (NOLOCK)
    WHERE BuyCurrencyID = 3 AND SellCurrencyID = 5
);
```

### 8.2 Equivalent manual query for a specific instrument

```sql
DECLARE @BuyCurrencyID INT, @SellCurrencyID INT;
SELECT @BuyCurrencyID = BuyCurrencyID, @SellCurrencyID = SellCurrencyID
FROM Trade.Instrument WITH (NOLOCK)
WHERE InstrumentID = 1234;

-- Buy-side cross
SELECT TOP 1 InstrumentID, 1 AS BuyCurrency,
    CASE WHEN BuyCurrencyID = @BuyCurrencyID THEN 0 ELSE 1 END AS IsReciprocal,
    InstrumentTypeID
FROM Trade.GetInstrument WITH (NOLOCK)
WHERE (BuyCurrencyID = @BuyCurrencyID AND SellCurrencyID = 1)
   OR (SellCurrencyID = @BuyCurrencyID AND BuyCurrencyID = 1)
UNION
-- Sell-side cross
SELECT TOP 1 InstrumentID, 0 AS BuyCurrency,
    CASE WHEN BuyCurrencyID = @SellCurrencyID THEN 0 ELSE 1 END AS IsReciprocal,
    InstrumentTypeID
FROM Trade.GetInstrument WITH (NOLOCK)
WHERE (BuyCurrencyID = @SellCurrencyID AND SellCurrencyID = 1)
   OR (SellCurrencyID = @SellCurrencyID AND BuyCurrencyID = 1);
```

### 8.3 List all custom cross instruments (those without a direct USD leg)

```sql
SELECT InstrumentID, BuyCurrencyID, SellCurrencyID
FROM Trade.Instrument WITH (NOLOCK)
WHERE BuyCurrencyID <> 1 AND SellCurrencyID <> 1
ORDER BY InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetCustomCrossInstruments | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.GetCustomCrossInstruments.sql*
