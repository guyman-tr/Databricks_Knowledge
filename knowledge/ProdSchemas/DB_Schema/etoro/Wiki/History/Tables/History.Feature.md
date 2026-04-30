# History.Feature

> Trigger-maintained audit log of every change to feature flag and configuration values in Maintenance.Feature, providing a complete point-in-time history of all platform feature settings from 2014 to present with operator identity captured per change.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | FeatureHistoryID (IDENTITY PK) |
| **Partition** | No (stored on [HISTORY] filegroup) |
| **Indexes** | 1 (CLUSTERED PK on FeatureHistoryID, FILLFACTOR=90, DATA_COMPRESSION=PAGE) |

---

## 1. Business Meaning

This table is the application-managed audit log for `Maintenance.Feature`, the platform's central feature flag and configuration store. Three DML triggers on `Maintenance.Feature` (FeatureInsert, FeatureUpdate, FeatureDelete) automatically write every change here, maintaining a complete immutable change history. Each row records one version of a feature's value - from the moment it was created (ValidFrom) until it was changed or removed (ValidTo).

The feature flag system controls a wide range of platform behaviors: trading execution parameters (e.g., "Price Filter (MS)", "Execution Delay (MS)"), feature toggle switches (e.g., "Enable ManualPositionClose Process using Service"), infrastructure credentials (e.g., OniXS FIX Engine license contents), operational timestamps (e.g., "Bsl Last Execute"), and hedging defaults (e.g., "Default value for HedgeServerID for PositionOpen"). Changes to these features affect real-money trading behavior, making their audit trail critical for incident investigation and compliance.

Data flows one-way into this table via triggers: any INSERT into Maintenance.Feature creates a row here with ValidTo='3000-01-01' (active sentinel). Any UPDATE closes the previous row (ValidTo=current time) and inserts a new row. Any DELETE closes the current row. The Login, Machine, and Application columns are populated by DEFAULT constraints (suser_sname(), host_name(), app_name()) at INSERT time, capturing the identity of whoever made the change. This table is never modified after creation - all history is append-only.

---

## 2. Business Logic

### 2.1 Trigger-Based SCD Type 2 Pattern

**What**: Maintenance.Feature uses a manual slowly-changing dimension type 2 (SCD2) pattern implemented via INSERT/UPDATE/DELETE triggers, maintaining one "current" row (ValidTo=3000-01-01) and one historical row per past version.

**Columns/Parameters Involved**: `FeatureID`, `ValidFrom`, `ValidTo`

**Rules**:
- ValidTo='3000-01-01 00:00:00.000' is the sentinel value meaning "currently active" - this row is the live value for this feature
- Each FeatureID has exactly ONE row in Maintenance.Feature (current state) but potentially many rows in History.Feature (one per past value)
- ValidFrom/ValidTo windows are non-overlapping and contiguous: when one version ends, the next begins at exactly the same timestamp
- History.Feature rows are append-only - no row is ever modified after insertion (triggers only UPDATE ValidTo on existing rows)
- The triggers use GETDATE() (local server time), not GETUTCDATE(), so timestamps are in local server time

**Diagram**:
```
Maintenance.Feature UPDATE FeatureID=121 from Value=0 to Value=1:
  Step 1: UPDATE History.Feature SET ValidTo=@Now WHERE FeatureID=121 AND ValidTo='3000-01-01'
  Step 2: INSERT INTO History.Feature (FeatureID=121, Value=1, ValidFrom=@Now, ValidTo='3000-01-01')

History.Feature rows for FeatureID=121 ("Enable ManualPositionClose Process using Service"):
  Row A: Value=0, ValidFrom=2025-11-13 08:44:03, ValidTo=2025-11-13 09:18:02  (38 min - toggle OFF)
  Row B: Value=1, ValidFrom=2025-11-13 09:18:02, ValidTo=2025-11-13 09:18:03  (1 sec - toggled ON, then quickly re-set)
  Row C: Value=1, ValidFrom=2025-11-13 09:18:03, ValidTo=3000-01-01 00:00:00  (current - feature ON)
```

