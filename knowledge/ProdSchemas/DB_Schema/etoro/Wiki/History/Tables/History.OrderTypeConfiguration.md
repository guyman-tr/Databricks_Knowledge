# History.OrderTypeConfiguration

> SQL Server temporal history table storing prior row versions of Hedge.OrderTypeConfiguration, preserving the full audit trail for changes to hedging order routing rules by instrument, group, or exchange.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No |
| **Indexes** | 1 (clustered on temporal system columns) |

---

## 1. Business Meaning

History.OrderTypeConfiguration is the SQL Server system-versioning history table for Hedge.OrderTypeConfiguration (declared as `SYSTEM_VERSIONING = ON (HISTORY_TABLE = [History].[OrderTypeConfiguration])`). Whenever a configuration row in Hedge.OrderTypeConfiguration is updated or deleted, the prior row version is automatically written here by the SQL Server temporal engine.

Hedge.OrderTypeConfiguration defines how the hedging engine routes orders to liquidity providers - which provider to use, what slippage tolerance to apply, what order duration to use (TimeInForce), and how long to wait before the order expires. Configuration is scoped either to individual instruments (Entity=0, Value=InstrumentID), instrument groups (Entity=1, Value=GroupID), or exchanges (Entity=2, Value=Exchange). This history table captures every change to these routing rules over time.

Data flows into this table via two mechanisms: standard temporal engine triggers (on UPDATE/DELETE to Hedge.OrderTypeConfiguration), and a special INSERT-capture trigger on the source table. Because SQL Server temporal by default only captures UPDATEs and DELETEs, Hedge.OrderTypeConfiguration has a trigger `AuditInsert_Hedge_OrderTypeConfiguration` that fires on INSERT and performs a no-op self-UPDATE (SET Value = Value), forcing the temporal engine to also write an INSERT record to this history table with SysStartTime = SysEndTime (a zero-duration window).

---

## 2. Business Logic

### 2.1 Temporal History Pattern

**What**: This table automatically receives all prior versions of Hedge.OrderTypeConfiguration rows.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `ConfigID`

**Rules**:
- SysStartTime: the UTC time the row version became active in Hedge.OrderTypeConfiguration.
- SysEndTime: the UTC time the row version was superseded (when it stopped being current).
- For INSERT events: SysStartTime = SysEndTime (zero-duration window) - this is the INSERT-capture trigger pattern.
- For UPDATE events: SysStartTime = when the row was last inserted/updated; SysEndTime = when it was updated again.
- For DELETE events: SysEndTime = when the row was deleted; the history row is the final state.
- To query the live current state, use Hedge.OrderTypeConfiguration. To query as-of a past timestamp, use the FOR SYSTEM_TIME AS OF syntax.

**Diagram**:
```
Hedge.OrderTypeConfiguration Change Flow
-----------------------------------------
INSERT ConfigID=34, Value="1000123"
  -> AuditInsert trigger fires: UPDATE ConfigID=34 SET Value=Value
  -> Temporal engine writes history: SysStartTime=SysEndTime=T1 (INSERT captured)
  -> Current row: ConfigID=34 in Hedge.OrderTypeConfiguration

Later: UPDATE ConfigID=34, Value="1000124"
  -> Temporal engine writes history: old version with SysEndTime=T2
  -> Current row updated in Hedge.OrderTypeConfiguration
```

### 2.2 Entity-Based Scope Hierarchy

**What**: The Entity column determines what the Value column represents - individual instrument, group, or exchange.

**Columns/Parameters Involved**: `Entity`, `Value`, `LiquidityAccountID`

**Rules**:
- Entity=0 (Instrument): Value stores an InstrumentID (cast as int). Routes orders for a specific instrument to the specified liquidity account.
- Entity=1 (Group): Value stores a GroupID from Hedge.InstrumentGroupsMapping. Routes orders for all instruments in that group.
- Entity=2 (Exchange): Value stores an Exchange identifier from Trade.InstrumentMetaData.Exchange. Routes orders for all instruments on that exchange.
- Hedge.GetOrderTypeConfiguration resolves these three variants via UNION, expanding groups and exchanges to individual instruments.
- The order of priority is controlled by the Priority column; lower Priority value = higher precedence.

