# History.PriceInstrumentTypeConfiguration

> Temporal history backing table for Price.InstrumentTypeConfiguration - storing all past versions of the market filter interval configuration per instrument type used by the price feed pipeline.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - clustered on (SysEndTime, SysStartTime) |
| **Partition** | No (ON [PRIMARY] filegroup) |
| **Indexes** | 1 (1 clustered temporal) |

---

## 1. Business Meaning

`History.PriceInstrumentTypeConfiguration` is the **temporal history backing table** for `Price.InstrumentTypeConfiguration`. SQL Server's system-versioned temporal tables automatically move old rows here whenever the live table is updated or deleted, preserving a complete audit trail of all configuration changes. This table is never written to directly.

The live table `Price.InstrumentTypeConfiguration` stores one row per instrument type, controlling how frequently the price feed pipeline processes top-of-book price updates. The `MarketFilterIntervalMS` column sets the minimum interval (in milliseconds) between consecutive price events for a given instrument type - acting as a throttle or deduplication window for incoming feed data. When the pricing team adjusts these intervals (e.g., tuning from 100ms to 400ms for a specific type), the old configuration is automatically versioned here.

With only 7 active rows across 5 instrument types (IDs 3, 4, 5, 6, 10), this is a low-churn configuration table. Changes are infrequent and operationally significant - each change modifies the real-time behavior of the price ingestion pipeline for an entire category of instruments.

The `InstrumentTypeID` column maps to `Dictionary.CurrencyType` (same lookup table, sharing the CurrencyTypeID key space), indicating that instrument type categories correspond to currency/asset type classifications in the dictionary schema.

---

## 2. Business Logic

### 2.1 SQL Server Temporal Table - Automatic Versioning

**What**: Every change to Price.InstrumentTypeConfiguration automatically writes the previous version here.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- `SysStartTime` = UTC timestamp when this configuration became active in Price.InstrumentTypeConfiguration
- `SysEndTime` = UTC timestamp when this configuration was superseded
- Rows in this table are EXPIRED versions only - current config lives in Price.InstrumentTypeConfiguration
- Both timestamps are computed by the SQL Server temporal engine (not application code)

**Diagram**:
```
Price.InstrumentTypeConfiguration (live - current intervals)
    SYSTEM_VERSIONING = ON
    HISTORY_TABLE = History.PriceInstrumentTypeConfiguration
    |
    v
History.PriceInstrumentTypeConfiguration (this table - past interval configurations)
```

### 2.2 MarketFilterIntervalMS - Price Feed Throttle

**What**: Controls how frequently the price pipeline emits updates for each instrument type category.

**Columns/Parameters Involved**: `InstrumentTypeID`, `MarketFilterIntervalMS`

**Rules**:
- The interval is the minimum milliseconds between consecutive price processing events for any instrument belonging to this type
- Lower values = higher update frequency = more processing load but fresher prices
- From live data: most instrument types use 100ms (standard); some use 400ms or 1000ms (slower, higher latency tolerance)
- One row per instrument type - this is a per-category setting, not per-instrument

### 2.3 Audit Identity Capture

