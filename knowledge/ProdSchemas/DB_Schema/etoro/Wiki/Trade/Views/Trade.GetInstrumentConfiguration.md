# Trade.GetInstrumentConfiguration

> Instrument configuration view that returns InstrumentID, Precision, InstrumentTypeID, and Ticker by joining ProviderToInstrument, Instrument, Dictionary.Currency, InstrumentMetaData, and TradonomiContracts.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID (from ProviderToInstrument) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentConfiguration exposes a compact instrument configuration dataset: InstrumentID, Precision (decimal places), InstrumentTypeID (asset class from Dictionary.Currency), and Ticker (human-readable symbol from TradonomiContracts.Description). It answers: "What are the trading parameters and display ticker for each instrument?" The view joins Trade.ProviderToInstrument as the driver, then Trade.Instrument, Dictionary.Currency (on BuyCurrencyID for CurrencyTypeID), Trade.InstrumentMetaData, and Trade.TradonomiContracts. Only instruments that have a Tradonomi contract appear (INNER JOIN to TradonomiContracts).

The view exists to provide a lightweight configuration feed for systems that need instrument ID, precision, type, and ticker without full metadata. Trade.FunGetInstrumentConfiguration is a parameterized function with similar logic (filtered by @LPID) that procedures like Trade.GetInstrumentConfigurationWrapper call. The view itself has no direct procedure references in the repo but may be used by APIs or reporting.

Data flows: The view reads from ProviderToInstrument (one row per ProviderID, InstrumentID), JOINs to Instrument, Dictionary.Currency (CurrencyID = BuyCurrencyID for CurrencyTypeID), InstrumentMetaData, and TradonomiContracts. Because ProviderToInstrument is the driver and there is no ProviderID filter, the view returns one row per (ProviderID, InstrumentID) that has a matching Tradonomi contract. Live sample shows Precision 2-4, InstrumentTypeID=5 (Stocks), Ticker as symbols (PFE, ZNGA, YHOO, AMZN, MSFT).

---

## 2. Business Logic

### 2.1 Precision from ProviderToInstrument

**What**: Precision (decimal places for price display) comes from the provider-instrument configuration.

**Columns/Parameters Involved**: `Precision`, `TPTI` (ProviderToInstrument)

**Rules**:
- Precision is provider-specific; same instrument can have different Precision per provider
- Used for rounding prices and position amounts in the UI and execution engine

### 2.2 InstrumentTypeID from Currency

**What**: InstrumentTypeID is sourced from Dictionary.Currency.CurrencyTypeID (via BuyCurrencyID), not from InstrumentMetaData.InstrumentTypeID.

**Columns/Parameters Involved**: `CurrencyTypeID AS InstrumentTypeID`, `DC.CurrencyID`, `TI.BuyCurrencyID`

**Rules**:
- JOIN Dictionary.Currency DC ON DC.CurrencyID = TI.BuyCurrencyID
- CurrencyTypeID from Dictionary.Currency defines asset class (1=Forex, 5=Stocks, 10=Crypto, etc.)

### 2.3 Ticker from TradonomiContracts

**What**: Ticker is the human-readable symbol from the Tradonomi contract (TC.Description).

**Columns/Parameters Involved**: `Description AS [Ticker]`, `TC.InstrumentID`

**Rules**:
- TC.Description holds symbols like EURUSD, PFE, MSFT
- INNER JOIN to TradonomiContracts means only instruments with a contract appear

---

## 3. Data Overview

| InstrumentID | Precision | InstrumentTypeID | Ticker | Meaning |
|---|---|---|---|---|
| 1028 | 4 | 5 | PFE | Pfizer stock. Precision=4, InstrumentTypeID=5 (Stocks). Ticker from Tradonomi contract. |
| 1007 | 4 | 5 | ZNGA | Zynga stock. Same precision and type. |
| 1006 | 2 | 5 | YHOO | Yahoo stock. Precision=2 (different rounding than PFE). |
| 1005 | 4 | 5 | AMZN | Amazon stock. |
| 1004 | 4 | 5 | MSFT | Microsoft stock. |

**Selection criteria**: Picked from live MCP sample. All stocks (InstrumentTypeID=5) showing Precision variety (2 vs 4) and ticker symbols.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | From TI (Trade.Instrument). Tradeable instrument. Same as TPTI.InstrumentID. |
| 2 | Precision | tinyint | NO | - | CODE-BACKED | From TPTI (ProviderToInstrument). Decimal places for price display and rounding. Provider-specific. |
| 3 | InstrumentTypeID | int | NO | - | CODE-BACKED | From DC.CurrencyTypeID (Dictionary.Currency via BuyCurrencyID). Asset class: 1=Forex, 5=Stocks, 10=Crypto, etc. Aliased from CurrencyTypeID. |
| 4 | Ticker | varchar(150) | YES | - | CODE-BACKED | From TC.Description (Trade.TradonomiContracts). Human-readable symbol (e.g., EURUSD, PFE, MSFT). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Lookup | Base instrument |
| Precision | Trade.ProviderToInstrument | Lookup | Provider-instrument config |
| InstrumentTypeID | Dictionary.Currency (CurrencyTypeID) | Lookup | Asset class |
| Ticker | Trade.TradonomiContracts | Lookup | Contract description/symbol |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetInstrumentConfigurationsByPriceServerID | Possible | Reader | Procedure name suggests config by price server; may reference view or function |
| Trade.FunGetInstrumentConfiguration | Similar logic | Function | Parameterized version with @LPID filter |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentConfiguration (view)
├── Trade.ProviderToInstrument (table)
├── Trade.Instrument (table)
├── Dictionary.Currency (table)
├── Trade.InstrumentMetaData (table)
└── Trade.TradonomiContracts (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | FROM - driver table |
| Trade.Instrument | Table | JOIN on InstrumentID |
| Dictionary.Currency | Table | JOIN on CurrencyID = BuyCurrencyID |
| Trade.InstrumentMetaData | Table | JOIN on InstrumentID |
| Trade.TradonomiContracts | Table | JOIN on InstrumentID (INNER - required) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrumentConfigurationsByPriceServerID | Procedure | May reference view |
| Trade.FunGetInstrumentConfiguration | Function | Similar logic, parameterized |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get configuration for specific instruments
```sql
SELECT InstrumentID, Precision, InstrumentTypeID, Ticker
  FROM Trade.GetInstrumentConfiguration WITH (NOLOCK)
 WHERE InstrumentID IN (1004, 1005, 1006)
```

### 8.2 Stock instruments only
```sql
SELECT InstrumentID, Precision, Ticker
  FROM Trade.GetInstrumentConfiguration WITH (NOLOCK)
 WHERE InstrumentTypeID = 5
 ORDER BY Ticker
```

### 8.3 Resolve InstrumentTypeID to asset class name
```sql
SELECT GIC.InstrumentID, GIC.Precision, GIC.Ticker,
       CT.Name AS AssetClassName
  FROM Trade.GetInstrumentConfiguration GIC WITH (NOLOCK)
  LEFT JOIN Dictionary.CurrencyType CT WITH (NOLOCK)
    ON GIC.InstrumentTypeID = CT.CurrencyTypeID
 WHERE GIC.InstrumentID <= 1100
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.2/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 direct refs | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetInstrumentConfiguration | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetInstrumentConfiguration.sql*
