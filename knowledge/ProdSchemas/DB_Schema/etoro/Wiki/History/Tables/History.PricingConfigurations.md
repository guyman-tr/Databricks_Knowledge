# History.PricingConfigurations

> Temporal history backing table for Price.PricingConfigurations - storing all past versions of the per-instrument pricing pipeline configuration including distribution type, pricing type, provider assignment, throttling intervals, and account routing.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - clustered on (SysEndTime, SysStartTime) |
| **Partition** | No (ON [DICTIONARY] filegroup) |
| **Indexes** | 3 (1 clustered temporal + 2 nonclustered on SysEndTime/SysStartTime) |

---

## 1. Business Meaning

`History.PricingConfigurations` is the **temporal history backing table** for `Price.PricingConfigurations`. SQL Server's system-versioned temporal tables automatically move old rows here whenever the live table is updated or deleted. This table is never written to directly.

The live table `Price.PricingConfigurations` holds one row per instrument, defining how that instrument's price is sourced, processed, and distributed:
- **DistributionType**: Controls how prices are published/distributed to clients
- **PricingType**: Determines the pricing strategy (e.g., raw feed redistribution vs. calculated pricing)
- **ProviderId**: The price feed provider assigned to this instrument
- **Throttling columns**: Rate-limiting controls at three pipeline stages (top-of-book, feed, client)
- **AccountId**: Routing identifier for price distribution (e.g., "RawRedistribution")

With 202,064 history rows and active writes as recently as February 2026, this is a high-churn configuration table - pricing configurations for instruments are frequently added or updated as new instruments are onboarded or feed assignments change. The dominant configuration (63% of rows) is `DistributionType=1, PricingType=1` which represents the standard active pricing mode.

The table lives on the [DICTIONARY] filegroup alongside the live table, reflecting its role as a configuration/reference store rather than a high-volume transactional log.

---

## 2. Business Logic

### 2.1 SQL Server Temporal Table - Automatic Versioning

**What**: Every change to Price.PricingConfigurations automatically writes the previous version here.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- `SysStartTime` = UTC timestamp when this configuration became active in Price.PricingConfigurations
- `SysEndTime` = UTC timestamp when this configuration was superseded
- Rows here are EXPIRED versions only - current config lives in Price.PricingConfigurations
- Both timestamps set by SQL Server temporal engine

**Diagram**:
```
Price.PricingConfigurations (live - current per-instrument pricing config)
    SYSTEM_VERSIONING = ON (HISTORY_TABLE = History.PricingConfigurations)
    |
    v
History.PricingConfigurations (this table - past pricing configurations)
```

### 2.2 DistributionType and PricingType Classification

**What**: The combination of DistributionType and PricingType defines the pricing mode for each instrument.

**Columns/Parameters Involved**: `InstrumentID`, `DistributionType`, `PricingType`

**Rules**:
- From 202K history rows (distribution of expired configurations):
  - DistributionType=1, PricingType=1: 127,827 rows (63%) - standard active pricing mode
  - DistributionType=1, PricingType=0: 38,520 rows (19%) - distribution active, pricing inactive/raw
  - DistributionType=0, PricingType=0: 35,708 rows (18%) - fully inactive (instrument not priced)
  - DistributionType=0, PricingType=1: 8 rows (<1%) - rare/transitional state
  - DistributionType=1, PricingType=2: 1 row (<1%) - special pricing type
- AccountId="RawRedistribution" is the dominant routing target for standard priced instruments

### 2.3 Three-Stage Throttling Pipeline

**What**: Price updates pass through three throttling stages, each rate-limited independently.

**Columns/Parameters Involved**: `TopOfBookThrottlingInMs`, `FeedThrottlingInMs`, `ClientThrottlingInMs`

