# History.ActiveFeatureThreshold

> Temporal history table for Trade.ActiveFeatureThreshold, capturing all changes to the per-instrument execution quality feature threshold selections (Price Filter, Execution Delay, Rate Volatility, etc.).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Clustered index on (SysEndTime, SysStartTime) - temporal history access pattern |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime, SysStartTime, PAGE compressed) |

---

## 1. Business Meaning

History.ActiveFeatureThreshold is the SQL Server system-versioning history table for `Trade.ActiveFeatureThreshold`, which stores the currently-selected execution quality threshold level for each (InstrumentID, FeatureID) pair. Every time the active threshold for an instrument's execution feature is changed - e.g., raising the Price Filter from Low to Maximum during high-volatility periods - the old configuration version is moved here automatically by the temporal mechanism.

The source table `Trade.ActiveFeatureThreshold` acts as a pointer: for each instrument and each feature type, it says "the currently active threshold level is X." The actual numeric threshold values live in `Trade.FeatureThresholdValues` (the threshold levels themselves). Together these two tables control execution quality guardrails per instrument:

- `Dictionary.Feature` defines the feature type (what is being filtered/limited)
- `Dictionary.FeatureThreshold` defines the threshold severity levels: 0=Minimum, 5=Low, 10=Medium, 15=High, 20=Maximum
- `Trade.FeatureThresholdValues` stores the numeric value at each (InstrumentID, FeatureID, ThresholdID) combination
- `Trade.ActiveFeatureThreshold` selects which ThresholdID is currently active per instrument/feature
- This history table records every change to that selection

Use cases: "What was the Rate Volatility threshold for InstrumentID=797 before Feb 2026?" and "Which instruments had their thresholds changed during a specific market event?" With 56,877 history rows across 10,499 instruments since September 2021, this table shows active operational management of execution quality across the instrument universe.

Data flows in automatically via SQL Server SYSTEM_VERSIONING. Additionally, three ASM-managed triggers (AuditInsert, AuditUpdate, AuditDelete) write changes to `History.AuditHistory`. The no-op INSERT trigger `Tr_T_ActiveFeatureThreshold_INSERT` forces temporal capture of INSERTs by performing an UPDATE on the inserted row (same pattern used in other Trade temporal tables).

---

## 2. Business Logic

### 2.1 Execution Feature Threshold System

**What**: Per-instrument threshold levels control how aggressively the trading engine applies execution quality filters for each instrument.

**Columns/Parameters Involved**: `InstrumentID`, `FeatureID`, `ActiveThresholdID`

**Rules**:
- Each instrument can independently have a different threshold level for each feature type
- Threshold levels (ActiveThresholdID) follow a 5-level severity scale:
  - 0 = Minimum (most permissive - few rejections)
  - 5 = Low
  - 10 = Medium
  - 15 = High
  - 20 = Maximum (most restrictive - highest rejection rate)
- The numeric value at the active threshold is looked up in `Trade.FeatureThresholdValues` by matching (InstrumentID, FeatureID, ThresholdID=ActiveThresholdID)
- The 6 active feature types and their units:
  - FeatureID 1: Price Filter (MS) - milliseconds
  - FeatureID 2: Execution Delay (MS) - milliseconds
  - FeatureID 3: Rate Volatility (Pip) - pips
  - FeatureID 4: Inactivity Timeout (MS) - milliseconds
  - FeatureID 5: Limit Execution (Pip) - pips
  - FeatureID 6: Rate Volatility (Percentage) - percent

**Diagram**:
```
Dictionary.Feature (FeatureID 1-6) + Dictionary.FeatureThreshold (0/5/10/15/20)
    |
    v
Trade.FeatureThresholdValues (InstrumentID, FeatureID, ThresholdID -> numeric Value)
    |
Trade.ActiveFeatureThreshold (InstrumentID, FeatureID -> ActiveThresholdID)
    |
    "For InstrumentID=797, FeatureID=6 (Rate Volatility %), use ThresholdID=20 (Maximum)"
    |
    "Look up Trade.FeatureThresholdValues WHERE InstrumentID=797, FeatureID=6, ThresholdID=20"
    |
    "Apply that numeric value as the current volatility rejection threshold"
```

### 2.2 Temporal Audit - Change History

**What**: Every change to an instrument's active threshold is recorded here automatically by SYSTEM_VERSIONING.

