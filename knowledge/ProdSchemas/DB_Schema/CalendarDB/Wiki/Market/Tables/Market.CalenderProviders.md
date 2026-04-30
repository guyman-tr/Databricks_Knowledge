# Market.CalenderProviders

> Registry of market data providers that supply exchange calendar and trading schedule data to the CalendarDB system.

| Property | Value |
|----------|-------|
| **Schema** | Market |
| **Object Type** | Table |
| **Key Identifier** | ProviderID (int, PK) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

`Market.CalenderProviders` is the master registry of external and internal providers from which the CalendarDB system receives market calendar data — including exchange trading hours, daily open/close schedules, and public holiday closures. Each provider is identified by a numeric ID and a human-readable name.

> **Note**: The table name contains a known typo ("CalenderProviders" instead of "CalendarProviders") that is preserved across all dependent objects for backward compatibility.

This table exists as the authoritative source for `ProviderID` values used throughout the CalendarDB schema. Without it, procedures such as `Market.SetProviderExchangeCalendarBulk` would have no validated list of provider identities, and exchange schedule data could not be reliably attributed to its source. It also serves as the primary registry for the mapping table `Market.CalendarProviderExchanges`.

The table is configured since system inception (2021-09-13) and currently has exactly two providers: eToro (the platform itself, ProviderID=0) and Xignite (a third-party financial market data provider, ProviderID=1). Data is written by administrative processes when a new calendar provider is onboarded. The table is read by all scheduling and calendar resolution procedures via the `ProviderID` parameter.

---

## 2. Business Logic

### 2.1 Temporal Audit via Trigger + System Versioning

**What**: Every change to a provider record is automatically logged to the history table for full temporal auditability.

**Columns/Parameters Involved**: `ProviderID`, `DbLoginName`, `AppLoginName`, `SysStartTime`, `SysEndTime`

**Rules**:
- SQL Server manages `SysStartTime` and `SysEndTime` automatically as system-versioned temporal table columns. The current row always has `SysEndTime = '9999-12-31 23:59:59.9999999'`.
- `DbLoginName` captures the SQL Server login (via `suser_name()`) at the time of the last write — shows which service account or DBA performed the operation.
- `AppLoginName` captures the application-level session identity (via `context_info()`) — applications set this to a GUID or identifier before executing statements, allowing attribution of changes to specific service instances.
- The `TRG_T_CalendarProviders` INSERT trigger performs a self-referential UPDATE (`SET ProviderID = ProviderID`) immediately after every INSERT. This forces the temporal versioning system to record a row into `History.CalenderProviders` for the insert operation, creating an audit trail even for new records.
- Historical versions of all provider records are preserved in `History.CalenderProviders`.

**Diagram**:
```
INSERT into Market.CalenderProviders
    ↓
TRG_T_CalendarProviders fires
    ↓ (self-update: SET ProviderID = ProviderID)
Temporal system detects row change
    ↓
Previous version written to History.CalenderProviders
    ↓
Current row kept in Market.CalenderProviders with new SysStartTime
```

### 2.2 Provider Enum (eToro = 0, Xignite = 1)

**What**: The table currently acts as a two-value enum distinguishing internal eToro calendar data from third-party Xignite data.

**Columns/Parameters Involved**: `ProviderID`, `ProviderName`

**Rules**:
- ProviderID=0 ("eToro"): Internal provider. Calendar data originates from eToro's own systems.
- ProviderID=1 ("Xignite"): External provider. Calendar data sourced from Xignite's financial data API.
- All downstream tables (`Market.CalendarProviderExchanges`, `Market.ProvidersExchangeDailySchedules`, `Market.ProvidersInstrumentDailySchedules`) use `ProviderID` to distinguish which source provided each schedule record.

**Diagram**:
```
ProviderID=0 → "eToro"    → Internal platform calendar data
ProviderID=1 → "Xignite"  → Third-party Xignite financial data API
```

---

## 3. Data Overview

Complete table contents (2 total rows):

