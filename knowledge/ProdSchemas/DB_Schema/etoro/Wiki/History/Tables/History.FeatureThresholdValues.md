# History.FeatureThresholdValues

> SQL Server system-versioned temporal history table for Trade.FeatureThresholdValues, recording every change to the numeric execution quality parameter values at each per-instrument, per-feature, per-threshold-level combination.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (InstrumentID, FeatureID, ThresholdID, SysStartTime, SysEndTime) - no formal PK; temporal history semantics |
| **Partition** | No |
| **Indexes** | 1 (CLUSTERED on SysEndTime ASC, SysStartTime ASC, DATA_COMPRESSION=PAGE) |

---

## 1. Business Meaning

This table is the automatically maintained historical version store for `Trade.FeatureThresholdValues`. SQL Server's system-versioning feature manages this table transparently: whenever a row in `Trade.FeatureThresholdValues` is inserted, updated, or deleted, the previous row state is written here with SysStartTime/SysEndTime stamped to record the exact validity window. No application code writes directly to this table.

`Trade.FeatureThresholdValues` stores the actual numeric configuration values for each combination of instrument, feature type, and threshold severity level. The feature threshold system controls execution quality guardrails per instrument: features like Price Filter (milliseconds), Execution Delay (milliseconds), Rate Volatility (pips), and Inactivity Timeout (milliseconds) are each parameterized at five severity tiers (Minimum=0 through Maximum=20). `Trade.ActiveFeatureThreshold` selects which tier is currently active per instrument/feature; `Trade.FeatureThresholdValues` provides the numeric value at each tier. Changes to these values - e.g., raising the Price Filter threshold during high-volatility periods - are operationally significant and must be auditable for incident analysis.

Data flows automatically: any UPDATE or DELETE on `Trade.FeatureThresholdValues` causes SQL Server to route the previous row state here. Additionally, the INSERT trigger `Tr_T_FeatureThresholdValues_INSERT` fires a no-op UPDATE on every inserted row to force temporal capture of insertions (without this, newly-created rows would not appear in history until their first update). Three ASM-managed triggers (AuditInsert, AuditUpdate, AuditDelete) also write column-level changes to `History.AuditHistory` for the `Value` column specifically.

---

## 2. Business Logic

### 2.1 Five-Tier Threshold Matrix Per Instrument Per Feature

**What**: Each instrument stores five versions of each feature parameter - one per severity level (Minimum to Maximum). Trade.ActiveFeatureThreshold selects which tier is currently active; this table stores all five numeric values ready to switch.

**Columns/Parameters Involved**: `InstrumentID`, `FeatureID`, `ThresholdID`, `Value`

**Rules**:
- ThresholdID values are the five tier levels: 0=Minimum, 5=Low, 10=Medium, 15=High, 20=Maximum
- Each (InstrumentID, FeatureID) pair has exactly 5 rows in Trade.FeatureThresholdValues - one per ThresholdID
- For a given instrument, all five tiers may have the same Value (e.g., InstrumentID=797, Price Filter=300ms at all tiers) meaning no graduated response is configured
- Or tiers may differ (e.g., Minimum=50ms, Low=100ms, Medium=200ms, High=400ms, Maximum=800ms) for instruments where graduated execution quality is needed
- The 6 feature types: 1=Price Filter (MS), 2=Execution Delay (MS), 3=Rate Volatility (Pip), 4=Inactivity Timeout (MS), 5=Limit Execution (Pip), 6=Rate Volatility (Percentage)

**Diagram**:
```
For InstrumentID=797, FeatureID=1 (Price Filter MS):
  ThresholdID=0  (Minimum): Value=300ms
  ThresholdID=5  (Low):     Value=300ms
  ThresholdID=10 (Medium):  Value=300ms
  ThresholdID=15 (High):    Value=300ms
  ThresholdID=20 (Maximum): Value=300ms
  -> Same value at all tiers: no graduated response for this instrument's Price Filter

Trade.ActiveFeatureThreshold says: InstrumentID=797, FeatureID=1 -> ActiveThresholdID=0 (Minimum)
  -> Look up Value=300ms from FeatureThresholdValues WHERE InstrumentID=797, FeatureID=1, ThresholdID=0
  -> Apply 300ms as the current Price Filter for InstrumentID=797
```

### 2.2 Dual Audit System - Temporal Versioning and Column-Level Triggers

**What**: Trade.FeatureThresholdValues employs two complementary audit mechanisms, ensuring changes are captured at both the full-row and column-specific level.

