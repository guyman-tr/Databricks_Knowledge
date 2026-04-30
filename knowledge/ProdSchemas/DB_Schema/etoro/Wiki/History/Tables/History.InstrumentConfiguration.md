# History.InstrumentConfiguration

> SQL Server temporal history table storing prior row versions of Price.InstrumentConfiguration, capturing every change to per-instrument spread alert, spread lock, skew limit, and max spread threshold settings.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No |
| **Indexes** | 1 (clustered on temporal system columns) |

---

## 1. Business Meaning

History.InstrumentConfiguration is the SQL Server system-versioning history table for Price.InstrumentConfiguration, declared as `HISTORY_TABLE = [History].[InstrumentConfiguration]` in the Price.InstrumentConfiguration DDL. Whenever a row in Price.InstrumentConfiguration is updated or deleted, the previous configuration values are written here by the SQL Server temporal engine.

Price.InstrumentConfiguration holds one row per instrument containing spread and skew quality thresholds used by the pricing engine. These thresholds control when the system raises alerts (spread too wide) or locks pricing (spread exceeds the lock threshold). The history table allows post-hoc investigation: operators can determine exactly what thresholds were in effect during a period of abnormal pricing, and trace when configurations were changed and by whom.

The trigger TRG_T_InstrumentConfiguration fires on each INSERT and performs a no-op self-UPDATE, causing an immediate history record with SysStartTime = SysEndTime. This means every new instrument configuration row produces an insert artifact in the history table.

6,427 history rows span from September 2021 to February 2026. The oldest batch (2021-09-13) likely represents a bulk migration event when temporal versioning was enabled for this table.

---

## 2. Business Logic

### 2.1 SQL Server Temporal Versioning Mechanics

**What**: SQL Server writes superseded row versions from Price.InstrumentConfiguration into this table on each UPDATE or DELETE.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `InstrumentID`

**Rules**:
- One history row per configuration change per instrument
- INSERT trigger TRG_T_InstrumentConfiguration produces an immediate history record (SysStartTime = SysEndTime)
- CLUSTERED INDEX on (SysEndTime, SysStartTime) optimizes FOR SYSTEM_TIME AS OF range queries

### 2.2 Spread Quality Threshold Configuration

**What**: Each instrument has four pricing quality thresholds that the Price engine monitors in real time.

**Columns/Parameters Involved**: `SpreadAlertThresholdPercentage`, `SpreadLockThresholdPercentage`, `SkewLimitThreshold`, `EtoroMaxSpreadPercentage`

**Rules**:
- SpreadAlertThresholdPercentage: when the received spread exceeds this % of mid-price, an alert is triggered (e.g., 2.5 = alert at 2.5% spread)
- SpreadLockThresholdPercentage: when spread exceeds this % threshold, the instrument's pricing may be locked/suspended (e.g., 3.5 = lock at 3.5%)
- SkewLimitThreshold: maximum allowed deviation in the skew calculation before triggering an override or alert. DEFAULT 0 = no limit
- EtoroMaxSpreadPercentage: eToro's own maximum allowable spread published to customers, regardless of what liquidity providers send. DEFAULT 0 = no cap enforced

### 2.3 Computed Columns Materialized in History

