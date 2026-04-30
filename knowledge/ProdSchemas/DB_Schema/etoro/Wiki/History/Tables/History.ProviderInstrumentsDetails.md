# History.ProviderInstrumentsDetails

> Temporal history backing table for CryptoLiquidity.ProviderInstrumentsDetails - storing all past versions of the per-instrument mode configuration for each crypto liquidity provider channel.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - clustered on (SysEndTime, SysStartTime) |
| **Partition** | No (ON [PRIMARY] filegroup) |
| **Indexes** | 1 (1 clustered temporal) |

---

## 1. Business Meaning

`History.ProviderInstrumentsDetails` is the **temporal history backing table** for `CryptoLiquidity.ProviderInstrumentsDetails`. SQL Server's system-versioned temporal tables automatically move old rows here whenever the live table is updated or deleted. This table is never written to directly.

The live table `CryptoLiquidity.ProviderInstrumentsDetails` defines how each financial instrument is configured within a specific crypto liquidity provider channel. Each row links one instrument (`instrument_id`) to one provider channel (`provider_channel_details_fk`) and specifies the operational `Mode` for that instrument on that channel (e.g., active, passive, disabled, or different execution strategies).

With 0 rows in the current environment, no configuration changes have been versioned since temporal versioning was enabled. The live table may be newly configured, or changes are very infrequent.

The `Pid` IDENTITY PK on the live table is the versioning key - when a row is updated, the old configuration is written here and a new row with a new Pid replaces it.

---

## 2. Business Logic

### 2.1 SQL Server Temporal Table - Automatic Versioning

**What**: Every change to CryptoLiquidity.ProviderInstrumentsDetails automatically writes the previous version here.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- `SysStartTime` = UTC timestamp when this instrument-channel-mode configuration became active
- `SysEndTime` = UTC timestamp when this configuration was superseded
- Rows here are EXPIRED versions only - current configuration lives in CryptoLiquidity.ProviderInstrumentsDetails

**Diagram**:
```
CryptoLiquidity.ProviderInstrumentsDetails (live - current crypto instrument channel configs)
    SYSTEM_VERSIONING = ON (HISTORY_TABLE = History.ProviderInstrumentsDetails)
    |
    v
History.ProviderInstrumentsDetails (this table - past configurations)
```

### 2.2 Instrument-Channel-Mode Assignment

**What**: The three business columns define the crypto liquidity routing configuration.

**Columns/Parameters Involved**: `Pid`, `provider_channel_details_fk`, `instrument_id`, `Mode`

**Rules**:
- `provider_channel_details_fk` FK to CryptoLiquidity.ProviderChannelDetails(Pid) - the specific channel through which this provider routes crypto orders
- `instrument_id` FK to instrument lookup - the crypto/financial instrument
- `Mode` (DEFAULT 0): operational mode for this instrument on this channel. 0 likely = standard/active mode; other values represent different execution strategies

---

## 3. Data Overview

0 rows in current environment. No configuration changes have been versioned since temporal versioning was enabled.

| Pid | provider_channel_details_fk | instrument_id | Mode | DbLoginName | Context |
|---|---|---|---|---|---|
| (no rows) | | | | | |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Pid | int | NO | - | CODE-BACKED | Auto-incrementing identity PK from the live CryptoLiquidity.ProviderInstrumentsDetails table. Carried into history to preserve the original row identifier. Allows joining back to the live table for context. |
| 2 | provider_channel_details_fk | int | NO | - | CODE-BACKED | FK to CryptoLiquidity.ProviderChannelDetails(Pid). Identifies the specific provider channel (a combination of provider, connection parameters, and routing rules) through which this instrument's crypto orders are routed. |
| 3 | instrument_id | int | NO | - | CODE-BACKED | The financial instrument (typically a crypto asset or crypto pair) configured on this provider channel. Implicit FK to instrument lookup. Snake_case naming inherited from the CryptoLiquidity schema's conventions. |
| 4 | Mode | int | NO | DEFAULT 0 | CODE-BACKED | Operational mode for this instrument on this channel. DEFAULT 0 = standard/active mode. Other values represent different execution behaviors (e.g., passive liquidity, disabled, special routing). |
| 5 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL login captured via suser_name() at write time on the live table. Identifies who modified the instrument channel configuration. |
| 6 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application identity from context_info() at write time. May contain null-byte padding. |
| 7 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this instrument-channel configuration became active. Set by SQL Server temporal engine. Starting boundary of validity period (inclusive). |
| 8 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this configuration was superseded. Set by SQL Server temporal engine. Ending boundary (exclusive). Clustered index leading column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| provider_channel_details_fk | CryptoLiquidity.ProviderChannelDetails | Implicit (FK on live table) | The provider channel this instrument is configured on |
| instrument_id | Instrument lookup | Implicit | The crypto/financial instrument |
| (all columns) | CryptoLiquidity.ProviderInstrumentsDetails | Temporal | This is the history backing table for the live CryptoLiquidity table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Server temporal engine | (auto) | System | Rows moved here automatically when CryptoLiquidity.ProviderInstrumentsDetails is modified |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ProviderInstrumentsDetails (table)
(temporal history backing table - no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No dependencies. Written entirely by SQL Server temporal table engine.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CryptoLiquidity.ProviderInstrumentsDetails | Table | Live table - SQL Server moves expired rows here automatically |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_ProviderInstrumentsDetails | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

*DATA_COMPRESSION=PAGE. Standard temporal history clustering pattern.*

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Point-in-time instrument channel configuration (via live table)

```sql
SELECT Pid, provider_channel_details_fk, instrument_id, Mode, DbLoginName, SysStartTime, SysEndTime
FROM CryptoLiquidity.ProviderInstrumentsDetails
FOR SYSTEM_TIME AS OF '2025-01-01 00:00:00'
WHERE instrument_id = @InstrumentID
```

### 8.2 Full change history for a specific channel-instrument pair

```sql
SELECT Pid, provider_channel_details_fk, instrument_id, Mode, DbLoginName, SysStartTime, SysEndTime
FROM History.ProviderInstrumentsDetails WITH (NOLOCK)
WHERE provider_channel_details_fk = @ChannelID AND instrument_id = @InstrumentID
ORDER BY SysStartTime ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.3/10 (Elements: 8.5/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ProviderInstrumentsDetails | Type: Table | Source: etoro/etoro/History/Tables/History.ProviderInstrumentsDetails.sql*
