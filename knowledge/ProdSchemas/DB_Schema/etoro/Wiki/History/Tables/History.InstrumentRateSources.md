# History.InstrumentRateSources

> Temporal history table capturing all changes to the per-instrument price feed source allocation, recording which rate providers were assigned to each instrument and in what priority order.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Clustered index on (SysEndTime, SysStartTime) - temporal history access pattern |
| **Partition** | No |
| **Indexes** | 1 active (clustered on SysEndTime, SysStartTime, PAGE compressed) |

---

## 1. Business Meaning

History.InstrumentRateSources is the SQL Server system-versioning history table for `Price.InstrumentRateSources`, which defines which price feed providers supply live market rates for each instrument in eToro's pricing engine. Every time the instrument-to-rate-source mapping changes (a new provider added, a provider removed, or priority reordered), the old row version is automatically moved here via the temporal mechanism.

This table answers audit questions such as "which rate source was supplying Bitcoin prices on a specific date?" and "when was a particular provider added or removed for instrument X?" These questions matter during pricing incidents, provider outages, or compliance reviews of past trade executions where the quality of the rate source at a specific point in time is relevant.

Data flows in automatically via SQL Server SYSTEM_VERSIONING from `Price.InstrumentRateSources`. The live table maps instruments to their rate sources (price feed providers identified by AccountRateSourceID), with an optional Priority column that determines which provider is preferred when multiple sources cover the same instrument. DbLoginName, AppLoginName, and HostName columns capture who made each change.

---

## 2. Business Logic

### 2.1 Multi-Source Priority Routing

**What**: An instrument can be mapped to multiple rate sources, with Priority determining which is consulted first.

**Columns/Parameters Involved**: `InstrumentID`, `AccountRateSourceID`, `Priority`

**Rules**:
- Lower Priority value = higher precedence (10 is tried before 20, 20 before 30)
- Multiple rows with the same InstrumentID represent a prioritized fallback chain
- When a primary source (Priority 10) is unavailable, the pricing engine falls back to Priority 20, then 30
- This history table preserves the exact routing configuration at every point in time

**Diagram**:
```
InstrumentID 100001 rate source chain (example from live data):
  Priority 10 -> AccountRateSourceID 102  (primary)
  Priority 20 -> AccountRateSourceID 102  (secondary, same provider, different config)
  Priority 30 -> AccountRateSourceID 217  (tertiary fallback)
  Priority 30 -> AccountRateSourceID 103  (tertiary fallback, alternative)
```

### 2.2 Temporal Change Capture

