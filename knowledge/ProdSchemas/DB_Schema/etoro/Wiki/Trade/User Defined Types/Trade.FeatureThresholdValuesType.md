# Trade.FeatureThresholdValuesType

> TVP for bulk-updating feature threshold configuration values targeting Trade.FeatureThresholdValues.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID, FeatureID, ThresholdID |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

Trade.FeatureThresholdValuesType is a table-valued parameter for bulk-updating feature threshold configuration. It targets the Trade.FeatureThresholdValues table. InstrumentID references Trade.Instrument; FeatureID and ThresholdID reference the feature/threshold configuration system (Trade.ActiveFeatureThreshold). The Value column holds the threshold amount.

Trade.UpdateFeatureThresholdValues accepts this TVP via the @Values parameter to apply updates in a single batch. All columns are nullable except where the procedure enforces values.

---

## 2. Business Logic

### 2.1 Feature threshold update

**What**: Each row specifies an instrument/feature/threshold combination and a new value. The procedure updates FeatureThresholdValues accordingly.

**Columns/Parameters Involved**: InstrumentID, FeatureID, ThresholdID, Value

**Rules**: InstrumentID -> Trade.Instrument. FeatureID and ThresholdID reference Trade.ActiveFeatureThreshold. Value is decimal(20,2).

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | Yes | - | 10 | Instrument (Trade.Instrument) |
| 2 | FeatureID | int | Yes | - | 10 | Feature in threshold config |
| 3 | ThresholdID | int | Yes | - | 10 | Threshold in config |
| 4 | Value | decimal(20,2) | Yes | - | 10 | Threshold amount |

---

## 5. Relationships

### 5.1 References To

| Target | Role |
|--------|------|
| Trade.Instrument (InstrumentID) | Implicit reference |
| Trade.ActiveFeatureThreshold (FeatureID, ThresholdID) | Implicit reference |
| Trade.FeatureThresholdValues | Target table for updates |

### 5.2 Referenced By

| Consumer | Usage |
|----------|-------|
| Trade.UpdateFeatureThresholdValues | Parameter @Values |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Trade.UpdateFeatureThresholdValues

---

## 7. Technical Details

### 7.1 Indexes

None.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update feature thresholds in batch

```sql
DECLARE @Values Trade.FeatureThresholdValuesType;
INSERT INTO @Values (InstrumentID, FeatureID, ThresholdID, Value)
VALUES (100, 1, 2, 5000.00), (101, 1, 2, 7500.00);
EXEC Trade.UpdateFeatureThresholdValues @Values = @Values;
```

### 8.2 Build from FeatureThresholdValues

```sql
DECLARE @V Trade.FeatureThresholdValuesType;
INSERT INTO @V (InstrumentID, FeatureID, ThresholdID, Value)
SELECT InstrumentID, FeatureID, ThresholdID, Value * 1.1
FROM Trade.FeatureThresholdValues
WHERE FeatureID = @FeatureID;
EXEC Trade.UpdateFeatureThresholdValues @Values = @V;
```

### 8.3 Inspect type definition

```sql
SELECT c.name, t.name AS type_name, c.precision, c.scale
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE tt.name = 'FeatureThresholdValuesType';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10, Logic: 5, Relationships: 8, Sources: 4)*
*Confidence: High (DDL + procedure reference)*
*Sources: DDL, Trade.UpdateFeatureThresholdValues procedure*
*Object: Trade.FeatureThresholdValuesType | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.FeatureThresholdValuesType.sql*