### 2.2 Polymorphic Value Storage

**What**: Features can hold different data types in the same table - numeric configs, boolean flags, string timestamps, and full XML documents - using a two-column value store.

**Columns/Parameters Involved**: `Value`, `XMLValue`, `Description`

**Rules**:
- `Value` is sql_variant: holds integers (feature flags: 0/1), small integers (e.g., HedgeServerID=1), strings/timestamps (e.g., BSL last execute time as varchar), or empty string ''
- `XMLValue` holds xml data when the configuration is too complex for sql_variant (e.g., OniXS FIX Engine license XML with customer/period/product/checksum nodes)
- A given feature uses either `Value` OR `XMLValue`, not both simultaneously - when XMLValue is populated, Value is NULL or empty ''
- `Description` is a free-text label written at INSERT/UPDATE time describing what the feature does (e.g., "Enable ManualPositionClose Process using Service"). This is the human-readable name since Dictionary.Feature only stores the short Name
- Feature types by observed pattern: toggle flags (0/1 int), numeric configs, operational timestamps (string), license blobs (XML)

### 2.3 Operator Identity Capture

**What**: The Login, Machine, and Application columns record WHO made the change, FROM which machine, and USING which application - enabling accountability for feature configuration changes.

**Columns/Parameters Involved**: `Login`, `Machine`, `Application`

**Rules**:
- `Login` = suser_sname() DEFAULT - SQL Server login of the session that triggered the Maintenance.Feature DML
- `Machine` = host_name() DEFAULT - client workstation or server hostname
- `Application` = app_name() DEFAULT - client application name (e.g., "Microsoft SQL Server Management Studio - Query" for manual SSMS changes, "CONFIGURATION_MANAGER_SRV_TYPE" for service-managed changes)
- These DEFAULTs fire at INSERT time into History.Feature (triggered by the Maintenance.Feature triggers), so they capture the context of the ORIGINAL Maintenance.Feature DML session
- Manual configuration changes via SSMS show "SQL Server Management Studio" as Application; automated service changes show the service name

---

## 3. Data Overview