**Columns/Parameters Involved**: `InstrumentID`, `FeatureID`, `ActiveThresholdID`, `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- INSERT on source -> no-op UPDATE trigger fires -> temporal engine writes an INSERT-capture row with SysStart = SysEnd (same transaction timestamp)
- UPDATE on source -> the previous row version moves here; SysEndTime = when the new value took effect
- DELETE on source -> the last row version moves here
- For a given (InstrumentID, FeatureID), the full change history is reconstructed by querying this table ordered by SysStartTime
- The `FOR SYSTEM_TIME AS OF` syntax on the source table implicitly uses this history table to reconstruct point-in-time state

---

## 3. Data Overview

56,877 history rows for 10,499 instruments across 6 features, from September 2021 to February 2026. The most common current state is ActiveThresholdID=20 (Maximum, 22,913 records) followed by 0 (Minimum, 21,149 records) and 5 (Low, 12,747 records) - indicating instruments are typically at extreme settings (fully enabled or disabled). FeatureID=6 (Rate Volatility Percentage) has the most change history (15,375 rows).

| InstrumentID | FeatureID | ActiveThresholdID | SysStartTime | SysEndTime | Meaning |
|---|---|---|---|---|---|
| 797 | 1 | 0 | 2026-02-05 07:09:28 | 2026-02-05 07:09:28 | INSERT capture: Price Filter for InstrumentID=797 set to Minimum (0). SysStart=SysEnd confirms INSERT trigger pattern. |
| 797 | 2 | 5 | 2026-02-05 07:09:28 | 2026-02-05 07:09:28 | INSERT capture: Execution Delay for same instrument set to Low (5). Same bulk operation timestamp. |
| 797 | 3 | 20 | 2026-02-05 07:09:28 | 2026-02-05 07:09:28 | INSERT capture: Rate Volatility (Pip) set to Maximum (20). Instrument entering with conservative volatility filtering. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | The trading instrument whose feature threshold changed. FK to Trade.Instrument(InstrumentID) in the source table - not enforced in this history table. Part of the natural key for point-in-time lookups. |
| 2 | FeatureID | int | NO | - | VERIFIED | The execution quality feature type whose threshold changed. FK to Dictionary.Feature(FeatureID) in the source. Values: 1=Price Filter (MS), 2=Execution Delay (MS), 3=Rate Volatility (Pip), 4=Inactivity Timeout (MS), 5=Limit Execution (Pip), 6=Rate Volatility (Percentage). |
| 3 | ActiveThresholdID | int | NO | - | VERIFIED | The threshold level that was active for this (InstrumentID, FeatureID) during the SysStartTime-SysEndTime interval. References Dictionary.FeatureThreshold(ThresholdID). Values: 0=Minimum (most permissive), 5=Low, 10=Medium, 15=High, 20=Maximum (most restrictive). This is the column tracked by the AuditHistory triggers (OldValue/NewValue = ActiveThresholdID). |
| 4 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | Database login name that made the change. Computed column in source (suser_name()), stored as literal in history. Identifies the service account, application, or DBA that modified the threshold. |
| 5 | AppLoginName | varchar(500) | YES | - | VERIFIED | Application-level session context at change time. Computed from context_info() in source table. Identifies the application or admin tool responsible for the threshold change. NULL if context_info was not set. |
| 6 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this threshold configuration became active in Trade.ActiveFeatureThreshold. For INSERT-captured rows: equals SysEndTime (same transaction, no-op UPDATE trigger). |
| 7 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this threshold configuration was superseded. First column of the clustered index (SysEndTime, SysStartTime) optimizing FOR SYSTEM_TIME AS OF queries. For INSERT-captured rows: equals SysStartTime. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. Temporal history tables carry no FK constraints.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ActiveFeatureThreshold | (temporal system) | Source Table | SQL Server SYSTEM_VERSIONING writes superseded row versions here automatically. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ActiveFeatureThreshold (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies. Temporal history tables have no FK constraints.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ActiveFeatureThreshold | Table | Source - SQL Server temporal moves superseded rows here. FOR SYSTEM_TIME queries implicitly access this table. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_ActiveFeatureThreshold | CLUSTERED (PAGE compressed) | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (none) | - | Temporal history tables have no PK or FK constraints by SQL Server design. |

---

## 8. Sample Queries

### 8.1 Full change history for a specific instrument and feature
```sql
SELECT
    InstrumentID,
    FeatureID,
    ActiveThresholdID,
    ft.Name AS ThresholdName,
    SysStartTime AS ValidFrom,
    SysEndTime   AS ValidTo,
    DbLoginName,
    AppLoginName
FROM History.ActiveFeatureThreshold WITH (NOLOCK)
INNER JOIN Dictionary.FeatureThreshold ft WITH (NOLOCK)
    ON ft.ThresholdID = ActiveThresholdID
WHERE InstrumentID = 797
  AND FeatureID = 6
ORDER BY SysStartTime ASC;
```

### 8.2 Point-in-time state of all thresholds for an instrument
```sql
SELECT
    aft.InstrumentID,
    f.Name AS FeatureName,
    aft.ActiveThresholdID,
    ft.Name AS ThresholdLevel
FROM Trade.ActiveFeatureThreshold aft
FOR SYSTEM_TIME AS OF '2025-01-01T00:00:00.000'
INNER JOIN Dictionary.Feature f WITH (NOLOCK)
    ON aft.FeatureID = f.FeatureID
INNER JOIN Dictionary.FeatureThreshold ft WITH (NOLOCK)
    ON aft.ActiveThresholdID = ft.ThresholdID
WHERE aft.InstrumentID = 797
ORDER BY aft.FeatureID;
```

### 8.3 Instruments that had threshold changes in a date range
```sql
SELECT DISTINCT
    InstrumentID,
    FeatureID,
    COUNT(*) AS ChangeCount,
    MIN(SysStartTime) AS FirstChange,
    MAX(SysEndTime) AS LastChange
FROM History.ActiveFeatureThreshold WITH (NOLOCK)
WHERE SysStartTime >= '2026-01-01'
  AND SysStartTime < '2026-04-01'
  AND ABS(DATEDIFF(millisecond, SysStartTime, SysEndTime)) > 100 -- exclude INSERT captures
GROUP BY InstrumentID, FeatureID
ORDER BY ChangeCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ActiveFeatureThreshold | Type: Table | Source: etoro/etoro/History/Tables/History.ActiveFeatureThreshold.sql*
