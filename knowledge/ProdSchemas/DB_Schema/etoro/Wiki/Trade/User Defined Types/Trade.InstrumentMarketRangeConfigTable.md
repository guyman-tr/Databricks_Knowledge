# Trade.InstrumentMarketRangeConfigTable

> TVP for bulk-updating market range configuration per instrument. Market range defines slippage tolerance (pips or percentage).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

Trade.InstrumentMarketRangeConfigTable is a table-valued parameter for bulk-updating market range configuration per instrument. Market range defines how far from the current market price an order can execute (slippage tolerance). MarketRange is an absolute pip-based range; MarketRangePercentage is percentage-based. MarketRangeValidationType determines which method to use (e.g., 0=pips, 1=percentage). Precision is decimal precision for the instrument's price; Symbol is the full symbol name. InstrumentTypeID references Dictionary.InstrumentTypes.

---

## 2. Business Logic

### 2.1 Bulk update of market range settings

**What**: The TVP passes rows with InstrumentID and new market range settings. UpdateInstrumentsMarketRange updates each instrument's slippage tolerance configuration.

**Columns/Parameters Involved**: InstrumentID, InstrumentTypeID, Symbol, Precision, MarketRange, MarketRangePercentage, MarketRangeValidationType

**Rules**: InstrumentID and Precision required. MarketRangeValidationType: 0=pips, 1=percentage. MarketRange and MarketRangePercentage used based on validation type. InstrumentTypeID references Dictionary.InstrumentTypes.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | No | - | 10 | Instrument identifier (Trade.Instrument) |
| 2 | InstrumentTypeID | int | No | - | 10 | Instrument type (Dictionary.InstrumentTypes) |
| 3 | Symbol | varchar(100) | Yes | - | 10 | Full symbol name (Latin1_General_BIN) |
| 4 | Precision | tinyint | No | - | 10 | Decimal precision for price |
| 5 | MarketRange | int | Yes | - | 10 | Absolute pip-based range |
| 6 | MarketRangePercentage | decimal(5,2) | Yes | - | 10 | Percentage-based range |
| 7 | MarketRangeValidationType | tinyint | No | - | 10 | 0=pips, 1=percentage, etc. |

---

## 5. Relationships

### 5.1 References To

| Target | Role |
|--------|------|
| Trade.Instrument (InstrumentID) | Implicit reference |
| Dictionary.InstrumentTypes (InstrumentTypeID) | Implicit reference |
| Instrument market range config | Target for update |

### 5.2 Referenced By

| Consumer | Usage |
|----------|-------|
| Trade.UpdateInstrumentsMarketRange | Parameter @InstrumentNewConfigTable |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Trade.UpdateInstrumentsMarketRange

---

## 7. Technical Details

### 7.1 Indexes

None.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update market range for instruments

```sql
DECLARE @InstrumentNewConfigTable Trade.InstrumentMarketRangeConfigTable;
INSERT INTO @InstrumentNewConfigTable
  (InstrumentID, InstrumentTypeID, Symbol, Precision, MarketRange, MarketRangePercentage, MarketRangeValidationType)
VALUES (100, 5, 'BTCUSD', 2, 50, NULL, 0), (101, 5, 'ETHUSD', 2, 100, NULL, 0);
EXEC Trade.UpdateInstrumentsMarketRange @InstrumentNewConfigTable = @InstrumentNewConfigTable;
```

### 8.2 Switch to percentage-based range

```sql
DECLARE @T Trade.InstrumentMarketRangeConfigTable;
INSERT INTO @T (InstrumentID, InstrumentTypeID, Symbol, Precision, MarketRange, MarketRangePercentage, MarketRangeValidationType)
VALUES (200, 1, 'AAPL', 4, NULL, 0.50, 1);
EXEC Trade.UpdateInstrumentsMarketRange @InstrumentNewConfigTable = @T;
```

### 8.3 Verify type columns

```sql
SELECT c.name, t.name AS type_name
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE tt.name = 'InstrumentMarketRangeConfigTable';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10, Logic: 5, Relationships: 8, Sources: 4)*
*Confidence: High (DDL + procedure reference)*
*Sources: DDL, Trade.UpdateInstrumentsMarketRange*
*Object: Trade.InstrumentMarketRangeConfigTable | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InstrumentMarketRangeConfigTable.sql*
