# History.LiquidityProviderType

> Temporal history table capturing all configuration changes made to Trade.LiquidityProviderType - the classification of external liquidity provider connection technologies used by the eToro hedging engine.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History Table) |
| **Key Identifier** | LiquidityProviderTypeID + SysStartTime (composite - allows multiple versions per type) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

History.LiquidityProviderType is the system-versioned temporal history table that records every configuration change ever made to Trade.LiquidityProviderType. The current (live) table classifies the different types of external liquidity providers that eToro connects to for price feeds and trade execution hedging. Each type defines the .NET assembly and class that the Price Control System (PCS) and Hedge Engine use to communicate with that provider technology.

Without this history table, only the current configuration of each provider type would be accessible. This history table allows the trading and operations teams to audit which assembly/class was in use at any given point in time - critical for diagnosing hedging issues, replaying historical trades, or understanding configuration rollbacks. It also captures who (DbLoginName) made each change.

Data flows from Trade.LiquidityProviderType via SQL Server's SYSTEM_VERSIONING mechanism: whenever a row in Trade.LiquidityProviderType is INSERTed, UPDATEd, or DELETEd, the old version is automatically moved to this history table with SysStartTime and SysEndTime stamped to reflect the validity period. The live table has a computed DbLoginName (suser_name()) and AppLoginName (context_info()) - in this history table those values are stored as captured snapshots at the time of change.

---

## 2. Business Logic

### 2.1 Temporal Versioning - How Change History is Captured

**What**: SQL Server's system-versioning mechanism automatically moves superseded rows from Trade.LiquidityProviderType to this history table, creating a complete audit trail of every configuration change.

**Columns/Parameters Involved**: `LiquidityProviderTypeID`, `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- When a row in Trade.LiquidityProviderType is modified, the OLD version is written here with SysEndTime = moment of change
- SysStartTime and SysEndTime together define the period during which that configuration was active
- When SysEndTime equals SysStartTime, the row had effectively zero duration (immediate reconfiguration)
- Multiple rows with the same LiquidityProviderTypeID represent sequential configuration versions
- DbLoginName captures the database user (TRAD domain accounts or service accounts) who triggered the change
- AppLoginName captures the application context (typically "username;ConfigurationManager" from context_info())

**Diagram**:
```
Trade.LiquidityProviderType (current)
    ID=308, Name="FD Ndf", SysStart=2023-10-12, SysEnd=9999-12-31

History.LiquidityProviderType (archived versions)
    ID=308, Name="FirstDerivativesRealStreamPriceProvider", SysStart=2023-08-01, SysEnd=2023-08-01 (immediate rename)
    ID=308, Name="FD Stream Provider",                      SysStart=2023-08-01, SysEnd=2023-08-15
    ID=308, Name="FD Ndf",                                  SysStart=2023-08-15, SysEnd=2023-10-12

Query current-at-point-in-time:
  SELECT * FROM Trade.LiquidityProviderType FOR SYSTEM_TIME AS OF '2023-09-01'
```

### 2.2 TypeSettingsXML - Provider Technology Configuration

**What**: The TypeSettingsXML column stores structured XML defining the .NET assemblies and configuration parameters that the Hedge Engine and PCS use to instantiate and connect to each provider type.

**Columns/Parameters Involved**: `TypeSettingsXML`, `LiquidityProviderTypeID`

**Rules**:
- `PCSClassInfo`: Specifies the DLL and class for the Price Control System feed (price-only providers may only have this)
- `HedgingProviderClassInfo`: Specifies the DLL and class for the Hedge Engine execution provider (execution-capable providers have this)
- `executionClassInfo`: Alternative execution class for some providers (e.g., First Derivatives DFLMFX client)
- `ProviderExecutionSettings`: Defines default_lot_size (e.g., 1 for FX pairs, 1000 for equity-style providers)
- `OnixsEngineSettings`: FIX protocol engine parameters (reconnectInterval, reconnectAttempts, sessionStorageType)
- NULL TypeSettingsXML indicates a provider type with no automated assembly configuration (manual setup or deprecated)
- `<typeSettings/>` (empty element) indicates a configured but assembly-less type (e.g., Watchlist)

**Diagram**:
```
Provider Type Categories (inferred from TypeSettingsXML patterns):
  Full Trading Provider (Price + Execution):
    PCSClassInfo + HedgingProviderClassInfo + ProviderExecutionSettings + OnixsEngineSettings
    Examples: FD, Talos, DLT, Marex, EMSX Citadel
  Price-Only Provider:
    PCSClassInfo only (no HedgingProviderClassInfo)
    Examples: QuantHouse, ICE, Bloomberg feeds
  Execution-Only Provider:
    HedgingProviderClassInfo only (no PCSClassInfo)
    Examples: OMS
  FIX Protocol Providers (9000-9999 range):
    PCSClassInfo with FixPriceProviderWrapper + OnixsEngineSettings with batchBulkSize
    Examples: FIX_ZBFX (9001), FIX_IG (9005), FIX_BITA (9006)
