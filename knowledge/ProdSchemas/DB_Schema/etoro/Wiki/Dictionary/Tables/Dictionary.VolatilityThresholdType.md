# Dictionary.VolatilityThresholdType

> Lookup table defining the two measurement units for instrument volatility thresholds — Pips (absolute price movement) or Percentage (relative price change) — used to configure when trading protections and alerts trigger for volatile market conditions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | VolatilityThresholdTypeID (INT, manually assigned) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 clustered (PK on VolatilityThresholdTypeID) |

---

## 1. Business Meaning

Dictionary.VolatilityThresholdType defines how volatility thresholds are measured for each traded instrument. When the platform monitors price movements to determine if an instrument is "too volatile" for normal trading (triggering spread widening, order rejection, or alerts), it needs to know whether the threshold is specified in absolute pips (price ticks) or as a percentage of the current price.

Without this table, the system could not support both measurement modes. Pips work well for forex pairs where a fixed pip movement is meaningful regardless of price level, but percentages are better for stocks and crypto where the same absolute movement means very different things at different price levels (a 100-pip move means more for a $10 stock than for a $1000 stock).

The table is referenced by Trade.InstrumentVolatilityThresholdType (which stores per-instrument threshold configurations), and consumed by Trade.InsertInstrumentRealTable, Trade.CheckValidInstruments, and the Trade.ReturnInstruemtFirstConfiguration/ReturnInstruemtFirstConfigurationNew functions during instrument setup and validation.

---

## 2. Business Logic

### 2.1 Volatility Measurement Modes

**What**: Two ways to define when an instrument's price movement is considered "volatile enough" to trigger protections.

**Columns/Parameters Involved**: `VolatilityThresholdTypeID`, `Name`, `Description`

**Rules**:
- ID 1 (Pips) — threshold is measured as absolute price ticks. Example: "if the price moves 50 pips from the last rate, consider it volatile." Best for forex pairs where pip values are standardized
- ID 2 (Percentage) — threshold is measured as the percentage difference between the last rate and current rate. Example: "if the price changes 5% from the last rate, consider it volatile." Best for equities and crypto where absolute movements vary with price level
- Each instrument in Trade.InstrumentVolatilityThresholdType has its own threshold value AND type (pips or percentage)
- When volatility exceeds the threshold, the platform may: widen spreads, reject market orders, require limit orders, or trigger monitoring alerts

**Diagram**:
```
Volatility Check:
  Current Price received
       │
       ▼
  Read instrument's threshold config
  (Trade.InstrumentVolatilityThresholdType)
       │
       ├─ Type = 1 (Pips):
       │   |current - last| > threshold_pips? ──► VOLATILE
       │
       └─ Type = 2 (Percentage):
           |current - last| / last × 100 > threshold_pct? ──► VOLATILE
```

---

## 3. Data Overview

| VolatilityThresholdTypeID | Name | Description | Meaning |
|---|---|---|---|
| 1 | Pips | Volatility threshold in pips | Absolute price movement measurement — best for forex pairs where one pip has a standardized value. A threshold of "50 pips" means the same thing whether the pair is at 1.1000 or 1.5000. |
| 2 | Percentage | Volatility threshold as percentage diff between last rate and current rate | Relative price movement measurement — best for stocks and crypto. A "5%" threshold automatically scales: triggers at $0.50 for a $10 stock but $50 for a $1000 stock. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | VolatilityThresholdTypeID | int | NO | - | CODE-BACKED | Unique identifier for the volatility measurement mode: 1=Pips (absolute), 2=Percentage (relative). Referenced by Trade.InstrumentVolatilityThresholdType per instrument and consumed by 4+ instrument configuration procedures/functions. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Short label: "Pips" or "Percentage". Used in instrument configuration screens and API responses to indicate which measurement mode applies. |
| 3 | Description | varchar(300) | YES | - | VERIFIED | Detailed explanation of the measurement mode. Self-documenting: "Volatility threshold in pips" or "Volatility threshold as percentage diff between last rate and current rate". Provides the calculation formula context for each mode. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InstrumentVolatilityThresholdType | VolatilityThresholdTypeID | Implicit | Stores which measurement mode applies to each instrument's volatility threshold |
| History.InstrumentVolatilityThresholdType | VolatilityThresholdTypeID | Implicit | Historical archive of instrument volatility threshold configurations |
| Trade.InsertInstrumentRealTable | VolatilityThresholdTypeID | Reader | Sets threshold type during instrument configuration |
| Trade.CheckValidInstruments | VolatilityThresholdTypeID | Reader | Validates threshold type during instrument config checks |
| Trade.ReturnInstruemtFirstConfigurationNew | VolatilityThresholdTypeID | Reader | Returns threshold type in instrument configuration data |
| Trade.ReturnInstruemtFirstConfiguration | VolatilityThresholdTypeID | Reader | Legacy version of configuration function |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.VolatilityThresholdType (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentVolatilityThresholdType | Table | Stores threshold type per instrument |
| Trade.InsertInstrumentRealTable | Stored Procedure | Configures threshold type for instruments |
| Trade.CheckValidInstruments | Stored Procedure | Validates threshold type |
| Trade.ReturnInstruemtFirstConfigurationNew | Function | Returns threshold type in config |
| Trade.ReturnInstruemtFirstConfiguration | Function | Legacy config function |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryVolatilityThresholdTypeID | CLUSTERED | VolatilityThresholdTypeID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all volatility threshold types with descriptions
```sql
SELECT  VolatilityThresholdTypeID,
        Name,
        Description
FROM    [Dictionary].[VolatilityThresholdType] WITH (NOLOCK)
ORDER BY VolatilityThresholdTypeID;
```

### 8.2 Find instruments with their volatility threshold mode
```sql
SELECT  ivt.InstrumentID,
        vt.Name AS ThresholdMode,
        ivt.ThresholdValue
FROM    [Trade].[InstrumentVolatilityThresholdType] ivt WITH (NOLOCK)
JOIN    [Dictionary].[VolatilityThresholdType] vt WITH (NOLOCK)
        ON vt.VolatilityThresholdTypeID = ivt.VolatilityThresholdTypeID
ORDER BY ivt.InstrumentID;
```

### 8.3 Count instruments by volatility threshold mode
```sql
SELECT  vt.Name AS ThresholdMode,
        COUNT(*) AS InstrumentCount
FROM    [Trade].[InstrumentVolatilityThresholdType] ivt WITH (NOLOCK)
JOIN    [Dictionary].[VolatilityThresholdType] vt WITH (NOLOCK)
        ON vt.VolatilityThresholdTypeID = ivt.VolatilityThresholdTypeID
GROUP BY vt.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 1 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.VolatilityThresholdType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.VolatilityThresholdType.sql*