| FeatureHistoryID | FeatureID | Value | Description | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|---|
| 7621 | 102 | 1 | Default value for HedgeServerID for PositionOpen | 2026-02-11 | 3000-01-01 | Current config: HedgeServerID=1 is the default server for new position opens. Changed via CONFIGURATION_MANAGER_SRV_TYPE service, meaning this is a production service-managed configuration (not manual). |
| 7620 | 125 | 2026-01-22 09:51:05 | Bsl Last Execute | 2026-01-22 | 3000-01-01 | Operational heartbeat: BSL (Balance Sheet Logic) job last ran on 2026-01-22. Updated by Trade.UpdateBslLastExecute stored procedure. Used by Monitor.LastTimeBslJobExecute_DataDog for alerting if the job stops running. |
| 7619 | 121 | 1 | Enable ManualPositionClose Process using Service | 2025-11-13 | 3000-01-01 | Feature flag: ManualPositionClose service is currently ENABLED (value=1). Prior versions (7617, 7618) show it was toggled on/off within seconds, then settled to 1. Shows live production feature toggling by eladav. |
| 7616 | 57 | NULL | OniXS CORE license content | 2025-09-25 | 3000-01-01 | License blob: Current OniXS FIX Engine CORE license for eToro Ltd (OF 9236-3), valid through 2026-11-04. XMLValue column holds the full license XML. License rotated by danielma. |
| 7614 | 124 | 1 | Enable SetInstrumentsDataForOpsAPI | 2025-09-25 | 3000-01-01 | Feature flag: SetInstrumentsDataForOpsAPI integration is currently ENABLED. Previous rows (7612, 7613) show it was toggled 1->0->1 within ~1 minute, a typical pattern for testing/verification before permanent enable. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FeatureHistoryID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate PK, auto-incrementing identity. Unique identifier for each history record. NOT FOR REPLICATION prevents identity values being re-seeded during replication. Always increases monotonically - higher IDs are more recent changes. |
| 2 | FeatureID | int | NO | - | CODE-BACKED | Feature identifier. FK to Dictionary.Feature.FeatureID and Maintenance.Feature.FeatureID (no constraint in history table; enforced at source). Multiple rows with the same FeatureID represent successive value versions over time. Dictionary.Feature provides the short Name; the Description column here provides the longer description. |
| 3 | Value | sql_variant | YES | - | CODE-BACKED | The feature's current value at this point in time. Polymorphic type (sql_variant) accommodates: int (0/1 toggle flags, numeric config values), varchar (timestamp strings for operational markers), empty string '' (when configuration is in XMLValue). NULL when XMLValue is used. Application reads this column for feature-flag checks (e.g., Trade.GetEnableNewPnLFormulaMaintenanceFeatureValue reads Value for its FeatureID). |
| 4 | XMLValue | xml | YES | - | CODE-BACKED | Complex configuration data stored as XML, used when the feature value exceeds sql_variant capacity. In practice, holds OniXS FIX Engine license XML (customer info, validity period, product list, checksums). NULL for the majority of features that use the Value column. Stored in TEXTIMAGE_ON [HISTORY] filegroup due to XML type. |
| 5 | Description | varchar(255) | YES | - | CODE-BACKED | Human-readable description of what this feature controls, as written by the operator at the time of the change. For toggle flags: "Enable [FeatureName]". For configs: "Default value for [Parameter]". For operational markers: "[Process] Last Execute". May differ from Dictionary.Feature.Name - the Dictionary Name is a short label, this Description is the operator's annotation at change time. |
| 6 | ValidFrom | datetime | NO | - | CODE-BACKED | Timestamp when this feature value version became active. Set to GETDATE() (local server time) by the Maintenance.Feature triggers at the moment the change was applied. Aligns exactly with the ValidTo of the prior version for the same FeatureID (except for the very first INSERT which has no prior version). |
| 7 | ValidTo | datetime | NO | - | CODE-BACKED | Timestamp when this version was superseded. '3000-01-01 00:00:00.000' is the sentinel meaning "currently active - not yet superseded". When Maintenance.Feature is updated or deleted, the trigger sets ValidTo=GETDATE() on this row, and inserts a new row (for UPDATE) or leaves this as the terminal version (for DELETE). To find the current value: WHERE ValidTo = '3000-01-01'. |
| 8 | Login | varchar(255) | NO | suser_sname() | CODE-BACKED | SQL Server login name of the session that performed the DML on Maintenance.Feature that triggered this history insertion. DEFAULT suser_sname() captures this automatically at INSERT time. Examples: "TRAD\eladav" (manual SSMS by Elad), "TRAD\Noah" (manual by Noah), service accounts for automated changes. Tracks who authorized the feature configuration change. |
| 9 | Machine | varchar(255) | NO | host_name() | CODE-BACKED | Client hostname from which the Maintenance.Feature change was executed. DEFAULT host_name() captured at INSERT time. Examples: "PF5L21F8", "PF1C3LRB" (developer workstations), "stg-hdge-we01" (hedging server). Distinguishes manual admin changes from automated service-initiated changes. |
| 10 | Application | varchar(255) | NO | app_name() | CODE-BACKED | Application name reported by the SQL connection that performed the Maintenance.Feature change. DEFAULT app_name() captured at INSERT time. Values observed: "Microsoft SQL Server Management Studio - Query" (direct SSMS), "Microsoft SQL Server Management Studio" (SSMS generic), "CONFIGURATION_MANAGER_SRV_TYPE" (configuration management service), "SQL Server Management Studio" (SSMS variant). Identifies whether changes were manual (SSMS) or automated (service). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FeatureID | Dictionary.Feature | Implicit lookup | Identifies which platform feature this history row describes. Dictionary.Feature provides the canonical short Name for the feature. No FK constraint in History.Feature. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Maintenance.Feature | FeatureInsert trigger | Writer | ON INSERT: inserts a new row with ValidTo='3000-01-01', capturing the newly created feature value |
| Maintenance.Feature | FeatureUpdate trigger | Writer/Modifier | ON UPDATE: sets ValidTo=@Now on the prior active row, then inserts a new row for the updated value |
| Maintenance.Feature | FeatureDelete trigger | Modifier | ON DELETE: sets ValidTo=@Now on the active row, marking the feature as no longer configured |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Feature (table)
- no code-level dependencies (leaf table, trigger-populated audit log)
```

This object has no code-level dependencies. It is populated exclusively by triggers on Maintenance.Feature.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | Source table - three triggers (FeatureInsert, FeatureUpdate, FeatureDelete) write all changes to History.Feature |
| Maintenance.GetFeature | Stored Procedure | Reads Maintenance.Feature for current values; history context provided by this table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HFTR | CLUSTERED | FeatureHistoryID ASC | - | - | Active (FILLFACTOR=90, DATA_COMPRESSION=PAGE, on [HISTORY] filegroup) |

Stored on the [HISTORY] filegroup with TEXTIMAGE_ON [HISTORY] for xml column storage. No additional non-clustered indexes.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| HFTR_USER | DEFAULT | Login = suser_sname() - captures SQL Server login of the change author |
| HFTR_MACHINE | DEFAULT | Machine = host_name() - captures client hostname of the change author |
| HFTR_APPLICATION | DEFAULT | Application = app_name() - captures application name of the change session |

---

## 8. Sample Queries

### 8.1 What was the value of a specific feature on a given date?

```sql
SELECT
    h.FeatureHistoryID,
    h.FeatureID,
    df.Name AS FeatureName,
    h.Value,
    h.XMLValue,
    h.Description,
    h.ValidFrom,
    h.ValidTo,
    h.Login,
    h.Application
