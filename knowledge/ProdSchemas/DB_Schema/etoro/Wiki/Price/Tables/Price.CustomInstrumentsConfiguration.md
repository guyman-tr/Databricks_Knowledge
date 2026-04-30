# Price.CustomInstrumentsConfiguration

> Key-value configuration store for eToro's custom price generator instruments - each row provides a named parameter to a specific instrument's internal price generator, enabling flexible configuration of derived/synthetic price calculations without code changes.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID + Key (CLUSTERED composite PK) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

Price.CustomInstrumentsConfiguration is the parameter store for custom price generators registered in Price.CustomInstruments. Each price generator class (e.g., MainFeedFactorPriceGenerator, SpotInstrumentPriceGenerator) needs configuration to operate - which base instrument to reference, what multiplication factor to apply, which spot key to use, etc. Rather than hard-coding these parameters, they are stored here as named key-value pairs.

The PCS.PriceProvider service reads this table at startup (alongside Price.CustomInstruments) to inject the correct configuration into each instantiated generator. This design allows operations teams to change generator behavior (e.g., point a derived instrument at a different base, adjust a factor) without redeploying the service.

Current live configuration (this environment):
- **InstrumentID 22** (SpotInstrumentPriceGenerator): Key="SpotKey", Value="SpotValue" - likely a placeholder or test value; the SpotKey identifies which spot reference price the generator uses
- **InstrumentID 666** (MainFeedFactorPriceGenerator): Key="BaseInstrumentID", Value="2" AND Key="Factor", Value="0.01" - instrument 666's price = instrument 2's price * 0.01

Data lifecycle: rows are added/updated by pricing operations or tooling when configuring custom instruments. The FK ensures configuration is only added for instruments registered in Trade.Instrument.

---

## 2. Business Logic

### 2.1 Key-Value Configuration Pattern

**What**: Named parameters are read by the corresponding price generator class to configure its behavior.

**Columns/Parameters Involved**: `InstrumentID`, `Key`, `Value`

**Rules**:
- InstrumentID must match a row in Price.CustomInstruments (implicit, via shared FK to Trade.Instrument)
- Key identifies which configuration parameter this row represents (generator-specific)
- Value is always stored as varchar(200) and parsed by the generator into the appropriate type (int, decimal, string, etc.)
- Multiple rows per instrument: one per required parameter for the generator

**Known Key-Value Patterns by Generator**:

| Generator | Key | Value | Meaning |
|---|---|---|---|
| MainFeedFactorPriceGenerator | BaseInstrumentID | "2" (int string) | InstrumentID of the base instrument to derive price from |
| MainFeedFactorPriceGenerator | Factor | "0.01" (decimal string) | Multiplier applied to base instrument's price: DerivedPrice = BasePrice * Factor |
| SpotInstrumentPriceGenerator | SpotKey | "SpotValue" (string) | Identifies the spot reference; "SpotValue" may be a placeholder in this environment |

**Diagram**:
```
Price.CustomInstruments: InstrumentID=666 -> MainFeedFactorPriceGenerator

Price.CustomInstrumentsConfiguration for InstrumentID=666:
  Key="BaseInstrumentID", Value="2"   -> int.Parse("2") = 2 (reference instrument)
  Key="Factor",           Value="0.01" -> decimal.Parse("0.01") = 0.01 (scale)

Generator logic:
  1. Read Trade.CurrencyPrice for InstrumentID=2 (e.g., Bid=1.3050, Ask=1.3052)
  2. Apply factor: DerivedBid = 1.3050 * 0.01 = 0.013050
  3. Publish price for InstrumentID=666: Bid=0.013050, Ask=0.013052
```

### 2.2 Extensibility Without Schema Changes

**What**: New generator parameters can be added without modifying the table schema - just insert new key-value rows.

**Rules**:
- Each generator class defines which keys it expects; missing required keys would cause runtime errors in PCS.PriceProvider
- No enforcement of valid keys at the DB level - validation is in application code
- varchar(200) for Value supports numeric values, strings, lists, or JSON fragments if needed

