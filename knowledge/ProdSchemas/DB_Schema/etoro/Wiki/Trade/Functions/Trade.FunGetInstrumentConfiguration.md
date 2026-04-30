# Trade.FunGetInstrumentConfiguration

> Returns instrument configuration for a given liquidity provider — precision, type, and ticker mapping — with LPID-specific logic: LPID 69 uses TradonomiContracts, others use LiquidityProviderContracts.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns TABLE with InstrumentID, Precision, InstrumentTypeID, Ticker |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FunGetInstrumentConfiguration returns the instrument configuration visible to a specific liquidity provider (LP). For each instrument that the LP supports, it provides the decimal precision, asset type, and the LP-specific ticker symbol. This powers hedge routing, price feed subscription, and instrument pickers in provider-specific contexts.

The function exists because different LPs use different ticker conventions and support different instrument subsets. LPID 69 (Tradonomi) uses Trade.TradonomiContracts for ticker mapping; all other LPs use Trade.LiquidityProviderContracts. The CASE expression picks the correct ticker source: TradonomiContracts.Description when LPID=69, else LiquidityProviderContracts.Ticker when LPID<>69.

Data flows: the function is called by Trade.GetInstrumentConfigurationWrapper, which uses it to build the instrument list for a given LP. BI and operational tools may query it for provider-specific instrument catalogs.

---

## 2. Business Logic

### 2.1 LPID-Specific Contract Source

**What**: LPID 69 (Tradonomi) vs all other LPs use different contract tables for ticker resolution.

**Columns/Parameters Involved**: `@LPID`

**Rules**:
- `@LPID = 69` → use Trade.TradonomiContracts for ticker (Description column)
- `@LPID <> 69` → use Trade.LiquidityProviderContracts for ticker (Ticker column)
- The WHERE clause ensures only instruments with a matching contract row are returned: `(TC1.LiquidityProviderID IS NOT NULL AND @LPID <> 69) OR (TC.InstrumentID IS NOT NULL AND @LPID = 69)`

**Diagram**:
```
@LPID
  │
  ├── 69  → TradonomiContracts (Description) — futures/commodity contracts
  └── ≠69 → LiquidityProviderContracts (Ticker) — FXCM, FD, etc.
```

### 2.2 Ticker Fallback

**What**: Ticker column uses Description when available, else contract ticker.

**Columns/Parameters Involved**: `TradonomiContracts.Description`, `LiquidityProviderContracts.Ticker`

**Rules**: `CASE WHEN Description IS NULL THEN TC1.Ticker ELSE Description END` — for LPID=69, Description from TradonomiContracts; for LPID<>69, TC1.Ticker from LiquidityProviderContracts (TC1 joined only when LPID<>69).

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LPID | INT | NO | - | CODE-BACKED | Liquidity Provider ID. 69 = Tradonomi (uses TradonomiContracts), others use LiquidityProviderContracts. |
| 2 | InstrumentID (return) | INT | NO | - | CODE-BACKED | Instrument identifier. From Trade.ProviderToInstrument. |
| 3 | Precision (return) | TINYINT | YES | - | CODE-BACKED | Decimal precision for the instrument. From Trade.ProviderToInstrument. |
| 4 | InstrumentTypeID (return) | INT | YES | - | CODE-BACKED | Asset class. From Dictionary.Currency.CurrencyTypeID via Instrument.BuyCurrencyID. See [Currency Type](_glossary.md#currency-type). |
| 5 | Ticker (return) | varchar | YES | - | CODE-BACKED | LP-specific ticker. TradonomiContracts.Description (LPID=69) or LiquidityProviderContracts.Ticker (LPID<>69). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.ProviderToInstrument | JOIN | Provider-instrument mapping |
| InstrumentID | Trade.Instrument | JOIN | Buy/sell currency pairing |
| BuyCurrencyID | Dictionary.Currency | JOIN | Asset type (CurrencyTypeID) |
| InstrumentID | Trade.InstrumentMetaData | JOIN | Extended metadata |
| InstrumentID | Trade.TradonomiContracts | LEFT JOIN | Contract ticker when LPID=69 |
| InstrumentID | Trade.LiquidityProviderContracts | LEFT JOIN | Contract ticker when LPID<>69 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetInstrumentConfigurationWrapper | FROM | Procedure reference | Wraps function for LP instrument list |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FunGetInstrumentConfiguration (function)
├── Trade.ProviderToInstrument (table)
├── Trade.Instrument (table)
├── Dictionary.Currency (table)
├── Trade.InstrumentMetaData (table)
├── Trade.TradonomiContracts (table) [conditional: LPID=69]
└── Trade.LiquidityProviderContracts (table) [conditional: LPID<>69]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | Precision, instrument list |
| Trade.Instrument | Table | BuyCurrencyID for currency lookup |
| Dictionary.Currency | Table | CurrencyTypeID (asset class) |
| Trade.InstrumentMetaData | Table | Extended metadata (join only) |
| Trade.TradonomiContracts | Table | Ticker when LPID=69 |
| Trade.LiquidityProviderContracts | Table | Ticker when LPID<>69 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrumentConfigurationWrapper | Procedure | FROM clause for LP instrument configuration |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS TABLE | Return type | Inline TVF returning 4 columns |
| LEFT JOIN + WHERE | Logic | Mutually exclusive contract source per LPID |

---

## 8. Sample Queries

### 8.1 Get instrument configuration for liquidity provider 2

```sql
SELECT  InstrumentID, Precision, InstrumentTypeID, Ticker
FROM    Trade.FunGetInstrumentConfiguration(2) WITH (NOLOCK)
ORDER BY InstrumentID;
```

### 8.2 Get Tradonomi (LPID 69) instrument configuration

```sql
SELECT  InstrumentID, Precision, InstrumentTypeID, Ticker
FROM    Trade.FunGetInstrumentConfiguration(69) WITH (NOLOCK)
ORDER BY InstrumentTypeID, InstrumentID;
```

### 8.3 Join to instrument metadata for display names

```sql
SELECT  gic.InstrumentID, gic.Ticker, gic.Precision, im.InstrumentDisplayName
FROM    Trade.FunGetInstrumentConfiguration(2) gic WITH (NOLOCK)
        LEFT JOIN Trade.InstrumentMetaData im WITH (NOLOCK) ON im.InstrumentID = gic.InstrumentID
ORDER BY im.InstrumentDisplayName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: DDL + Dependency docs*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 consumer | Dependencies: Tables documented | Corrections: 0 applied*
*Object: Trade.FunGetInstrumentConfiguration | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.FunGetInstrumentConfiguration.sql*
