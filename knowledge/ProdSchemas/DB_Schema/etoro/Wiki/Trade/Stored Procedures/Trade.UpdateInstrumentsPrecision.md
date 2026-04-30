# Trade.UpdateInstrumentsPrecision

> Updates the price display precision settings (Precision and AboveDollarPrecision) on Trade.ProviderToInstrument for a batch of instruments, controlling how many decimal places are shown when displaying instrument prices to users.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentNewConfigTable.InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Precision and AboveDollarPrecision control how instrument prices are displayed to customers across all eToro platforms. Precision determines the number of decimal places for prices below $1 (e.g., crypto or penny stocks where 8 decimal places may be needed), while AboveDollarPrecision controls the number of decimal places for prices at or above $1 (e.g., a stock trading at $150.25 might use 2 decimal places). Together, they define the visual formatting contract between the database and the client.

Both fields are consumed by the Market Data API and TAPI Public endpoints, making them part of the publicly-facing instrument configuration. Incorrect precision values result in prices being displayed with too many or too few decimal places, which affects user trust and readability across the trading UI, watchlist, and order placement screens.

This procedure is called directly by external operational tooling (no callers found in the Trade stored procedure layer), suggesting it is invoked from an administrative interface or configuration management system when precision values are updated from a data provider feed or manual configuration change.

---

## 2. Business Logic

### 2.1 Dual-Range Precision Control

**What**: Two separate precision fields handle the display of prices in different value ranges - one for sub-dollar prices, one for above-dollar prices.

**Columns/Parameters Involved**: `@InstrumentNewConfigTable.ConfigurationValue` (maps to Precision), `@InstrumentNewConfigTable.AboveDollarPrecision`

**Rules**:
- ConfigurationValue maps to Trade.ProviderToInstrument.Precision - the number of decimal places for prices below $1
- AboveDollarPrecision - the number of decimal places for prices at or above $1
- Both are TINYINT (0-255 range), meaning values like 2, 4, 5, or 8 are typical
- Both are applied atomically in a single UPDATE statement per instrument
- The separation exists because many instruments (especially crypto) have very different precision requirements for micro-price vs macro-price ranges

**Diagram**:
```
Price display logic (in consuming APIs):
  If price < $1.00  --> use Precision decimal places
  If price >= $1.00 --> use AboveDollarPrecision decimal places

Example: Bitcoin
  Precision = 2 (price below $1 rarely happens but stored for completeness)
  AboveDollarPrecision = 2 (BTC/USD displayed as $87,234.56)

Example: Low-cap crypto token
  Precision = 8 (e.g., 0.00000123 displayed with 8 decimal places)
  AboveDollarPrecision = 4 (if price rises above $1, show 4 decimals)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentNewConfigTable | Trade.InstrumentPrecisionConfigTable (TVP, READONLY) | NO | - | CODE-BACKED | Batch of precision configuration updates. Contains InstrumentID (key), ConfigurationValue (tinyint, NOT NULL - new value for Trade.ProviderToInstrument.Precision, number of decimal places for sub-dollar prices), and AboveDollarPrecision (tinyint, NOT NULL - new value for Trade.ProviderToInstrument.AboveDollarPrecision, number of decimal places for prices above $1). All three columns are required. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentNewConfigTable.InstrumentID | Trade.ProviderToInstrument | Implicit JOIN | Updates Precision (from ConfigurationValue) and AboveDollarPrecision for matching instruments |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External configuration tooling | Application call | Caller | No internal SP callers found; called directly from an administrative or configuration management system |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInstrumentsPrecision (procedure)
└── Trade.ProviderToInstrument (table) [UPDATE - Precision and AboveDollarPrecision columns]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | UPDATEd: Precision set from ConfigurationValue, AboveDollarPrecision set from AboveDollarPrecision column |
| Trade.InstrumentPrecisionConfigTable | User Defined Type | TVP type for @InstrumentNewConfigTable |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Market Data API | External consumer | Reads Precision and AboveDollarPrecision from ProviderToInstrument to format prices for client display |
| TAPI Public | External consumer | Reads both precision fields for public trading API instrument responses |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Both precision values required | TVP design | ConfigurationValue and AboveDollarPrecision are NOT NULL in the TVP type - caller must provide both values for every instrument |
| Atomic transaction | TRY/CATCH | Single UPDATE in BEGIN TRAN / COMMIT. ROLLBACK on error, COMMIT on nested transactions (@@TRANCOUNT > 1). |
| SET NOCOUNT ON | Session setting | Suppresses row-count messages. |

---

## 8. Sample Queries

### 8.1 Update precision for a single instrument

```sql
DECLARE @Config [Trade].[InstrumentPrecisionConfigTable]
INSERT INTO @Config (InstrumentID, ConfigurationValue, AboveDollarPrecision)
VALUES (1234, 8, 2)  -- 8 decimal places below $1, 2 decimal places above $1

EXEC Trade.UpdateInstrumentsPrecision
    @InstrumentNewConfigTable = @Config
```

### 8.2 Batch update precision for multiple instruments

```sql
DECLARE @Config [Trade].[InstrumentPrecisionConfigTable]
INSERT INTO @Config (InstrumentID, ConfigurationValue, AboveDollarPrecision)
VALUES
    (1234, 8, 2),   -- Crypto: high precision sub-dollar, 2 places above
    (5678, 2, 2),   -- Stock: 2 decimal places in both ranges
    (9012, 5, 4)    -- Forex: 5 places sub-dollar, 4 places above

EXEC Trade.UpdateInstrumentsPrecision
    @InstrumentNewConfigTable = @Config
```

### 8.3 Check current precision settings for instruments

```sql
SELECT
    tpti.InstrumentID,
    timd.InstrumentDisplayName,
    tpti.Precision,
    tpti.AboveDollarPrecision
FROM Trade.ProviderToInstrument tpti WITH (NOLOCK)
LEFT JOIN Trade.InstrumentMetaData timd WITH (NOLOCK) ON timd.InstrumentID = tpti.InstrumentID
WHERE tpti.InstrumentID IN (1234, 5678)
ORDER BY tpti.InstrumentID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Instrument property sources](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/13102743707/Instrument+property+sources) | Confluence | Confirms Precision and AboveDollarPrecision are exposed via Market Data API and TAPI Public endpoints, making them client-facing display properties |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 1 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInstrumentsPrecision | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInstrumentsPrecision.sql*
