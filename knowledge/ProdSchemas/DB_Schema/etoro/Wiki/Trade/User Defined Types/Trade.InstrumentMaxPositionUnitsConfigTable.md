# Trade.InstrumentMaxPositionUnitsConfigTable

> TVP for bulk-updating the maximum position units allowed per instrument. Risk control to prevent excessively large positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

Trade.InstrumentMaxPositionUnitsConfigTable is a table-valued parameter for bulk-updating the maximum position units allowed per instrument. ConfigurationValue is the maximum number of units a single position can hold. This is a risk control that prevents excessively large positions. InstrumentID references Trade.Instrument. For example, Bitcoin might have a max of 100 units while Apple stock might have 10000.

---

## 2. Business Logic

### 2.1 Bulk update of max position units

**What**: The TVP passes rows with InstrumentID and new ConfigurationValue. UpdateInstrumentsMaxPositionUnits updates each instrument's max position size limit.

**Columns/Parameters Involved**: InstrumentID, ConfigurationValue

**Rules**: Both required. ConfigurationValue must be positive. InstrumentID must exist in Trade.Instrument. Used for risk and exposure limits.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | No | - | 10 | Instrument identifier (Trade.Instrument) |
| 2 | ConfigurationValue | decimal(18,4) | No | - | 10 | Maximum units per position |

---

## 5. Relationships

### 5.1 References To

| Target | Role |
|--------|------|
| Trade.Instrument (InstrumentID) | Implicit reference |
| Instrument max position config | Target for update |

### 5.2 Referenced By

| Consumer | Usage |
|----------|-------|
| Trade.UpdateInstrumentsMaxPositionUnits | Parameter @InstrumentNewConfigTable |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Trade.UpdateInstrumentsMaxPositionUnits

---

## 7. Technical Details

### 7.1 Indexes

None.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update max position units for instruments

```sql
DECLARE @InstrumentNewConfigTable Trade.InstrumentMaxPositionUnitsConfigTable;
INSERT INTO @InstrumentNewConfigTable (InstrumentID, ConfigurationValue)
VALUES (100, 100.0000), (101, 1000.0000), (102, 10000.0000);
EXEC Trade.UpdateInstrumentsMaxPositionUnits @InstrumentNewConfigTable = @InstrumentNewConfigTable;
```

### 8.2 Build from Instrument table with default

```sql
DECLARE @T Trade.InstrumentMaxPositionUnitsConfigTable;
INSERT INTO @T (InstrumentID, ConfigurationValue)
SELECT InstrumentID, 1000.0000
FROM Trade.Instrument
WHERE InstrumentTypeID = 1;
EXEC Trade.UpdateInstrumentsMaxPositionUnits @InstrumentNewConfigTable = @T;
```

### 8.3 Verify type columns

```sql
SELECT c.name, t.name AS type_name
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE tt.name = 'InstrumentMaxPositionUnitsConfigTable';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10, Logic: 5, Relationships: 8, Sources: 4)*
*Confidence: High (DDL + procedure reference)*
*Sources: DDL, Trade.UpdateInstrumentsMaxPositionUnits*
*Object: Trade.InstrumentMaxPositionUnitsConfigTable | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InstrumentMaxPositionUnitsConfigTable.sql*
