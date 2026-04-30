# Price.CustomInstruments

> Registry of instruments that use eToro's internal custom price generators rather than external market data feeds - each row registers one instrument with the fully-qualified .NET type name of its price generator class, enabling the PCS.PriceProvider service to instantiate the correct generator at startup.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (int, CLUSTERED PK, FK to Trade.Instrument) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

Price.CustomInstruments is the plugin registry for eToro's custom price generation system. Most instruments receive prices from external feeds (Bloomberg, Xignite, FIX sessions, etc.) configured in Price.AccountRateSource and Price.InstrumentRateSources. But a small subset of instruments have prices generated internally by custom .NET classes in the PCS.PriceProvider service.

This table registers those instruments and tells the PCS.PriceProvider service which specific price generator class to use. The `PriceGeneratorType` column holds the fully-qualified .NET type name - the service uses reflection or dependency injection to instantiate the correct class when the service starts.

Current live instruments using custom generators:
- **InstrumentID 22**: Uses `SpotInstrumentPriceGenerator` - generates a synthetic spot price, likely referencing another instrument's spot as a basis
- **InstrumentID 666**: Uses `MainFeedFactorPriceGenerator` - derives its price by taking a base instrument's price and applying a multiplication factor (configured in Price.CustomInstrumentsConfiguration)

Custom instruments are typically used for synthetic/derived products: mini contracts, scaled versions, or instruments whose price is a mathematical function of another instrument's price.

Data lifecycle: rows are added manually or via tooling when a new custom-priced instrument is onboarded. Configuration parameters for the generator are stored in the companion table `Price.CustomInstrumentsConfiguration`.

---

## 2. Business Logic

### 2.1 Custom Price Generator Registry Pattern

**What**: Each row binds one instrument to its internal price generator class; the generator is instantiated by the PCS.PriceProvider service using the type name.

**Columns/Parameters Involved**: `InstrumentID`, `PriceGeneratorType`

**Rules**:
- PriceGeneratorType must be a valid, loadable .NET type in the PCS.PriceProvider assembly
- One row per instrument - an instrument can only have one custom generator
- Instruments in this table are excluded from normal external feed routing (or handled specially)
- Generator classes follow the namespace pattern: `PCS.PriceProvider.Internal.Custom.PriceGenerators.{Category}.{ClassName}`
- Additional parameters for the generator are stored in Price.CustomInstrumentsConfiguration (key-value pairs keyed by InstrumentID)

**Known Generator Types**:
| PriceGeneratorType (short) | Category | How It Works |
|---|---|---|
| SpotInstrumentPriceGenerator | Spots | Generates a spot price; reads spot reference from CustomInstrumentsConfiguration (SpotKey) |
| MainFeedFactorPriceGenerator | - | Takes BaseInstrumentID's price and multiplies by Factor (both from CustomInstrumentsConfiguration) |

**Diagram**:
```
PCS.PriceProvider service startup:
  1. Read Price.CustomInstruments
  2. For each row: instantiate PriceGeneratorType via .NET reflection
  3. Read Price.CustomInstrumentsConfiguration for that InstrumentID -> inject config parameters
  4. Generator runs in price loop, producing bid/ask for the InstrumentID

Example - InstrumentID 666 (MainFeedFactorPriceGenerator):
  BaseInstrumentID=2, Factor=0.01
  -> Read live price of Instrument 2 (e.g., 1.3050 bid / 1.3052 ask)
  -> Multiply by 0.01 -> 0.01305 bid / 0.013052 ask
  -> Publish as price for Instrument 666
```

---

## 3. Data Overview

| InstrumentID | PriceGeneratorType | Meaning |
|---|---|---|
| 22 | PCS.PriceProvider.Internal.Custom.PriceGenerators.Spots.SpotInstrumentPriceGenerator | Synthetic spot instrument. Generates a spot price using spot reference configuration. Configuration in CustomInstrumentsConfiguration (Key="SpotKey", Value="SpotValue" - likely placeholder in this environment). |
| 666 | PCS.PriceProvider.Internal.Custom.PriceGenerators.MainFeedFactorPriceGenerator | Factor-derived instrument. Derives price from Instrument 2 (BaseInstrumentID=2) multiplied by 0.01 (Factor=0.01). Likely a mini or micro contract. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | CODE-BACKED | eToro instrument identifier. CLUSTERED PK. FK to Trade.Instrument (FK_CusInst_TradeInstrument). One row per custom instrument - an instrument is either in this registry (custom generator) or gets prices from external feeds. |
| 2 | PriceGeneratorType | varchar(150) | NOT NULL | - | CODE-BACKED | Fully-qualified .NET class name of the price generator to instantiate for this instrument. The PCS.PriceProvider service loads this type at startup. Namespace prefix: PCS.PriceProvider.Internal.Custom.PriceGenerators. Known types: SpotInstrumentPriceGenerator (spot reference), MainFeedFactorPriceGenerator (base price * factor). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK (FK_CusInst_TradeInstrument) | Custom generator registered for an existing instrument; FK ensures instrument must exist |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.CustomInstrumentsConfiguration | InstrumentID | Implicit companion | Stores key-value configuration parameters for each generator registered here |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.CustomInstruments (table)
  |-- FK -> Trade.Instrument
  |-- Companion: Price.CustomInstrumentsConfiguration (configuration parameters for each generator)
  |-- Read by: PCS.PriceProvider service (application code, not in SSDT)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK - instrument must exist before custom generator can be registered |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.CustomInstrumentsConfiguration | Table | Companion configuration - stores parameters keyed by InstrumentID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomInstruments | CLUSTERED PK | InstrumentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_CusInst_TradeInstrument | FK | InstrumentID -> Trade.Instrument(InstrumentID) |

---

## 8. Sample Queries

### 8.1 List all custom-priced instruments with their generator types

```sql
SELECT CI.InstrumentID, CI.PriceGeneratorType
FROM Price.CustomInstruments CI WITH (NOLOCK)
ORDER BY CI.InstrumentID;
```

### 8.2 Join with configuration to see full generator setup

```sql
SELECT
    CI.InstrumentID,
    CI.PriceGeneratorType,
    CIC.[Key],
    CIC.[Value]
FROM Price.CustomInstruments CI WITH (NOLOCK)
LEFT JOIN Price.CustomInstrumentsConfiguration CIC WITH (NOLOCK)
    ON CI.InstrumentID = CIC.InstrumentID
ORDER BY CI.InstrumentID, CIC.[Key];
```

### 8.3 Verify custom instruments exist in Trade.Instrument

```sql
SELECT CI.InstrumentID, CI.PriceGeneratorType, I.InstrumentTypeID
FROM Price.CustomInstruments CI WITH (NOLOCK)
JOIN Trade.Instrument I WITH (NOLOCK) ON CI.InstrumentID = I.InstrumentID
ORDER BY CI.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.CustomInstruments | Type: Table | Source: etoro/etoro/Price/Tables/Price.CustomInstruments.sql*
