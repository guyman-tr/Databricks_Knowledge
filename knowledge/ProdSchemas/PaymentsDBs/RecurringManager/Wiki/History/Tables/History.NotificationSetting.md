# History.NotificationSetting

> Temporal history table that stores previous versions of notification configuration settings, tracking changes to country/regulation-level notification enablement rules over time.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | SettingId (mirrors PK of Configuration.NotificationSetting) |
| **Partition** | No |
| **Indexes** | 1 clustered (SysEndTime, SysStartTime) |

---

## 1. Business Meaning

History.NotificationSetting is the system-versioned temporal history table for `Configuration.NotificationSetting`. It stores previous versions of notification configuration records - each row represents a past state of a notification setting that was either modified or deleted in the base table. The settings control whether notifications of a specific type are enabled for a given country, US state, or regulatory jurisdiction.

This table exists to provide a full audit trail of notification configuration changes. Because notification enablement directly affects whether customers receive communications about their recurring payments, regulatory and compliance teams need the ability to reconstruct the notification configuration as it existed at any point in time.

Data flows into this table automatically via SQL Server's temporal table mechanism. When a row in `Configuration.NotificationSetting` is updated or deleted, the old version is moved here by the database engine. No stored procedures or application code directly write to this history table - all inserts are system-managed. The Trace column (computed in the base table) captures the session context at the time of each change, providing attribution for who made the modification.

---

## 2. Business Logic

### 2.1 Temporal Versioning

**What**: Automatic audit trail of notification setting changes via SQL Server system-versioned temporal tables.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, all data columns

**Rules**:
- When a row in Configuration.NotificationSetting is modified, the old version is inserted here with SysEndTime set to the modification timestamp
- SysStartTime records when this version became active; SysEndTime records when it was superseded
- To reconstruct settings at a point in time, query with `FOR SYSTEM_TIME AS OF @timestamp` on the base table
- The Trace column preserves the audit context (hostname, application, user, SPID) from the session that created this version in the base table

**Diagram**:
```
Configuration.NotificationSetting (current)
    |
    | UPDATE/DELETE triggers temporal move
    v
History.NotificationSetting (previous versions)
    [SysStartTime] = when this version became active
    [SysEndTime]   = when this version was superseded
```

### 2.2 Geographic/Regulatory Notification Filtering

**What**: Notification settings can be scoped to specific countries, states, or regulatory frameworks, allowing granular control over which notifications are enabled in which jurisdictions.

**Columns/Parameters Involved**: `CountryId`, `StateId`, `RegulationId`, `NotificationTypeId`, `NotificationEnabled`

**Rules**:
- All three filter columns (CountryId, StateId, RegulationId) are nullable - NULL means the setting applies broadly (not filtered to a specific jurisdiction)
- The combination of these filters with NotificationTypeId determines whether a specific notification type is enabled for a specific geographic/regulatory scope
- Only NotificationTypeId value 1 has been observed in production data

---

## 3. Data Overview