```

### 2.3 Provider Type ID Naming Conventions

**What**: LiquidityProviderTypeID values follow loose numeric conventions that reflect the provider technology category, though these are not enforced by constraints.

**Columns/Parameters Involved**: `LiquidityProviderTypeID`, `Name`

**Rules**:
- IDs 1-299: Legacy/primary broker and exchange providers (FD=3, APEX=40, Blooberg Futures=43, Watchlist=50)
- IDs 300-499: Direct book depth and exchange connections (eToroX=300, Binance Direct=302, DLT=439)
- IDs 9000-9999: FIX protocol-based providers (FIX_ZBFX=9001 through FIX_BITA=9006)
- IDs 10000-10999: Specialized market data and OMS providers (OMS=10002, FD Ndf=10004, QuantHouse=10005, ICE=10006)
- IDs 20000+: Newer streaming/market data providers (Market Stream Bloomberg=20000)

---

## 3. Data Overview

| LiquidityProviderTypeID | Name | TypeSettingsXML Summary | DbLoginName | Meaning |
|---|---|---|---|---|
| 3 | FD | PCSClassInfo=FD NDF + HedgingProviderClassInfo=FDHedgingProvider, lot_size=1000, OnixS reconnect | ETORO_ADMIN / TRAD\ivango | First Derivatives - primary equities broker used for real stock hedging. Had 3 configuration versions between 2021-2024 as FIX protocol and class names were updated. |
| 128 | Talos | PCSClassInfo=TalosPriceProvider + HedgingProviderClassInfo=TalosHedgingProvider, lot_size=1, OnixS reconnect=10s | TRAD\michaelta | Talos - crypto and FX trading venue added Oct 2024 for institutional-grade crypto execution. Small lot_size=1 indicates unit-based sizing. |
| 9005 | FIX_IG | PCSClassInfo=FixPriceProviderWrapper, batchBulkSize=100, FileStorage | TRAD\danielga | IG Group - connected via FIX protocol for price feeds. Part of the FIX provider batch added Apr 2024 for multi-provider price aggregation. |
| 10006 | ICE | PCSClassInfo=ICEPriceProvider only (no hedging class) | TRAD\Igalsh | Intercontinental Exchange - price feed only provider, added Jan 2024 for commodity and energy market data. No hedging class = price source only. |
| 100 | DO NOT USE | typeSettings (empty) | (internal) | Deprecated/placeholder type ID. The "DO NOT USE" name flags this as retired. Appears in history from Jun 2022, suggesting it was retired at that time. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityProviderTypeID | int | NO | - | CODE-BACKED | Unique identifier for the provider type. This is the PK of Trade.LiquidityProviderType; in the history table it can repeat for the same ID representing successive configuration versions. Numeric ranges follow loose conventions: 1-299=legacy brokers, 300-499=direct exchange connections, 9000-9999=FIX protocol providers, 10000-10999=specialized feeds. Referenced by History.LiquidityProviders.LiquidityProviderTypeID. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable name of the provider type (e.g., "FD", "Talos", "FIX_IG"). Maximum 50 characters. This name is used in operational tooling to identify the technology stack. Some names are placeholders (e.g., "DO NOT USE", "OMS Horizon - Do not use") indicating deprecated types. Some names contain typos preserved from original entry (e.g., "Blooberg Futures"). |
| 3 | TypeSettingsXML | xml | YES | - | CODE-BACKED | XML configuration blob defining the .NET assembly and class names for the Hedge Engine and Price Control System (PCS). Structure: PCSClassInfo (price feed class), HedgingProviderClassInfo (hedge execution class), executionClassInfo (execution client), ProviderExecutionSettings (default_lot_size), OnixsEngineSettings (FIX reconnect parameters). NULL for types without automated assembly configuration. Empty `<typeSettings/>` for configured but class-less types (Watchlist, some deprecated types). The history of this XML reveals how provider integrations evolved over time. |
| 4 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | Captured database login name of the user who last modified this row at time of archival. In the live table (Trade.LiquidityProviderType) this is a computed column = suser_name(); here it is stored as a snapshot. Format: domain\username (e.g., "TRAD\michaelta", "ETORO_ADMIN"). Identifies the operator who made the configuration change. NULL for some rows where context was unavailable. |
| 5 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application-level identity of who initiated the change, stored as a snapshot (in live table this is a computed column = context_info()). Format: "username;ConfigurationManager" followed by null-byte padding to fill the 500-byte buffer (visible as Unicode null characters in raw data). The ";ConfigurationManager" suffix indicates changes made through the Configuration Manager tool. NULL for changes made directly via SQL (no context_info set). |
| 6 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this version of the provider type configuration became active in Trade.LiquidityProviderType. Set automatically by SQL Server SYSTEM_VERSIONING. Precision: 7 decimal places (100ns). Together with SysEndTime, defines the exact period during which this configuration was live. The clustered index is ordered by SysEndTime ASC, SysStartTime ASC for efficient temporal range scans. |
| 7 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this version was superseded (replaced by a newer configuration in Trade.LiquidityProviderType). Set automatically by SQL Server SYSTEM_VERSIONING when the live row is modified or deleted. When SysEndTime equals SysStartTime, the configuration was changed immediately after insertion (effectively instantaneous). The clustered index leading column supports queries filtering by "was this type configured before date X?" |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. As a temporal history table, it does not enforce FK constraints - it is a passive archive managed by SQL Server's SYSTEM_VERSIONING.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.LiquidityProviderType | (SYSTEM_VERSIONING) | Temporal History | This table IS the history table for Trade.LiquidityProviderType. SQL Server automatically populates it. |
| History.LiquidityProviders | LiquidityProviderTypeID | Implicit lookup | Each liquidity provider instance (History.LiquidityProviders) references a provider type; the history of that type's configuration is in this table. |
| History.LiquidityProviderQuantities | LiquidityProviderTypeID | Implicit lookup | Historical quantity configurations per provider type. |
| History.ProviderInstrumentConfiguration | (via LiquidityProviderTypeID) | Implicit lookup | Historical per-instrument settings link back to provider type. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.LiquidityProviderType (table - temporal history)
  - No code-level dependencies (history tables are pure archives managed by SQL Server)
  - Live source: Trade.LiquidityProviderType (table)
```

