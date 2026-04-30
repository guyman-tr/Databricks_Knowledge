# History.ServiceConfiguration

> System-versioned temporal history table for Internal.ServiceConfiguration, archiving all past states of runtime service configuration key-value pairs used by eToro's internal platform services.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite temporal key (SysEndTime, SysStartTime) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime ASC, SysStartTime ASC) |

---

## 1. Business Meaning

This table is the **active system-versioned temporal history table** for `Internal.ServiceConfiguration` (source declares `SYSTEM_VERSIONING = ON (HISTORY_TABLE = [History].[ServiceConfiguration])`). SQL Server automatically archives superseded configuration states here when any row in the source table is updated or deleted.

`Internal.ServiceConfiguration` is the central key-value configuration store for eToro's internal platform services. Each row stores one configuration parameter (`ConfigurationKey`) and its value (`Value`) for a specific service instance. Services load their runtime configuration from this table at startup via `Internal.GetServiceConfiguration`. Examples of configuration keys observed: `CircuitBreakerInterval`, `PeriodicHedgeIntervalMS`, `UseFractionalAmount`, `IsUSProvider`, `IsAKS`, `OpenPositionMaxThrottlingIntervalSeconds`.

With 2,719 history rows spanning September 2021 through March 2026, configurations are actively maintained. Service types observed include hedge servers (HEDGE_SRV_TYPE), price services (PRICE_SRV_TYPE), and the majority using the flexible `DEFINE_AS_SERVICE_NAME` (ServiceTypeID 51) pattern where the service identifies itself by name rather than type ID.

**Triple audit trail**: In addition to temporal history, `Internal.ServiceConfiguration` has three ASM-generated audit triggers (AuditInsert, AuditUpdate, AuditDelete) that write key/value change details to `History.AuditHistory` for each INSERT/UPDATE/DELETE operation.

---

## 2. Business Logic

### 2.1 Instance-Specific Configuration Override

**What**: Services can have a global default configuration and per-instance overrides using InstanceID.

**Columns/Parameters Involved**: `InstanceID`, `ConfigurationKey`, `ServerTypeName`

**Rules**:
- `InstanceID=0` is the global/default configuration for all instances of a service
- `InstanceID>0` is an instance-specific override (overrides the default for that instance)
- `Internal.GetServiceConfiguration(@ServiceName, @InstanceID)` resolves the effective value by selecting WHERE `InstanceID IN (0, @InstanceID)` and taking the row with the highest InstanceID (most specific) via `ROW_NUMBER() OVER(PARTITION BY ConfigurationKey ORDER BY InstanceID DESC)`
- If both a default (InstanceID=0) and a specific (InstanceID=N) exist for the same ConfigurationKey, the instance-specific value wins

**Diagram**:
```
Service "HPH-TRAFIX" instance 5 requests config:
  SELECT ConfigurationKey, Value WHERE ServerTypeName='HPH-TRAFIX' AND InstanceID IN (0, 5)
  |
  ConfigurationKey    | InstanceID=0 (default) | InstanceID=5 (override)
  IsAKS               | false                  | true     <- instance wins
  CircuitBreakerInt   | 500000                 | (none)   <- default used
```

### 2.2 DEFINE_AS_SERVICE_NAME Pattern

**What**: Services using ServerType=51 self-identify by name rather than by service type category.

**Columns/Parameters Involved**: `ServerType`, `ServerTypeName`

**Rules**:
- `ServerType=51` (DEFINE_AS_SERVICE_NAME) means the `ServerTypeName` column is the service's unique identifier
- 97.6% of history rows use ServerType=51; traditional type IDs (2=ORDER, 9=HEDGE, 10=PRICE) are used for legacy services
- Services queried by name: `Internal.GetServiceConfiguration(@ServiceName, ...)` uses `ServerTypeName = @ServiceName`

### 2.3 IsApplicative and TRG_T_ServiceConfiguration

**What**: `IsApplicative` flags whether a configuration entry is active/applicable.

**Columns/Parameters Involved**: `IsApplicative`

