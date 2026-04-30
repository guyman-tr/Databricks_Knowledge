# Trade.GetMarketRangeValidationTypes

> Returns all market range validation type definitions (PIPS vs Percentage), used to configure how order execution tolerances are calculated.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: MarketRangeValidationTypeID + Name |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMarketRangeValidationTypes returns the complete dictionary of market range validation types from Dictionary.MarketRangeValidationType. Market range defines the acceptable price deviation when executing a trade - if the market moves beyond this range between the time a user clicks "trade" and the order reaches the server, the order may be rejected or filled at a different price. The validation type determines whether this range is measured in PIPS (absolute price units) or as a Percentage of the current price.

This procedure exists to provide the application with the enumeration of validation types for configuration screens and order validation logic. Currently there are two types: PIPS (ID=1) and Percentage (ID=2).

No specific application user grants were found, suggesting this may be accessible through broader role-based permissions or used internally.

---

## 2. Business Logic

### 2.1 Market Range Validation Types

**What**: Dictionary lookup returning the two modes of measuring order execution tolerance.

**Columns/Parameters Involved**: `Dictionary.MarketRangeValidationType`

**Rules**:
- MarketRangeValidationTypeID=1 (PIPS): Tolerance measured in pip units (absolute price movement)
- MarketRangeValidationTypeID=2 (Percentage): Tolerance measured as a percentage of the current market price
- These types are used in Trade.Instrument configuration to set how market range is validated per instrument
- No parameters - returns all rows

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

This procedure has no parameters.

### 4.2 Result Set

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | MarketRangeValidationTypeID | int | NO | CODE-BACKED | PK identifier for the validation type. 1=PIPS, 2=Percentage. Referenced by instrument configuration. |
| 2 | Name | varchar | NO | CODE-BACKED | Human-readable name: 'PIPS' or 'Percentage'. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | Dictionary.MarketRangeValidationType | SELECT (READER) | Reads all validation type definitions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No explicit DB-level callers found) | - | - | Likely accessible via broader permissions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMarketRangeValidationTypes (procedure)
+-- Dictionary.MarketRangeValidationType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.MarketRangeValidationType | Table | SELECT all rows to return validation type dictionary |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No DB-level dependents found) | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all market range validation types

```sql
EXEC Trade.GetMarketRangeValidationTypes;
```

### 8.2 Check which instruments use which validation type

```sql
SELECT  i.InstrumentID,
        i.SymbolFull,
        i.MarketRangeValidationType,
        mrvt.Name AS ValidationTypeName
FROM    Trade.Instrument i WITH (NOLOCK)
        LEFT JOIN Dictionary.MarketRangeValidationType mrvt WITH (NOLOCK)
            ON i.MarketRangeValidationType = mrvt.MarketRangeValidationTypeID
WHERE   i.MarketRangeValidationType IS NOT NULL;
```

### 8.3 Direct dictionary lookup

```sql
SELECT  MarketRangeValidationTypeID,
        Name
FROM    Dictionary.MarketRangeValidationType WITH (NOLOCK)
ORDER BY MarketRangeValidationTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMarketRangeValidationTypes | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMarketRangeValidationTypes.sql*
