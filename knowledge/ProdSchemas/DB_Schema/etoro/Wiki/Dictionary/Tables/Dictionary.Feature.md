# Dictionary.Feature

> Lookup table defining the types of trading execution features whose thresholds are configured per instrument — price filters, execution delays, volatility limits, and staleness timeouts.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | FeatureID (INT, CLUSTERED PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.Feature defines the catalog of trading execution features that can be individually configured per instrument. Each feature represents a specific aspect of trade execution quality control — how long prices remain valid, how much delay is acceptable, what volatility thresholds trigger protective actions, and when price data is considered stale.

This table exists because eToro's trading engine needs per-instrument fine-tuning of execution parameters. A highly liquid forex pair needs different price filter and volatility thresholds than a thinly traded stock. Without this classification, the system would have to apply one-size-fits-all execution rules, which would either reject too many valid trades on volatile instruments or allow unacceptable slippage on stable ones.

Feature definitions are consumed by Trade.ActiveFeatureThreshold (which links a FeatureID + InstrumentID to an active threshold level) and Trade.FeatureThresholdValues (which stores the actual numeric value for each Feature + Threshold + Instrument combination). Configuration is managed through the dealing Configuration Manager tool and is audited via INSERT/UPDATE/DELETE triggers on the consumer tables.

---

## 2. Business Logic

### 2.1 Feature-Threshold-Instrument Matrix

**What**: Each feature has five threshold levels per instrument, forming a 3-dimensional configuration matrix.

**Columns/Parameters Involved**: `FeatureID`, `Name`

**Rules**:
- Each Feature (e.g., "Price Filter") has 5 threshold tiers (Minimum/Low/Medium/High/Maximum) defined in Dictionary.FeatureThreshold
- Each Feature+Threshold combination gets a numeric value per instrument in Trade.FeatureThresholdValues
- Trade.ActiveFeatureThreshold selects which threshold level is currently active for each Feature+Instrument pair
- The active threshold determines the actual runtime behavior of the trading engine for that instrument

**Diagram**:
```
Dictionary.Feature (7 features)
    │
    ├── Trade.FeatureThresholdValues (Feature × Threshold × Instrument = numeric value)
    │       FeatureID + ThresholdID + InstrumentID → Value
    │
    └── Trade.ActiveFeatureThreshold (Feature × Instrument → active threshold level)
            FeatureID + InstrumentID → ActiveThresholdID (temporal, audited)
```

### 2.2 Feature Categories

**What**: Features fall into three categories: time-based (milliseconds), price-based (pips), and percentage-based.

**Columns/Parameters Involved**: `FeatureID`, `Name`

**Rules**:
- Time features (IDs 1, 2, 4, 7): measured in milliseconds — control execution timing and staleness detection
- Pip features (IDs 3, 5): measured in price pips — control price movement tolerance
- Percentage features (ID 6): measured as percentage — alternative volatility measurement

---

## 3. Data Overview

| FeatureID | Name | Meaning |
|---|---|---|
| 1 | Price Filter (MS) | Maximum allowed age of a price quote in milliseconds before the trading engine rejects it as stale. Prevents execution on outdated prices during fast-moving markets. |
| 2 | Execution Delay (MS) | Intentional delay in milliseconds before executing a trade. Used for requote protection and to allow price verification on instruments with high manipulation risk. |
| 3 | Rate Volatility (Pip) | Maximum allowed price movement in pips within a time window. When breached, the instrument may be temporarily suspended or trades rejected to protect against flash crashes. |
| 4 | Inactivity Timeout (MS) | Time in milliseconds after which a price feed is considered inactive/stale. Triggers alerts or automatic instrument suspension when no price updates arrive. |
| 5 | Limit Execution (Pip) | Maximum pip deviation allowed when executing limit orders. Controls how far from the requested limit price the system will still fill the order. |

| FeatureID | Name | Meaning |
|---|---|---|
| 6 | Rate Volatility (Percentage) | Alternative volatility measurement as a percentage of price rather than absolute pips. More suitable for instruments with widely varying price levels (e.g., crypto vs forex). |
| 7 | Price Stale timeout (MS) | Secondary staleness check — timeout specifically for price data freshness, distinct from the general inactivity timeout. May apply to specific price source scenarios. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FeatureID | int | NO | - | VERIFIED | Primary key identifying the execution feature type. 1=Price Filter (MS), 2=Execution Delay (MS), 3=Rate Volatility (Pip), 4=Inactivity Timeout (MS), 5=Limit Execution (Pip), 6=Rate Volatility (Percentage), 7=Price Stale timeout (MS). Referenced by Trade.ActiveFeatureThreshold and Trade.FeatureThresholdValues to link threshold values to specific execution features per instrument. |
| 2 | Name | nvarchar(50) | NO | - | VERIFIED | Human-readable label for the feature including its unit of measurement in parentheses (MS=milliseconds, Pip=price pips, Percentage). Used in the Configuration Manager UI and audit logs. Not a code-level identifier — FeatureID is used in all programmatic references. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ActiveFeatureThreshold | FeatureID | FK | Links active threshold level selection to this feature type per instrument (temporal, audited) |
| Trade.FeatureThresholdValues | FeatureID | FK | Stores numeric threshold values for each feature + threshold tier + instrument combination |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ActiveFeatureThreshold | Table | FK to FeatureID — stores which threshold tier is active per feature+instrument |
| Trade.FeatureThresholdValues | Table | FK to FeatureID — stores actual numeric values per feature+threshold+instrument |
| Dictionary.GetFeatures (PSConfigurations) | Stored Procedure | Reads all features for configuration UI |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Feature | CLUSTERED PK | FeatureID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Feature | PRIMARY KEY | Unique feature identifier |

---

## 8. Sample Queries

### 8.1 List all execution features
```sql
SELECT  FeatureID,
        Name
FROM    [Dictionary].[Feature] WITH (NOLOCK)
ORDER BY FeatureID;
```

### 8.2 Show active threshold level per feature for a specific instrument
```sql
SELECT  f.Name          AS FeatureName,
        ft.Name         AS ThresholdLevel,
        aft.ActiveThresholdID
FROM    [Trade].[ActiveFeatureThreshold] aft WITH (NOLOCK)
JOIN    [Dictionary].[Feature] f WITH (NOLOCK)
        ON aft.FeatureID = f.FeatureID
JOIN    [Dictionary].[FeatureThreshold] ft WITH (NOLOCK)
        ON aft.ActiveThresholdID = ft.ThresholdID
WHERE   aft.InstrumentID = @InstrumentID;
```

### 8.3 Show all threshold values for a specific instrument across all features
```sql
SELECT  f.Name          AS FeatureName,
        ft.Name         AS ThresholdTier,
        ftv.Value
FROM    [Trade].[FeatureThresholdValues] ftv WITH (NOLOCK)
JOIN    [Dictionary].[Feature] f WITH (NOLOCK)
        ON ftv.FeatureID = f.FeatureID
JOIN    [Dictionary].[FeatureThreshold] ft WITH (NOLOCK)
        ON ftv.ThresholdID = ft.ThresholdID
WHERE   ftv.InstrumentID = @InstrumentID
ORDER BY f.FeatureID, ft.ThresholdID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Feature | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Feature.sql*