FROM History.Feature h WITH (NOLOCK)
JOIN Dictionary.Feature df WITH (NOLOCK) ON df.FeatureID = h.FeatureID
WHERE h.FeatureID = @FeatureID
  AND h.ValidFrom <= @PointInTime
  AND h.ValidTo > @PointInTime;
```

### 8.2 Full change history for all features, most recent first

```sql
SELECT TOP 50
    h.FeatureHistoryID,
    h.FeatureID,
    df.Name AS FeatureName,
    h.Value,
    h.Description,
    h.ValidFrom,
    h.ValidTo,
    DATEDIFF(MINUTE, h.ValidFrom, CASE WHEN h.ValidTo = '3000-01-01' THEN GETDATE() ELSE h.ValidTo END) AS ActiveForMinutes,
    h.Login,
    h.Machine,
    h.Application,
    CASE WHEN h.ValidTo = '3000-01-01' THEN 'Current' ELSE 'Historical' END AS VersionStatus
FROM History.Feature h WITH (NOLOCK)
JOIN Dictionary.Feature df WITH (NOLOCK) ON df.FeatureID = h.FeatureID
ORDER BY h.FeatureHistoryID DESC;
```

### 8.3 Find all feature toggle changes made manually via SSMS (not by automated services)

```sql
SELECT
    h.FeatureHistoryID,
    h.FeatureID,
    df.Name AS FeatureName,
    h.Value,
    h.Description,
    h.ValidFrom,
    h.Login,
    h.Machine,
    h.Application
FROM History.Feature h WITH (NOLOCK)
JOIN Dictionary.Feature df WITH (NOLOCK) ON df.FeatureID = h.FeatureID
WHERE h.Application LIKE '%SQL Server Management Studio%'
  AND h.ValidFrom >= DATEADD(DAY, -30, GETDATE())
ORDER BY h.ValidFrom DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (Trade.UpdateBslLastExecute, Maintenance.GetFeature) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Feature | Type: Table | Source: etoro/etoro/History/Tables/History.Feature.sql*
