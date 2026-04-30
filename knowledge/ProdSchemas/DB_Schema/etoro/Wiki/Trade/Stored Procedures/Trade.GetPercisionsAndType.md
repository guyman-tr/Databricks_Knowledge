# Trade.GetPercisionsAndType

> Returns InstrumentID, decimal precision, and currency type for all instruments - a bulk lookup of instrument price formatting and currency classification metadata. (Note: name has typo "Percisions" instead of "Precisions".)

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns all instruments |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetPercisionsAndType` (note intentional typo in name) returns a full table of InstrumentID, decimal Precision, and CurrencyType for every instrument in the system. It provides the two key formatting/classification facts needed for price display and instrument-type routing.

**WHY:** Client applications and calculation engines need to know: (1) how many decimal places to display/round prices for each instrument (Precision), and (2) what currency type the instrument's buy-side currency is (CurrencyType - e.g., Crypto, Fiat, Stock). These facts are stable and cached; this SP provides the bulk load endpoint.

**HOW:** Joins Trade.ProviderToInstrument (source of Precision) to Trade.Instrument (source of BuyCurrencyID), then LEFT JOINs Dictionary.Currency to resolve CurrencyTypeID for the buy currency. One row per provider-instrument combination (not per instrument - instruments with multiple providers appear once per provider).

---

## 2. Business Logic

### 2.1 Precision and Currency Type Bulk Load

**What:** Single three-table join returning all provider-instrument rows with formatting and classification data.

**Columns/Parameters Involved:** `InstrumentID`, `Precision`, `CurrencyType`

**Rules:**
- `FROM Trade.ProviderToInstrument` - one row per provider+instrument pair
- LEFT JOIN to Trade.Instrument on InstrumentID -> to get BuyCurrencyID
- LEFT JOIN to Dictionary.Currency on BuyCurrencyID -> to get CurrencyTypeID
- CurrencyType = Dictionary.Currency.CurrencyTypeID (not the currency name)
- NULL CurrencyType possible if BuyCurrencyID not in Dictionary.Currency

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:** None.

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument ID from Trade.ProviderToInstrument. |
| 2 | Precision | INT | YES | - | CODE-BACKED | Decimal places for price display/rounding. From Trade.ProviderToInstrument.Precision. E.g., 2=cents, 5=forex pips. |
| 3 | CurrencyType | INT | YES | - | CODE-BACKED | CurrencyTypeID of the instrument's buy-side currency. From Dictionary.Currency.CurrencyTypeID. NULL if BuyCurrencyID has no Currency record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.ProviderToInstrument | Lookup | Precision per provider-instrument |
| InstrumentID | Trade.Instrument | Lookup | BuyCurrencyID for currency classification |
| BuyCurrencyID | Dictionary.Currency | Lookup | CurrencyTypeID classification |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by price formatting and instrument classification services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPercisionsAndType (procedure)
|- Trade.ProviderToInstrument (table) - precision
|- Trade.Instrument (table) - buy currency ID
|- Dictionary.Currency (table) - currency type ID
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | Precision per instrument per provider |
| Trade.Instrument | Table | BuyCurrencyID for currency classification |
| Dictionary.Currency | Table | CurrencyTypeID from BuyCurrencyID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by instrument metadata services |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| LEFT JOIN to Instrument | Nullable | Instrument may not exist if ProviderToInstrument has orphaned rows |
| LEFT JOIN to Currency | Nullable | CurrencyType NULL if BuyCurrencyID not in Dictionary.Currency |
| NOLOCK on all tables | Performance | Dirty read acceptable for metadata bulk load |
| No parameters | Scope | Returns ALL instruments |

---

## 8. Sample Queries

### 8.1 Load all instrument precisions and types

```sql
EXEC Trade.GetPercisionsAndType
```

### 8.2 Find all instruments with 5 decimal places (forex)

```sql
DECLARE @t TABLE (InstrumentID INT, Precision INT, CurrencyType INT)
INSERT @t EXEC Trade.GetPercisionsAndType
SELECT * FROM @t WHERE Precision = 5
```

### 8.3 Group instruments by currency type

```sql
DECLARE @t TABLE (InstrumentID INT, Precision INT, CurrencyType INT)
INSERT @t EXEC Trade.GetPercisionsAndType
SELECT CurrencyType, COUNT(*) AS InstrumentCount FROM @t GROUP BY CurrencyType ORDER BY InstrumentCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 8.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPercisionsAndType | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPercisionsAndType.sql*