**Rules**:
- `TopOfBookThrottlingInMs`: Minimum interval at the top-of-book aggregation stage
- `FeedThrottlingInMs`: Minimum interval at the feed processing stage
- `ClientThrottlingInMs`: Minimum interval for client-facing price emission
- NULL in any column = no throttling applied at that stage
- Most standard instruments have all three as NULL (rely on InstrumentTypeConfiguration's MarketFilterIntervalMS instead)
- When non-NULL, these override the type-level filter for specific instruments needing special handling

### 2.4 Provider Assignment

**What**: ProviderId links each instrument to its designated price feed provider.

**Columns/Parameters Involved**: `InstrumentID`, `ProviderId`

**Rules**:
- ProviderId=1 is the dominant value in recent history rows (observed in top-5 data)
- NULL ProviderId = instrument uses system-default or inherited provider assignment
- Changes to ProviderId generate a history row, enabling audit of provider reassignments

---

## 3. Data Overview

202,064 rows. High churn - multiple instruments update configuration frequently. Most recent changes: February 2026.

| InstrumentID | DistributionType | PricingType | ProviderId | AccountId | TopOfBookThrottlingInMs | FeedThrottlingInMs | ClientThrottlingInMs | SysEndTime |
|---|---|---|---|---|---|---|---|---|
| 1053988 | 1 | 1 | 1 | RawRedistribution | NULL | NULL | NULL | 2026-02-17 16:05:31 |
| 1016586 | 1 | 1 | 1 | RawRedistribution | NULL | NULL | NULL | 2026-02-17 10:27:39 |
| 1050127 | 1 | 1 | 1 | RawRedistribution | NULL | NULL | NULL | 2026-02-12 12:13:37 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Financial instrument this pricing configuration applies to. PK in the live Price.PricingConfigurations (one row per instrument). Implicit FK to instrument lookup. |
| 2 | DistributionType | tinyint | NO | - | CODE-BACKED | Controls how prices for this instrument are distributed to clients. 0=distribution inactive (instrument not published), 1=distribution active. Dominant value: 1 (63%+18%=81% of history rows have active distribution in some form). |
| 3 | PricingType | tinyint | NO | - | CODE-BACKED | Pricing strategy for this instrument. 0=inactive/raw, 1=standard active pricing (feeds from ProviderId), 2=special pricing mode. Combined with DistributionType=1/PricingType=1 as the standard operating configuration (63% of rows). |
| 4 | ProviderId | int | YES | - | CODE-BACKED | ID of the price feed provider assigned to this instrument. Implicit FK to provider lookup. NULL = no specific provider assigned (system default). Most recent rows show ProviderId=1 as the primary provider. |
| 5 | TopOfBookThrottlingInMs | int | YES | - | CODE-BACKED | Rate-limit interval in milliseconds at the top-of-book aggregation stage. NULL = no throttle at this stage. When set, overrides the InstrumentTypeConfiguration filter for this specific instrument. |
| 6 | FeedThrottlingInMs | int | YES | - | CODE-BACKED | Rate-limit interval in milliseconds at the feed processing stage. NULL = no throttle. Part of the three-stage pipeline throttle system. |
| 7 | ClientThrottlingInMs | int | YES | - | CODE-BACKED | Rate-limit interval in milliseconds for client-facing price emission. NULL = no throttle. Controls the maximum frequency at which price updates are pushed to connected clients for this instrument. |
| 8 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL login name captured at write time via suser_name() on the live table. Identifies the DBA or service account that modified the pricing configuration. Stored in history rows as-captured. |
| 9 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application identity from context_info() set before writing the live table. Observed value: PricingOpsApiUser (the pricing operations API). May contain null-byte padding from varchar(500) context_info() storage. |
| 10 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this pricing configuration became active in Price.PricingConfigurations. Set by SQL Server temporal engine. Starting boundary of validity period (inclusive). |
| 11 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this configuration was superseded. Set by SQL Server temporal engine. Ending boundary (exclusive). Clustered index leading column. Two additional nonclustered indexes (IX_SysEndTime, IX_SysStartTime) support efficient temporal range queries. |
| 12 | AccountId | varchar(100) | YES | - | CODE-BACKED | Routing identifier for price distribution. Dominant value: "RawRedistribution" (instruments whose prices are redistributed from the raw feed). NULL for instruments with non-standard routing. Added as a later column (positioned last in DDL). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Instrument lookup | Implicit | The instrument being configured |
| ProviderId | Provider lookup | Implicit | The price feed provider assigned to this instrument |
| (all columns) | Price.PricingConfigurations | Temporal | This is the history backing table for the live Price table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Server temporal engine | (auto) | System | Rows moved here automatically when Price.PricingConfigurations is updated |
| Price.TRG_INSERT_PricingConfigurations | Trigger | Related | No-op touch trigger on live table that forces temporal row versioning on INSERT |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PricingConfigurations (table)
(temporal history backing table - no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No dependencies. Written entirely by SQL Server temporal table engine.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.PricingConfigurations | Table | Live table - SQL Server moves expired rows here automatically |
| Price.UpdatePricingConfigurations | Stored Procedure | Updates live table (indirectly generates history rows via temporal engine); uses TVP Price.PricingConfigurationList |
| Price.InsertPricingConfiguration | Stored Procedure | Inserts new instrument configurations into live table (generates first history row) |
| Price.GetPricingConfigurations | Stored Procedure | Reads live table (may use FOR SYSTEM_TIME queries) |
| Price.GetPricingConfigurationsByInstrumentIds | Stored Procedure | Reads live table for specific instrument IDs |
| Price.CheckPricingConfigurationsExistence | Stored Procedure | Validates configuration existence on live table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_PricingConfigurations | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |
| IX_SysEndTime | NONCLUSTERED | SysEndTime ASC | - | - | Active |
| IX_SysStartTime | NONCLUSTERED | SysStartTime ASC | - | - | Active |

*DATA_COMPRESSION=PAGE on clustered index and history table. ON [DICTIONARY] filegroup. The two additional nonclustered indexes (IX_SysEndTime, IX_SysStartTime) are unusual for temporal history tables - likely added due to high query volume on temporal range scans given the 202K+ row count.*

### 7.2 Constraints

None (no FK constraints on history table - constraints enforced on live table).

---

## 8. Sample Queries

### 8.1 Point-in-time pricing configuration (via live table)

```sql
SELECT InstrumentID, DistributionType, PricingType, ProviderId, AccountId,
    TopOfBookThrottlingInMs, FeedThrottlingInMs, ClientThrottlingInMs,
    DbLoginName, SysStartTime, SysEndTime
FROM Price.PricingConfigurations
FOR SYSTEM_TIME AS OF '2025-01-01 00:00:00'
WHERE InstrumentID = @InstrumentID
```

### 8.2 Full change history for a specific instrument

```sql
SELECT InstrumentID, DistributionType, PricingType, ProviderId, AccountId,
    DbLoginName, AppLoginName, SysStartTime, SysEndTime,
    DATEDIFF(SECOND, SysStartTime, SysEndTime) AS DurationSeconds
FROM History.PricingConfigurations WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
ORDER BY SysStartTime ASC
```

### 8.3 Recent provider reassignments (last 30 days)

```sql
SELECT InstrumentID, ProviderId, AccountId, DistributionType, PricingType,
    DbLoginName, AppLoginName, SysStartTime, SysEndTime
FROM History.PricingConfigurations WITH (NOLOCK)
WHERE SysEndTime >= DATEADD(DAY, -30, GETUTCDATE())
ORDER BY SysEndTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.9/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PricingConfigurations | Type: Table | Source: etoro/etoro/History/Tables/History.PricingConfigurations.sql*
