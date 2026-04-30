# Trade.FeatureThresholdValues

> Per-instrument, per-feature threshold value store that defines the numeric limits (e.g., milliseconds, pips, percentages) for each threshold level used by the dealing and validation subsystems.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID, FeatureID, ThresholdID (composite PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK) |

---

## 1. Business Meaning

Trade.FeatureThresholdValues stores the **numeric values** that define what each threshold level means for each instrument and feature. While Trade.ActiveFeatureThreshold selects which threshold (Minimum/Low/Medium/High/Maximum) is active per instrument-feature pair, this table holds the actual numbers: e.g., "Execution Delay (MS) at Low = 50 ms", "Inactivity Timeout (MS) at Maximum = 300000 ms". Features include price filter timing, execution delay, rate volatility (pip and percentage), inactivity timeout, limit execution, and price stale timeout.

This table exists because trading validation and dealing logic need concrete numeric limits. When CheckValidInstruments validates an instrument, it requires both ActiveFeatureThreshold (which level is active) and FeatureThresholdValues (what the numbers are). Without this table, the system cannot enforce instrument-specific limits for latency, volatility, or timeout behavior.

Data flows as follows: rows are created by Trade.InsertInstrumentRealTable during bulk instrument load from temp tables (##Trade_FeatureThresholdValues). Trade.UpdateFeatureThresholdValues MERGEs updates from a TVP. The table is read by Trade.CheckValidInstruments and Trade.CheckValidInstruments_bck for instrument validation. System versioning records changes to History.FeatureThresholdValues.

---

## 2. Business Logic

### 2.1 Feature-Threshold-Value Triangle

**What**: Each instrument has multiple features (e.g., Price Filter, Execution Delay). Each feature has multiple threshold levels (Minimum, Low, Medium, High, Maximum). This table stores the Value for each (InstrumentID, FeatureID, ThresholdID) combination.

**Columns/Parameters Involved**: `InstrumentID`, `FeatureID`, `ThresholdID`, `Value`

**Rules**:
- Value is decimal(20,2) - can represent milliseconds, pips, percentages, or counts depending on the feature
- Feature 4 (Inactivity Timeout) uses large values (e.g., 300000 = 5 minutes in ms); Feature 5 (Limit Execution) uses pip values (0, 50, 10000)
- Trade.UpdateFeatureThresholdValues MERGEs on (InstrumentID, FeatureID, ThresholdID) - matched rows update Value, new rows insert
- Trade.ActiveFeatureThreshold selects which ThresholdID is "active" for each instrument-feature; this table provides the Value at that level

**Diagram**:
```
Instrument 2008, Feature 4 (Inactivity Timeout):
  Threshold 15 (High)  -> Value 300000 (5 min)
  Threshold 20 (Max)   -> Value 300000 (5 min)
Instrument 2008, Feature 5 (Limit Execution):
  Threshold 0 (Min)    -> Value 0
  Threshold 10 (Medium) -> Value 50
  Threshold 20 (Max)    -> Value 10000
```

---

## 3. Data Overview

| InstrumentID | FeatureID | ThresholdID | Value | Meaning |
|--------------|-----------|-------------|-------|---------|
| 2008 | 4 | 15 | 300000 | Inactivity Timeout (MS) at High level - 5 minutes. Used when instrument requires extended timeout for inactivity detection. |
| 2008 | 4 | 20 | 300000 | Inactivity Timeout (MS) at Maximum - same 5 min cap at max level. |
| 2008 | 5 | 0 | 0 | Limit Execution (Pip) at Minimum - no pip threshold. |
| 2008 | 5 | 10 | 50 | Limit Execution (Pip) at Medium - 50 pips allowed from market for limit execution. |
| 2008 | 5 | 20 | 10000 | Limit Execution (Pip) at Maximum - 10000 pips at max level. |

**Selection criteria for the 5 rows:**
- Rows show different features (4 = Inactivity, 5 = Limit Execution) and threshold levels
- Values illustrate both small (50) and large (300000, 10000) numeric ranges typical of the table

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. Identifies the tradeable instrument. Part of composite PK. Used by InsertInstrumentRealTable and UpdateFeatureThresholdValues. |
| 2 | FeatureID | int | NO | - | CODE-BACKED | FK to Dictionary.Feature. Feature: 1=Price Filter (MS), 2=Execution Delay (MS), 3=Rate Volatility (Pip), 4=Inactivity Timeout (MS), 5=Limit Execution (Pip), 6=Rate Volatility (%), 7=Price Stale timeout (MS). Part of composite PK. |
| 3 | ThresholdID | int | NO | - | CODE-BACKED | FK to Dictionary.FeatureThreshold. Threshold level: 0=Minimum, 5=Low, 10=Medium, 15=High, 20=Maximum. Part of composite PK. |
| 4 | Value | decimal(20,2) | NO | - | CODE-BACKED | Numeric value for this threshold. Units depend on feature: ms for timing features, pips for execution/volatility, percentage for Feature 6. Audited on INSERT/UPDATE/DELETE. |
| 5 | DbLoginName | varchar(128) | NO | computed | CODE-BACKED | Computed: suser_name(). SQL login audit context. |
| 6 | AppLoginName | varchar(500) | NO | computed | CODE-BACKED | Computed: CONVERT(varchar(500), context_info()). Application context audit. |
| 7 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System-versioning row start. GENERATED ALWAYS AS ROW START. |
| 8 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | System-versioning row end. GENERATED ALWAYS AS ROW END. |
| 9 | HostName | nvarchar(128) | NO | computed | CODE-BACKED | Computed: host_name(). Server name for audit context. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK | Instrument this threshold applies to. |
| FeatureID | Dictionary.Feature | FK | Which feature (price filter, execution delay, etc.). |
| ThresholdID | Dictionary.FeatureThreshold | FK | Which level (Minimum/Low/Medium/High/Maximum). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InsertInstrumentRealTable | - | INSERT | Bulk load from ##Trade_FeatureThresholdValues |
| Trade.UpdateFeatureThresholdValues | - | MERGE | Updates/inserts via TVP |
| Trade.CheckValidInstruments | - | SELECT | Validates instrument has feature threshold values |
| Trade.CheckValidInstruments_bck | - | SELECT | Same validation in backup procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FeatureThresholdValues (table)
  -> Trade.Instrument (table)
  -> Dictionary.Feature (table)
  -> Dictionary.FeatureThreshold (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK InstrumentID |
| Dictionary.Feature | Table | FK FeatureID |
| Dictionary.FeatureThreshold | Table | FK ThresholdID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertInstrumentRealTable | Procedure | INSERT from temp table |
| Trade.UpdateFeatureThresholdValues | Procedure | MERGE (update/insert) |
| Trade.CheckValidInstruments | Procedure | SELECT validation |
| Trade.CheckValidInstruments_bck | Procedure | SELECT validation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FeatureThresholdValues | CLUSTERED | InstrumentID, FeatureID, ThresholdID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_FeatureThresholdValues | PRIMARY KEY | Unique (InstrumentID, FeatureID, ThresholdID) |
| FK_FeatureThresholdValues_Instrument | FOREIGN KEY | InstrumentID -> Trade.Instrument(InstrumentID) |
| FK_FeatureThresholdValues_Feature | FOREIGN KEY | FeatureID -> Dictionary.Feature(FeatureID) |
| FK_FeatureThresholdValues_FeatureThreshold | FOREIGN KEY | ThresholdID -> Dictionary.FeatureThreshold(ThresholdID) |
| DF_FeatureThresholdValues_SysStart | DEFAULT | getutcdate() for SysStartTime |
| DF_FeatureThresholdValues_SysEnd | DEFAULT | 9999-12-31 23:59:59.9999999 for SysEndTime |
| PERIOD FOR SYSTEM_TIME | SYSTEM VERSIONING | SysStartTime, SysEndTime -> History.FeatureThresholdValues |

---

## 8. Sample Queries

### 8.1 Get feature threshold values for an instrument
```sql
SELECT FTV.InstrumentID,
       FTV.FeatureID,
       F.Name AS FeatureName,
       FTV.ThresholdID,
       FT.Name AS ThresholdName,
       FTV.Value
FROM Trade.FeatureThresholdValues FTV WITH (NOLOCK)
JOIN Dictionary.Feature F WITH (NOLOCK) ON F.FeatureID = FTV.FeatureID
JOIN Dictionary.FeatureThreshold FT WITH (NOLOCK) ON FT.ThresholdID = FTV.ThresholdID
WHERE FTV.InstrumentID = 2008
ORDER BY FTV.FeatureID, FTV.ThresholdID;
```

### 8.2 Compare active threshold values across instruments
```sql
SELECT AFT.InstrumentID,
       AFT.FeatureID,
       F.Name AS FeatureName,
       FT.Name AS ActiveThresholdName,
       FTV.Value
FROM Trade.ActiveFeatureThreshold AFT WITH (NOLOCK)
JOIN Trade.FeatureThresholdValues FTV WITH (NOLOCK)
  ON FTV.InstrumentID = AFT.InstrumentID
  AND FTV.FeatureID = AFT.FeatureID
  AND FTV.ThresholdID = AFT.ActiveThresholdID
JOIN Dictionary.Feature F WITH (NOLOCK) ON F.FeatureID = AFT.FeatureID
JOIN Dictionary.FeatureThreshold FT WITH (NOLOCK) ON FT.ThresholdID = AFT.ActiveThresholdID
WHERE AFT.InstrumentID IN (1006, 1007, 2008)
ORDER BY AFT.InstrumentID, AFT.FeatureID;
```

### 8.3 Resolve all IDs to human-readable names
```sql
SELECT FTV.InstrumentID,
       F.Name AS FeatureName,
       FT.Name AS ThresholdName,
       FTV.Value
FROM Trade.FeatureThresholdValues FTV WITH (NOLOCK)
JOIN Dictionary.Feature F WITH (NOLOCK) ON F.FeatureID = FTV.FeatureID
JOIN Dictionary.FeatureThreshold FT WITH (NOLOCK) ON FT.ThresholdID = FTV.ThresholdID
WHERE FTV.FeatureID = 4
ORDER BY FTV.InstrumentID, FTV.ThresholdID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.4/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: DDL, LiveData, Grep*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: N/A | Corrections: 0 applied*
*Object: Trade.FeatureThresholdValues | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.FeatureThresholdValues.sql*
