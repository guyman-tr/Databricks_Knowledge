# History.FIXConnections

> SQL Server system-versioned temporal history table for Hedge.FIXConnections, recording every change to FIX protocol connection registrations that link eToro's hedging engine to external liquidity providers.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (ConnectionID, SysStartTime, SysEndTime) - no formal PK; temporal history semantics |
| **Partition** | No (stored on [MAIN] filegroup) |
| **Indexes** | 1 (CLUSTERED on SysEndTime ASC, SysStartTime ASC, DATA_COMPRESSION=PAGE) |

---

## 1. Business Meaning

This table is the automatically maintained historical version store for `Hedge.FIXConnections`. SQL Server's system-versioning manages this table transparently: whenever a row in `Hedge.FIXConnections` is inserted, updated, or deleted, the previous row state is written here with SysStartTime/SysEndTime bracketing the validity window.

`Hedge.FIXConnections` registers each FIX (Financial Information eXchange) protocol connection that eToro's hedging engine maintains with external liquidity providers. FIX is the industry-standard messaging protocol for electronic trading - each connection represents a dedicated channel to a specific counterparty (e.g., "ZBFX Price2 Execution", "Trafix UAT Fractional") through which hedge orders are routed. Each connection is associated with a LiquidityAccountID and a ScheduleID controlling when the connection is active.

Changes to FIX connections are operationally significant - modifying connection names, reassigning liquidity accounts, or changing trading schedules affects how orders are routed to liquidity providers. The history table provides an audit trail for compliance and incident investigation. The `AppLoginName` pattern "username;ConfigurationManager" (padded with null bytes) identifies changes made through the dedicated Configuration Manager tool rather than direct SQL access.

---

## 2. Business Logic

### 2.1 FIX Connection Registry

**What**: Each row in Hedge.FIXConnections defines one FIX protocol session to a liquidity provider, identified by a manually-assigned ConnectionID and linked to a LiquidityAccountID.

**Columns/Parameters Involved**: `ConnectionID`, `Name`, `LiquidityAccountID`, `ScheduleID`

**Rules**:
- ConnectionID is manually assigned (not IDENTITY) - operators control the numeric ID
- LiquidityAccountID links to the liquidity provider account that this FIX session serves; Hedge.GetFIXConnections filters by LiquidityAccountID to find all sessions for a provider
- ScheduleID references a trading schedule configuration (e.g., "AllWeekExample" = 24/7 operation, "Default" = standard hours)
- The detailed FIX protocol parameters (host, port, SenderCompID, etc.) live in Hedge.FIXConnectionDetails keyed by ConnectionID
- Test/UAT connections co-exist with production connections (e.g., "Trafix UAT Fractional", "FD Provider UAT Connection")

### 2.2 SQL Server Temporal + INSERT Trigger Capture

**What**: Standard dual-capture pattern - temporal versioning for UPDATE/DELETE, INSERT trigger for creation events.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- INSERT trigger TRG_T_FIXConnections fires a no-op UPDATE (SET ConnectionID=ConnectionID) to force SQL Server to write the new row into this history table
- AppLoginName format: "{username};ConfigurationManager" padded with null bytes - operator email/username plus the tool name that made the change, stored as null-padded varchar via context_info()
- When AppLoginName is NULL (e.g., DevTradingSTG), the change was made directly via SQL without the Configuration Manager tool

---

## 3. Data Overview

