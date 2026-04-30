# History.HedgeServerInstrumentConfiguration

> SQL Server system-versioned temporal history table for Hedge.HedgeServerInstrumentConfiguration, recording every change to the per-hedge-server, per-instrument configuration including HBC failover permissions, price source assignment, deal size check flags, and initial margin minimums.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (HedgeServerID, InstrumentID, SysStartTime, SysEndTime) - no formal PK; temporal history semantics |
| **Partition** | No (stored on [DICTIONARY] filegroup) |
| **Indexes** | 1 (CLUSTERED on SysEndTime ASC, SysStartTime ASC, DATA_COMPRESSION=PAGE) |

---

## 1. Business Meaning

This table is the automatically maintained historical version store for `Hedge.HedgeServerInstrumentConfiguration`. SQL Server's system-versioning manages this table transparently: whenever a row in `Hedge.HedgeServerInstrumentConfiguration` is inserted, updated, or deleted, the previous row state is written here with SysStartTime/SysEndTime bracketing the validity window.

`Hedge.HedgeServerInstrumentConfiguration` provides the most granular level of hedge routing configuration: one row per (hedge server, instrument) pair. While `Hedge.InstrumentTypeConfiguration` assigns a default hedge server per instrument type, and `Hedge.InstrumentConfiguration` sets per-instrument order size limits and circuit breakers, this table configures the behavior of a specific instrument on a specific hedge server:

- **HBC failover**: whether this instrument is allowed to fail over to an alternative hedge server if the HBC (Hedge Book Control) system detects an issue
- **Price source**: which price feed this server uses for this instrument's pricing
- **Close position max deal size check**: whether the max deal size check is enforced when closing (not just opening) positions
- **Minimum amount for IM**: the minimum position size that requires an Initial Margin calculation

The INSERT trigger `Tr_T_HedgeServerInstrumentConfiguration_INSERT` fires a no-op UPDATE to capture newly inserted rows in temporal history. Stored on [DICTIONARY] filegroup despite being hedge operational data - a legacy placement decision.

0 rows in this environment.

---

## 2. Business Logic

### 2.1 HBC Failover Control

**What**: The HBC (Hedge Book Control) system can route instruments to alternative hedge servers when the primary server has issues. This flag controls whether a specific instrument is eligible for that failover.

**Columns/Parameters Involved**: `HedgeServerID`, `InstrumentID`, `AllowHBCFailover`

**Rules**:
- bit, not nullable - must be explicitly set
- 1 (true): this instrument is allowed to fail over to another hedge server if HBC detects a routing issue
- 0 (false): this instrument is pinned to this specific hedge server; failover is disabled regardless of HBC state
- Disabling failover (0) may be appropriate for instruments with server-specific configurations or regulatory requirements

### 2.2 Price Source Assignment

**What**: Each hedge server can use a different price feed for an instrument. PriceSource identifies which price source this server uses for pricing decisions on this instrument.

**Columns/Parameters Involved**: `PriceSource`

**Rules**:
- smallint, DEFAULT 1 - the primary/default price source
- The integer value maps to an internal price source enum (specific mappings not in SSDT DDL)
- Different price sources affect bid/ask pricing, spread calculations, and mark-to-market valuations for this instrument on this server

### 2.3 Close Position Max Deal Size Check

**What**: Controls whether the maximum deal size validation runs when closing positions, in addition to when opening them.

**Columns/Parameters Involved**: `AllowClosePositionMaxDealSizeCheck`

**Rules**:
- bit, DEFAULT 1 (check enabled on close)
- 1: the HBC max deal size check applies both when opening AND closing positions
- 0: the max deal size check is bypassed when closing positions (allowing close orders above the normal threshold - useful for unwinding large positions that exceed current limits)

### 2.4 Minimum Amount for Initial Margin