### 2.3 Scheduling Window

**What**: Some configurations apply only during specific time windows.

**Columns/Parameters Involved**: `ScheduleActive`, `FromTime`, `ToTime`

**Rules**:
- ScheduleActive=1: the FromTime/ToTime window is active; the configuration only applies during that time range.
- ScheduleActive=0 (most rows): configuration applies at all times; FromTime and ToTime are NULL.
- Time comparisons use wall-clock time (time(7) - no date component).

---

## 3. Data Overview

| ConfigID | ScheduleActive | Entity | Value | ProviderType | LiquidityAccountID | Slippage | SysStartTime | SysEndTime | Meaning |
|----------|---------------|--------|-------|-------------|-------------------|----------|-------------|------------|---------|
| 12 | false | 0 | 1211 | 69 | 10 | 0 | 2025-06-25 13:18 | 2026-02-26 09:49 | Instrument 1211's routing via provider type 69 (LA 10) was active ~8 months until Feb 2026 reconfiguration |
| 34 | false | 0 | 1000123 | 1 | 1 | 0.05 | 2025-08-07 11:40 | 2025-08-07 11:40 | INSERT-capture record (SysStart=SysEnd): ConfigID 34 was created then immediately deleted or modified on the same timestamp |
| 33 | false | 0 | 1000122 | 1 | 1 | 0.05 | 2025-08-07 11:31 | 2025-08-07 11:31 | INSERT-capture record for ConfigID 33 created and modified within the same second |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ConfigID | int | NO | - | CODE-BACKED | Configuration row identifier from Hedge.OrderTypeConfiguration (IDENTITY). Not unique in this history table - the same ConfigID can appear multiple times representing its different versions over time. |
| 2 | ScheduleActive | bit | NO | - | CODE-BACKED | Whether time-window scheduling is active: 1=only apply this configuration during FromTime-ToTime window; 0=apply at all times (FromTime/ToTime are NULL). |
| 3 | FromTime | time(7) | YES | - | CODE-BACKED | Start of the active time window (UTC wall-clock time). NULL when ScheduleActive=0. |
| 4 | ToTime | time(7) | YES | - | CODE-BACKED | End of the active time window (UTC wall-clock time). NULL when ScheduleActive=0. |
| 5 | ProviderType | int | NO | - | CODE-BACKED | Liquidity provider type/category for order routing. Determines which category of LP handles orders matching this rule. Implicit FK to provider type lookup tables. |
| 6 | LiquidityAccountID | int | NO | - | CODE-BACKED | Specific liquidity account to route orders to. FK to History.LiquidityAccounts (done Batch 8) / Trade.LiquidityAccounts. Identifies the exact connection account (e.g., execution account for a given LP). |
| 7 | Entity | smallint | NO | - | CODE-BACKED | Scope type determining what Value represents: 0=individual instrument (Value=InstrumentID); 1=instrument group (Value=GroupID from Hedge.InstrumentGroupsMapping); 2=exchange (Value=Exchange from Trade.InstrumentMetaData). |
| 8 | Value | varchar(250) | NO | - | CODE-BACKED | The scope identifier whose meaning depends on Entity: InstrumentID (Entity=0), GroupID (Entity=1), or Exchange name/code (Entity=2). Cast to int for Entity 0 and 1; used as string for Entity=2. |
| 9 | QuantityType | smallint | NO | - | CODE-BACKED | How the Threshold quantity is measured (e.g., lots, units, value). Determines the unit of measurement for the Threshold column. |
| 10 | Threshold | decimal(18,6) | NO | - | CODE-BACKED | Minimum or maximum quantity threshold for this routing rule. The interpretation depends on QuantityType. 0 means no threshold applied. |
| 11 | Slippage | decimal(18,6) | NO | - | CODE-BACKED | Maximum acceptable slippage (price deviation) for orders routed via this rule, expressed as a decimal value. 0 means no slippage tolerance set (exact price required or best-effort). |
| 12 | ExpirationInSeconds | int | NO | - | CODE-BACKED | How long (in seconds) an order placed under this rule should remain open before it expires. 0 means no expiration. Governs how quickly unexecuted hedge orders are cancelled. |
| 13 | Priority | int | NO | - | CODE-BACKED | Routing priority; lower value = higher precedence. When multiple configuration rules match an instrument, the lower Priority number wins. |
| 14 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login that made the change, computed via SUSER_NAME() in the source table. Captured at INSERT/UPDATE time for audit. |
| 15 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application context info at the time of the change, from CONTEXT_INFO(). Set by the application layer before running the configuration change. Identifies which application/service made the change. |
| 16 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row version became active in Hedge.OrderTypeConfiguration. Set by the SQL Server temporal engine. |
| 17 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row version was superseded. SysStartTime=SysEndTime indicates an INSERT-capture record (from the AuditInsert trigger pattern). |
| 18 | TimeInForce | varchar(128) | NO | 'Day' | CODE-BACKED | Order duration instruction for the LP: "Day" (expires at end of trading day, the default), "ImmediateOrCancel" (fill what you can immediately, cancel the rest), or a numeric string (e.g., "3" = a legacy numeric TimeInForce code). |
| 19 | ReferencePriceType | varchar(128) | NO | 'Default' | CODE-BACKED | Price reference type for the order. "Default" is the standard reference. May specify alternate price reference modes for specific LP configurations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityAccountID | Trade.LiquidityAccounts | Implicit | Routes hedge orders to a specific LP connection account. History version of this reference links to History.LiquidityAccounts. |
| (source table) | Hedge.OrderTypeConfiguration | Temporal History | This table is declared as the HISTORY_TABLE for Hedge.OrderTypeConfiguration. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.OrderTypeConfiguration | HISTORY_TABLE | Temporal system versioning | All row version changes in Hedge.OrderTypeConfiguration are automatically written here. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (temporal history tables receive data via the SQL Server engine, not via SQL code).

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.OrderTypeConfiguration | Table | Source of all history writes via SQL Server temporal system versioning |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_OrderTypeConfiguration | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