| ConnectionID | Name | LiquidityAccountID | ScheduleID | SysStartTime | SysEndTime | Meaning |
|---|---|---|---|---|---|---|
| 14 | Trafix UAT Fractional | 14 | AllWeekExample | 2026-02-25 | 2026-02-25 (same) | INSERT capture for UAT/test connection to Trafix provider (fractional shares). AllWeekExample = always-on schedule. Changed by dotanva via ConfigurationManager. |
| 10 | ZBFX Price2 Execution | 10 | AllWeekExample | 2025-03-19 | 2025-03-19 (same) | INSERT capture for ZBFX production liquidity provider connection (execution channel). Changed by yardenmo via ConfigurationManager. |
| 7 | sdfsdf | 13 | Default | 2026-02-19 | 2026-02-19 (same) | Test/scratch connection (name "sdfsdf"). LiquidityAccountID=13, Default schedule. Created by dotanva for testing purposes. |
| 3545411 | FD Provider UAT Connection | 354541 | AllWeekExample | 2025-08-13 | 2025-08-13 (same) | UAT connection for FD (FD Provider) with high ConnectionID=3545411. Added via direct SQL (AppLoginName=NULL, DbLoginName=DevTradingSTG). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ConnectionID | int | NO | - | CODE-BACKED | Manually-assigned identifier for this FIX protocol connection. Not an IDENTITY - operators choose the ID. Matches Hedge.FIXConnections.ConnectionID (PK). Used as FK in Hedge.FIXConnectionDetails to link connection parameters. Multiple history rows with the same ConnectionID represent successive configuration versions. |
| 2 | Name | varchar(256) | YES | - | CODE-BACKED | Human-readable display name for this FIX connection, as shown in the Configuration Manager UI. Examples: "ZBFX Price2 Execution", "Trafix UAT Fractional", "FD Provider UAT Connection". Includes the liquidity provider name and connection purpose (Price/Execution, UAT/Prod). NULL allowed but in practice always populated. |
| 3 | LiquidityAccountID | int | YES | - | CODE-BACKED | The liquidity provider account that this FIX connection serves. Indexed in the source table (IX_LiquidityAccountID). Hedge.GetFIXConnections queries by this column to retrieve all FIX sessions for a given provider. Implicit FK to the liquidity accounts configuration. |
| 4 | ScheduleID | varchar(256) | NO | - | CODE-BACKED | Identifier for the trading schedule that controls when this FIX connection is active. Observed values: "AllWeekExample" (connection active 24/7 or all trading days), "Default" (standard trading hours schedule). References a schedule definition in the FIX engine configuration. |
| 5 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login (suser_name()) that made the change. Computed in source, materialized here. Examples: "TRAD\dotanva", "TRAD\yardenmo" (hedging team operators), "DevTradingSTG" (dev/staging service account). |
| 6 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application context from context_info() at time of change. Format when set by Configuration Manager: "{username};ConfigurationManager" followed by null-byte padding (e.g., "dotanva;ConfigurationManager\0\0..."). NULL when change was made directly via SQL without the Configuration Manager tool. |
| 7 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this connection configuration version became active. For INSERT-trigger-captured rows, equals SysEndTime (zero-duration version). |
| 8 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this version was superseded. CLUSTERED index leading column. SysEndTime=SysStartTime marks INSERT trigger capture events. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ConnectionID | [History.FIXConnectionDetails](History.FIXConnectionDetails.md) | Implicit | Each FIXConnections history row has corresponding FIXConnectionDetails history rows storing the FIX protocol parameters (host, port, SenderCompID, etc.) for that connection version. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.FIXConnections | SYSTEM_VERSIONING | Temporal history source | All superseded row versions routed here; INSERT trigger forces creation capture. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.FIXConnections (table)
- no code-level dependencies (leaf table, temporal history)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.FIXConnections | Table | Source temporal table |
| Hedge.GetFIXConnections | Stored Procedure | Reads source table (not history directly) to retrieve FIX sessions by LiquidityAccountID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_FIXConnections | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (DATA_COMPRESSION=PAGE, on [MAIN] filegroup) |

### 7.2 Constraints

None. Temporal history tables have no PK, FK, CHECK, UNIQUE, or DEFAULT constraints.

---

## 8. Sample Queries

### 8.1 What were all FIX connections for a liquidity account on a specific date?

```sql
SELECT
    fc.ConnectionID,
    fc.Name,
    fc.LiquidityAccountID,
    fc.ScheduleID,
    fc.SysStartTime,
    fc.SysEndTime,
    fc.DbLoginName
FROM Hedge.FIXConnections FOR SYSTEM_TIME AS OF '2025-12-01T00:00:00' fc WITH (NOLOCK)
WHERE fc.LiquidityAccountID = @LiquidityAccountID;
```

### 8.2 Full history of changes for a specific FIX connection

```sql
SELECT
    h.ConnectionID,
    h.Name,
    h.LiquidityAccountID,
    h.ScheduleID,
    h.SysStartTime AS ValidFrom,
    h.SysEndTime AS ValidUntil,
    h.DbLoginName AS ChangedBy,
    h.AppLoginName,
    DATEDIFF(SECOND, h.SysStartTime, h.SysEndTime) AS VersionDurationSecs
FROM History.FIXConnections h WITH (NOLOCK)
WHERE h.ConnectionID = @ConnectionID
  AND DATEDIFF(MILLISECOND, h.SysStartTime, h.SysEndTime) > 100
ORDER BY h.SysStartTime;
```

### 8.3 All FIX connection changes in a time window across all providers

```sql
SELECT
    h.ConnectionID,
    h.Name,
    h.LiquidityAccountID,
    h.ScheduleID AS OldScheduleID,
    h.SysEndTime AS ChangeTime,
    h.DbLoginName AS ChangedBy,
    LEFT(h.AppLoginName, CHARINDEX(';', h.AppLoginName + ';') - 1) AS OperatorName
FROM History.FIXConnections h WITH (NOLOCK)
WHERE h.SysEndTime >= @StartDate
  AND h.SysEndTime < @EndDate
  AND DATEDIFF(MILLISECOND, h.SysStartTime, h.SysEndTime) > 100
ORDER BY h.SysEndTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Hedge.GetFIXConnections) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.FIXConnections | Type: Table | Source: etoro/etoro/History/Tables/History.FIXConnections.sql*
