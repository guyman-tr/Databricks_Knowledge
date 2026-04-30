# Dictionary.MarketRangeValidationType

> Lookup table defining the 3 methods for validating market-range orders (price tolerance bands around the requested execution price).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | MarketRangeValidationTypeID (TINYINT IDENTITY, CLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.MarketRangeValidationType defines how the trading engine validates whether a market order should be executed when the actual execution price deviates from the price the user saw at order submission. Market conditions can change between the time a user clicks "Buy" and the order reaches the execution engine — the market range validation type determines how this slippage is handled.

This protects users from unexpected price slippage while balancing the need for order execution in fast-moving markets. Different instruments and market conditions may use different validation approaches.

MarketRangeValidationTypeID is referenced by instrument configuration to define the slippage tolerance behavior per instrument.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| MarketRangeValidationTypeID | Name | Meaning |
|---|---|---|
| 1 | NoValidation | No price validation — the order executes at whatever the current market price is, regardless of deviation from the requested price. Used for highly liquid instruments where any slippage is acceptable. |
| 2 | OneDirection | Validates slippage in one direction only — rejects the order if the price moves against the user but allows execution if the price moves in the user's favor. Protects against negative slippage while allowing positive slippage. |
| 3 | BothDirections | Validates slippage in both directions — rejects the order if the price moves beyond the tolerance band in either direction. Strictest mode. Ensures execution only within a tight price range. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MarketRangeValidationTypeID | tinyint | NO | IDENTITY(1,1) | CODE-BACKED | Primary key (auto-increment). 1=NoValidation, 2=OneDirection, 3=BothDirections. See [Market Range Validation Type](_glossary.md#market-range-validation-type). (Dictionary.MarketRangeValidationType) |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Validation method name. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Instrument configuration tables | MarketRangeValidationTypeID | Implicit Lookup | Defines slippage tolerance per instrument |

---

## 6. Dependencies

This object has no dependencies.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryMarketRangeValidationTypes | CLUSTERED PK | MarketRangeValidationTypeID ASC | - | - | Active |

---

## 8. Sample Queries

### 8.1 List all market range validation types
```sql
SELECT MarketRangeValidationTypeID, Name
FROM [Dictionary].[MarketRangeValidationType] WITH (NOLOCK) ORDER BY MarketRangeValidationTypeID;
```

---

*Generated: 2026-03-13 | Quality: 7.0/10*
*Object: Dictionary.MarketRangeValidationType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.MarketRangeValidationType.sql*