### 6.1 Objects This Depends On

No dependencies. This is a temporal history table with no code-level dependencies - all data is written by SQL Server's SYSTEM_VERSIONING mechanism.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityProviderType | Table | Live source - SYSTEM_VERSIONING writes superseded rows here automatically |
| History.LiquidityProviders | Table (also temporal history) | Shares the same temporal pattern; LiquidityProviderTypeID links these provider histories |
| History.LiquidityProviderQuantities | Table (also temporal history) | Historical quantity data per provider type |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_LiquidityProviderType | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

Note: The clustered index on (SysEndTime, SysStartTime) is the standard SQL Server pattern for temporal history tables - it optimizes the most common query pattern of finding rows valid as of a point in time or within a date range.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (none) | - | Temporal history tables carry no FK or CHECK constraints - referential integrity is enforced on the live table (Trade.LiquidityProviderType). |

Data compression: PAGE compression applied to reduce storage footprint of the XML-heavy rows.

---

## 8. Sample Queries

### 8.1 Get the configuration of a provider type at a specific point in time

```sql
SELECT
    lpt.LiquidityProviderTypeID,
    lpt.Name,
    lpt.TypeSettingsXML,
    lpt.DbLoginName,
    lpt.SysStartTime,
    lpt.SysEndTime
FROM [Trade].[LiquidityProviderType] FOR SYSTEM_TIME AS OF '2023-09-01 00:00:00'
    WITH (NOLOCK) lpt
WHERE lpt.LiquidityProviderTypeID = 308
```

### 8.2 See the full change history for a specific provider type

```sql
SELECT
    h.LiquidityProviderTypeID,
    h.Name,
    h.DbLoginName,
    h.AppLoginName,
    h.SysStartTime AS ValidFrom,
    h.SysEndTime AS ValidTo,
    DATEDIFF(SECOND, h.SysStartTime, h.SysEndTime) AS DurationSeconds
FROM [History].[LiquidityProviderType] h WITH (NOLOCK)
WHERE h.LiquidityProviderTypeID = 308
ORDER BY h.SysStartTime ASC
```

### 8.3 Find all provider type changes made by a specific operator

```sql
SELECT
    h.LiquidityProviderTypeID,
    h.Name,
    h.DbLoginName,
    h.SysStartTime AS ChangedAt,
    h.TypeSettingsXML
FROM [History].[LiquidityProviderType] h WITH (NOLOCK)
WHERE h.DbLoginName LIKE '%michaelta%'
ORDER BY h.SysStartTime DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Trade.LiquidityProviders](https://etoro-jira.atlassian.net/wiki/spaces/TR/pages/1719304345/Trade.LiquidityProviders) | Confluence | Overview of liquidity provider structure in the TR space - provides context on how provider types relate to provider instances. Last updated 2020-12-23. |

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.9/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed (temporal history - no write procedures) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.LiquidityProviderType | Type: Table (Temporal History) | Source: etoro/etoro/History/Tables/History.LiquidityProviderType.sql*