| SettingId | CountryId | NotificationTypeId | NotificationEnabled | Meaning |
|---|---|---|---|---|
| 3 | 219 | 1 | true | A superseded notification setting for country 219 (US) that was active from 2022-06-15 06:52 to 09:53 UTC - this version was replaced within 3 hours of creation, likely a configuration correction during initial setup |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SettingId | int | NO | - | CODE-BACKED | Mirrors the PK of Configuration.NotificationSetting (IDENTITY). Identifies which notification setting this historical version belongs to. Not unique in the history table - the same SettingId may appear multiple times representing successive versions. |
| 2 | CountryId | int | YES | - | NAME-INFERRED | Country identifier for geographic scoping of the notification setting. NULL means the setting is not country-specific. Value 219 (US) observed in history data. External reference - likely maps to a country lookup in another system. |
| 3 | StateId | int | YES | - | NAME-INFERRED | Sub-national state/province identifier for finer geographic scoping. NULL means the setting is not state-specific. Always NULL in observed data - suggests state-level filtering is defined but rarely used. |
| 4 | RegulationId | int | YES | - | NAME-INFERRED | Regulatory framework identifier for jurisdiction-based notification rules. NULL means the setting is not regulation-specific. Always NULL in observed data - suggests regulation-level filtering is defined but rarely used. |
| 5 | NotificationTypeId | int | NO | - | CODE-BACKED | Classifies the type of notification this setting controls. Same column appears in Recurring.Notification and History.Notification tables. Only value 1 observed across all tables. No Dictionary lookup table exists - values are likely application-defined. |
| 6 | NotificationEnabled | bit | NO | - | CODE-BACKED | Whether notifications of this type are enabled for the specified geographic/regulatory scope. 1 = enabled (notifications will be sent), 0 = disabled (notifications suppressed). All observed values are 1 (enabled). |
| 7 | CreateDate | datetime | YES | - | CODE-BACKED | Timestamp when the original notification setting record was created in Configuration.NotificationSetting. Carried forward from the base table into the history record. |
| 8 | Trace | nvarchar(733) | NO | - | VERIFIED | Audit context captured at the time of modification. In the base table, this is a computed column using `CONCAT(HOST_NAME(), APP_NAME(), SUSER_NAME(), @@SPID, DB_NAME(), OBJECT_NAME(@@PROCID))` formatted as JSON. In the history table, the computed value is materialized as a static string. Contains: HostName, AppName, SUserName, SPID, DBName, ObjectName - enabling attribution of who changed the setting and from which application. |
| 9 | SysStartTime | datetime2(7) | NO | - | VERIFIED | System-managed temporal column. Records when this version of the setting became the active version in the base table. Part of the clustered index for efficient temporal queries. |
| 10 | SysEndTime | datetime2(7) | NO | - | VERIFIED | System-managed temporal column. Records when this version was superseded by a newer version (or deleted) in the base table. Part of the clustered index. Together with SysStartTime defines the validity period of this historical version. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | Configuration.NotificationSetting | Temporal History | This is the system-versioned history table for Configuration.NotificationSetting. All rows are automatically created by the temporal mechanism when the base table is modified. |
| NotificationTypeId | (no lookup table) | Implicit | Notification type classifier shared with Recurring.Notification - no Dictionary table exists for this ID |

### 5.2 Referenced By (other objects point to this)

No objects reference this history table directly. It is accessed via temporal queries on Configuration.NotificationSetting using `FOR SYSTEM_TIME` clauses.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies. It is a history table managed by SQL Server's temporal mechanism.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Configuration.NotificationSetting | Table | This is the temporal history table for that base table (SYSTEM_VERSIONING = ON) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_Execution | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

Note: The index is named `ix_Execution` which appears to be a naming error (likely copy-pasted from History.Execution). The index serves temporal query optimization - SysEndTime is the leading column because point-in-time queries filter on `SysEndTime > @asof` first. PAGE compression is enabled.

### 7.2 Constraints

None. History tables managed by SQL Server temporal do not have PK, FK, CHECK, or DEFAULT constraints. The base table (Configuration.NotificationSetting) holds PK_Configuration_NotificationSetting on SettingId.

---

## 8. Sample Queries

### 8.1 View all historical versions of a specific notification setting
```sql
SELECT SettingId, CountryId, StateId, RegulationId,
       NotificationTypeId, NotificationEnabled,
       SysStartTime, SysEndTime
FROM History.NotificationSetting WITH (NOLOCK)
WHERE SettingId = 3
ORDER BY SysStartTime DESC
```

### 8.2 Reconstruct notification settings as they existed at a specific point in time
```sql
SELECT *
FROM Configuration.NotificationSetting
FOR SYSTEM_TIME AS OF '2022-06-15 08:00:00'
```

### 8.3 Find who changed notification settings with audit trail
```sql
SELECT h.SettingId, h.CountryId, h.NotificationEnabled,
       h.SysStartTime AS VersionStart,
       h.SysEndTime AS VersionEnd,
       JSON_VALUE(h.Trace, '$.SUserName') AS ChangedBy,
       JSON_VALUE(h.Trace, '$.AppName') AS ViaApplication
FROM History.NotificationSetting h WITH (NOLOCK)
ORDER BY h.SysEndTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Confluence searches for "NotificationSetting" and "NotificationSetting RecurringManager" in the TRAD space returned no results.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 5.9/10 (Elements: 7.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 3 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.NotificationSetting | Type: Table | Source: RecurringManager/History/Tables/History.NotificationSetting.sql*
