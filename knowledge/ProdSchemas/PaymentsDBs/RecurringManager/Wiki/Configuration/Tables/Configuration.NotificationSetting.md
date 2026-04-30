# Configuration.NotificationSetting

> Controls whether recurring payment notifications are enabled for specific countries, states, and regulatory jurisdictions.

| Property | Value |
|----------|-------|
| **Schema** | Configuration |
| **Object Type** | Table |
| **Key Identifier** | SettingId (INT IDENTITY, clustered PK) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Configuration.NotificationSetting is a feature-flag table that determines whether the Recurring Manager service should send notifications for recurring payment events in specific geographic and regulatory contexts. Each row represents a notification setting rule for a particular combination of country, state, regulation, and notification type, with a boolean toggle to enable or disable it.

Without this table, the system would either send notifications to all jurisdictions uniformly or require hardcoded logic for jurisdiction-specific notification rules. This table externalizes that logic, allowing operations teams to enable or disable notification types per country/regulation without code deployments.

Data enters this table through manual configuration (likely via backoffice tools or DML scripts). The table is temporal (SYSTEM_VERSIONING enabled with History.NotificationSetting), so all changes are automatically tracked and auditable. The Recurring Manager service reads these settings to determine whether a notification should be generated when processing payment executions for users in specific countries. The related Recurring.Notification table stores the actual notification records, while this table controls whether those records should be created.

---

## 2. Business Logic

### 2.1 Jurisdiction-Based Notification Gating

**What**: A multi-dimensional configuration matrix that controls notification delivery by geography and regulatory framework.

**Columns/Parameters Involved**: `CountryId`, `StateId`, `RegulationId`, `NotificationTypeId`, `NotificationEnabled`

**Rules**:
- Each row defines a rule: "For notification type X in country Y (optionally state Z, regulation W), notifications are enabled/disabled"
- CountryId is the primary dimension - currently the only populated geographic filter (StateId and RegulationId are NULL in all rows, reserved for future granularity)
- NotificationTypeId groups rules by notification category - currently only type 1 is configured across the system
- NotificationEnabled is the toggle - when false, the matching notification type is suppressed for that jurisdiction
- The table supports overlapping rules (same NotificationTypeId across different countries) enabling per-country rollout of notification features

**Diagram**:
```
Notification Decision Flow:
  Payment Execution event occurs
       |
       v
  Look up user's CountryId (+ StateId, RegulationId if applicable)
       |
       v
  Query Configuration.NotificationSetting
  WHERE NotificationTypeId = {type}
    AND CountryId = {user's country}
    AND (StateId = {state} OR StateId IS NULL)
    AND (RegulationId = {reg} OR RegulationId IS NULL)
       |
       v
  NotificationEnabled = true?
   YES -> Create Recurring.Notification record
   NO  -> Suppress notification
```

### 2.2 Temporal Audit Trail

**What**: All configuration changes are automatically version-tracked via SQL Server temporal tables.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `Trace`

**Rules**:
- Every INSERT, UPDATE, or DELETE is captured in History.NotificationSetting with the exact time window the row was valid
- The computed Trace column captures session metadata (hostname, app name, SQL user, SPID, database) as a JSON string, providing attribution for who made each change
- Gap in SettingId values (1, 5) indicates rows were historically inserted and later deleted or modified, with full history preserved in the temporal table

---

## 3. Data Overview