**Rules**:
- `IsApplicative=1` (true): the configuration value is currently active and should be applied
- `IsApplicative=0` (false, default): the entry is inactive - services may ignore it
- The trigger `TRG_T_ServiceConfiguration` (FOR INSERT) performs a self-update (`SET IsApplicative = IsApplicative`) after every INSERT; this forces the temporal system to register the row and fires the audit triggers for a consistent audit trail on INSERT

### 2.4 Operational Safeguard Alerts

**What**: `Monitor.AlertForDealingExecutionConfigurationManager` enforces safe value boundaries on critical configuration keys.

**Columns/Parameters Involved**: `ConfigurationKey`, `Value`

**Rules**:
- `CircuitBreakerInterval > 600000` (600 seconds) triggers an alert - hedge circuit breaker must not be set too long
- `PeriodicHedgeIntervalMS > 7200000` (2 hours) triggers an alert - periodic hedge run must not be delayed too long
- Alerts fire when thresholds are breached: "In the table Internal.ServiceConfiguration the value for X is: Y while the allowed threshold is Z"

---

## 3. Data Overview

| ServerType | SampleServerTypeName | HistoryRows | DistinctKeys | Range |
|---|---|---|---|---|
| 51 (DEFINE_AS_SERVICE_NAME) | various (ERM-AKS, HPH-TRAFIX, HedgeCostAPI, RealizedCustomerService, ...) | 2,654 | 853 | 2021-09 to 2026-03 |
| 10 (PRICE_SRV_TYPE) | PRICE_SRV_TYPE | 50 | 13 | 2021-09 to 2025-06 |
| 9 (HEDGE_SRV_TYPE) | UnrealizedCustomer | 13 | 8 | 2021-09 to 2023-02 |
| 2 (ORDER_SRV_TYPE) | ORDER_SRV_TYPE | 1 | 1 | 2024-06 |
| 3 (LOGIN_SRV_TYPE) | DLTProvider | 1 | 1 | 2024-06 |

Sample configuration keys observed (ServerType=51):
- `UseFractionalAmount` = "true"
- `IsUSProvider` = "true"
- `IsAKS` = "true"
- `OpenPositionMaxThrottlingIntervalSeconds` = "10"
- `OpenPositionPrefetchCount` = "1000"
- `OpenPositionRoutingKey` = "Trading.Position.Open.#"
- `RefreshTimeActiveMappingsJobCronExpression` = "*/3 * * * * *"

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Identifier of the original `Internal.ServiceConfiguration` row (IDENTITY int in source, NOT an identity here). Same ID can appear multiple times - one per historical state. Uniquely identifies which configuration entry this history row belongs to. |
| 2 | ServerType | int | NO | - | VERIFIED | Service type category for this configuration entry. FK to Dictionary.ServiceType. 47 types defined: 1=LOBBY_SRV_TYPE, 2=ORDER_SRV_TYPE, 9=HEDGE_SRV_TYPE, 10=PRICE_SRV_TYPE, 51=DEFINE_AS_SERVICE_NAME (dominant - 97.6% of rows), 99=MONITOR_SRV_TYPE. When ServerType=51, the service is identified by ServerTypeName. |
| 3 | InstanceID | int | NO | - | VERIFIED | The specific service instance this configuration applies to. InstanceID=0 is the global default (applies to all instances of the service). InstanceID>0 is an instance-specific override. `Internal.GetServiceConfiguration` resolves instance-specific config by prioritizing higher InstanceID values. |
| 4 | ConfigurationKey | varchar(50) | NO | - | CODE-BACKED | The name of the configuration parameter. Examples: CircuitBreakerInterval, PeriodicHedgeIntervalMS, UseFractionalAmount, IsUSProvider, IsAKS, OpenPositionPrefetchCount. 853+ distinct keys observed across all services. |
| 5 | Value | nvarchar(max) | NO | - | CODE-BACKED | The configuration parameter value as a string. Values include simple scalars ("true", "1000", "10"), routing keys ("Trading.Position.Open.#"), cron expressions ("*/3 * * * * *"), and potentially JSON payloads. Stored as nvarchar(max) (TEXTIMAGE_ON PRIMARY) to accommodate arbitrarily large configuration values. |
| 6 | IsApplicative | bit | NO | 0 | CODE-BACKED | Whether this configuration entry is active. 1=active (applied by the service); 0=inactive (default - ignored). TRG_T_ServiceConfiguration performs a self-update on INSERT to ensure a consistent audit trail. |
| 7 | ServerTypeName | varchar(256) | NO | '' | VERIFIED | The service's self-reported name. When ServerType=51 (DEFINE_AS_SERVICE_NAME), this is the primary service identifier used by Internal.GetServiceConfiguration to filter configuration. Examples: "ERM-AKS", "HPH-TRAFIXUS", "HPH-TRAFIX", "RealizedCustomerService", "HedgeCostAPI", "HedgeCostPushService", "ZBFXUSProvider". |
| 8 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | Computed in source as `suser_name()` - SQL Server login that last modified this configuration entry. Stored as a plain value in history. NULL when the login could not be determined. |
| 9 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Computed in source as `CONVERT(varchar(500), context_info())` - the application-set session context. NULL when context_info() was not set. |
| 10 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | UTC instant when this configuration state became current in `Internal.ServiceConfiguration`. Automatically managed by SQL Server temporal system versioning. Nanosecond precision. |
| 11 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | CODE-BACKED | UTC instant when this configuration state was superseded. Automatically set by SQL Server. Leading key of the clustered index. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ID | Internal.ServiceConfiguration | Temporal History | Each row is a past state of the source configuration entry; ID identifies which entry. |
| ServerType | Dictionary.ServiceType | Implicit (FK on source) | 47 service type categories; 51=DEFINE_AS_SERVICE_NAME is the modern pattern. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Internal.ServiceConfiguration | HISTORY_TABLE | Temporal History | Active source table; expired configuration states archived here by SQL Server. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ServiceConfiguration (table)
  (temporal history - no code-level dependencies; populated by SQL Server from Internal.ServiceConfiguration)