**What**: DbLoginName and AppLoginName are computed (non-persisted) in Price.InstrumentConfiguration. This history table stores their evaluated values at each version close.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`

**Rules**:
- DbLoginName: suser_name() at write time (e.g., "TRAD\bonniegr" for manual admin changes)
- AppLoginName: context_info() - typically NULL for automated or direct SQL changes

---

## 3. Data Overview

6,427 rows. Range: 2021-09-13 to 2026-02-05.

| InstrumentID | SpreadAlert% | SpreadLock% | SkewLimit | EtoroMaxSpread% | DbLoginName | SysStartTime | SysEndTime | Meaning |
|-------------|-------------|------------|----------|----------------|------------|-------------|-----------|---------|
| 797 | 2.5 | 3.5 | 0 | 0 | TRAD\bonniegr | 2026-02-05 07:09:28 | 2026-02-05 07:09:28 | Insert artifact (trigger) for instrument 797. Admin TRAD\bonniegr added a new InstrumentConfiguration row with standard thresholds. SysStart=SysEnd confirms it is an insert-triggered temporal version, not a genuine update. |
| 791 | 2.5 | 3.5 | 0 | 0 | TRAD\bonniegr | 2026-02-05 07:09:25 | 2026-02-05 07:09:25 | Same pattern as above - multiple instruments bulk-configured in February 2026 with identical default thresholds. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | The instrument whose price configuration is captured in this version. PK in source table (one config row per instrument). Implicit FK to Trade.Instrument (source has explicit FK FK_PriceInstrumentConfiguration_InstrumentID). |
| 2 | SpreadAlertThresholdPercentage | decimal(10,6) | NO | - | CODE-BACKED | Spread alert trigger threshold as a percentage of mid-price. When the pricing engine receives a spread wider than this % threshold, an alert is generated. Example: 2.5 means alert fires when spread >= 2.5% of mid. |
| 3 | SpreadLockThresholdPercentage | decimal(12,5) | YES | - | CODE-BACKED | Spread lock trigger threshold as a percentage of mid-price. When spread exceeds this level, the instrument's pricing may be locked or suspended to protect customers from extreme spreads. NULL = no lock threshold configured. Example: 3.5 = lock at 3.5%. |
| 4 | SkewLimitThreshold | decimal(10,6) | NO | 0 | CODE-BACKED | Maximum allowed deviation in the price skew calculation. When the skew model produces a skew exceeding this threshold, the engine may override or alert. DEFAULT 0 = no skew limit enforced (threshold disabled). |
| 5 | EtoroMaxSpreadPercentage | decimal(10,6) | NO | 0 | CODE-BACKED | eToro's own maximum spread cap published to customers, independent of what liquidity providers send. If the incoming spread exceeds this, eToro clips it to this cap. DEFAULT 0 = no cap enforced (0 means disabled, not 0%). |
| 6 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | Materialized snapshot of suser_name() at the time this configuration version was superseded. Identifies who changed the configuration. Observed: "TRAD\bonniegr" (manual admin operation). |
| 7 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Materialized snapshot of context_info() at version close time. Typically NULL - configuration changes are typically made via direct SQL or an admin tool that does not set context_info. |
| 8 | SysStartTime | datetime2(7) | NO | - | VERIFIED | Start of validity for this configuration version. Set by SQL Server temporal engine. Rows where SysStartTime = SysEndTime are insert artifacts from TRG_T_InstrumentConfiguration (see Section 2.1). |
| 9 | SysEndTime | datetime2(7) | NO | - | VERIFIED | End of validity for this configuration version. Set by SQL Server temporal engine to the timestamp when the live configuration row was updated or deleted. CLUSTERED INDEX ordered (SysEndTime, SysStartTime) for temporal scan performance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit (from source FK) | The instrument whose pricing thresholds are captured. Source has FK FK_PriceInstrumentConfiguration_InstrumentID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.InstrumentConfiguration | (SYSTEM_VERSIONING) | Temporal - HISTORY_TABLE | All closed configuration versions flow here automatically via SQL Server temporal versioning. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.InstrumentConfiguration (table)
  - leaf node: no code-level dependencies (auto-managed by SQL Server temporal engine)
```

### 6.1 Objects This Depends On

No dependencies. Managed exclusively by SQL Server temporal versioning.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.InstrumentConfiguration | Table | Declares this as its HISTORY_TABLE via SYSTEM_VERSIONING. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_InstrumentConfiguration | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage option | Page-level compression on all data and index pages. |

---

## 8. Sample Queries

### 8.1 Retrieve full configuration history for a specific instrument
```sql
SELECT InstrumentID, SpreadAlertThresholdPercentage, SpreadLockThresholdPercentage,
       SkewLimitThreshold, EtoroMaxSpreadPercentage,
       SysStartTime, SysEndTime, DbLoginName
FROM History.InstrumentConfiguration WITH (NOLOCK)
WHERE InstrumentID = 1014
ORDER BY SysStartTime;
```

### 8.2 Check what thresholds were in effect at a specific point in time
```sql
SELECT InstrumentID, SpreadAlertThresholdPercentage, SpreadLockThresholdPercentage,
       SkewLimitThreshold, EtoroMaxSpreadPercentage,
       SysStartTime, SysEndTime
FROM Price.InstrumentConfiguration WITH (NOLOCK)
FOR SYSTEM_TIME AS OF '2025-06-01 00:00:00'
WHERE InstrumentID = 1014;
```

### 8.3 Find instruments whose spread lock threshold changed on a given date
```sql
SELECT h.InstrumentID, h.SpreadLockThresholdPercentage AS OldThreshold,
       c.SpreadLockThresholdPercentage AS NewThreshold,
       h.SysEndTime AS ChangedAt, h.DbLoginName
FROM History.InstrumentConfiguration h WITH (NOLOCK)
JOIN Price.InstrumentConfiguration c WITH (NOLOCK) ON c.InstrumentID = h.InstrumentID
WHERE CAST(h.SysEndTime AS date) = '2026-02-05'
  AND h.SysStartTime != h.SysEndTime  -- exclude insert artifacts
  AND h.SpreadLockThresholdPercentage != c.SpreadLockThresholdPercentage
ORDER BY h.SysEndTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.InstrumentConfiguration | Type: Table | Source: etoro/etoro/History/Tables/History.InstrumentConfiguration.sql*