| SettingId | CountryId | NotificationTypeId | NotificationEnabled | CreateDate | Meaning |
|-----------|-----------|--------------------|--------------------|------------|---------|
| 1 | 250 | 1 | true | 2022-06-14 | Notifications of type 1 are enabled for country 250 - one of the first two countries onboarded to the recurring notifications feature |
| 5 | 219 | 1 | true | 2022-06-16 | Notifications of type 1 are enabled for country 219 - the second country onboarded two days after the initial launch, suggesting a phased geographic rollout |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SettingId | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. Gap between observed values (1, 5) indicates historical rows were created and later removed, with changes tracked in the temporal history table. |
| 2 | CountryId | int | YES | - | CODE-BACKED | Identifier of the country for which this notification setting applies. References an external platform country table (not in RecurringManager DB). Current values: 250, 219. When NULL, the setting would apply regardless of country (global rule), though all current rows have a value. |
| 3 | StateId | int | YES | - | CODE-BACKED | Identifier of the state/province within a country for sub-national notification rules. Currently 100% NULL across all rows - reserved for future use when state-level notification granularity is needed (e.g., US state-specific regulatory requirements). |
| 4 | RegulationId | int | YES | - | CODE-BACKED | Identifier of the regulatory framework governing the notification rule. Currently 100% NULL across all rows - reserved for future use when regulation-specific notification controls are required (e.g., different rules for MiFID II vs SEC jurisdictions). |
| 5 | NotificationTypeId | int | NO | - | CODE-BACKED | Classifies the type of notification being configured. Currently only value 1 exists in both this table and Recurring.Notification (48,688 notification records). No corresponding Dictionary lookup table exists in this database - the type definitions are likely managed by the application layer. |
| 6 | NotificationEnabled | bit | NO | - | CODE-BACKED | Feature toggle: 1 (true) = notifications of this type are enabled for the specified jurisdiction, 0 (false) = notifications are suppressed. All current rows have true, meaning both configured countries actively receive notifications. |
| 7 | CreateDate | datetime | YES | - | CODE-BACKED | Timestamp when this configuration row was originally created. Values show the initial setup occurred on 2022-06-14 and 2022-06-16, indicating a two-day phased rollout. Nullable, though all existing rows have values. |
| 8 | Trace | computed (varchar) | - | - | CODE-BACKED | Computed audit column: `CONCAT('{"HostName": "', HOST_NAME(), '","AppName": "', APP_NAME(), ...})`. Generates a JSON string capturing the current session's connection metadata (hostname, application name, SQL user, SPID, database name, calling object). Note: returns the READING session's info, not the original writer's - historical writer info is preserved in the temporal history table where Trace is materialized as nvarchar(733). |
| 9 | SysStartTime | datetime2(7) | NO | GENERATED ALWAYS AS ROW START | CODE-BACKED | Temporal system column (HIDDEN). Marks the instant this row version became the current version. Automatically set by SQL Server on INSERT or UPDATE. Used with SysEndTime to define the validity period of each row version. |
| 10 | SysEndTime | datetime2(7) | NO | GENERATED ALWAYS AS ROW END | CODE-BACKED | Temporal system column (HIDDEN). Marks the instant this row version was superseded by a newer version (or deleted). Set to 9999-12-31 for the current version. Together with SysStartTime, enables point-in-time queries via FOR SYSTEM_TIME AS OF. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (temporal) | History.NotificationSetting | Temporal History | System-versioned history table that stores all previous row versions. Automatically maintained by SQL Server temporal table infrastructure. |
| CountryId | External (not in RecurringManager DB) | Implicit FK | References a platform-level country table in another database. Values are integer country identifiers. |
| StateId | External (not in RecurringManager DB) | Implicit FK | Reserved for future state/province references. Currently unused (100% NULL). |
| RegulationId | External (not in RecurringManager DB) | Implicit FK | Reserved for future regulatory framework references. Currently unused (100% NULL). |

### 5.2 Referenced By (other objects point to this)

No database objects in the RecurringManager repository directly reference this table via FK, JOIN, or code. The table is consumed by the Recurring Manager application service at runtime to gate notification creation. Recurring.Notification shares the NotificationTypeId concept but does not have a direct relationship.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in the database code. The table is consumed by the Recurring Manager application service.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Configuration_NotificationSetting | CLUSTERED PK | SettingId ASC | - | - | Active |

The History.NotificationSetting table has a clustered index `ix_NotificationSetting` on (SysEndTime ASC, SysStartTime ASC) with PAGE compression.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Configuration_NotificationSetting | PRIMARY KEY | Ensures unique SettingId per row |

No CHECK, DEFAULT, or UNIQUE constraints. The temporal PERIOD FOR SYSTEM_TIME enforces that SysStartTime < SysEndTime.

---

## 8. Sample Queries

### 8.1 Check if notifications are enabled for a specific country and type
```sql
SELECT SettingId, CountryId, NotificationTypeId, NotificationEnabled
FROM Configuration.NotificationSetting WITH (NOLOCK)
WHERE CountryId = 250
  AND NotificationTypeId = 1
```

### 8.2 View the full change history for all notification settings
```sql
SELECT SettingId, CountryId, StateId, RegulationId,
       NotificationTypeId, NotificationEnabled, CreateDate,
       Trace, SysStartTime, SysEndTime
FROM Configuration.NotificationSetting
FOR SYSTEM_TIME ALL
ORDER BY SettingId, SysStartTime
```

### 8.3 Find all countries with enabled notifications by type
```sql
SELECT NotificationTypeId, CountryId, NotificationEnabled
FROM Configuration.NotificationSetting WITH (NOLOCK)
WHERE NotificationEnabled = 1
ORDER BY NotificationTypeId, CountryId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for this object. The "LLD Recurring Payments Zero Auth" Confluence page (page ID 13319798791) describes the broader Recurring Manager system architecture but does not reference Configuration.NotificationSetting directly.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 6.9/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Configuration.NotificationSetting | Type: Table | Source: RecurringManager/Configuration/Tables/Configuration.NotificationSetting.sql*
