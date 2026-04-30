# Dictionary.FeatureThreshold

> Lookup table defining the five threshold severity tiers (Minimum through Maximum) used to classify trading execution feature sensitivity levels per instrument.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ThresholdID (INT, CLUSTERED PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.FeatureThreshold defines the five severity tiers that classify how aggressively a trading execution feature is configured for a given instrument. Each tier (Minimum, Low, Medium, High, Maximum) represents a progressively stricter threshold level — for example, a "High" Price Filter threshold would reject prices more aggressively than a "Low" one.

This table exists because the dealing team needs a standardized vocabulary for threshold severity across all feature types. Rather than storing raw numeric values without context, the system categorizes thresholds into named tiers that the Configuration Manager UI can display. This allows dealers to quickly understand and compare instrument configurations — "Instrument X has High volatility threshold" is more meaningful than "Instrument X has threshold value 42."

ThresholdID values are consumed by Trade.FeatureThresholdValues (which maps each Feature + Threshold + Instrument to a numeric value) and Trade.ActiveFeatureThreshold (which records which tier is currently active). The IDs are spaced at intervals of 5 (0, 5, 10, 15, 20) rather than sequential, allowing future insertion of intermediate tiers if needed.

---

## 2. Business Logic

### 2.1 Threshold Tier Hierarchy

**What**: The five tiers form an ordered severity scale from least to most restrictive.

**Columns/Parameters Involved**: `ThresholdID`, `Name`

**Rules**:
- Minimum (0): Least restrictive — widest tolerances, most permissive execution
- Low (5): Below-average restriction
- Medium (10): Default/balanced threshold level
- High (15): Above-average restriction — tighter tolerances
- Maximum (20): Most restrictive — narrowest tolerances, most protective

**Diagram**:
```
Threshold Severity Scale:
Minimum (0) ──► Low (5) ──► Medium (10) ──► High (15) ──► Maximum (20)
  least                      balanced                       most
  restrictive                                               restrictive
```

---

## 3. Data Overview

| ThresholdID | Name | Meaning |
|---|---|---|
| 0 | Minimum | Least restrictive threshold tier. Applied to stable, highly liquid instruments where tight controls would cause unnecessary trade rejections. Widest price filter windows, lowest volatility sensitivity. |
| 5 | Low | Below-average restriction. Suitable for instruments with moderate liquidity where some protection is needed but aggressive filtering would impair execution rates. |
| 10 | Medium | Default/balanced threshold tier. Standard protection level applied as baseline before per-instrument tuning. Balances execution success rate against price protection. |
| 15 | High | Above-average restriction. Applied to instruments showing elevated volatility or thin liquidity. Tighter price filters and shorter staleness windows. |
| 20 | Maximum | Most restrictive threshold tier. Applied to instruments during extreme market conditions, newly listed instruments, or those with known manipulation risk. Narrowest tolerances. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ThresholdID | int | NO | - | VERIFIED | Primary key identifying the threshold severity tier. Values are spaced at intervals of 5 (0=Minimum, 5=Low, 10=Medium, 15=High, 20=Maximum) to allow future intermediate tiers. Referenced by Trade.FeatureThresholdValues and Trade.ActiveFeatureThreshold to classify execution feature sensitivity levels per instrument. |
| 2 | Name | nvarchar(50) | NO | - | VERIFIED | Human-readable label for the threshold tier (Minimum/Low/Medium/High/Maximum). Used in the Configuration Manager UI for display and in audit logs when threshold levels are changed by the dealing team. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FeatureThresholdValues | ThresholdID | FK | Stores numeric value for each feature + threshold tier + instrument combination |
| Trade.ActiveFeatureThreshold | ActiveThresholdID | Implicit Lookup | References which threshold tier is active (maps to ThresholdID) |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FeatureThresholdValues | Table | FK to ThresholdID — stores actual numeric values per feature+threshold+instrument |
| Trade.ActiveFeatureThreshold | Table | References ThresholdID via ActiveThresholdID column |
| Dictionary.GetFeatureThresholds (PSConfigurations) | Stored Procedure | Reads all threshold tiers for configuration UI |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FeatureThreshold | CLUSTERED PK | ThresholdID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_FeatureThreshold | PRIMARY KEY | Unique threshold tier identifier |

---

## 8. Sample Queries

### 8.1 List all threshold tiers
```sql
SELECT  ThresholdID,
        Name
FROM    [Dictionary].[FeatureThreshold] WITH (NOLOCK)
ORDER BY ThresholdID;
```

### 8.2 Show threshold values for a feature across all tiers for an instrument
```sql
SELECT  ft.Name         AS ThresholdTier,
        ftv.Value
FROM    [Trade].[FeatureThresholdValues] ftv WITH (NOLOCK)
JOIN    [Dictionary].[FeatureThreshold] ft WITH (NOLOCK)
        ON ftv.ThresholdID = ft.ThresholdID
WHERE   ftv.FeatureID = @FeatureID
        AND ftv.InstrumentID = @InstrumentID
ORDER BY ft.ThresholdID;
```

### 8.3 Find instruments using Maximum threshold for any feature
```sql
SELECT  f.Name      AS FeatureName,
        dc.Name     AS InstrumentName,
        ft.Name     AS ThresholdLevel
FROM    [Trade].[ActiveFeatureThreshold] aft WITH (NOLOCK)
JOIN    [Dictionary].[Feature] f WITH (NOLOCK)
        ON aft.FeatureID = f.FeatureID
JOIN    [Dictionary].[FeatureThreshold] ft WITH (NOLOCK)
        ON aft.ActiveThresholdID = ft.ThresholdID
JOIN    [Dictionary].[Currency] dc WITH (NOLOCK)
        ON aft.InstrumentID = dc.CurrencyID
WHERE   aft.ActiveThresholdID = 20
ORDER BY f.Name, dc.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.FeatureThreshold | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.FeatureThreshold.sql*