**What**: The minimum position size (in the instrument's base unit) that triggers an Initial Margin (IM) calculation requirement.

**Columns/Parameters Involved**: `MinAmountForIM`

**Rules**:
- decimal(16,4), DEFAULT 0 - by default no minimum (all positions require IM)
- When set to a positive value: positions below this amount are exempt from the IM calculation, reducing margin overhead for very small positions
- Relevant for instruments where small fractional positions are common (e.g., crypto)

### 2.5 INSERT Trigger Capture Pattern

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- INSERT trigger `Tr_T_HedgeServerInstrumentConfiguration_INSERT` fires a no-op UPDATE (SET HedgeServerID=HedgeServerID, InstrumentID=InstrumentID) joining on (HedgeServerID, InstrumentID) to force SQL Server to write the newly inserted row into temporal history
- Zero-duration rows (SysStartTime = SysEndTime) mark INSERT captures
- DbLoginName: suser_name() computed column in source, materialized in history
- AppLoginName: CONVERT(varchar(500), context_info()) computed column in source, materialized in history

---

## 3. Data Overview

| Scale | Value |
|-------|-------|
| Total rows | 0 (dev environment - table not deployed) |
| Source table | Hedge.HedgeServerInstrumentConfiguration |
| Cardinality | One row per (HedgeServerID, InstrumentID) pair |
| Filegroup | [DICTIONARY] |

In production, row count equals the number of configured (hedge server, instrument) routing pairs. Given eToro's instrument catalog (~1,000+ instruments) and multiple hedge servers, this table may have thousands of rows.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | NO | - | CODE-BACKED | The hedge server for which this instrument configuration applies. Part of the composite PK. Implicit FK to Trade.HedgeServer(HedgeServerID). The source has nonclustered index idx_HSID on this column for fast lookup of all instruments on a given server. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | The financial instrument being configured on this hedge server. Part of the composite PK. Implicit FK to Trade.Instrument(InstrumentID). Source has nonclustered index idx_InstrumentID on this column for fast lookup of all servers for a given instrument. |
| 3 | AllowHBCFailover | bit | NO | - | CODE-BACKED | Whether the HBC system is permitted to fail over this instrument to an alternative hedge server. 1=failover allowed, 0=pinned to this server (no failover). Source has no explicit DEFAULT - must be set on insert. |
| 4 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login (suser_name()) at time of change. Computed column in source, materialized in history. |
| 5 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application context from context_info() at time of change. May contain operator email or service identifier. |
| 6 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this server-instrument configuration version became active. Source DEFAULT=getutcdate(). For INSERT-trigger-captured rows, equals SysEndTime. |
| 7 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this version was superseded. CLUSTERED index leading column. Source DEFAULT='9999-12-31'. |
| 8 | PriceSource | smallint | NO | - | CODE-BACKED | Price feed source for this instrument on this hedge server. Source DEFAULT=1 (primary price source). The integer maps to an internal price source enum determining which market data feed is used for pricing decisions. |
| 9 | AllowClosePositionMaxDealSizeCheck | bit | NO | - | CODE-BACKED | Whether the HBC max deal size check also applies when closing positions (not just opening). Source DEFAULT=1 (check enabled on close). 0=bypass the check on close, allowing large positions to be unwound even if they exceed the current deal size limit. |
| 10 | MinAmountForIM | decimal(16,4) | NO | - | CODE-BACKED | Minimum position size (in the instrument's base unit) that requires an Initial Margin (IM) calculation. Source DEFAULT=0 (all positions require IM). Positive values exempt small fractional positions from margin overhead. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | Implicit | Hedge server this configuration applies to. No FK constraint on history table; enforced implicitly via source. |
| InstrumentID | Trade.Instrument | Implicit | Financial instrument being configured. No FK constraint on history table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.HedgeServerInstrumentConfiguration | SYSTEM_VERSIONING | Temporal history source | All superseded row versions routed here; INSERT trigger captures creations. |
| Hedge.GetHedgeServerInstrumentConfiguration | - | Reader | Bulk-reads all current configurations for the hedging engine startup/reload. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.HedgeServerInstrumentConfiguration (table)
- no code-level dependencies (leaf table, temporal history)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HedgeServerInstrumentConfiguration | Table | Source temporal table |
| Hedge.GetHedgeServerInstrumentConfiguration | Stored Procedure | Bulk reader - loads all configs at startup |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_HedgeServerInstrumentConfiguration | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (DATA_COMPRESSION=PAGE, on [DICTIONARY] filegroup) |

Source table additionally has:
- CLUSTERED PK on (HedgeServerID, InstrumentID) - on [DICTIONARY] filegroup
- idx_HSID: NONCLUSTERED on HedgeServerID (lookup all instruments for a server)
- idx_InstrumentID: NONCLUSTERED on InstrumentID (lookup all servers for an instrument)

### 7.2 Constraints

None on history table. Source table has:
- CLUSTERED PK on (HedgeServerID, InstrumentID)
- DEFAULT PriceSource=1, AllowClosePositionMaxDealSizeCheck=1, MinAmountForIM=0

### 7.3 Notes

- Stored on [DICTIONARY] filegroup despite being operational hedge routing data - legacy placement; no dedicated Hedge filegroup exists
- No FK constraints on either HedgeServerID or InstrumentID despite both being implied foreign keys - flexibility for adding instrument/server configs before their parent records exist
- AllowHBCFailover has no DEFAULT - must be explicitly set on every INSERT; implies callers always have a deliberate choice for this flag

---

## 8. Sample Queries

### 8.1 All instrument configurations for a hedge server (current)

```sql
SELECT
    hsic.HedgeServerID,
    hsic.InstrumentID,
    hsic.AllowHBCFailover,
    hsic.PriceSource,
    hsic.AllowClosePositionMaxDealSizeCheck,
    hsic.MinAmountForIM
FROM Hedge.HedgeServerInstrumentConfiguration hsic WITH (NOLOCK)
WHERE hsic.HedgeServerID = @HedgeServerID
ORDER BY hsic.InstrumentID;
```

### 8.2 Change history for a server-instrument pair

```sql
SELECT
    h.HedgeServerID,
    h.InstrumentID,
    h.AllowHBCFailover,
    h.PriceSource,
    h.AllowClosePositionMaxDealSizeCheck,
    h.MinAmountForIM,
    h.DbLoginName AS ChangedBy,
    h.SysStartTime AS ValidFrom,
    h.SysEndTime AS ValidUntil
FROM History.HedgeServerInstrumentConfiguration h WITH (NOLOCK)
WHERE h.HedgeServerID = @HedgeServerID
  AND h.InstrumentID = @InstrumentID
  AND DATEDIFF(MILLISECOND, h.SysStartTime, h.SysEndTime) > 100
ORDER BY h.SysStartTime;
```

### 8.3 Instruments with HBC failover disabled on a specific date

```sql
SELECT
    hsic.HedgeServerID,
    hsic.InstrumentID
FROM Hedge.HedgeServerInstrumentConfiguration
    FOR SYSTEM_TIME AS OF '2026-01-01T00:00:00' hsic WITH (NOLOCK)
WHERE hsic.AllowHBCFailover = 0
ORDER BY hsic.HedgeServerID, hsic.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Hedge.GetHedgeServerInstrumentConfiguration) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.HedgeServerInstrumentConfiguration | Type: Table | Source: etoro/etoro/History/Tables/History.HedgeServerInstrumentConfiguration.sql*