**What**: DbLoginName and AppLoginName are auto-computed at write time on the live table, then carried into history.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`

**Rules**:
- `DbLoginName`: computed as `suser_name()` on the live table at INSERT/UPDATE time
- `AppLoginName`: computed as `CONVERT(varchar(500), context_info())` - application sets context_info before writing
- From live data: DbLoginName = `TRAD\urielyo`, AppLoginName = `ConfigurationManager` (the pricing config management application)
- These capture who/what changed the configuration, providing a human-readable audit trail alongside the temporal timestamps

---

## 3. Data Overview

Table had rows populated when Price.InstrumentTypeConfiguration was last modified. Live data shows 7 rows across 5 instrument types.

| InstrumentTypeID | MarketFilterIntervalMS | DbLoginName | AppLoginName | Context |
|---|---|---|---|---|
| 3 | 100 | TRAD\urielyo | ConfigurationManager | Standard 100ms filter for type 3 instruments |
| 4 | 100 | TRAD\urielyo | ConfigurationManager | Standard 100ms filter for type 4 instruments |
| 5 | 400 | TRAD\urielyo | ConfigurationManager | Slower 400ms filter - type 5 instruments tolerate higher latency |
| 6 | 1000 | TRAD\urielyo | ConfigurationManager | 1000ms filter - type 6 instruments (lowest frequency) |
| 10 | 100 | TRAD\urielyo | ConfigurationManager | Standard 100ms filter for type 10 instruments |

*Last configuration change: 2024-05-29 by TRAD\urielyo via ConfigurationManager.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentTypeID | int | NO | - | CODE-BACKED | Category ID of the instrument type this configuration applies to. PK in the live Price.InstrumentTypeConfiguration table. Shares the key space with Dictionary.CurrencyType(CurrencyTypeID) - instrument type IDs correspond to currency/asset type categories. Values observed: 3, 4, 5, 6, 10. |
| 2 | MarketFilterIntervalMS | int | NO | - | CODE-BACKED | Minimum interval in milliseconds between consecutive price processing events for instruments of this type. Acts as a throttle/deduplication window in the price feed pipeline. Common values: 100ms (standard), 400ms (medium latency), 1000ms (low frequency). |
| 3 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL login name of the session that modified Price.InstrumentTypeConfiguration. Computed as suser_name() on the live table. Stored in history rows as-captured. Observed value: TRAD\urielyo (pricing operations account). |
| 4 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application identity set via context_info() by the calling application before modifying the live table. Stored in history rows as-captured. Observed value: ConfigurationManager (pricing configuration management system). May contain null-byte padding due to varchar(500) context_info() storage. |
| 5 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this configuration became active in Price.InstrumentTypeConfiguration. Set by SQL Server temporal engine. Starting boundary of validity period (inclusive). |
| 6 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this configuration was superseded by a newer version. Set by SQL Server temporal engine. Ending boundary of validity period (exclusive). Clustered index leading column for efficient temporal queries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentTypeID | Dictionary.CurrencyType | Implicit (FK enforced on live table) | Instrument type category; same key space as CurrencyTypeID |
| (all columns) | Price.InstrumentTypeConfiguration | Temporal | This is the history backing table for the live Price table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Server temporal engine | (auto) | System | Rows moved here automatically on UPDATE/DELETE of Price.InstrumentTypeConfiguration |
| Price.TRG_T_InstrumentTypeConfiguration | Trigger | Related | No-op touch trigger on live table that forces temporal row versioning on INSERT |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PriceInstrumentTypeConfiguration (table)
(temporal history backing table - no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No dependencies. Written entirely by SQL Server temporal table engine.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.InstrumentTypeConfiguration | Table | Live table - SQL Server moves expired rows here automatically |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_PriceInstrumentTypeConfiguration | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

*DATA_COMPRESSION=PAGE. Clustered on (SysEndTime, SysStartTime) - standard temporal history pattern optimizing FOR SYSTEM_TIME AS OF queries.*

### 7.2 Constraints

None (no FK constraints on history table - constraints enforced on live table).

---

## 8. Sample Queries

### 8.1 Point-in-time instrument type filter configuration (via live table)

```sql
SELECT InstrumentTypeID, MarketFilterIntervalMS, DbLoginName, SysStartTime, SysEndTime
FROM Price.InstrumentTypeConfiguration
FOR SYSTEM_TIME AS OF '2025-01-01 00:00:00'
ORDER BY InstrumentTypeID
```

### 8.2 Full change history for a specific instrument type

```sql
SELECT InstrumentTypeID, MarketFilterIntervalMS, DbLoginName, AppLoginName,
    SysStartTime, SysEndTime,
    DATEDIFF(DAY, SysStartTime, SysEndTime) AS DaysActive
FROM History.PriceInstrumentTypeConfiguration WITH (NOLOCK)
WHERE InstrumentTypeID = @InstrumentTypeID
ORDER BY SysStartTime ASC
```

### 8.3 All configuration changes in the last 90 days

```sql
SELECT InstrumentTypeID, MarketFilterIntervalMS, DbLoginName, AppLoginName,
    SysStartTime, SysEndTime
FROM History.PriceInstrumentTypeConfiguration WITH (NOLOCK)
WHERE SysEndTime >= DATEADD(DAY, -90, GETUTCDATE())
ORDER BY SysEndTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PriceInstrumentTypeConfiguration | Type: Table | Source: etoro/etoro/History/Tables/History.PriceInstrumentTypeConfiguration.sql*
