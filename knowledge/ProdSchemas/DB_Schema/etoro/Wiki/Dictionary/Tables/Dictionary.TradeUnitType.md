# Dictionary.TradeUnitType

> Defines the two trade unit measurement types: Units and Lots.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table (heap — no PK) |
| **Key Identifier** | TradeUnitTypeID (tinyint, logical PK) |
| **Row Count** | 2 distinct values (8 rows due to duplicates) |
| **Indexes** | None (heap table) |
| **Filegroup** | DICTIONARY |

---

## 1. Business Meaning

### What It Is
Dictionary.TradeUnitType defines the two measurement systems for trade quantities on the eToro platform: Units (fractional shares/contracts) and Lots (standard forex lot sizing).

### Why It Exists
Different financial instruments use different quantity systems. Stocks and crypto are traded in **units** (fractional shares — e.g., 0.5 shares of Apple), while traditional forex instruments may use **lots** (standard lot = 100,000 units of base currency). This table provides the reference for which unit system applies to each instrument.

### How It Works
The `TradeUnitTypeID` is stored in `Trade.ProviderToInstrument` (and its history counterpart), configuring whether a specific instrument-provider combination uses units or lots for quantity calculation. Procedures like `Trade.InsertInstrumentTradingData` and `Trade.GetInstrumentDataForAPI` read this value.

---

## 2. Business Logic

### Value Map (2 distinct values)

| TradeUnitTypeID | TradeUnitTypeName | Business Meaning |
|-----------------|-------------------|------------------|
| 0 | Units | Fractional unit-based trading (stocks, ETFs, crypto) |
| 1 | Lots | Standard lot-based trading (forex, some CFDs) |

### Data Quality Note
The table contains duplicate rows (4 copies of each value = 8 total rows). This is because it's a heap with no PK or unique constraint, and the data was likely inserted multiple times. The logical distinct set is 2 rows.

---

## 3. Data Overview

| TradeUnitTypeID | TradeUnitTypeName | Scenario |
|-----------------|-------------------|----------|
| 0 | Units | User buys 2.5 units of AAPL stock |
| 1 | Lots | User opens 0.01 lots (1,000 units) of EUR/USD |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TradeUnitTypeID | tinyint | NO | — | HIGH | Logical key identifying the unit system. `0`=Units, `1`=Lots. Referenced by Trade.ProviderToInstrument. |
| 2 | TradeUnitTypeName | char(50) | NO | — | HIGH | Unit type label. Fixed-width with trailing spaces. |

---

## 5. Relationships

### Referenced By (Implicit)

| Consumer Table | Column | Evidence |
|----------------|--------|----------|
| Trade.ProviderToInstrument | TradeUnitTypeID | Instrument-provider unit configuration |
| History.TradeProviderToInstrument | TradeUnitTypeID | Historical archive |

### Procedure Consumers

| Procedure | Operation | Context |
|-----------|-----------|---------|
| Trade.InsertInstrumentTradingData | INSERT (into ProviderToInstrument) | Sets unit type for new instrument-provider mappings |
| Trade.GetInstrumentDataForAPI | SELECT (JOIN) | Returns unit type in API response |
| Trade.CheckValidInstruments | SELECT (validation) | Validates unit type |
| Trade.InsertInstrumentRealTable | INSERT | Real instrument insertion |

---

## 6. Dependencies

### Depends On
None — leaf dictionary table.

### Depended On By
- `Trade.ProviderToInstrument` — stores unit type per instrument-provider

---

## 7. Technical Details

**Note**: This table is a **heap** (no primary key, no clustered index). Contains duplicate rows due to missing unique constraint.

| Property | Value |
|----------|-------|
| Filegroup | DICTIONARY |

---

## 8. Sample Queries

```sql
-- Get distinct unit types
SELECT DISTINCT TradeUnitTypeID, RTRIM(TradeUnitTypeName) AS UnitType
FROM    Dictionary.TradeUnitType WITH (NOLOCK)
ORDER BY TradeUnitTypeID;

-- Count instruments by unit type
SELECT  RTRIM(ut.TradeUnitTypeName) AS UnitType, COUNT(*) AS InstrumentCount
FROM    Trade.ProviderToInstrument pi WITH (NOLOCK)
JOIN    (SELECT DISTINCT TradeUnitTypeID, TradeUnitTypeName
         FROM Dictionary.TradeUnitType WITH (NOLOCK)) ut
        ON pi.TradeUnitTypeID = ut.TradeUnitTypeID
GROUP BY ut.TradeUnitTypeName;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira references found for `TradeUnitType`.

---

*Generated: 2026-03-14 | Quality: 9.0/10*
*Object: Dictionary.TradeUnitType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.TradeUnitType.sql*
