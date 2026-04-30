# Dictionary.AmountFormula

> Lookup table defining the 2 pricing formulas — PriceByUnitRate and FixPricePerLot — that determine how trade amounts are calculated from instrument prices and position sizes.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | AmountFormulaID (TINYINT, no PK constraint) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 0 (heap — no indexes) |

---

## 1. Business Meaning

Dictionary.AmountFormula defines the two mathematical formulas used to calculate trade amounts (position value) for different instrument types. The formula determines the relationship between the quoted price, the number of units/lots, and the resulting dollar amount that appears on the customer's trade.

This distinction matters because different asset classes price differently. Forex instruments use a "price per unit" model (Amount = Units × Rate), while some legacy or commodity instruments use a "fixed price per lot" model (Amount = Lots × FixedLotPrice). The formula type is stored per instrument in Trade.ProviderToInstrument.

Referenced by Trade.GetInstrumentDataForAPI (returns formula to frontend for amount preview calculations), Trade.CheckValidInstruments (validation), Trade.InsertInstrumentTradingData and Trade.InsertInstrumentRealTable (instrument configuration), Trade.GetPortfolioAggregates, and Trade.UserPositionsTableType_MOT (UDT for position data).

---

## 2. Business Logic

### 2.1 Pricing Formulas

**What**: How trade amounts are calculated from price and quantity.

**Columns/Parameters Involved**: `AmountFormulaID`, `AmountFormulaName`

**Rules**:
- **PriceByUnitRate (0)**: Amount = Units × Current Market Rate. Used for most modern instruments (stocks, forex, crypto, indices). The trade amount fluctuates with the market price. This is the standard formula for the majority of tradeable instruments.
- **FixPricePerLot (1)**: Amount = Lots × Fixed Lot Price. Used for instruments with fixed lot pricing (typically legacy commodities or structured products). The per-lot price is predefined and doesn't change with the market rate for amount calculation purposes.

---

## 3. Data Overview

| AmountFormulaID | AmountFormulaName | Meaning |
|---|---|---|
| 0 | PriceByUnitRate | Standard pricing: trade amount equals units multiplied by the current market rate. Used for stocks, forex pairs, crypto, and indices. Amount fluctuates as the market price changes. |
| 1 | FixPricePerLot | Fixed lot pricing: trade amount equals the number of lots multiplied by a predefined fixed price per lot. Used for legacy commodity instruments or structured products where the lot value is fixed. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AmountFormulaID | tinyint | NO | - | CODE-BACKED | Identifier for the pricing formula. 0=PriceByUnitRate (Amount=Units×Rate), 1=FixPricePerLot (Amount=Lots×FixedPrice). No PK constraint. Stored in Trade.ProviderToInstrument per instrument. Used by the trading engine to calculate position values. |
| 2 | AmountFormulaName | char(50) | NO | - | CODE-BACKED | Fixed-width formula name (padded with spaces). Legacy char(50) type. Values: 'PriceByUnitRate', 'FixPricePerLot'. Returned by Trade.GetInstrumentDataForAPI for frontend amount calculations. Trim trailing spaces when displaying. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ProviderToInstrument | AmountFormulaID | Implicit | Per-instrument pricing formula configuration |
| History.TradeProviderToInstrument | AmountFormulaID | Implicit | Historical instrument configuration |
| Trade.GetInstrumentDataForAPI | AmountFormulaID | SELECT | Returns formula for frontend calculations |
| Trade.CheckValidInstruments | AmountFormulaID | SELECT | Instrument validation |
| Trade.InsertInstrumentTradingData | AmountFormulaID | INSERT | Sets formula during instrument setup |
| Trade.InsertInstrumentRealTable | AmountFormulaID | INSERT | Sets formula for real instruments |
| Trade.GetPortfolioAggregates | AmountFormulaID | SELECT | Portfolio-level calculations |
| Trade.UserPositionsTableType_MOT | AmountFormulaID | Column | UDT for passing position data between procedures |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | Stores AmountFormulaID per instrument |
| Trade.GetInstrumentDataForAPI | Stored Procedure | Reader — frontend instrument config |
| Trade.InsertInstrumentTradingData | Stored Procedure | Writer — instrument setup |
| Trade.GetPortfolioAggregates | Stored Procedure | Reader — portfolio calculations |

---

## 7. Technical Details

### 7.1 Indexes

No indexes defined. Table is a heap on DICTIONARY filegroup.

### 7.2 Constraints

None. No PK, no unique constraints. Note: live data contains duplicate rows per ID (4 rows each for IDs 0 and 1) — likely a data quality issue.

---

## 8. Sample Queries

### 8.1 List distinct pricing formulas
```sql
SELECT  DISTINCT
        AmountFormulaID,
        RTRIM(AmountFormulaName) AS AmountFormulaName
FROM    Dictionary.AmountFormula WITH (NOLOCK)
ORDER BY AmountFormulaID;
```

### 8.2 Count instruments by pricing formula
```sql
SELECT  RTRIM(af.AmountFormulaName) AS Formula,
        COUNT(DISTINCT pti.InstrumentID) AS InstrumentCount
FROM    Trade.ProviderToInstrument pti WITH (NOLOCK)
JOIN    (SELECT DISTINCT AmountFormulaID, AmountFormulaName
         FROM Dictionary.AmountFormula WITH (NOLOCK)) af
        ON pti.AmountFormulaID = af.AmountFormulaID
GROUP BY RTRIM(af.AmountFormulaName);
```

### 8.3 Find instruments using fixed lot pricing
```sql
SELECT  pti.InstrumentID,
        RTRIM(af.AmountFormulaName) AS Formula
FROM    Trade.ProviderToInstrument pti WITH (NOLOCK)
JOIN    (SELECT DISTINCT AmountFormulaID, AmountFormulaName
         FROM Dictionary.AmountFormula WITH (NOLOCK)) af
        ON pti.AmountFormulaID = af.AmountFormulaID
WHERE   af.AmountFormulaID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AmountFormula | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.AmountFormula.sql*
