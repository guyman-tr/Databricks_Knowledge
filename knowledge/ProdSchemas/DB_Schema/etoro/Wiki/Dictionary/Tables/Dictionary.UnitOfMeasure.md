# Dictionary.UnitOfMeasure

> Lookup table defining the physical or monetary units used to measure quantities for traded instruments — from commodity barrels and troy ounces to cryptocurrency tokens and fiat currency units.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (TINYINT, manually assigned) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 clustered (PK on ID) |

---

## 1. Business Meaning

Dictionary.UnitOfMeasure defines the base measurement unit for each type of traded instrument. When the platform displays position sizes, calculates lot values, or computes margin requirements, it needs to know what "one unit" of an instrument represents — a barrel of oil, a troy ounce of gold, one Bitcoin, or one euro.

Without this table, the system could not correctly display or calculate quantities in their natural units. A position in crude oil measured in barrels is fundamentally different from a position in gold measured in troy ounces, even though both are stored as numeric values. This table provides the semantic mapping between raw numbers and their real-world physical or monetary meaning.

The table is consumed by Trade.InsertInstrumentRealTable and Trade.CheckValidInstruments during instrument configuration, and by Trade.FuturesMetaData which stores per-instrument metadata including the unit of measure. Trade.ReturnInstruemtFirstConfigurationNew also references it when building instrument configuration data.

---

## 2. Business Logic

### 2.1 Instrument Unit Classification

**What**: Each traded instrument has a specific unit of measure that defines what "one unit" represents in the real world.

**Columns/Parameters Involved**: `ID`, `Value`

**Rules**:
- Commodities use physical units: Barrel (oil), Troy Ounce (gold/silver), MMBtu (natural gas), Pounds (copper/cocoa), Short Tons (coal/sugar)
- Fiat currencies use monetary units: Euros, Australian Dollars, British Pounds
- Cryptocurrencies use token units: Bitcoin, Ether, SOL, XRP
- ID 0 (Points) is the default/abstract unit for index-based instruments where position size is measured in index points rather than physical units
- The unit determines how lot size calculations translate to real-world quantities and display formatting

**Diagram**:
```
Unit Categories:
  ┌─────────────────────────────────────────────────┐
  │  Abstract:  0=Points (indices, synthetic)        │
  │  Energy:    1=Barrel, 3=MMBtu                    │
  │  Metals:    2=Troy Ounce                         │
  │  Agri:      4=Pounds, 5=Short Tons               │
  │  Fiat:      6=Euros, 7=AUD, 8=GBP               │
  │  Crypto:    9=Ether, 10=Bitcoin, 11=SOL, 12=XRP  │
  └─────────────────────────────────────────────────┘
```

---

## 3. Data Overview

| ID | Value | Meaning |
|---|---|---|
| 0 | Points | Abstract measurement for index instruments (S&P 500, NASDAQ) — one unit equals one index point in position size calculations |
| 1 | Barrel | Standard petroleum measurement — used for crude oil (WTI, Brent) contracts where one unit represents one barrel (~159 liters) |
| 2 | Troy Ounce | Precious metals standard — used for gold, silver, and platinum where one unit equals one troy ounce (~31.1 grams) |
| 9 | Ether | Ethereum cryptocurrency token — one unit equals one ETH, allowing fractional positions (0.001 ETH) |
| 10 | Bitcoin | Bitcoin cryptocurrency token — one unit equals one BTC, the primary crypto instrument with the highest trading volume |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | tinyint | NO | - | CODE-BACKED | Unique identifier for the unit of measure: 0=Points, 1=Barrel, 2=Troy Ounce, 3=MMBtu, 4=Pounds, 5=Short Tons, 6=Euros, 7=AUD, 8=GBP, 9=Ether, 10=Bitcoin, 11=SOL, 12=XRP. Referenced by Trade.FuturesMetaData and instrument configuration procedures. |
| 2 | Value | varchar(50) | NO | - | CODE-BACKED | Display name for the unit. Shown in trading interfaces when describing position sizes (e.g., "10 Barrels" or "0.5 Troy Ounce"). Note: "Bitcoin" has a leading space in the data — likely a data entry artifact. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FuturesMetaData | UnitOfMeasure | Implicit | Stores which unit applies to each futures instrument |
| History.FuturesMetaData | UnitOfMeasure | Implicit | Historical archive of futures metadata unit assignments |
| Trade.InsertInstrumentRealTable | UnitOfMeasure | Reader | Reads units during instrument creation/configuration |
| Trade.CheckValidInstruments | UnitOfMeasure | Reader | Validates unit of measure during instrument configuration checks |
| Trade.ReturnInstruemtFirstConfigurationNew | UnitOfMeasure | Reader | Includes unit of measure in instrument configuration results |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.UnitOfMeasure (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FuturesMetaData | Table | Stores UnitOfMeasure reference per futures instrument |
| Trade.InsertInstrumentRealTable | Stored Procedure | Reads unit values during instrument configuration |
| Trade.CheckValidInstruments | Stored Procedure | Validates unit of measure assignments |
| Trade.ReturnInstruemtFirstConfigurationNew | Function | Returns unit of measure in instrument config data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (PK) | CLUSTERED | ID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all units of measure
```sql
SELECT  ID,
        Value AS UnitName
FROM    [Dictionary].[UnitOfMeasure] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Find instruments with their unit of measure
```sql
SELECT  f.InstrumentID,
        u.Value AS UnitOfMeasure
FROM    [Trade].[FuturesMetaData] f WITH (NOLOCK)
JOIN    [Dictionary].[UnitOfMeasure] u WITH (NOLOCK)
        ON u.ID = f.UnitOfMeasure
ORDER BY f.InstrumentID;
```

### 8.3 Group instruments by unit category
```sql
SELECT  u.Value AS UnitOfMeasure,
        COUNT(*) AS InstrumentCount
FROM    [Trade].[FuturesMetaData] f WITH (NOLOCK)
JOIN    [Dictionary].[UnitOfMeasure] u WITH (NOLOCK)
        ON u.ID = f.UnitOfMeasure
GROUP BY u.Value
ORDER BY InstrumentCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.UnitOfMeasure | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.UnitOfMeasure.sql*