**What**: Every INSERT/UPDATE/DELETE on Price.InstrumentRateSources creates a history row capturing the old configuration.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`, `HostName`

**Rules**:
- SysStartTime: UTC timestamp when this configuration row became active in Price.InstrumentRateSources
- SysEndTime: UTC timestamp when this configuration was superseded (row changed or deleted)
- SysEndTime = '9999-12-31' in the live table marks currently active rows; no such rows appear in this history table
- DbLoginName: SQL Server login that executed the change (computed from suser_name() in live table)
- AppLoginName: Application-level user context (computed from context_info() in live table)
- HostName: Host machine that executed the change (computed from host_name() in live table)

---

## 3. Data Overview

| InstrumentRateSourceID | InstrumentID | AccountRateSourceID | Priority | Meaning |
|---|---|---|---|---|
| 605133 | 100001 | 217 | 30 | Tertiary fallback rate source for instrument 100001 - this was the most recent config change, now superseded |
| 605132 | 100001 | 21 | 20 | Secondary rate source for instrument 100001 prior to the above change |
| 605131 | 100001 | 102 | 10 | Primary rate source for instrument 100001 - highest priority feed |
| 605130 | 100001 | 103 | 30 | Previous tertiary fallback for instrument 100001, replaced by ID 605133 |
| 605129 | 100001 | 102 | 20 | Previous secondary assignment for instrument 100001, before recent re-ordering |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentRateSourceID | int | NO | - | CODE-BACKED | Unique identifier for the instrument-to-rate-source mapping row. IDENTITY(1,1) in the live Price table. Primary key in the live table; no PK in this history table (temporal history stores duplicates per change). |
| 2 | PriceServerID | int | YES | - | NAME-INFERRED | Optional reference to a price server instance. Nullable in both live and history tables; rarely populated in live data (all sampled rows show NULL). Likely a legacy field for a direct server assignment model predating the AccountRateSource abstraction. |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | The trading instrument this rate source mapping applies to. FK to Trade.Instrument(InstrumentID) in the live table. References the master instrument registry. |
| 4 | AccountRateSourceID | int | NO | - | CODE-BACKED | Identifies the price feed provider assigned to this instrument. FK to Price.AccountRateSource(AccountRateSourceID) in the live table. Values follow the AccountRateSource numbering scheme: 1-6 = simulation feeds, 8-299 = real HTTP/WebSocket providers (Xignite, Bloomberg, ZBFX, etc.), 9001-9010 = FIX protocol connections, 100000+ = OMS-integrated providers. See History.AccountRateSource for full provider registry. |
| 5 | Priority | int | YES | - | CODE-BACKED | Ordering priority for rate source selection when multiple providers are mapped to the same instrument. Lower value = higher precedence (10 = primary, 20 = secondary, 30 = tertiary fallback). The pricing engine uses this to determine failover order during provider outages. |
| 6 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login name of the session that made the change. Computed from suser_name() in the live Price.InstrumentRateSources table; stored as a static value in this history table. Used for change attribution and audit. |
| 7 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application-level user context at the time of the change. Computed from context_info() in the live table, which applications set to the authenticated user identity before executing DML. Stored statically here for audit. |
| 8 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row became the active configuration in Price.InstrumentRateSources. Start of the validity window for this instrument-to-rate-source assignment. |
| 9 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row was superseded by a change in Price.InstrumentRateSources. End of the validity window. Rows with SysEndTime = '9999-12-31' are the currently active versions (those remain in the live table, not here). |
| 10 | HostName | nvarchar(128) | YES | - | CODE-BACKED | Name of the host machine that executed the change. Computed from host_name() in the live table; stored statically here. Useful for infrastructure-level audit tracing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit (FK in live table) | The instrument whose price feed allocation is recorded. FK enforced on Price.InstrumentRateSources, not on this history table. |
| AccountRateSourceID | Price.AccountRateSource | Implicit (FK in live table) | The price feed provider assigned to the instrument. FK enforced on Price.InstrumentRateSources. See History.AccountRateSource for historical provider names. |
| InstrumentRateSourceID | Price.InstrumentRateSources | Temporal History | This table IS the history table for Price.InstrumentRateSources via SYSTEM_VERSIONING. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.InstrumentRateSources | SYSTEM_VERSIONING | Temporal Source | The live table that populates this history table via SQL Server temporal mechanism. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. (It is a temporal history table - a passive receiver of change data from the live table.)

---

### 6.1 Objects This Depends On

No dependencies. (History tables have no DDL-level dependencies; they receive data from the live temporal table.)

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.InstrumentRateSources | Table | Live temporal table whose change history is stored here via SYSTEM_VERSIONING |
| Price.InstrumentRateSourceAdd | Stored Procedure | Writer - inserts new instrument-to-rate-source mappings in the live table, creating history rows here |
| Price.InstrumentRateSourceEdit | Stored Procedure | Modifier - updates existing mappings, creating history rows here |
| Price.UpdateInstrumentRateSources | Stored Procedure | Modifier - bulk updates rate source assignments, generating history rows |
| Price.CleanUnmappedInstrumentRateSources | Stored Procedure | Deleter - removes unmapped entries, creating history rows |
| Trade.InstrumentRateSourceAdd | Stored Procedure | Writer - alternative path to create instrument rate source mappings |
| Trade.InstrumentRateSourceDelete | Stored Procedure | Deleter - removes instrument rate source mappings |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_InstrumentRateSources | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

None. (History tables do not have PK, FK, or CHECK constraints - temporal data is managed by the SQL Server temporal mechanism.)

---

## 8. Sample Queries

### 8.1 Find rate source history for a specific instrument
```sql
SELECT
    InstrumentRateSourceID,
    InstrumentID,
    AccountRateSourceID,
    Priority,
    SysStartTime,
    SysEndTime,
    DbLoginName,
    AppLoginName
FROM History.InstrumentRateSources WITH (NOLOCK)
WHERE InstrumentID = 100001
ORDER BY SysEndTime DESC
```

### 8.2 Find what rate source configuration was active for an instrument at a specific point in time
```sql
DECLARE @AsOf datetime2 = '2024-06-01 12:00:00'
SELECT
    InstrumentRateSourceID,
    AccountRateSourceID,
    Priority,
    SysStartTime,
    SysEndTime
FROM History.InstrumentRateSources WITH (NOLOCK)
WHERE InstrumentID = 10  -- e.g., EUR/USD
  AND SysStartTime <= @AsOf
  AND SysEndTime > @AsOf
ORDER BY Priority
```

### 8.3 Audit trail showing rate source changes with provider names
```sql
SELECT
    h.InstrumentRateSourceID,
    h.InstrumentID,
    h.AccountRateSourceID,
    ars.Name AS RateSourceName,
    h.Priority,
    h.SysStartTime AS ActiveFrom,
    h.SysEndTime AS ActiveTo,
    h.DbLoginName,
    h.AppLoginName
FROM History.InstrumentRateSources h WITH (NOLOCK)
LEFT JOIN Price.AccountRateSource ars WITH (NOLOCK)
    ON h.AccountRateSourceID = ars.AccountRateSourceID
WHERE h.SysEndTime > DATEADD(day, -30, GETUTCDATE())
ORDER BY h.InstrumentID, h.SysEndTime DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Liquidity Account & PCS](https://etoro-jira.atlassian.net/wiki/spaces/MDT/pages/11768725682/Liquidity+Account+PCS) | Confluence | Context on liquidity account and price source architecture used by eToro's pricing infrastructure |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.InstrumentRateSources | Type: Table | Source: etoro/etoro/History/Tables/History.InstrumentRateSources.sql*