None. Temporal history tables have no PK or FK constraints - they are append-only managed by the SQL Server engine.

---

## 8. Sample Queries

### 8.1 View the full change history for a specific configuration row

```sql
SELECT ConfigID, Entity, Value, LiquidityAccountID, ProviderType, TimeInForce, Slippage,
       DbLoginName, AppLoginName, SysStartTime, SysEndTime
FROM History.OrderTypeConfiguration WITH (NOLOCK)
WHERE ConfigID = 12
ORDER BY SysStartTime;
```

### 8.2 Find all configuration changes made by OpsFlowAPI

```sql
SELECT ConfigID, Entity, Value, ProviderType, Slippage, DbLoginName, SysStartTime, SysEndTime
FROM History.OrderTypeConfiguration WITH (NOLOCK)
WHERE DbLoginName LIKE '%OpsFlow%'
ORDER BY SysStartTime DESC;
```

### 8.3 Query the current live configuration alongside its history count

```sql
SELECT c.ConfigID, c.Entity, c.Value, c.LiquidityAccountID, c.Priority,
       COUNT(h.ConfigID) AS VersionCount
FROM Hedge.OrderTypeConfiguration c WITH (NOLOCK)
LEFT JOIN History.OrderTypeConfiguration h WITH (NOLOCK) ON h.ConfigID = c.ConfigID
GROUP BY c.ConfigID, c.Entity, c.Value, c.LiquidityAccountID, c.Priority
ORDER BY c.Priority;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.OrderTypeConfiguration | Type: Table | Source: etoro/etoro/History/Tables/History.OrderTypeConfiguration.sql*