**Columns/Parameters Involved**: `Value`, `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- **Temporal versioning (this table)**: Full-row snapshots for every change to any column. SysStartTime/SysEndTime bracket the validity window.
- **Column-level triggers (History.AuditHistory)**: Three ASM-managed triggers (AuditInsert, AuditUpdate, AuditDelete) individually track changes to the `Value` column. Each writes old/new values with UserName, AppName, HostName, Operation ('I'/'U'/'D'), and PK_Value = 'InstrumentID,FeatureID,ThresholdID'.
- **INSERT trigger pattern**: `Tr_T_FeatureThresholdValues_INSERT` fires FOR INSERT and immediately runs `UPDATE SET InstrumentID=InstrumentID` on the new row - forcing SQL Server temporal engine to write the just-inserted row into this history table. Without this, INSERTs are not captured by temporal versioning.
- This dual system is consistent with `Trade.ActiveFeatureThreshold`, `Trade.Instrument`, and other critical Trade tables.

### 2.3 Bulk Upsert via Table-Valued Type

**What**: The primary write path uses a MERGE statement with a user-defined table type, enabling efficient batch configuration updates across many instruments simultaneously.

**Columns/Parameters Involved**: `InstrumentID`, `FeatureID`, `ThresholdID`, `Value`

**Rules**:
- `Trade.UpdateFeatureThresholdValues` accepts `@Values Trade.FeatureThresholdValuesType READONLY` (a table-valued parameter)
- MERGE: if (InstrumentID, FeatureID, ThresholdID) exists -> UPDATE Value; if not -> INSERT new row
- Typical callers: `Internal.Newcurrency`, `Trade.InsertInstrumentRealTable`, `Stocks.AddNewStock` - used when onboarding new instruments or updating configuration in bulk
- Each row in the MERGE batch triggers one temporal history capture (for INSERTs, the trigger pattern; for UPDATEs, SQL Server temporal directly)

---

## 3. Data Overview

| InstrumentID | FeatureID | ThresholdID | Value | SysStartTime | SysEndTime | Meaning |
|---|---|---|---|---|---|---|
| 797 | 1 (Price Filter MS) | 0 (Minimum) | 300 | 2026-02-05 07:09:28 | 2026-02-05 07:09:28 | INSERT capture: Price Filter at Minimum tier = 300ms. SysStart=SysEnd confirms INSERT trigger pattern (instrument newly onboarded). |
| 797 | 2 (Execution Delay MS) | 0 (Minimum) | 0 | 2026-02-05 07:09:28 | 2026-02-05 07:09:28 | INSERT capture: Execution Delay at Minimum = 0ms (no artificial delay). Common default for instruments where immediate execution is preferred. |
| 797 | 4 (Inactivity Timeout MS) | 0 (Minimum) | 120000 | 2026-02-05 07:09:28 | 2026-02-05 07:09:28 | INSERT capture: Inactivity timeout = 120,000ms (2 minutes). Same value at all tiers for this instrument - timeout does not vary with volatility level. |
| 797 | 5 (Limit Execution Pip) | 0 (Minimum) | 0 | 2026-02-05 07:09:28 | 2026-02-05 07:09:28 | INSERT capture: Limit Execution threshold = 0 pips at Minimum tier (no limit execution restriction). |
| 797 | 1 (Price Filter MS) | 5 (Low) | 300 | 2026-02-05 07:09:28 | 2026-02-05 07:09:28 | Same Value (300ms) at Low tier as Minimum tier for this instrument, confirming uniform Price Filter regardless of threshold level selected by ActiveFeatureThreshold. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | Trading instrument identifier. Part of the source table's composite PK (InstrumentID, FeatureID, ThresholdID). FK to Trade.Instrument.InstrumentID in the source table - not enforced in this history table. Multiple rows with the same InstrumentID represent successive value versions across all feature/threshold combinations. |
| 2 | FeatureID | int | NO | - | VERIFIED | Execution quality feature type. Part of the composite PK. FK to Dictionary.Feature.FeatureID in source. Values: 1=Price Filter (MS), 2=Execution Delay (MS), 3=Rate Volatility (Pip), 4=Inactivity Timeout (MS), 5=Limit Execution (Pip), 6=Rate Volatility (Percentage). See History.ActiveFeatureThreshold Section 2.1 for full feature semantics. |
| 3 | ThresholdID | int | NO | - | VERIFIED | Threshold severity tier level. Part of the composite PK. FK to Dictionary.FeatureThreshold.ThresholdID in source. Values: 0=Minimum (most permissive), 5=Low, 10=Medium, 15=High, 20=Maximum (most restrictive). Each instrument stores a Value for each of these 5 tiers per feature. Trade.ActiveFeatureThreshold determines which tier is currently active. |
| 4 | Value | decimal(20,2) | NO | - | VERIFIED | The numeric threshold parameter value for this (InstrumentID, FeatureID, ThresholdID) combination at the time of this version. Units depend on FeatureID: milliseconds for FeatureIDs 1, 2, 4; pips for FeatureID 3, 5; percentage for FeatureID 6. This is the only column tracked individually by the AuditHistory column-level triggers (OldValue/NewValue = Value). |
| 5 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login name (suser_name()) of the session that made the configuration change captured in this version. Computed column in Trade.FeatureThresholdValues, materialized here at version creation. Identifies which operator or service account modified the threshold value. |
| 6 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application-level login from SQL Server context_info() at time of change. Computed column in Trade.FeatureThresholdValues as CONVERT(varchar(500), context_info()). NULL if the calling application did not set context_info (NULL in all observed live data). |
| 7 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this row version became active in Trade.FeatureThresholdValues. For INSERT-trigger-captured rows, equals SysEndTime (same transaction). For UPDATE-superseded rows, marks when the new value took effect. |
| 8 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this row version was superseded. CLUSTERED index leading column for temporal range scans. SysEndTime=SysStartTime marks rows captured by the INSERT trigger pattern (creation events with zero-duration version). |
| 9 | HostName | nvarchar(128) | YES | - | CODE-BACKED | Client hostname (host_name()) of the session that made the change. Computed column in Trade.FeatureThresholdValues, materialized here at version creation. Present in observed live data (e.g., "PF5L1WW5"). Extends the audit identity beyond Login/App to include the machine. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | History.Instrument | Implicit | Identifies the trading instrument whose threshold value version this records. No FK constraint in history table by SQL Server design. |
| FeatureID | Dictionary.Feature | Implicit | Identifies the execution quality feature type. FK is on Trade.FeatureThresholdValues. |
| ThresholdID | Dictionary.FeatureThreshold | Implicit | Identifies the severity tier (Minimum/Low/Medium/High/Maximum). FK is on Trade.FeatureThresholdValues. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FeatureThresholdValues | SYSTEM_VERSIONING | Temporal history source | SQL Server automatically routes superseded row versions here on UPDATE/DELETE; INSERT trigger forces creation capture. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.FeatureThresholdValues (table)
- no code-level dependencies (leaf table, temporal history)
```

