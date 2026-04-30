# History.ProviderInstrumentConfiguration

> Temporal history backing table for Hedge.ProviderInstrumentConfiguration - storing all past versions of the per-instrument order routing configuration for each liquidity provider, including order type, limit offset, and GTD time span.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - clustered on (SysEndTime, SysStartTime) |
| **Partition** | No (ON [DICTIONARY] filegroup) |
| **Indexes** | 1 (1 clustered temporal) |

---

## 1. Business Meaning

`History.ProviderInstrumentConfiguration` is the **temporal history backing table** for `Hedge.ProviderInstrumentConfiguration`. SQL Server's system-versioned temporal tables automatically move old rows here whenever the live table is updated or deleted. This table is never written to directly.

The live table `Hedge.ProviderInstrumentConfiguration` defines how hedge orders for each instrument are structured when sent to a specific liquidity provider. It controls three key order routing parameters:
- **OrderType**: the type of order to place with the provider (market, limit, etc.)
- **LimitOffsetPercentage**: when placing limit orders, how much to offset from the current price
- **GTDTimeSpanInSeconds**: how long a "Good Till Date" order remains active before expiry

With 0 rows in the current environment, no configurations have been versioned yet (the live table may have never been modified since temporal versioning was enabled, or this is recently configured).

---

## 2. Business Logic

### 2.1 SQL Server Temporal Table - Automatic Versioning

**What**: Every change to Hedge.ProviderInstrumentConfiguration automatically writes the previous version here.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- `SysStartTime` = UTC when this configuration became active
- `SysEndTime` = UTC when this configuration was superseded
- Composite PK on live table: (LiquidityProviderTypeID, InstrumentID) - one row per provider/instrument combination

### 2.2 Order Routing Parameters

**What**: The three business columns control how hedge orders are placed with each provider for each instrument.

**Columns/Parameters Involved**: `LiquidityProviderTypeID`, `InstrumentID`, `OrderType`, `LimitOffsetPercentage`, `GTDTimeSpanInSeconds`

**Rules**:
- `OrderType` (tinyint): determines order type sent to the provider. Enum values defined in the hedge engine (e.g., 0=Market, 1=Limit, 2=GTD or similar)
- `LimitOffsetPercentage` (decimal 8,2): when OrderType requires a limit price, this percentage offset is applied to the reference price to set the limit
- `GTDTimeSpanInSeconds`: for GTD (Good Till Date/Time) orders, how many seconds the order remains live before the provider cancels it automatically
- The combination allows fine-tuned per-instrument, per-provider order placement behavior

---

## 3. Data Overview

0 rows in current environment. No configuration changes have been versioned since temporal versioning was enabled.

| LiquidityProviderTypeID | InstrumentID | OrderType | LimitOffsetPercentage | GTDTimeSpanInSeconds | Context |
|---|---|---|---|---|---|
| (no rows) | | | | | |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityProviderTypeID | int | NO | - | CODE-BACKED | The liquidity provider type for which this order configuration applies. Part of the composite PK in the live Hedge.ProviderInstrumentConfiguration table. Implicit FK to Trade.LiquidityProviderType. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | The financial instrument for which this order configuration applies. Part of the composite PK. Implicit FK to instrument lookup. Together with LiquidityProviderTypeID, provides one configuration row per provider/instrument pair. |
| 3 | OrderType | tinyint | NO | - | CODE-BACKED | Specifies the order type to use when sending hedge orders for this instrument to this provider. Tinyint enum - values defined by the hedge engine (e.g., market order, limit order, GTD order). |
| 4 | LimitOffsetPercentage | decimal(8,2) | NO | - | CODE-BACKED | Percentage offset from the reference price when placing limit orders for this instrument at this provider. Applied as: limit_price = reference_price * (1 +/- LimitOffsetPercentage / 100). Precision to 2 decimal places (e.g., 0.50 = 0.5% offset). |
| 5 | GTDTimeSpanInSeconds | int | NO | - | CODE-BACKED | Duration in seconds for Good Till Date orders. When an order is placed with GTD order type, the provider will cancel it if unfilled after this many seconds. Controls order lifecycle for non-immediate execution modes. |
| 6 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL login captured via suser_name() at write time on the live table. Identifies who changed the order routing configuration. |
| 7 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application identity from context_info() at write time. May contain null-byte padding from varchar(500) context_info() storage. |
| 8 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this order configuration became active. Set by SQL Server temporal engine. Starting boundary of validity period (inclusive). |
| 9 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this configuration was superseded. Set by SQL Server temporal engine. Ending boundary (exclusive). Clustered index leading column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityProviderTypeID | Trade.LiquidityProviderType | Implicit (FK on live table) | The liquidity provider type being configured |
| InstrumentID | Instrument lookup | Implicit | The instrument this order configuration applies to |
| (all columns) | Hedge.ProviderInstrumentConfiguration | Temporal | This is the history backing table for the live Hedge table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Server temporal engine | (auto) | System | Rows moved here automatically when Hedge.ProviderInstrumentConfiguration is modified |
| Hedge.Tr_T_ProviderInstrumentConfiguration_INSERT | Trigger | Related | No-op touch trigger on live table that forces temporal versioning on INSERT |
| Hedge.GetProviderInstrumentConfiguration | Stored Procedure | READER | Reads live table to get order routing parameters for hedge execution |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ProviderInstrumentConfiguration (table)
(temporal history backing table - no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No dependencies. Written entirely by SQL Server temporal table engine.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ProviderInstrumentConfiguration | Table | Live table - SQL Server moves expired rows here automatically |
| Hedge.GetProviderInstrumentConfiguration | Stored Procedure | Reads live table for order routing parameters |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_ProviderInstrumentConfiguration | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

*DATA_COMPRESSION=PAGE. ON [DICTIONARY] filegroup. Standard temporal history clustering pattern.*

### 7.2 Constraints

None (FK/PK constraints enforced on live Hedge.ProviderInstrumentConfiguration table).

---

## 8. Sample Queries

### 8.1 Point-in-time order routing configuration (via live table)

```sql
SELECT LiquidityProviderTypeID, InstrumentID, OrderType, LimitOffsetPercentage, GTDTimeSpanInSeconds,
    DbLoginName, SysStartTime, SysEndTime
FROM Hedge.ProviderInstrumentConfiguration
FOR SYSTEM_TIME AS OF '2025-01-01 00:00:00'
WHERE LiquidityProviderTypeID = @ProviderTypeID
```

### 8.2 Change history for a specific provider-instrument configuration

```sql
SELECT LiquidityProviderTypeID, InstrumentID, OrderType, LimitOffsetPercentage, GTDTimeSpanInSeconds,
    DbLoginName, AppLoginName, SysStartTime, SysEndTime,
    DATEDIFF(DAY, SysStartTime, SysEndTime) AS DaysActive
FROM History.ProviderInstrumentConfiguration WITH (NOLOCK)
WHERE LiquidityProviderTypeID = @ProviderTypeID AND InstrumentID = @InstrumentID
ORDER BY SysStartTime ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ProviderInstrumentConfiguration | Type: Table | Source: etoro/etoro/History/Tables/History.ProviderInstrumentConfiguration.sql*