| ProviderID | ProviderName | DbLoginName | Meaning |
|---|---|---|---|
| 0 | eToro | McpUserRO | Internal provider — eToro's own market calendar data, used for exchange schedules sourced from the platform itself. |
| 1 | Xignite | McpUserRO | Third-party financial data provider — Xignite supplies exchange trading hours, holiday calendars, and daily open/close schedules via their market data API. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | — | CODE-BACKED | Unique numeric identifier for the calendar data provider. Primary key. Current values: `0 = eToro` (internal platform), `1 = Xignite` (third-party financial data API). Used as a parameter in all scheduling procedures to identify the data source. |
| 2 | ProviderName | varchar(250) | NO | — | CODE-BACKED | Human-readable display name of the provider. Current values: `"eToro"` and `"Xignite"`. Used for display and attribution when inspecting schedule data. |
| 3 | DbLoginName | varchar (computed) | NO | — | CODE-BACKED | Computed column: `suser_name()`. Captures the SQL Server login name of the session that last modified this row. Set automatically on every write — read-only to applications. Shows service account or DBA identity for audit purposes. |
| 4 | AppLoginName | varchar(500) (computed) | NO | — | CODE-BACKED | Computed column: `CONVERT(varchar(500), context_info())`. Captures the application session identity stored in SQL Server's `context_info` buffer. Applications set this to a session GUID or service identifier before executing statements, enabling attribution of changes to specific application instances or deployments. Stored as raw bytes converted to varchar. |
| 5 | SysStartTime | datetime2(7) | NO | `getutcdate()` | CODE-BACKED | Temporal ROW START column, managed by SQL Server. Records the UTC timestamp when this version of the row became current. On INSERT, defaults to `getutcdate()`. Automatically updated by the temporal system on any UPDATE. Used to query point-in-time history via `History.CalenderProviders`. |
| 6 | SysEndTime | datetime2(7) | NO | `9999-12-31 23:59:59.9999999` | CODE-BACKED | Temporal ROW END column, managed by SQL Server. Current active rows always have `SysEndTime = '9999-12-31 23:59:59.9999999'`. When a row is updated, the old version is moved to `History.CalenderProviders` with this column set to the timestamp of the change. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Market.CalendarProviderExchanges | ProviderID | Implicit FK | Maps providers to the exchanges they supply calendar data for. Each row in CalendarProviderExchanges belongs to one provider. |
| Market.ProvidersExchangeDailySchedules | ProviderID | Implicit FK | Daily open/close schedule records are attributed to the provider that supplied them. |
| Market.ProvidersInstrumentDailySchedules | ProviderID | Implicit FK | Instrument-level daily schedules are attributed to the provider that supplied them. |
| Market.SetProviderExchangeCalendarBulk | @ProviderID | Parameter | Accepts a ProviderID to identify which provider's exchange schedules are being bulk-updated. |
| Market.GetHaltConfigurationsByProviderAndAccount | @ProviderID | Parameter | Filters halt configurations by provider. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Market.CalendarProviderExchanges | Table | References ProviderID as implicit FK — maps providers to their covered exchanges |
| Market.ProvidersExchangeDailySchedules | Table | References ProviderID — attributes each exchange daily schedule to a provider |
| Market.ProvidersInstrumentDailySchedules | Table | References ProviderID — attributes each instrument daily schedule to a provider |
| History.CalenderProviders | Table | Temporal history table — automatically maintained by SQL Server system versioning |
| Market.SetProviderExchangeCalendarBulk | Stored Procedure | Takes @ProviderID parameter — writes exchange schedule data for a specific provider |
| Market.GetHaltConfigurationsByProviderAndAccount | Stored Procedure | Takes @ProviderID parameter — retrieves halt configs filtered by provider |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| pk_calendarProviders | CLUSTERED PK | ProviderID | — | — | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| pk_calendarProviders | PRIMARY KEY | Enforces uniqueness of ProviderID. Each calendar data provider has exactly one entry. |
| DF_CalenderProviders_SysStart | DEFAULT | `SysStartTime` defaults to `getutcdate()` — sets the row creation time to current UTC on INSERT. |
| DF_CalenderProviders_SysEnd | DEFAULT | `SysEndTime` defaults to `'9999-12-31 23:59:59.9999999'` — marks newly inserted rows as currently active (no expiry). |

**Trigger**: `TRG_T_CalendarProviders` — fires FOR INSERT. Performs a no-op self-update (`SET ProviderID = ProviderID`) to force the temporal versioning engine to write an entry to `History.CalenderProviders`, ensuring every INSERT is audited in addition to UPDATEs.

---

## 8. Sample Queries

### 8.1 List all calendar data providers
```sql
SELECT ProviderID, ProviderName
FROM [Market].[CalenderProviders] WITH (NOLOCK)
ORDER BY ProviderID;
```

### 8.2 Check provider change history
```sql
SELECT ProviderID, ProviderName, DbLoginName, AppLoginName,
       SysStartTime, SysEndTime
FROM [History].[CalenderProviders] WITH (NOLOCK)
WHERE ProviderID IN (0, 1)
ORDER BY ProviderID, SysStartTime;
```

### 8.3 List exchanges covered by each provider
```sql
SELECT cp.ProviderID, cp.ProviderName,
       cpe.ExchangeID, cpe.ExchangeName
FROM [Market].[CalenderProviders] cp WITH (NOLOCK)
INNER JOIN [Market].[CalendarProviderExchanges] cpe WITH (NOLOCK)
    ON cp.ProviderID = cpe.ProviderID
ORDER BY cp.ProviderID, cpe.ExchangeName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: — | Quality: 6.9/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Market.CalenderProviders | Type: Table | Source: CalendarDB/CalendarDB/Market/Tables/Market.CalenderProviders.sql*
