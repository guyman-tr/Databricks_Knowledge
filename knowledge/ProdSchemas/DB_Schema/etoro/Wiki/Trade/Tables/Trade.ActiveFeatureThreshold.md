# Trade.ActiveFeatureThreshold

> Configures which threshold level (Minimum, Low, Medium, High, Maximum) is currently active for each instrument-feature pair, driving trading behavior such as execution delay, rate volatility limits, and inactivity timeouts.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID, FeatureID (composite PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK) |

---

## 1. Business Meaning

Trade.ActiveFeatureThreshold defines the **active sensitivity level** for each trading feature per instrument. Features include Price Filter (MS), Execution Delay (MS), Rate Volatility (Pip), Inactivity Timeout (MS), Limit Execution (Pip), and Rate Volatility (Percentage). Each instrument can have different sensitivity settings - for example, a high-liquidity forex pair may allow lower execution delays than a thinly traded stock.

This table exists because the order matching and hedging subsystems need per-instrument thresholds to balance latency, risk, and execution quality. Without it, all instruments would share the same settings. CheckValidInstruments validates that every instrument has at least one row here before trading is enabled. The view Trade.GetActiveFeatureThresholds pivots this data for easy consumption (Feature1 through Feature6 columns).

Data flows as follows: rows are created by Trade.InsertInstrumentRealTable during instrument bulk load from staging tables (##Trade_ActiveFeatureThreshold). The table is read by Trade.CheckValidInstruments (validates instrument config completeness), Trade.CheckValidInstruments_bck, and Trade.GetActiveFeatureThresholds. System versioning records all changes to History.ActiveFeatureThreshold.

---

## 2. Business Logic

### 2.1 Instrument-Feature-Threshold Matrix

**What**: Each (InstrumentID, FeatureID) pair has exactly one active threshold level. The threshold level determines the numeric value used from Trade.FeatureThresholdValues.

**Columns/Parameters Involved**: `InstrumentID`, `FeatureID`, `ActiveThresholdID`

**Rules**:
- ActiveThresholdID references Dictionary.FeatureThreshold.ThresholdID implicitly (0=Minimum, 5=Low, 10=Medium, 15=High, 20=Maximum)
- For FeatureID 1 (Price Filter): 0 = Minimum means least restrictive; 20 = Maximum means most restrictive
- Trade.FeatureThresholdValues stores the actual numeric values per (InstrumentID, FeatureID, ThresholdID); this table selects which threshold level is currently active
- CheckValidInstruments fails if an instrument has no row in this table - every tradeable instrument must have feature thresholds configured

**Diagram**:
```
Instrument 1006, Feature 1 (Price Filter) -> ActiveThresholdID 0 (Minimum)
Instrument 1006, Feature 2 (Execution Delay) -> ActiveThresholdID 5 (Low)
Instrument 1006, Feature 3-6 -> ActiveThresholdID 20 (Maximum)
```

### 2.2 Pivoted View for Application Consumption

**What**: Trade.GetActiveFeatureThresholds pivots rows into columns (Feature1..Feature6) so calling code can read threshold IDs without joining.

**Columns/Parameters Involved**: InstrumentID, FeatureID (1-6), ActiveThresholdID

**Rules**:
- View uses PIVOT to transform one row per (InstrumentID, FeatureID) into one row per InstrumentID with Feature1..Feature6
- Features 1-6 correspond to Dictionary.Feature IDs 1-6 (Price Filter, Execution Delay, Rate Volatility Pip, Inactivity Timeout, Limit Execution, Rate Volatility Percentage)
- Feature 7 (Price Stale timeout) is not in the pivot - may be used differently

---

## 3. Data Overview

| InstrumentID | FeatureID | ActiveThresholdID | Meaning |
|---|---|---|---|
| 1006 | 1 | 0 | Price Filter at Minimum - least restrictive for this instrument |
| 1006 | 2 | 5 | Execution Delay at Low - moderate delay tolerance |
| 1006 | 3 | 20 | Rate Volatility (Pip) at Maximum - strictest volatility limit |
| 1007 | 1 | 0 | Same instrument type pattern - Price Filter Minimum |
| 1007 | 2 | 5 | Execution Delay Low |

**Selection criteria for the 5 rows:**
- Instrument 1006 and 1007 show the typical pattern: Feature 1 at Minimum (0), Feature 2 at Low (5), Features 3-6 at Maximum (20)
- Represents configuration for execution-sensitive instruments

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. The tradeable instrument this threshold config applies to. Referenced by CheckValidInstruments and InsertInstrumentRealTable. |
| 2 | FeatureID | int | NO | - | CODE-BACKED | FK to Dictionary.Feature. Feature being configured: 1=Price Filter (MS), 2=Execution Delay (MS), 3=Rate Volatility (Pip), 4=Inactivity Timeout (MS), 5=Limit Execution (Pip), 6=Rate Volatility (Percentage), 7=Price Stale timeout (MS). |
| 3 | ActiveThresholdID | int | NO | - | CODE-BACKED | Implicit FK to Dictionary.FeatureThreshold.ThresholdID. Active sensitivity level: 0=Minimum, 5=Low, 10=Medium, 15=High, 20=Maximum. Determines which row in Trade.FeatureThresholdValues is used for this instrument-feature. |
| 4 | DbLoginName | varchar(128) | NO | computed | CODE-BACKED | Computed: suser_name(). SQL login that last modified the row. Audit context. |
| 5 | AppLoginName | varchar(500) | NO | computed | CODE-BACKED | Computed: CONVERT(varchar(500), context_info()). Application context from context_info. |
| 6 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System-versioning start. When this row became effective. GENERATED ALWAYS AS ROW START. |
| 7 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | System-versioning end. When this row was superseded. GENERATED ALWAYS AS ROW END. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK | The tradeable instrument |
| FeatureID | Dictionary.Feature | FK | The feature being configured (Price Filter, Execution Delay, etc.) |
| ActiveThresholdID | Dictionary.FeatureThreshold | Implicit | Which sensitivity level (Minimum..Maximum) is active |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CheckValidInstruments | - | EXISTS/SELECT | Validates instrument has threshold config; fails if missing |
| Trade.CheckValidInstruments_bck | - | EXISTS/SELECT | Same validation in backup procedure |
| Trade.InsertInstrumentRealTable | - | INSERT | Bulk load from ##Trade_ActiveFeatureThreshold |
| Trade.GetActiveFeatureThresholds | - | FROM | Pivots this table for application consumption |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ActiveFeatureThreshold (table)
  -> Trade.Instrument (table)
  -> Dictionary.Feature (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK InstrumentID references InstrumentID |
| Dictionary.Feature | Table | FK FeatureID references FeatureID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CheckValidInstruments | Procedure | EXISTS validation, SELECT |
| Trade.CheckValidInstruments_bck | Procedure | EXISTS validation, SELECT |
| Trade.InsertInstrumentRealTable | Procedure | INSERT |
| Trade.GetActiveFeatureThresholds | View | FROM, PIVOT |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ActiveFeatureThreshold | CLUSTERED | InstrumentID, FeatureID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ActiveFeatureThreshold | PRIMARY KEY | Unique (InstrumentID, FeatureID) |
| FK_ActiveFeatureThreshold_Feature | FOREIGN KEY | FeatureID -> Dictionary.Feature(FeatureID) |
| FK_ActiveFeatureThreshold_Instrument | FOREIGN KEY | InstrumentID -> Trade.Instrument(InstrumentID) |
| DF_ActiveFeatureThreshold_SysStart | DEFAULT | getutcdate() for SysStartTime |
| DF_ActiveFeatureThreshold_SysEnd | DEFAULT | 9999-12-31 23:59:59.9999999 for SysEndTime |
| PERIOD FOR SYSTEM_TIME | SYSTEM VERSIONING | SysStartTime, SysEndTime -> History.ActiveFeatureThreshold |

---

## 8. Sample Queries

### 8.1 Get active thresholds for an instrument
```sql
SELECT AFT.InstrumentID,
       AFT.FeatureID,
       F.Name AS FeatureName,
       AFT.ActiveThresholdID,
       FT.Name AS ThresholdName
FROM Trade.ActiveFeatureThreshold AFT WITH (NOLOCK)
JOIN Dictionary.Feature F WITH (NOLOCK) ON F.FeatureID = AFT.FeatureID
LEFT JOIN Dictionary.FeatureThreshold FT WITH (NOLOCK) ON FT.ThresholdID = AFT.ActiveThresholdID
WHERE AFT.InstrumentID = 1006
ORDER BY AFT.FeatureID;
```

### 8.2 Use pivoted view for threshold lookup
```sql
SELECT InstrumentID,
       Feature1 AS PriceFilterThreshold,
       Feature2 AS ExecutionDelayThreshold,
       Feature3 AS RateVolatilityPipThreshold,
       Feature4 AS InactivityTimeoutThreshold
FROM Trade.GetActiveFeatureThresholds WITH (NOLOCK)
WHERE InstrumentID = 1006;
```

### 8.3 Instruments with Maximum rate volatility (Feature 3)
```sql
SELECT AFT.InstrumentID,
       I.InstrumentID,
       AFT.ActiveThresholdID
FROM Trade.ActiveFeatureThreshold AFT WITH (NOLOCK)
JOIN Trade.Instrument I WITH (NOLOCK) ON I.InstrumentID = AFT.InstrumentID
WHERE AFT.FeatureID = 3
  AND AFT.ActiveThresholdID = 20
ORDER BY AFT.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: DDL, LiveData, Grep*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: N/A | Corrections: 0 applied*
*Object: Trade.ActiveFeatureThreshold | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.ActiveFeatureThreshold.sql*
