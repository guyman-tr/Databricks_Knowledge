# Price.ThresholdsTypeValue

> Two-column table-valued parameter (TVP) for passing OMPD (Order Margin Price Deviation) threshold type-value pairs to stored procedures, enabling bulk updates of multiple threshold types for a given instrument in a single call.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | User Defined Type |
| **Key Identifier** | ThresholdType (determines which threshold to update) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This TVP is the input contract for `Price.UpdateInstrumentThresholdsWithActiveThreshold`. OMPD (Order Margin Price Deviation) thresholds define price deviation limits that trigger special order handling rules - when the market price deviates from the order price by more than a threshold amount, the system may reject, re-quote, or apply margin adjustments to the order.

Different threshold types (identified by ThresholdType, referenced in Dictionary.OMPDThresholdType) represent different deviation scenarios or instrument categories. This TVP allows the pricing operations team to update multiple threshold type-value pairs for one instrument atomically in a single API call, rather than calling a separate procedure for each threshold type.

Data flows from the pricing operations API -> this TVP -> `UpdateInstrumentThresholdsWithActiveThreshold` -> UPDATE Price.OMPDThresholdValues + optionally UPDATE Price.OMPDActiveThreshold. The SP performs extensive validation before the update: checks that InstrumentID exists, ThresholdTypes are valid per Dictionary.OMPDThresholdType, and all threshold types exist in Price.OMPDThresholdValues for the given instrument.

---

## 2. Business Logic

### 2.1 OMPD Threshold Update with Validation

**What**: Enables atomic update of multiple OMPD threshold values per instrument, with full referential validation before any data changes.

**Columns/Parameters Involved**: `ThresholdType`, `Value`

**Rules**:
- ThresholdType must exist in Dictionary.OMPDThresholdType (SP validates before update; raises error if invalid)
- All ThresholdType values in the TVP must already exist in Price.OMPDThresholdValues for the target InstrumentID (no inserts allowed via this path - see Price.CreateInstrumentOMPDThresholdByInstrumentId)
- Value precision: decimal(20,2) supports large threshold values with 2 decimal places

**Diagram**:
```
Caller TVP contents (per instrument):
  ThresholdType=1, Value=0.50  (e.g., 0.50% deviation threshold for type 1)
  ThresholdType=2, Value=1.00  (e.g., 1.00% deviation threshold for type 2)

SP Validation:
  1. InstrumentID exists in Trade.InstrumentMetaData? -> YES or RAISERROR
  2. All ThresholdTypes valid in Dictionary.OMPDThresholdType? -> YES or RAISERROR
  3. All ThresholdTypes exist in OMPDThresholdValues for this instrument? -> YES or RAISERROR

SP Update:
  UPDATE Price.OMPDThresholdValues SET Value = srcTbl.Value
    WHERE InstrumentID = @InstrumentID AND ThresholdType matches
  [Optional] UPDATE Price.OMPDActiveThreshold SET ThresholdType = @ActiveThresholdType
```

### 2.2 Active Threshold Coupling

**What**: The TVP is passed alongside an @ActiveThresholdType parameter that can simultaneously update which threshold is "active" for the instrument.

**Columns/Parameters Involved**: `ThresholdType`

**Rules**:
- The @ActiveThresholdType parameter in the SP (not part of this TVP) must be one of the ThresholdTypes included in this TVP
- This ensures the newly-active threshold type has a corresponding value in the TVP
- Setting ActiveThresholdType = NULL preserves the current active threshold; only the values change

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ThresholdType | int | NOT NULL | - | CODE-BACKED | Identifies which OMPD threshold category to update. NOT NULL - must be a valid ID from Dictionary.OMPDThresholdType (SP validates this). Determines the type of price deviation scenario this threshold governs. |
| 2 | Value | decimal(20,2) | NOT NULL | - | CODE-BACKED | The threshold value for the specified ThresholdType. NOT NULL - the core payload. Represents the deviation limit (e.g., in percentage points or absolute price units depending on ThresholdType definition). Precision decimal(20,2) supports both very large threshold values and sub-unit precision. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (TVP - no FK constraints).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.UpdateInstrumentThresholdsWithActiveThreshold | @ThresholdValues | TVP Parameter | Validates ThresholdTypes against Dictionary.OMPDThresholdType and updates Price.OMPDThresholdValues |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.UpdateInstrumentThresholdsWithActiveThreshold | Stored Procedure | Declares @ThresholdValues as this type READONLY; validates and bulk-updates Price.OMPDThresholdValues |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ThresholdType NOT NULL | NOT NULL | Threshold type identification required; determines which OMPD threshold category to update |
| Value NOT NULL | NOT NULL | The threshold value must always be explicitly specified; no default deviation tolerance |

---

## 8. Sample Queries

### 8.1 Update two threshold types for an instrument, changing active threshold

```sql
DECLARE @Thresholds Price.ThresholdsTypeValue;
INSERT INTO @Thresholds (ThresholdType, Value)
VALUES (1, 0.50),  -- threshold type 1: 0.5 deviation limit
       (2, 1.00);  -- threshold type 2: 1.0 deviation limit
EXEC Price.UpdateInstrumentThresholdsWithActiveThreshold
    @InstrumentID = 1001,
    @ThresholdValues = @Thresholds,
    @ActiveThresholdType = 1;
```

### 8.2 Update threshold values without changing the active threshold

```sql
DECLARE @Thresholds Price.ThresholdsTypeValue;
INSERT INTO @Thresholds (ThresholdType, Value)
VALUES (1, 0.75),
       (2, 1.25);
EXEC Price.UpdateInstrumentThresholdsWithActiveThreshold
    @InstrumentID = 1001,
    @ThresholdValues = @Thresholds,
    @ActiveThresholdType = NULL;  -- preserves current active threshold
```

### 8.3 Check valid threshold types from dictionary

```sql
SELECT ThresholdTypeID, ThresholdTypeName
FROM Dictionary.OMPDThresholdType WITH (NOLOCK)
ORDER BY ThresholdTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.ThresholdsTypeValue | Type: User Defined Type | Source: etoro/etoro/Price/User Defined Types/Price.ThresholdsTypeValue.sql*