### 6.1 Objects This Depends On

No dependencies. Temporal history tables have no FK constraints or code references.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FeatureThresholdValues | Table | Source temporal table - SQL Server writes superseded row versions here; INSERT trigger captures creations |
| Trade.UpdateFeatureThresholdValues | Stored Procedure | Primary writer to source table via MERGE; changes propagate here via temporal versioning |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_FeatureThresholdValues | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (DATA_COMPRESSION=PAGE) |

No primary key constraint. Standard SQL Server temporal history clustered index pattern. Table is on [PRIMARY] filegroup.

### 7.2 Constraints

None. Temporal history tables intentionally have no CHECK, UNIQUE, DEFAULT, or FOREIGN KEY constraints.

---

## 8. Sample Queries

### 8.1 What were all threshold values for an instrument at a point in time?

```sql
-- Use FOR SYSTEM_TIME on the source table, not this history table directly
SELECT
    ftv.InstrumentID,
    ftv.FeatureID,
    f.Name AS FeatureName,
    ftv.ThresholdID,
    ftv.Value,
    ftv.SysStartTime,
    ftv.SysEndTime,
    ftv.DbLoginName
FROM Trade.FeatureThresholdValues FOR SYSTEM_TIME AS OF '2025-06-01T00:00:00' ftv WITH (NOLOCK)
JOIN Dictionary.Feature f WITH (NOLOCK) ON f.FeatureID = ftv.FeatureID
WHERE ftv.InstrumentID = @InstrumentID
ORDER BY ftv.FeatureID, ftv.ThresholdID;
```

### 8.2 Change history for a specific instrument/feature/tier combination

```sql
SELECT
    h.InstrumentID,
    h.FeatureID,
    f.Name AS FeatureName,
    h.ThresholdID,
    h.Value,
    h.SysStartTime AS ValidFrom,
    h.SysEndTime AS ValidUntil,
    h.DbLoginName AS ChangedBy,
    h.HostName,
    DATEDIFF(SECOND, h.SysStartTime, h.SysEndTime) AS VersionDurationSeconds
FROM History.FeatureThresholdValues h WITH (NOLOCK)
JOIN Dictionary.Feature f WITH (NOLOCK) ON f.FeatureID = h.FeatureID
WHERE h.InstrumentID = @InstrumentID
  AND h.FeatureID = @FeatureID
  AND h.ThresholdID = @ThresholdID
ORDER BY h.SysStartTime ASC;
```

### 8.3 Find instruments where Price Filter value changed, with before/after values

```sql
SELECT
    h.InstrumentID,
    h.ThresholdID,
    h.Value AS OldValue,
    curr.Value AS NewValue,
    h.SysEndTime AS ChangeTime,
    h.DbLoginName AS ChangedBy
FROM History.FeatureThresholdValues h WITH (NOLOCK)
JOIN Trade.FeatureThresholdValues curr WITH (NOLOCK)
    ON h.InstrumentID = curr.InstrumentID
    AND h.FeatureID = curr.FeatureID
    AND h.ThresholdID = curr.ThresholdID
WHERE h.FeatureID = 1  -- Price Filter (MS)
  AND h.SysEndTime >= @StartDate
  AND h.SysEndTime <  @EndDate
  AND DATEDIFF(MILLISECOND, h.SysStartTime, h.SysEndTime) > 100  -- exclude INSERT captures
  AND h.Value <> curr.Value
ORDER BY h.SysEndTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (Trade.UpdateFeatureThresholdValues, Trade.InsertInstrumentRealTable) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.FeatureThresholdValues | Type: Table | Source: etoro/etoro/History/Tables/History.FeatureThresholdValues.sql*