```

---

### 6.1 Objects This Depends On

No dependencies. Temporal history table.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Internal.ServiceConfiguration | Table | Active source table; expired configuration states archived here automatically. |

Note: The live source table `Internal.ServiceConfiguration` is read by `Internal.GetServiceConfiguration` and monitored by `Monitor.AlertForDealingExecutionConfigurationManager`. Audit triggers (AuditInsert/Update/Delete) write key/value change details to `History.AuditHistory` in parallel with temporal versioning.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_ServiceConfiguration | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

Note: DATA_COMPRESSION = PAGE on both table and clustered index. TEXTIMAGE_ON [PRIMARY] for nvarchar(max) Value column.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page compression for archival data. |

---

## 8. Sample Queries

### 8.1 View recent service configuration changes
```sql
SELECT
    h.ID,
    h.ServerTypeName,
    h.ConfigurationKey,
    LEFT(h.Value, 100) AS ValuePreview,
    h.IsApplicative,
    h.DbLoginName,
    h.SysStartTime AS ValidFrom,
    h.SysEndTime AS ValidTo
FROM [History].[ServiceConfiguration] h WITH (NOLOCK)
ORDER BY h.SysEndTime DESC
```

### 8.2 Track all changes to a specific configuration key
```sql
SELECT
    ServerTypeName,
    ConfigurationKey,
    Value,
    IsApplicative,
    DbLoginName,
    SysStartTime AS EffectiveFrom,
    SysEndTime AS EffectiveTo
FROM [History].[ServiceConfiguration] WITH (NOLOCK)
WHERE ConfigurationKey = @ConfigurationKey
ORDER BY SysStartTime ASC
```

### 8.3 Restore configuration as of a past date
```sql
-- Uses SQL Server temporal FOR SYSTEM_TIME on the source table
SELECT ID, ServerType, InstanceID, ConfigurationKey, Value, IsApplicative, ServerTypeName
FROM [Internal].[ServiceConfiguration]
FOR SYSTEM_TIME AS OF '2025-01-01T00:00:00'
WHERE ServerTypeName = @ServiceName
ORDER BY InstanceID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ServiceConfiguration | Type: Table | Source: etoro/etoro/History/Tables/History.ServiceConfiguration.sql*