---

## 3. Data Overview

| InstrumentID | Key | Value | Meaning |
|---|---|---|---|
| 22 | SpotKey | SpotValue | SpotInstrumentPriceGenerator: spot reference identifier. "SpotValue" may be placeholder in this environment. |
| 666 | BaseInstrumentID | 2 | MainFeedFactorPriceGenerator: derive price from Trade.Instrument InstrumentID=2. |
| 666 | Factor | 0.01 | MainFeedFactorPriceGenerator: multiply base instrument price by 0.01 to produce derived price. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | CODE-BACKED | eToro instrument identifier. Part of the composite PK. FK to Trade.Instrument (FK_CusInstConf_TradeInstrument). Must correspond to an instrument also registered in Price.CustomInstruments. Groups all configuration parameters for one generator instance. |
| 2 | Key | varchar(50) | NOT NULL | - | CODE-BACKED | Parameter name for the price generator. Part of the composite PK - one row per key per instrument. Generator-specific: known keys include "BaseInstrumentID" (MainFeedFactorPriceGenerator), "Factor" (MainFeedFactorPriceGenerator), "SpotKey" (SpotInstrumentPriceGenerator). The generator class defines which keys it reads and how it parses them. |
| 3 | Value | varchar(200) | NOT NULL | - | CODE-BACKED | Parameter value stored as a string. The price generator class is responsible for parsing this to the appropriate type (int, decimal, string, etc.). varchar(200) provides capacity for complex values including numeric strings, identifiers, or short JSON fragments. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK (FK_CusInstConf_TradeInstrument) | Configuration is tied to an existing instrument |

### 5.2 Referenced By (other objects point to this)

No SSDT objects reference this table. Read by PCS.PriceProvider application at service startup.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.CustomInstrumentsConfiguration (table)
  |-- FK -> Trade.Instrument
  |-- Companion to: Price.CustomInstruments (registry - defines which generator to use)
  |-- Read by: PCS.PriceProvider (application code)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK - instrument must exist before configuration can be stored |

### 6.2 Objects That Depend On This

No SSDT objects depend on this table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomInstrumentsConfiguration | CLUSTERED PK | InstrumentID ASC, Key ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_CusInstConf_TradeInstrument | FK | InstrumentID -> Trade.Instrument(InstrumentID) |

---

## 8. Sample Queries

### 8.1 View all configuration for custom instruments

```sql
SELECT CIC.InstrumentID, CI.PriceGeneratorType, CIC.[Key], CIC.[Value]
FROM Price.CustomInstrumentsConfiguration CIC WITH (NOLOCK)
JOIN Price.CustomInstruments CI WITH (NOLOCK)
    ON CIC.InstrumentID = CI.InstrumentID
ORDER BY CIC.InstrumentID, CIC.[Key];
```

### 8.2 Find all instruments using a specific base instrument

```sql
SELECT InstrumentID, [Value] AS BaseInstrumentID
FROM Price.CustomInstrumentsConfiguration WITH (NOLOCK)
WHERE [Key] = 'BaseInstrumentID'
ORDER BY InstrumentID;
```

### 8.3 Get factor-based price derivation for instrument 666

```sql
SELECT
    cfg_base.[Value] AS BaseInstrumentID,
    cfg_factor.[Value] AS Factor
FROM Price.CustomInstrumentsConfiguration cfg_base WITH (NOLOCK)
JOIN Price.CustomInstrumentsConfiguration cfg_factor WITH (NOLOCK)
    ON cfg_base.InstrumentID = cfg_factor.InstrumentID
WHERE cfg_base.InstrumentID = 666
  AND cfg_base.[Key] = 'BaseInstrumentID'
  AND cfg_factor.[Key] = 'Factor';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.CustomInstrumentsConfiguration | Type: Table | Source: etoro/etoro/Price/Tables/Price.CustomInstrumentsConfiguration.sql*
